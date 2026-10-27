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

    /// A game played to the end: every round's saying is marked seen as it is completed.
    private func play(seed: UInt64) -> [SayingRound] {
        let rounds = deal(seed: seed)
        for round in rounds { SayingsDeck.markSeen(round.saying, defaults: defaults) }
        return rounds
    }

    func testGivenSevenGamesWhenDealingThen56DifferentSayingsAndNoRepeat() {
        let seen = (1...7).flatMap { play(seed: UInt64($0)).map(\.saying) }
        XCTAssertEqual(seen.count, 56)
        XCTAssertEqual(Set(seen).count, 56)
    }

    func testGivenOnlyFourUnseenWhenDealingThenSeenResetsAndEightAreDealt() {
        defaults.set(Sayings.all.prefix(56).map(\.id), forKey: SayingsDeck.seenKey)
        let rounds = deal()
        XCTAssertEqual(Set(rounds.map(\.saying)).count, 8)
        XCTAssertEqual(defaults.array(forKey: SayingsDeck.seenKey) as? [Int], [])
    }

    func testGivenHardWhenThreeSameThemeSayingsExistThenDistractorsShareTheTheme() {
        // 8 animal sayings and 8 money sayings: every round can draw 3 of its own theme.
        let pool = (1...16).map { Saying(id: $0, theme: $0 <= 8 ? .animals : .money) }
        for round in deal(.hard, pool: pool) {
            XCTAssertTrue(round.choices.allSatisfy { $0.theme == round.saying.theme })
        }
    }

    func testGivenLevelsSixToTenWhenThreeSameThemeSayingsExistThenDistractorsShareTheTheme() {
        // The bridge reads 6–10 as hard (#197): no level above 6 may get easier.
        let pool = (1...16).map { Saying(id: $0, theme: $0 <= 8 ? .animals : .money) }
        for level in 6...10 {
            for round in deal(Difficulty(level: level), pool: pool) {
                XCTAssertTrue(round.choices.allSatisfy { $0.theme == round.saying.theme }, "level \(level)")
            }
        }
    }

    func testGivenARoundCompletedWhenMarkedThenItsIDIsPersistedUnderSeenKey() {
        let rounds = deal()
        SayingsDeck.markSeen(rounds[0].saying, defaults: defaults)
        SayingsDeck.markSeen(rounds[1].saying, defaults: defaults)
        XCTAssertEqual(defaults.array(forKey: SayingsDeck.seenKey) as? [Int], [rounds[0].saying.id, rounds[1].saying.id])
    }

    func testGivenAGameLeftEarlyWhenDealingAgainThenUnplayedSayingsAreStillUnseen() {
        let first = deal(seed: 1)
        SayingsDeck.markSeen(first[0].saying, defaults: defaults)  // he finished one round, then left
        let seen = Set(defaults.array(forKey: SayingsDeck.seenKey) as? [Int] ?? [])
        XCTAssertEqual(seen, [first[0].saying.id])
        // Only the finished round counts as seen; the seven he never reached stay in the pool.
        let unplayed = Set(first.dropFirst().map(\.saying.id))
        XCTAssertTrue(seen.isDisjoint(with: unplayed))
        XCTAssertFalse(deal(seed: 2).map(\.saying.id).contains(first[0].saying.id))
    }

    func testGivenTheSameSayingMarkedTwiceThenItIsStoredOnce() {
        let saying = Sayings.all[0]
        SayingsDeck.markSeen(saying, defaults: defaults)
        SayingsDeck.markSeen(saying, defaults: defaults)
        XCTAssertEqual(defaults.array(forKey: SayingsDeck.seenKey) as? [Int], [saying.id])
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
