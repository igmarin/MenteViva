import AVFoundation
import UIKit

/// Synthesized game sounds + haptics — no audio files, no royalties, no fees
/// (see docs/jev-sounds.md). Sound and haptics share one Settings toggle.
nonisolated enum Feedback {
    enum Event { case tap, success, complete, miss }

    /// One call for every feedback moment: plays the tone and, on a device that
    /// supports it, a matching haptic. Both are no-ops in the simulator's audio
    /// path or when the toggle is off. Nothing here ever blocks the UI.
    static func play(_ event: Event) {
        SoundPlayer.play(tone(for: event))
        haptic(for: event)
    }

    private static func tone(for event: Event) -> SoundPlayer.Tone {
        switch event {
        case .tap: .tap
        case .success: .success
        case .complete: .complete
        case .miss: .miss
        }
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

/// Synthesized tones (no audio files). Three soft, low-frequency sounds; a wrong
/// answer is a short, quiet, low tone, never a buzzer.
nonisolated enum SoundPlayer {
    enum Tone { case tap, success, complete, miss }

    private static var engine: AVAudioEngine?

    /// Whether sound is currently allowed. The single Settings toggle governs
    /// both sound and haptics (docs/jev-sounds.md decision 5).
    static var isEnabled: Bool {
        UserDefaults.standard.object(forKey: "soundEnabled") as? Bool ?? true
    }

    static func play(_ tone: Tone) {
        guard isEnabled else { return }
        // .ambient respects the silent switch and mixes with other audio.
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.ambient, options: [.mixWithOthers])

        if engine == nil {
            let e = AVAudioEngine()
            engine = e
        }
        guard let engine else { return }

        let player = AVAudioPlayerNode()
        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!
        let buffer = Self.buffer(for: tone, format: format)
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)
        engine.prepare()
        try? engine.start()

        player.scheduleBuffer(buffer, at: nil, options: .interrupts, completionHandler: {
            player.stop()
            engine.detach(player)
        })
        player.play()
    }

    private static func buffer(for tone: Tone, format: AVAudioFormat) -> AVAudioPCMBuffer {
        // Concatenate one or more notes into a single scheduled buffer.
        let notes: [(Double, Double, Float)]
        switch tone {
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
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: totalFrames)!
        buffer.frameLength = totalFrames
        let channel = buffer.floatChannelData![0]

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
