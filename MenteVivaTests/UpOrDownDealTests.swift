import XCTest

@testable import MenteViva

/// #180: Up or Down, a golf solitaire. Tap a card one higher or one lower than the
/// open card; turn the deck when none fits. Easy deals always clear.
final class UpOrDownDealTests: XCTestCase {
    /// Deterministic generator so the property runs never flake.
    private struct SeededGenerator: RandomNumberGenerator {
        var state: UInt64
        mutating func next() -> UInt64 {
            state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
            return state
        }
    }

    private static let wide = 700.0
    private static let iPhoneSE = 343.0  // 375pt screen minus the 16pt gutters

    private func card(_ rank: Int, _ suit: PlayingCard.Suit = .spades) -> PlayingCard {
        PlayingCard(rank: rank, suit: suit)
    }

    private func deal(_ difficulty: Difficulty, seed: UInt64 = 1, width: Double = wide) -> UpOrDownDeal {
        var generator = SeededGenerator(state: seed)
        return UpOrDownDeal.make(difficulty: difficulty, width: width, using: &generator)
    }

    /// A pile whose top fits the open card, and one whose top does not.
    private func playableIndices(_ d: UpOrDownDeal) -> (fits: Int?, misses: Int?) {
        let fits = d.piles.indices.first { !d.piles[$0].isEmpty && d.playablePiles.contains($0) }
        let misses = d.piles.indices.first { !d.piles[$0].isEmpty && !d.playablePiles.contains($0) }
        return (fits, misses)
    }

    func testGivenAnOpenSevenWhenCheckingThenSixAndEightFitAndNineDoesNot() {
        XCTAssertTrue(UpOrDownDeal.canPlay(card(6, .hearts), on: card(7), wraps: false))
        XCTAssertTrue(UpOrDownDeal.canPlay(card(8, .clubs), on: card(7), wraps: false))
        XCTAssertFalse(UpOrDownDeal.canPlay(card(9), on: card(7), wraps: true))
        XCTAssertFalse(UpOrDownDeal.canPlay(card(7, .diamonds), on: card(7), wraps: true))
    }

    func testGivenAnOpenKingWhenWrapsThenAceFitsAndWithoutWrapItDoesNot() {
        XCTAssertTrue(UpOrDownDeal.canPlay(card(1), on: card(13), wraps: true))
        XCTAssertTrue(UpOrDownDeal.canPlay(card(13), on: card(1), wraps: true))
        XCTAssertFalse(UpOrDownDeal.canPlay(card(1), on: card(13), wraps: false))
    }

    func testGivenEachLevelOnAWideScreenWhenPileCountThenFourFiveSix() {
        XCTAssertEqual(UpOrDownDeal.pileCount(for: .easy, width: Self.wide), 4)
        XCTAssertEqual(UpOrDownDeal.pileCount(for: .medium, width: Self.wide), 5)
        XCTAssertEqual(UpOrDownDeal.pileCount(for: .hard, width: Self.wide), 6)
    }

    func testGivenHardOnAnIPhoneSEWidthWhenPileCountThenFive() {
        // Six cards and their gaps leave under 60pt each at 343pt; five do not.
        XCTAssertEqual(UpOrDownDeal.pileCount(for: .hard, width: Self.iPhoneSE), 5)
        XCTAssertEqual(UpOrDownDeal.pileCount(for: .easy, width: Self.iPhoneSE), 4)
    }

    func testGivenAMadeDealThenEachPileHasThreeAndAll52CardsAreUsedOnce() {
        for difficulty in [Difficulty.easy, .medium, .hard] {
            let d = deal(difficulty)
            XCTAssertTrue(d.piles.allSatisfy { $0.count == 3 })
            let all = d.piles.flatMap { $0 } + [d.open] + d.deck
            XCTAssertEqual(all.count, 52)
            XCTAssertEqual(Set(all).count, 52)
        }
    }

    func testGivenFiftySeedsWhenMakeEasyThenEveryDealGreedyClears() {
        for seed in 1...50 {
            XCTAssertTrue(UpOrDownDeal.greedyClears(deal(.easy, seed: UInt64(seed))), "seed \(seed)")
        }
    }

    func testGivenHardWhenMakeThenItDoesNotWrap() {
        XCTAssertTrue(deal(.easy).wraps)
        XCTAssertTrue(deal(.medium).wraps)
        XCTAssertFalse(deal(.hard).wraps)
    }

    // MARK: The three-level bridge reads bands, not exact levels (#197)

    func testGivenLevelsSixToTenWhenMakeThenNoneWraps() {
        for level in 6...10 {
            XCTAssertFalse(deal(Difficulty(level: level)).wraps, "level \(level)")
        }
    }

    func testGivenLevelsOneToThreeWhenMakeThenEveryDealGreedyClears() {
        for level in 1...3 {
            for seed in 1...20 {
                let made = deal(Difficulty(level: level), seed: UInt64(seed))
                XCTAssertTrue(UpOrDownDeal.greedyClears(made), "level \(level) seed \(seed)")
            }
        }
    }

    func testGivenEachLevelWhenAskedThenOnlyTheEasyBandLiftsPlayableCards() {
        let lifts = (1...10).map { UpOrDownDeal.liftsPlayableCards(at: Difficulty(level: $0)) }
        XCTAssertEqual(lifts, [true, true, true, false, false, false, false, false, false, false])
    }

    func testGivenAFittingTopWhenPlayThenItBecomesTheOpenCardAndLeavesThePile() throws {
        var d = deal(.easy)
        while playableIndices(d).fits == nil { XCTAssertTrue(d.turn()) }
        let pile = try XCTUnwrap(playableIndices(d).fits)
        let top = try XCTUnwrap(d.piles[pile].last)
        XCTAssertTrue(d.play(pile: pile))
        XCTAssertEqual(d.open, top)
        XCTAssertEqual(d.piles[pile].count, 2)
    }

    func testGivenANonFittingTopWhenPlayThenFalseAndNothingChanges() throws {
        var d = deal(.hard, seed: 3)
        while playableIndices(d).misses == nil { XCTAssertTrue(d.turn()) }
        let before = d
        XCTAssertFalse(d.play(pile: try XCTUnwrap(playableIndices(d).misses)))
        XCTAssertEqual(d, before)
    }

    func testGivenAnEmptyDeckWhenTurnThenFalse() {
        var d = deal(.medium)
        while !d.deck.isEmpty { XCTAssertTrue(d.turn()) }
        let before = d
        XCTAssertFalse(d.turn())
        XCTAssertEqual(d, before)
    }

    func testGivenEmptyDeckAndNoFitWhenAskedThenIsStuck() {
        var d = deal(.hard, seed: 7)
        while !d.deck.isEmpty { d.turn() }
        while let pile = d.playablePiles.first { d.play(pile: pile) }
        XCTAssertTrue(d.isStuck || d.isCleared)
        XCTAssertNotEqual(d.isStuck, d.isCleared)
    }

    func testGivenASixPileDealWhenTheScreenNarrowsThenItNoLongerFits() {
        // Dealt in landscape on an iPhone SE, then turned to portrait.
        let d = deal(.hard, width: 600)
        XCTAssertEqual(d.piles.count, 6)
        XCTAssertTrue(d.fits(width: 600))
        XCTAssertFalse(d.fits(width: Self.iPhoneSE))
    }

    // MARK: Ten levels (#202)

    func testGivenLevelsTwoFourSixWhenDealtThenMatchesOldEasyMediumHard() {
        let easy = deal(Difficulty(level: 2))
        XCTAssertEqual(easy.piles.count, 4)
        XCTAssertTrue(easy.wraps)
        let medium = deal(Difficulty(level: 4))
        XCTAssertEqual(medium.piles.count, 5)
        XCTAssertTrue(medium.wraps)
        let hard = deal(Difficulty(level: 6))
        XCTAssertEqual(hard.piles.count, 6)
        XCTAssertFalse(hard.wraps)
        for seed in 1...50 {
            XCTAssertTrue(
                UpOrDownDeal.greedyClears(deal(Difficulty(level: 2), seed: UInt64(seed))), "seed \(seed)")
        }
    }

    func testGivenLevelOneWhenDealtThenAlwaysClearable() {
        for seed in 1...50 {
            let made = deal(Difficulty(level: 1), seed: UInt64(seed))
            XCTAssertEqual(made.piles.count, 3)
            XCTAssertTrue(UpOrDownDeal.greedyClears(made), "seed \(seed)")
        }
    }

    func testGivenRisingLevelsWhenRulesThenNeverEasier() {
        let rules = (1...10).map { UpOrDownDeal.rules(for: Difficulty(level: $0)) }
        XCTAssertEqual(rules.map(\.piles), [3, 4, 4, 5, 5, 6, 6, 7, 7, 7])
        for pair in zip(rules, rules.dropFirst()) {
            XCTAssertLessThanOrEqual(pair.0.piles, pair.1.piles)
            // Wrapping and clearability never come back once off.
            XCTAssertTrue(pair.0.wraps || !pair.1.wraps)
            XCTAssertTrue(pair.0.clearable || !pair.1.clearable)
        }
    }

    // MARK: Stuck cue (#265)

    func testGivenNotStuckWhenBecomingStuckThenPulseAndAnnounce() {
        let cue = UpOrDownDeal.stuckCue(wasStuck: false, isStuck: true, reduceMotion: false)
        XCTAssertTrue(cue.pulse)
        XCTAssertTrue(cue.announce)
    }

    func testGivenStuckWhenStillStuckThenNoSecondAnnouncement() {
        let cue = UpOrDownDeal.stuckCue(wasStuck: true, isStuck: true, reduceMotion: false)
        XCTAssertTrue(cue.pulse)
        XCTAssertFalse(cue.announce)
    }

    func testGivenReduceMotionWhenBecomingStuckThenAnnounceWithoutPulse() {
        let cue = UpOrDownDeal.stuckCue(wasStuck: false, isStuck: true, reduceMotion: true)
        XCTAssertFalse(cue.pulse)
        XCTAssertTrue(cue.announce)
    }

    func testGivenStuckWhenClearingThenNoPulseAndNoAnnouncement() {
        let cue = UpOrDownDeal.stuckCue(wasStuck: true, isStuck: false, reduceMotion: false)
        XCTAssertFalse(cue.pulse)
        XCTAssertFalse(cue.announce)
    }
}
