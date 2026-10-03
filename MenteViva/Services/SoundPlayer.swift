import AVFoundation
import UIKit

/// Synthesized game sounds + haptics — no audio files, no royalties, no fees
/// (see docs/jev-sounds.md). Sound and haptics share one Settings toggle.
@MainActor
enum Feedback {
    /// A user interaction that receives synchronized sound and haptic feedback.
    enum Event {
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

    private static var engine: AVAudioEngine?
    private static var playerNode: AVAudioPlayerNode?

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
        guard isEnabled else { return }
        // .ambient respects the silent switch and mixes with other audio.
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.ambient, options: [.mixWithOthers])

        if engine == nil {
            let e = AVAudioEngine()
            engine = e
        }
        guard let engine else { return }

        guard let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1),
            let buffer = Self.buffer(for: event, format: format)
        else { return }

        if playerNode == nil {
            let player = AVAudioPlayerNode()
            engine.attach(player)
            engine.connect(player, to: engine.mainMixerNode, format: format)
            playerNode = player
        }
        guard let playerNode else { return }

        engine.prepare()
        if !engine.isRunning {
            try? engine.start()
        }

        // Reuse the node. The .interrupts option stops the previous short tone
        // without requiring graph mutation from the audio render thread.
        playerNode.scheduleBuffer(buffer, at: nil, options: .interrupts)
        playerNode.play()
    }

    private static func buffer(for event: Feedback.Event, format: AVAudioFormat) -> AVAudioPCMBuffer? {
        // Concatenate one or more notes into a single scheduled buffer.
        let notes: [(Double, Double, Float)]
        switch event {
        case .tap:
            notes = [(440, 0.10, 0.35)]
        case .success:
            notes = [(392, 0.14, 0.5), (523, 0.18, 0.5)]
        case .complete:
            notes = [(392, 0.12, 0.5), (523, 0.12, 0.5), (659, 0.20, 0.5)]
        case .miss:
            notes = [(180, 0.16, 0.28)]
        }

        let sampleRate = 44100.0
        var totalDuration = 0.0
        for note in notes { totalDuration += note.1 }

        let totalFrames = AVAudioFrameCount(totalDuration * sampleRate)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: totalFrames),
            let channel = buffer.floatChannelData?[0]
        else { return nil }
        buffer.frameLength = totalFrames

        var offset = 0
        for note in notes {
            let freq = note.0
            let duration = note.1
            let amplitude = note.2
            let frames = AVAudioFrameCount(sampleRate * duration)
            let attack = 0.01
            for i in 0..<Int(frames) {
                let t = Double(i) / sampleRate
                let attackEnv = min(t / attack, 1.0)
                let decayEnv = max(1.0 - t / (duration * 0.25), 0.0)
                let envelope = Float(attackEnv * decayEnv)
                channel[offset + i] = Float(sin(2.0 * Double.pi * freq * t)) * envelope * amplitude
            }
            offset += Int(frames)
        }
        return buffer
    }
}
