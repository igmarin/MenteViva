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
        for level in Difficulty.range {
            let rules = SequenceDeal.rules(for: Difficulty(level: level), width: 400)
            for seed in 0..<1000 {
                let seq = deal(level: level, seed: UInt64(seed))
                XCTAssertEqual(seq.count, rules.length, "level \(level) seed \(seed)")
                XCTAssertTrue(seq.allSatisfy { (0..<(rules.columns * rules.rows)).contains($0) })
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
}
