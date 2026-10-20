import XCTest

@testable import MenteViva

/// #181: Finish the Saying deals 8 sayings a game and repeats none until all are seen.
final class SayingsDeckTests: XCTestCase {
    /// Deterministic generator so the property runs never flake.
    private struct SeededGenerator: RandomNumberGenerator {
        var state: UInt64
        mutating func next() -> UInt64 {
            state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
            return state
        }
    }

    private var defaults: UserDefaults!

    override func setUp() {
        defaults = UserDefaults(suiteName: "SayingsDeckTests")!
        defaults.removePersistentDomain(forName: "SayingsDeckTests")
    }

    private func deal(
        _ difficulty: Difficulty = .medium, pool: [Saying] = Sayings.all, seed: UInt64 = 1
    ) -> [SayingRound] {
        var generator = SeededGenerator(state: seed)
        return SayingsDeck.deal(difficulty: difficulty, from: pool, defaults: defaults, using: &generator)
    }

    func testGivenEachLevelWhenChoiceCountThenThreeFourFour() {
        XCTAssertEqual(SayingsDeck.choiceCount(for: .easy), 3)
        XCTAssertEqual(SayingsDeck.choiceCount(for: .medium), 4)
        XCTAssertEqual(SayingsDeck.choiceCount(for: .hard), 4)
    }

    func testGivenADealThenEightRoundsWithEightDifferentSayings() {
        let rounds = deal()
        XCTAssertEqual(rounds.count, 8)
        XCTAssertEqual(Set(rounds.map(\.saying)).count, 8)
    }

    func testGivenADealThenEachRoundHoldsItsSayingOnceAmongDistinctChoices() {
        for difficulty in [Difficulty.easy, .medium, .hard] {
            for round in deal(difficulty) {
                XCTAssertEqual(round.choices.count, SayingsDeck.choiceCount(for: difficulty))
                XCTAssertEqual(Set(round.choices).count, round.choices.count)
                XCTAssertEqual(round.choices.filter { $0 == round.saying }.count, 1)
            }
        }
    }

    func testGivenSevenGamesWhenDealingThen56DifferentSayingsAndNoRepeat() {
        let seen = (1...7).flatMap { deal(seed: UInt64($0)).map(\.saying) }
        XCTAssertEqual(seen.count, 56)
        XCTAssertEqual(Set(seen).count, 56)
    }

    func testGivenOnlyFourUnseenWhenDealingThenSeenResetsAndEightAreDealt() {
        defaults.set(Sayings.all.prefix(56).map(\.id), forKey: SayingsDeck.seenKey)
        let rounds = deal()
        XCTAssertEqual(Set(rounds.map(\.saying)).count, 8)
        XCTAssertEqual(defaults.array(forKey: SayingsDeck.seenKey) as? [Int], rounds.map(\.saying.id))
    }

    func testGivenHardWhenThreeSameThemeSayingsExistThenDistractorsShareTheTheme() {
        // 8 animal sayings and 8 money sayings: every round can draw 3 of its own theme.
        let pool = (1...16).map { Saying(id: $0, theme: $0 <= 8 ? .animals : .money) }
        for round in deal(.hard, pool: pool) {
            XCTAssertTrue(round.choices.allSatisfy { $0.theme == round.saying.theme })
        }
    }

    func testGivenADealThenSeenIDsArePersistedUnderSeenKey() {
        let rounds = deal()
        XCTAssertEqual(defaults.array(forKey: SayingsDeck.seenKey) as? [Int], rounds.map(\.saying.id))
    }

    func testGivenTheContentListThenSixtyUniqueIDsOneToSixty() {
        XCTAssertEqual(Sayings.all.map(\.id), Array(1...60))
    }

    func testGivenEveryThemeThenAtLeastFourSlotsSoHardAlwaysHasThreeOfItsOwn() {
        for theme in Saying.Theme.allCases {
            XCTAssertGreaterThanOrEqual(Sayings.all.filter { $0.theme == theme }.count, 4, "\(theme)")
        }
    }

    func testGivenASlotThenItsKeysAreZeroPadded() {
        XCTAssertEqual(Saying(id: 7, theme: .time).startKey, "saying.07.start")
        XCTAssertEqual(Saying(id: 7, theme: .time).endKey, "saying.07.end")
    }
}
