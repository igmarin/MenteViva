import XCTest

@testable import MenteViva

/// #244: Quick Eyes' deal — the picture to flash and the four options — with
/// the generator passed in, so a seeded run reproduces and a thousand seeds
/// can be checked for a round that can actually be answered.
final class QuickEyesDealTests: XCTestCase {
    /// Deterministic generator so the property runs never flake.
    private struct SeededGenerator: RandomNumberGenerator {
        var state: UInt64
        mutating func next() -> UInt64 {
            state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
            return state
        }
    }

    private func round(seed: UInt64) -> QuickEyesDeal.Round {
        var generator = SeededGenerator(state: seed)
        return QuickEyesDeal.make(using: &generator)
    }

    func testGivenTheSameSeedWhenDealtTwiceThenTheSameRound() {
        XCTAssertEqual(round(seed: 4), round(seed: 4))
    }

    func testGivenDifferentSeedsWhenDealtThenTheRoundsDiffer() {
        XCTAssertNotEqual(round(seed: 1), round(seed: 2))
    }

    func testGivenOneThousandSeedsWhenDealtThenEveryRoundIsValid() {
        for seed in 1...1000 {
            let dealt = round(seed: UInt64(seed))
            XCTAssertEqual(dealt.options.count, QuickEyesDeal.optionsPerRound, "seed \(seed)")
            // Four different pictures, all from the game's own set.
            XCTAssertEqual(Set(dealt.options).count, QuickEyesDeal.optionsPerRound, "seed \(seed)")
            XCTAssertTrue(dealt.options.allSatisfy(QuickEyesDeal.pictures.contains), "seed \(seed)")
            // The picture that flashed is among them, exactly once.
            XCTAssertEqual(dealt.options.filter { $0 == dealt.target }.count, 1, "seed \(seed)")
            XCTAssertTrue(QuickEyesDeal.pictures.contains(dealt.target), "seed \(seed)")
        }
    }

    // MARK: #46 player-paced levels

    func testGivenEachLevelWhenAskedThenTwoToFourOptionsGrowingWithTheLevel() {
        let counts = (1...10).map { QuickEyesDeal.optionCount(for: Difficulty(level: $0)) }
        XCTAssertEqual(counts, [2, 2, 3, 3, 4, 4, 4, 4, 4, 4])
        XCTAssertEqual(counts, counts.sorted())
    }

    func testGivenAnOptionCountWhenDealtThenThatManyDifferentPicturesWithTheTarget() {
        for count in 2...4 {
            for seed in 1...200 {
                var generator = SeededGenerator(state: UInt64(seed))
                let dealt = QuickEyesDeal.make(optionCount: count, using: &generator)
                XCTAssertEqual(Set(dealt.options).count, count, "count \(count) seed \(seed)")
                XCTAssertEqual(dealt.options.filter { $0 == dealt.target }.count, 1, "count \(count) seed \(seed)")
            }
        }
    }

    func testGivenLevelFiveAndSixWhenAskedThenOnlyFiveAndBelowArePaced() {
        XCTAssertTrue(QuickEyesDeal.isPaced(Difficulty(level: 1)))
        XCTAssertTrue(QuickEyesDeal.isPaced(Difficulty(level: 5)))
        XCTAssertFalse(QuickEyesDeal.isPaced(Difficulty(level: 6)))
        XCTAssertFalse(QuickEyesDeal.isPaced(Difficulty(level: 10)))
    }

    func testGivenThreeQuickRightRoundsWhenRecordedThenTheInviteShowsOnceOnTheThird() {
        var invite = FasterInvite()
        XCTAssertFalse(invite.record(rightFirstTry: true, look: 0.5))
        XCTAssertFalse(invite.record(rightFirstTry: true, look: 0.5))
        XCTAssertTrue(invite.record(rightFirstTry: true, look: 0.5))
        XCTAssertFalse(invite.record(rightFirstTry: true, look: 0.5))
    }

    func testGivenAMissOrASlowLookWhenRecordedThenTheStreakStartsOver() {
        var invite = FasterInvite()
        XCTAssertFalse(invite.record(rightFirstTry: true, look: 0.5))
        XCTAssertFalse(invite.record(rightFirstTry: false, look: 0.5))
        XCTAssertFalse(invite.record(rightFirstTry: true, look: 0.5))
        XCTAssertFalse(invite.record(rightFirstTry: true, look: 1.5))
        XCTAssertFalse(invite.record(rightFirstTry: true, look: 0.5))
        XCTAssertFalse(invite.record(rightFirstTry: true, look: 0.5))
        XCTAssertTrue(invite.record(rightFirstTry: true, look: 0.5))
    }
}
