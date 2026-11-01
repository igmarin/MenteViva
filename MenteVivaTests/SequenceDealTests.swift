import XCTest

@testable import MenteViva

/// #397 (#216): Repeat the Sequence's pure rules, the deal and the session,
/// with a seeded generator so a thousand seeds per level cannot flake.
final class SequenceDealTests: XCTestCase {
    /// Deterministic generator so the property runs never flake.
    private struct SeededGenerator: RandomNumberGenerator {
        var state: UInt64
        mutating func next() -> UInt64 {
            state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
            return state
        }
    }

    private func deal(level: Int, width: Double = 400, seed: UInt64) -> [Int] {
        var generator = SeededGenerator(state: seed)
        return SequenceDeal.deal(level: Difficulty(level: level), width: width, using: &generator)
    }

    // MARK: Deal

    func testGivenAThousandSeedsAtEveryLevelWhenDealtThenEveryDealIsValid() {
        for width in [320.0, 400.0] {
            for level in Difficulty.range {
                let rules = SequenceDeal.rules(for: Difficulty(level: level), width: width)
                for seed in 0..<1000 {
                    let seq = deal(level: level, width: width, seed: UInt64(seed))
                    let note = "width \(width) level \(level) seed \(seed)"
                    XCTAssertEqual(seq.count, rules.length, note)
                    XCTAssertTrue(
                        seq.allSatisfy { (0..<(rules.columns * rules.rows)).contains($0) }, note)
                }
            }
        }
    }

    func testGivenLevelsOneToFourWhenDealtThenNoBackToBackRepeats() {
        for level in 1...4 {
            for seed in 0..<1000 {
                let seq = deal(level: level, seed: UInt64(seed))
                for (a, b) in zip(seq, seq.dropFirst()) {
                    XCTAssertNotEqual(a, b, "level \(level) seed \(seed)")
                }
            }
        }
    }

    func testGivenASeedAndLevelThreeWhenDealtTwiceThenTheDealRepeats() {
        XCTAssertEqual(deal(level: 3, seed: 7), deal(level: 3, seed: 7))
    }

    // MARK: Rules

    func testGivenLevelSixAtWidth320WhenRulesThenTwoByThreeAndLengthSix() {
        let rules = SequenceDeal.rules(for: Difficulty(level: 6), width: 320)
        XCTAssertEqual(rules.columns, 2)
        XCTAssertEqual(rules.rows, 3)
        XCTAssertEqual(rules.length, 6)
    }

    func testGivenLevelSixAtWidth375WhenRulesThenThreeByThreeAndLengthFive() {
        let rules = SequenceDeal.rules(for: Difficulty(level: 6), width: 375)
        XCTAssertEqual(rules.columns, 3)
        XCTAssertEqual(rules.rows, 3)
        XCTAssertEqual(rules.length, 5)
    }

    func testGivenLevelsOneToTenWhenRulesThenLengthNeverDropsAndLightNeverLengthens() {
        let all = Difficulty.range.map { SequenceDeal.rules(for: Difficulty(level: $0), width: 400) }
        for (earlier, later) in zip(all, all.dropFirst()) {
            XCTAssertLessThanOrEqual(earlier.length, later.length)
            XCTAssertGreaterThanOrEqual(earlier.light, later.light)
        }
    }

    // MARK: Session

    func testGivenTheRightSequenceWhenRecordedThenCorrect() {
        var session = SequenceDeal.Session(sequences: [[0, 1, 0], [2]])
        XCTAssertEqual(session.record(tapped: [0, 1, 0]), .correct)
        XCTAssertEqual(session.index, 1)
        XCTAssertEqual(session.correct, 1)
        XCTAssertEqual(session.attempts, 1)
    }

    func testGivenAWrongFirstTapWhenRecordedThenAlmostAndNeedsReplay() {
        var session = SequenceDeal.Session(sequences: [[0, 1, 0, 1, 0, 1, 0, 1]])
        XCTAssertEqual(session.record(tapped: [3]), .almost)
        XCTAssertTrue(session.needsReplay)
        XCTAssertEqual(session.index, 0)
    }

    func testGivenACorrectPrefixWhenRecordedThenKeepGoingAndAttemptsUnchanged() {
        var session = SequenceDeal.Session(sequences: [[0, 0, 1]])
        // A repeated tile in the sequence: each prefix stays a prefix.
        XCTAssertEqual(session.record(tapped: [0]), .keepGoing)
        XCTAssertEqual(session.record(tapped: [0, 0]), .keepGoing)
        XCTAssertEqual(session.attempts, 0)
        XCTAssertFalse(session.needsReplay)
        XCTAssertEqual(session.record(tapped: [0, 0, 1]), .correct)
    }

    func testGivenAWrongLastTapWhenRecordedThenAlmost() {
        var session = SequenceDeal.Session(sequences: [[0, 1, 2]])
        XCTAssertEqual(session.record(tapped: [0, 1]), .keepGoing)
        XCTAssertEqual(session.record(tapped: [0, 1, 3]), .almost)
    }

    func testGivenTwoMissesWhenRecordedThenIndexAdvancesAndReplayCleared() {
        var session = SequenceDeal.Session(sequences: [[0, 1], [2, 3]])
        XCTAssertEqual(session.record(tapped: [1]), .almost)
        XCTAssertEqual(session.index, 0)
        XCTAssertEqual(session.record(tapped: [1]), .almost)
        XCTAssertEqual(session.index, 1)
        XCTAssertFalse(session.needsReplay)
    }

    func testGivenTwoMissesWhenRecordedThenTwoAttemptsAndNoneCorrect() {
        var session = SequenceDeal.Session(sequences: [[0, 1]])
        _ = session.record(tapped: [1])
        _ = session.record(tapped: [1])
        XCTAssertEqual(session.attempts, 2)
        XCTAssertEqual(session.correct, 0)
        XCTAssertTrue(session.isFinished)
    }

    // MARK: Redeal when the board changes size (#415)

    private func fiveSequences(level: Int, width: Double) -> SequenceDeal.Session {
        SequenceDeal.Session(sequences: (0..<5).map { deal(level: level, width: width, seed: UInt64($0)) })
    }

    func testGivenAWiderBoardTurnedNarrowWhenRedealtThenTheRestFitsTheSmallerGrid() {
        // Level 10 is 3x3 at 400pt and 2x3 at 320pt, where tile 5 would be stranded off the board.
        let level = Difficulty(level: 10)
        var session = fiveSequences(level: 10, width: 400)
        session.index = 2
        var generator = SeededGenerator(state: 99)
        session.redeal(level: level, width: 320, using: &generator)
        let rules = SequenceDeal.rules(for: level, width: 320)
        XCTAssertEqual(session.sequences.count, 5)
        for sequence in session.sequences[2...] {
            XCTAssertEqual(sequence.count, rules.length)
            XCTAssertTrue(sequence.allSatisfy { (0..<(rules.columns * rules.rows)).contains($0) })
        }
    }

    func testGivenRoundsAlreadyPlayedWhenRedealtThenTheyAndTheCountsStay() {
        let level = Difficulty(level: 10)
        var session = fiveSequences(level: 10, width: 400)
        let played = Array(session.sequences[..<2])
        session.index = 2
        session.attempts = 3
        session.correct = 2
        var generator = SeededGenerator(state: 7)
        session.redeal(level: level, width: 320, using: &generator)
        XCTAssertEqual(Array(session.sequences[..<2]), played)
        XCTAssertEqual(session.index, 2)
        XCTAssertEqual(session.attempts, 3)
        XCTAssertEqual(session.correct, 2)
    }

    func testGivenAMissAwaitingReplayWhenRedealtThenTheNewSequenceStartsClean() {
        let level = Difficulty(level: 10)
        var session = fiveSequences(level: 10, width: 400)
        _ = session.record(tapped: [9])
        XCTAssertTrue(session.needsReplay)
        var generator = SeededGenerator(state: 3)
        session.redeal(level: level, width: 320, using: &generator)
        XCTAssertFalse(session.needsReplay)
        XCTAssertEqual(session.index, 0)
    }

    func test_givenDemoPlaying_whenATileIsLit_thenTheOthersDimAndItStaysFull() {
        XCTAssertEqual(SequenceDeal.tileOpacity(isLit: true, demoPlaying: true), 1)
        XCTAssertEqual(SequenceDeal.tileOpacity(isLit: false, demoPlaying: true), 0.4)
    }

    func test_givenThePlayersTurn_whenATileIsTapped_thenNoTileDims() {
        XCTAssertEqual(SequenceDeal.tileOpacity(isLit: true, demoPlaying: false), 1)
        XCTAssertEqual(SequenceDeal.tileOpacity(isLit: false, demoPlaying: false), 1)
    }
}
