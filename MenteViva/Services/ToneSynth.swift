import Foundation

/// Renders the app's feedback tones as plain samples, with no audio engine involved.
///
/// It lives apart from `SoundPlayer` so the note tables and the waveform can be tested
/// (headroom, miss pitch) on any machine; `SoundPlayer` only copies the samples into a
/// buffer and plays them (#240, finding 6 in docs/review-2026-10-gamefeel.md).
enum ToneSynth {
    /// One note of a tone: pitch in Hz, length in seconds, and peak level of the fundamental (0...1).
    struct Note: Equatable {
        let frequency: Double
        let duration: Double
        let amplitude: Float
    }

    /// Samples per second; the player builds its audio format from the same value.
    static let sampleRate = 44100.0
    /// Linear fade-in so a tone never starts with a click.
    static let attack = 0.01
    /// How far the level falls over a whole note: e^-5 is under 1%, so the end is a
    /// whisper rather than a hard zero (a cut-off would click on a phone speaker).
    static let decayRate = 5.0
    /// Level of the second harmonic relative to the fundamental; it adds warmth and is
    /// what small speakers can still reproduce when the fundamental is low.
    static let harmonicLevel = 0.2
    /// The summed peak of every rendered tone must stay under this (checked in tests).
    static let headroom: Float = 0.8

    /// The notes of each feedback moment. The miss tone stays the lowest and softest, but
    /// at 280 Hz so an iPhone speaker can actually play it.
    static func notes(for event: Feedback.Event) -> [Note] {
        switch event {
        case .tap:
            return [Note(frequency: 440, duration: 0.10, amplitude: 0.35)]
        case .success:
            return [
                Note(frequency: 392, duration: 0.14, amplitude: 0.5),
                Note(frequency: 523, duration: 0.18, amplitude: 0.5),
            ]
        case .complete:
            return [
                Note(frequency: 392, duration: 0.12, amplitude: 0.5),
                Note(frequency: 523, duration: 0.12, amplitude: 0.5),
                Note(frequency: 659, duration: 0.20, amplitude: 0.5),
            ]
        case .miss:
            return [Note(frequency: 280, duration: 0.20, amplitude: 0.28)]
        }
    }

    /// One pentatonic pitch per Repeat the Sequence tile (C D E G A, then up to G), so any
    /// order the tiles are played in sounds pleasant and no two tiles share a pitch.
    static let tilePitches: [Double] = [262, 294, 330, 392, 440, 523, 587, 659, 784]

    /// The note a tile sounds when it lights or is tapped. An index off the board is
    /// clamped to the nearest tile rather than failing, since this runs during play.
    /// Amplitude 0.45 plus the second harmonic peaks near 0.54, under `headroom`.
    static func tileNote(_ index: Int) -> Note {
        let safe = min(max(index, 0), tilePitches.count - 1)
        return Note(frequency: tilePitches[safe], duration: 0.28, amplitude: 0.45)
    }

    /// The samples for an event: its notes rendered one after another.
    static func samples(for event: Feedback.Event) -> [Float] {
        render(notes(for: event))
    }

    /// Renders notes back to back. Each note is a fundamental plus a soft second harmonic under a
    /// 10 ms attack and an exponential decay across the whole note.
    static func render(_ notes: [Note]) -> [Float] {
        var output: [Float] = []
        for note in notes {
            // Truncate per note, then append, so the length is exactly the sum of the notes.
            let frames = Int(sampleRate * note.duration)
            output.reserveCapacity(output.count + frames)
            for i in 0..<frames {
                let t = Double(i) / sampleRate
                let envelope = min(t / attack, 1.0) * exp(-decayRate * t / note.duration)
                let phase = 2.0 * Double.pi * note.frequency * t
                let wave = sin(phase) + harmonicLevel * sin(2.0 * phase)
                output.append(Float(wave * envelope) * note.amplitude)
            }
        }
        return output
    }
}
