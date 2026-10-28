import XCTest

@testable import MenteViva

/// #244: Color Clash's deal — the ink the word is painted in and the word
/// itself — with the generator passed in, so a seeded run reproduces and a
/// thousand seeds can be checked for a word the level can actually ask for.
final class ColorClashDealTests: XCTestCase {
    /// Deterministic generator so the property runs never flake.
    private struct SeededGenerator: RandomNumberGenerator {
        var state: UInt64
        mutating func next() -> UInt64 {
            state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
            return state
        }
    }

    private func deal(_ level: Int, seed: UInt64) -> ColorClashDeal.Stimulus {
        var generator = SeededGenerator(state: seed)
        return ColorClashDeal.make(difficulty: Difficulty(level: level), using: &generator)
    }

    func testGivenTheSameSeedWhenDealtTwiceThenTheSameStimulus() {
        XCTAssertEqual(deal(4, seed: 9), deal(4, seed: 9))
    }

    func testGivenDifferentSeedsWhenDealtThenTheStimuliDiffer() {
        XCTAssertNotEqual(deal(4, seed: 1), deal(4, seed: 2))
    }

    func testGivenOneThousandSeedsWhenDealtThenEveryStimulusIsValid() {
        for level in 1...10 {
            let pool = ColorClashDeal.availableInks(for: Difficulty(level: level))
            for seed in 1...1000 {
                let dealt = deal(level, seed: UInt64(seed))
                XCTAssertTrue(pool.contains(dealt.ink), "level \(level) seed \(seed)")
                XCTAssertTrue(pool.contains(dealt.word), "level \(level) seed \(seed)")
            }
        }
    }

    func testGivenLevelsSixToTenWhenDealtThenTheWordNeverMatchesTheInk() {
        // From level 6 the matching chance is 0, so the word is always a decoy.
        for level in 6...10 {
            for seed in 1...1000 {
                let dealt = deal(level, seed: UInt64(seed))
                XCTAssertNotEqual(dealt.word, dealt.ink, "level \(level) seed \(seed)")
            }
        }
    }

    func testGivenLevelOneWhenDealtThenTheWordUsuallyMatchesTheInk() {
        // 0.85 by the table: the point of level 1 is that the word mostly agrees.
        let matches = (1...1000).filter { deal(1, seed: UInt64($0)).word == deal(1, seed: UInt64($0)).ink }.count
        XCTAssertGreaterThan(matches, 700)
        XCTAssertLessThan(matches, 1000)
    }

    func testGivenLevelsNineAndTenWhenDealtThenSixInksAreOffered() {
        XCTAssertEqual(ColorClashDeal.availableInks(for: Difficulty(level: 9)).count, 6)
        XCTAssertEqual(ColorClashDeal.availableInks(for: Difficulty(level: 10)).count, 6)
        XCTAssertEqual(ColorClashDeal.availableInks(for: Difficulty(level: 8)).count, 4)
    }
}
