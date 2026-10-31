import XCTest

@testable import MenteViva

/// #240: the tones are warm and soft, and the miss tone is high enough for a phone speaker.
final class ToneSynthTests: XCTestCase {
    func testGivenEachEventWhenRenderedThenPeakBelowHeadroom() {
        for event in Feedback.Event.allCases {
            let samples = ToneSynth.samples(for: event)
            let peak = samples.map { abs($0) }.max() ?? 0
            XCTAssertFalse(samples.isEmpty, "\(event) rendered nothing")
            XCTAssertLessThan(peak, ToneSynth.headroom, "\(event) peaks at \(peak)")
        }
    }

    func testGivenMissWhenRenderedThenFundamentalAtLeast250Hz() {
        let notes = ToneSynth.notes(for: .miss)
        XCTAssertFalse(notes.isEmpty)
        for note in notes {
            XCTAssertGreaterThanOrEqual(note.frequency, 250)
            XCTAssertLessThanOrEqual(note.frequency, 300)
        }
    }

    func testGivenMissWhenComparedThenLowerAndSofterThanTheOthers() {
        let miss = ToneSynth.notes(for: .miss)
        let others = Feedback.Event.allCases.filter { $0 != .miss }.flatMap { ToneSynth.notes(for: $0) }
        XCTAssertLessThan(miss.map(\.frequency).max() ?? 0, others.map(\.frequency).min() ?? 0)
        XCTAssertLessThan(miss.map(\.amplitude).max() ?? 0, others.map(\.amplitude).min() ?? 0)
    }

    func testGivenANoteWhenRenderedThenItFadesInAndNeverCutsToZero() {
        let note = ToneSynth.Note(frequency: 440, duration: 0.2, amplitude: 0.5)
        let samples = ToneSynth.render([note])
        XCTAssertEqual(samples.count, Int(ToneSynth.sampleRate * note.duration))
        XCTAssertEqual(samples[0], 0, accuracy: 0.0001)
        // Past the 10 ms attack the tone is audible, and in the last quarter it is still decaying, not zero.
        let attackFrames = Int(ToneSynth.sampleRate * ToneSynth.attack)
        XCTAssertGreaterThan(samples[attackFrames...].prefix(100).map { abs($0) }.max() ?? 0, 0.1)
        let tail = samples[(samples.count * 3 / 4)...].map { abs($0) }.max() ?? 0
        XCTAssertGreaterThan(tail, 0)
    }

    /// #398: every Repeat the Sequence tile has its own pitch, rising across the board.
    func testGivenEveryTileIndexWhenToneNoteThenFrequenciesAreDistinctAndAscending() {
        let frequencies = (0..<9).map { ToneSynth.tileNote($0).frequency }
        XCTAssertEqual(Set(frequencies).count, 9)
        XCTAssertEqual(frequencies, frequencies.sorted())
        XCTAssertEqual(frequencies.first, 262)
        XCTAssertEqual(frequencies.last, 784)
    }

    /// #398: the second harmonic must not push a tile note into clipping.
    func testGivenTileNotesWhenRenderedThenPeakStaysUnderHeadroom() {
        for index in 0..<9 {
            let samples = ToneSynth.render([ToneSynth.tileNote(index)])
            let peak = samples.map { abs($0) }.max() ?? 0
            XCTAssertFalse(samples.isEmpty, "tile \(index) rendered nothing")
            XCTAssertLessThan(peak, ToneSynth.headroom, "tile \(index) peaks at \(peak)")
        }
    }

    /// #398: a stray index never crashes the board; it sounds the nearest tile.
    func testGivenAnIndexOffTheBoardWhenToneNoteThenItClampsToTheNearestTile() {
        XCTAssertEqual(ToneSynth.tileNote(-3).frequency, ToneSynth.tileNote(0).frequency)
        XCTAssertEqual(ToneSynth.tileNote(40).frequency, ToneSynth.tileNote(8).frequency)
    }
}

/// #417: the audio engine stops itself after a quiet spell.
final class SoundPlayerIdleTests: XCTestCase {
    func testGivenToneJustPlayedWhenCheckedThenEngineKeepsRunning() {
        XCTAssertFalse(SoundPlayer.shouldStopEngine(lastToneAt: 10, now: 12))
    }

    func testGivenFourQuietSecondsWhenCheckedThenEngineStops() {
        XCTAssertTrue(SoundPlayer.shouldStopEngine(lastToneAt: 10, now: 14))
    }

    func testGivenNewToneDuringTheWaitWhenCheckedThenEngineKeepsRunning() {
        // The first tone's check fires at 14, but a tone at 13 moved the mark.
        XCTAssertFalse(SoundPlayer.shouldStopEngine(lastToneAt: 13, now: 14))
    }
}
