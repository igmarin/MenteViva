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
        _ difficulty: Difficulty = Difficulty(level: 4), pool: [Saying] = Sayings.all, seed: UInt64 = 1,
        choices: Int? = nil
    ) -> [SayingRound] {
        var generator = SeededGenerator(state: seed)
        return SayingsDeck.deal(
            difficulty: difficulty, from: pool, choices: choices, defaults: defaults, using: &generator)
    }

    func testGivenSayingWhenOpeningThenItIsTheLocalizedStartWithAnEllipsis() {
        let saying = Saying(id: 7, theme: .animals)
        XCTAssertEqual(saying.opening(localize: { "<\($0)>" }), "<saying.07.start>…")
    }

    func testGivenEachLevelWhenChoiceCountThenThreeFourFour() {
        XCTAssertEqual(SayingsDeck.choiceCount(for: Difficulty(level: 2)), 3)
        XCTAssertEqual(SayingsDeck.choiceCount(for: Difficulty(level: 4)), 4)
        XCTAssertEqual(SayingsDeck.choiceCount(for: Difficulty(level: 6)), 4)
    }

    // MARK: - Fit the screen (#415)

    /// Five 100pt endings and the 12pt gaps between them need 548pt; each 112pt step buys one ending.
    func testGivenTheHeightForFiveEndingsWhenLevelTenThenFiveFit() {
        let ten = Difficulty(level: 10)
        XCTAssertEqual(SayingsDeck.choiceCount(for: ten, fittingHeight: 548), 5)
        XCTAssertEqual(SayingsDeck.choiceCount(for: ten, fittingHeight: 547), 4)
        XCTAssertEqual(SayingsDeck.choiceCount(for: ten, fittingHeight: 436), 4)
        XCTAssertEqual(SayingsDeck.choiceCount(for: ten, fittingHeight: 435), 3)
        XCTAssertEqual(SayingsDeck.choiceCount(for: ten, fittingHeight: 324), 3)
        XCTAssertEqual(SayingsDeck.choiceCount(for: ten, fittingHeight: 323), 2)
    }

    func testGivenALowBoardWhenFittingThenNeverFewerThanTwoEndings() {
        XCTAssertEqual(SayingsDeck.choiceCount(for: Difficulty(level: 10), fittingHeight: 40), 2)
        XCTAssertEqual(SayingsDeck.choiceCount(for: Difficulty(level: 10), fittingHeight: 0), 2)
        XCTAssertEqual(SayingsDeck.choiceCount(for: Difficulty(level: 10), fittingHeight: -50), 2)
    }

    /// Room never adds endings: the level's table is the ceiling (iPad and tall boards are unchanged).
    func testGivenMoreRoomThanTheTableWantsWhenFittingThenTheTableCount() {
        for level in 1...10 {
            let difficulty = Difficulty(level: level)
            XCTAssertEqual(
                SayingsDeck.choiceCount(for: difficulty, fittingHeight: 5000), SayingsDeck.choiceCount(for: difficulty))
            XCTAssertEqual(
                SayingsDeck.choiceCount(for: difficulty, fittingHeight: .greatestFiniteMagnitude),
                SayingsDeck.choiceCount(for: difficulty))
        }
    }

    // MARK: - When to deal (#415)

    func testGivenNoRoundsWhenShouldDealThenDeal() {
        XCTAssertTrue(SayingsDeck.shouldDeal(hasRounds: false, started: false, dealt: nil, fitted: 4))
    }

    func testGivenAStartedGameWhenTheFitChangesThenNeverDeal() {
        XCTAssertFalse(SayingsDeck.shouldDeal(hasRounds: true, started: true, dealt: 4, fitted: 2))
    }

    func testGivenTheSameFitWhenNothingStartedThenDoNotDealAgain() {
        XCTAssertFalse(SayingsDeck.shouldDeal(hasRounds: true, started: false, dealt: 4, fitted: 4))
    }

    func testGivenAChangedFitWhenNothingStartedThenDealAgain() {
        XCTAssertTrue(SayingsDeck.shouldDeal(hasRounds: true, started: false, dealt: 4, fitted: 2))
        XCTAssertTrue(SayingsDeck.shouldDeal(hasRounds: true, started: false, dealt: nil, fitted: 2))
    }

    func testGivenFewerEndingsAskedWhenDealtThenEachRoundHoldsItsSayingOnceAmongThatMany() {
        for round in deal(Difficulty(level: 10), choices: 3) {
            XCTAssertEqual(round.choices.count, 3)
            XCTAssertEqual(Set(round.choices).count, 3)
            XCTAssertEqual(round.choices.filter { $0 == round.saying }.count, 1)
        }
    }

    func testGivenADealThenEightRoundsWithEightDifferentSayings() {
        let rounds = deal()
        XCTAssertEqual(rounds.count, 8)
        XCTAssertEqual(Set(rounds.map(\.saying)).count, 8)
    }

    func testGivenADealThenEachRoundHoldsItsSayingOnceAmongDistinctChoices() {
        for difficulty in [Difficulty(level: 2), Difficulty(level: 4), Difficulty(level: 6)] {
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
        defaults.set(Sayings.all.dropLast(4).map(\.id), forKey: SayingsDeck.seenKey)
        let rounds = deal()
        XCTAssertEqual(Set(rounds.map(\.saying)).count, 8)
        XCTAssertEqual(defaults.array(forKey: SayingsDeck.seenKey) as? [Int], [])
    }

    func testGivenHardWhenThreeSameThemeSayingsExistThenDistractorsShareTheTheme() {
        // 8 animal sayings and 8 money sayings: every round can draw 3 of its own theme.
        let pool = (1...16).map { Saying(id: $0, theme: $0 <= 8 ? .animals : .money) }
        for round in deal(Difficulty(level: 6), pool: pool) {
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

    func testGivenAllSayingsWhenListingThenIdsAreUniqueAndEveryThemeHasAtLeastFifteen() {
        // #414: the second pack fills 61-120, so ids run 1-120 with no gap or repeat.
        XCTAssertEqual(Sayings.all.map(\.id), Array(1...120))
        for theme in Saying.Theme.allCases {
            XCTAssertGreaterThanOrEqual(Sayings.all.filter { $0.theme == theme }.count, 15, "\(theme)")
        }
    }

    func testGivenAFreshPlayerWhenFifteenGamesArePlayedThenNoSayingRepeats() {
        // #414: 15 games of 8 use all 120 sayings before any comes back.
        let seen = (1...15).flatMap { play(seed: UInt64($0)).map(\.saying) }
        XCTAssertEqual(seen.count, 120)
        XCTAssertEqual(Set(seen).count, 120)
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
