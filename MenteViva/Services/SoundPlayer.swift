import AVFoundation
import UIKit

/// Synthesized game sounds + haptics — no audio files, no royalties, no fees
/// (see docs/jev-sounds.md). Sound and haptics share one Settings toggle.
@MainActor
enum Feedback {
    /// A user interaction that receives synchronized sound and haptic feedback.
    enum Event: CaseIterable {
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

    private static func haptic(for event: Event) {
        guard SoundPlayer.isEnabled else { return }
        switch event {
        case .tap: UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .success: UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        case .complete: UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .miss: UIImpactFeedbackGenerator(style: .soft).impactOccurred()
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

            if !engine.isRunning {
                engine.prepare()
                try? engine.start()
            }

            // Reuse the node. The .interrupts option stops the previous short tone
            // without requiring graph mutation from the audio render thread.
            playerNode.scheduleBuffer(buffer, at: nil, options: .interrupts)
            playerNode.play()
        }
    }

    /// Each tone is synthesized once, then reused: four short buffers, so a tap
    /// never pays for rendering sine waves.
    private static var buffers: [Feedback.Event: AVAudioPCMBuffer] = [:]

    private static func cachedBuffer(for event: Feedback.Event, format: AVAudioFormat) -> AVAudioPCMBuffer? {
        if let cached = buffers[event] { return cached }
        let rendered = buffer(for: event, format: format)
        buffers[event] = rendered
        return rendered
    }

    /// Copies the synthesized samples (see `ToneSynth`) into a playable buffer.
    private static func buffer(for event: Feedback.Event, format: AVAudioFormat) -> AVAudioPCMBuffer? {
        let samples = ToneSynth.samples(for: event)
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
