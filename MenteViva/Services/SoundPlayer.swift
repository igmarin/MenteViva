import AVFoundation
import UIKit

/// Synthesized game sounds + haptics — no audio files, no royalties, no fees
/// (see docs/jev-sounds.md). Sound and haptics share one Settings toggle.
@MainActor
enum Feedback {
    /// A user interaction that receives synchronized sound and haptic feedback.
    nonisolated enum Event: CaseIterable {
        case tap
        case success
        case complete
        case miss
    }

    /// One call for every feedback moment: plays the tone and, on a device that
    /// supports it, a matching haptic. Both are no-ops in the simulator's audio
    /// path or when the toggle is off. Nothing here ever blocks the UI.
    static func play(_ event: Event) {
        SoundPlayer.play(event)
        haptic(for: event)
    }

    /// A Repeat the Sequence tile tapped by the player: its own note plus the
    /// light tap haptic. Same toggle as every other feedback moment.
    static func playTile(_ index: Int) {
        SoundPlayer.playTile(index)
        haptic(for: .tap)
    }

    /// Generators are created once and kept prepared, so the first tap of a
    /// game does not wait for the Taptic Engine to spin up (#417).
    private static let light = UIImpactFeedbackGenerator(style: .light)
    private static let medium = UIImpactFeedbackGenerator(style: .medium)
    private static let soft = UIImpactFeedbackGenerator(style: .soft)
    private static let notification = UINotificationFeedbackGenerator()

    /// Wakes the haptic generators ahead of the first tap. No-op when feedback is off.
    static func warmUp() {
        guard SoundPlayer.isEnabled else { return }
        light.prepare()
        medium.prepare()
        soft.prepare()
        notification.prepare()
    }

    private static func haptic(for event: Event) {
        guard SoundPlayer.isEnabled else { return }
        switch event {
        case .tap:
            light.impactOccurred()
            light.prepare()
        case .success:
            medium.impactOccurred()
            medium.prepare()
        case .complete:
            notification.notificationOccurred(.success)
            notification.prepare()
        case .miss:
            soft.impactOccurred()
            soft.prepare()
        }
    }
}

/// Creates the app's short, synthesized feedback tones.
///
/// No audio files are bundled. Playback is intentionally gentle, respects the
/// device's silent switch, and shares its setting with haptic feedback.
@MainActor
enum SoundPlayer {
    /// The shared UserDefaults key used by Settings and feedback playback.
    static let enabledKey = "soundEnabled"

    /// Used only on `AudioSession`'s queue.
    nonisolated(unsafe) private static var engine: AVAudioEngine?
    nonisolated(unsafe) private static var playerNode: AVAudioPlayerNode?

    /// How long the audio engine may sit unused before it is stopped, so a
    /// finished game does not keep the audio hardware awake.
    nonisolated static let idleStopDelay: TimeInterval = 4

    /// Whether the engine has been quiet long enough to stop. Pure so the
    /// timing rule is tested without an engine or a clock.
    nonisolated static func shouldStopEngine(
        lastToneAt: TimeInterval, now: TimeInterval, delay: TimeInterval = idleStopDelay
    ) -> Bool {
        now - lastToneAt >= delay
    }

    /// Time of the last scheduled tone. Used only on `AudioSession`'s queue.
    nonisolated(unsafe) private static var lastToneAt: TimeInterval = 0

    /// Prepares the haptics and renders the event tone buffers ahead of the
    /// first tap. The audio engine itself still starts on the first tone. Called when a game opens; does nothing while feedback is off.
    static func warmUp() {
        guard isEnabled else { return }
        Feedback.warmUp()
        guard let format = AVAudioFormat(standardFormatWithSampleRate: ToneSynth.sampleRate, channels: 1)
        else { return }
        for event in Feedback.Event.allCases { _ = cachedBuffer(for: event, format: format) }
    }

    /// Whether sound and haptics are currently allowed.
    ///
    /// The setting is shared by the sound and haptic paths, so a player can
    /// silence all feedback from one place (see `docs/jev-sounds.md`).
    static var isEnabled: Bool {
        UserDefaults.standard.object(forKey: enabledKey) as? Bool ?? true
    }

    /// Plays the event's tone if feedback is enabled.
    ///
    /// Playback is best effort: audio-session setup and engine startup are
    /// allowed to fail without interrupting the game.
    ///
    /// - Parameter event: The moment whose tone to play.
    static func play(_ event: Feedback.Event) {
        guard isEnabled,
            let format = AVAudioFormat(standardFormatWithSampleRate: ToneSynth.sampleRate, channels: 1),
            let buffer = cachedBuffer(for: event, format: format)
        else { return }
        schedule(buffer, format: format)
    }

    /// Plays one Repeat the Sequence tile's own note (see `ToneSynth.tileNote`), so the
    /// order can be heard as well as seen. Silent when feedback is off; the tile still lights.
    ///
    /// - Parameter index: The tile's position on the board (0...8).
    static func playTile(_ index: Int) {
        guard isEnabled,
            let format = AVAudioFormat(standardFormatWithSampleRate: ToneSynth.sampleRate, channels: 1),
            let buffer = cachedTileBuffer(index, format: format)
        else { return }
        schedule(buffer, format: format)
    }

    /// Hands a ready buffer to the shared engine, best effort.
    private static func schedule(_ buffer: AVAudioPCMBuffer, format: AVAudioFormat) {
        // On the session queue: the category is set before the engine starts,
        // and starting it (which can block) stays off the main thread.
        AudioSession.playTone {
            if engine == nil {
                engine = AVAudioEngine()
            }
            guard let engine else { return }

            if playerNode == nil {
                let player = AVAudioPlayerNode()
                engine.attach(player)
                engine.connect(player, to: engine.mainMixerNode, format: format)
                playerNode = player
            }
            guard let playerNode else { return }

            // After a call, Siri or an alarm the engine can refuse to start.
            // `playerNode.play()` on a stopped engine raises an Objective-C
            // exception Swift cannot catch, so skip this tone and try again on
            // the next tap.
            if !engine.isRunning {
                engine.prepare()
                do {
                    try engine.start()
                } catch {
                    return
                }
            }

            // Reuse the node. The .interrupts option stops the previous short tone
            // without requiring graph mutation from the audio render thread.
            playerNode.scheduleBuffer(buffer, at: nil, options: .interrupts)
            playerNode.play()

            lastToneAt = ProcessInfo.processInfo.systemUptime
            // Each tone arms its own check; only the one after the last tone
            // finds the engine idle. The next tone restarts the engine above.
            AudioSession.run(after: idleStopDelay) {
                guard let engine = SoundPlayer.engine, let playerNode = SoundPlayer.playerNode, engine.isRunning,
                    shouldStopEngine(lastToneAt: lastToneAt, now: ProcessInfo.processInfo.systemUptime)
                else { return }
                playerNode.stop()
                engine.stop()
            }
        }
    }

    /// Each tone is synthesized once, then reused: four short buffers, so a tap
    /// never pays for rendering sine waves.
    private static var buffers: [Feedback.Event: AVAudioPCMBuffer] = [:]

    /// The nine tile notes, rendered once on first use like the event tones.
    private static var tileBuffers: [Int: AVAudioPCMBuffer] = [:]

    private static func cachedTileBuffer(_ index: Int, format: AVAudioFormat) -> AVAudioPCMBuffer? {
        if let cached = tileBuffers[index] { return cached }
        let rendered = makeBuffer(samples: ToneSynth.render([ToneSynth.tileNote(index)]), format: format)
        tileBuffers[index] = rendered
        return rendered
    }

    private static func cachedBuffer(for event: Feedback.Event, format: AVAudioFormat) -> AVAudioPCMBuffer? {
        if let cached = buffers[event] { return cached }
        let rendered = buffer(for: event, format: format)
        buffers[event] = rendered
        return rendered
    }

    /// Copies the synthesized samples (see `ToneSynth`) into a playable buffer.
    private static func buffer(for event: Feedback.Event, format: AVAudioFormat) -> AVAudioPCMBuffer? {
        makeBuffer(samples: ToneSynth.samples(for: event), format: format)
    }

    private static func makeBuffer(samples: [Float], format: AVAudioFormat) -> AVAudioPCMBuffer? {
        let totalFrames = AVAudioFrameCount(samples.count)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: totalFrames),
            let channel = buffer.floatChannelData?[0]
        else { return nil }
        buffer.frameLength = totalFrames
        for (i, sample) in samples.enumerated() { channel[i] = sample }
        return buffer
    }
}

/// The one owner of the shared AVAudioSession, for spoken names and game tones
/// alike. Every session call runs on one serial queue, so a check ("is a name
/// being spoken?") and the change it guards run together and in order, and
/// none of them blocks the main thread (the async session API needs iOS 27).
nonisolated enum AudioSession {
    private static let queue = DispatchQueue(label: "AudioSession", qos: .userInitiated)
    /// The utterance that owns the session (.playback), if any. Used only on `queue`.
    nonisolated(unsafe) private static var speech: ObjectIdentifier?

    /// Hands the session to `utterance` (.playback, active), then runs `start` on
    /// the main thread, so speech never begins under the old category.
    static func beginSpeech(_ utterance: ObjectIdentifier, then start: @escaping @MainActor () -> Void) {
        queue.async {
            speech = utterance
            try? CaptionSpeaker.configureSession()
            try? AVAudioSession.sharedInstance().setActive(true)
            DispatchQueue.main.async { start() }
        }
    }

    /// Gives the session back once `utterance` is done, unless a newer name
    /// already owns it.
    static func endSpeech(_ utterance: ObjectIdentifier) {
        queue.async {
            guard speech == utterance else { return }
            speech = nil
            try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        }
    }

    /// Runs `work` on the session queue after `delay` seconds.
    static func run(after delay: TimeInterval, _ work: @escaping @Sendable () -> Void) {
        queue.asyncAfter(deadline: .now() + delay, execute: work)
    }

    /// Runs `play` under .ambient (respects the silent switch, mixes with other
    /// audio). While a name is being spoken the category is left alone: flipping
    /// it mid-utterance would drop the voice below the silent switch.
    static func playTone(_ play: @escaping @Sendable () -> Void) {
        queue.async {
            let session = AVAudioSession.sharedInstance()
            if speech == nil, session.category != .ambient {
                try? session.setCategory(.ambient, options: [.mixWithOthers])
            }
            play()
        }
    }
}
