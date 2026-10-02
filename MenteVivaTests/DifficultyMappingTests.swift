import XCTest
@testable import MenteViva

/// Each game's difficulty knob: easy is never harder than medium, medium never
/// harder than hard, and medium keeps the original game exactly.
final class DifficultyMappingTests: XCTestCase {
    func testGivenDifficultiesWhenMemoryPairsThenGridGrowsToAtMostEight() {
        // #109: at most 8 pairs so every card fits on screen, large (Jev 012).
        XCTAssertEqual([Difficulty.easy, .medium, .hard].map(MemoryMatchView.pairCount), [4, 6, 8])
    }

    // MARK: Memory board fit (#109): every card visible, as large as possible

    func testGivenSquareSpaceWhenSixteenCardsThenFourByFour() {
        let fit = MemoryMatchView.gridFit(count: 16, in: CGSize(width: 800, height: 800), spacing: 0)
        XCTAssertEqual(fit.columns, 4)
        XCTAssertEqual(fit.card.width, 200, accuracy: 0.01)
        XCTAssertEqual(fit.card.height, 200, accuracy: 0.01)
    }

    func testGivenTallPhoneSpaceWhenTwelveCardsThenFewerColumnsAndCardsFitHeight() {
        let fit = MemoryMatchView.gridFit(count: 12, in: CGSize(width: 400, height: 900), spacing: 0)
        XCTAssertEqual(fit.columns, 2)
        XCTAssertEqual(fit.card.height, 150, accuracy: 0.01)   // 6 rows fill 900
    }

    func testGivenSpacingWhenFittingThenGapsAreSubtracted() {
        let fit = MemoryMatchView.gridFit(count: 8, in: CGSize(width: 800, height: 1000), spacing: 16)
        XCTAssertEqual(fit.columns, 2)
        XCTAssertEqual(fit.card.width, 392, accuracy: 0.01)    // (800 - 16) / 2
        XCTAssertEqual(fit.card.height, 238, accuracy: 0.01)   // (1000 - 3*16) / 4
    }

    func testGivenSixteenCardsOnAPhoneWhenFittingThenFullRowsBeatALoneLastCard() {
        // 3 columns would give slightly wider cards but leave 1 card on row 6.
        let fit = MemoryMatchView.gridFit(count: 16, in: CGSize(width: 370, height: 600), spacing: 12)
        XCTAssertEqual(16 % fit.columns, 0)
    }

    func testGivenIPhoneHardBoardWhenFittingThenCardsStayAboveTheTouchFloor() {
        // iPhone 17 portrait, 8 pairs: still >= 60pt (conventions §4).
        let fit = MemoryMatchView.gridFit(count: 16, in: CGSize(width: 370, height: 600), spacing: 12)
        XCTAssertGreaterThanOrEqual(min(fit.card.width, fit.card.height), 60)
    }

    func testGivenNoCardsWhenFittingThenNothingBreaks() {
        let fit = MemoryMatchView.gridFit(count: 0, in: CGSize(width: 300, height: 300), spacing: 8)
        XCTAssertEqual(fit.columns, 1)
    }

    func testGivenSameStreakWhenMaxSumThenEasyIsSmallestAndMediumIsOriginal() {
        XCTAssertEqual(MathStreakView.maxSum(streak: 0, difficulty: .medium), 10)
        XCTAssertEqual(MathStreakView.maxSum(streak: 100, difficulty: .medium), 50)
        XCTAssertEqual(MathStreakView.maxSum(streak: 100, difficulty: .easy), 20)
        XCTAssertGreaterThan(MathStreakView.maxSum(streak: 0, difficulty: .hard),
                             MathStreakView.maxSum(streak: 0, difficulty: .medium))
    }

    func testGivenDifficultiesWhenDisplayTimesThenEasyFlashesLongerAndFloorIsHigher() {
        let (e, m, h) = (QuickEyesView.displayTimes(for: .easy),
                         QuickEyesView.displayTimes(for: .medium),
                         QuickEyesView.displayTimes(for: .hard))
        XCTAssertGreaterThan(e.start, m.start); XCTAssertGreaterThan(m.start, h.start)
        XCTAssertGreaterThan(e.floor, m.floor); XCTAssertGreaterThan(m.floor, h.floor)
        XCTAssertEqual(m.start, 1.2); XCTAssertEqual(m.floor, 0.35)
    }

    func testGivenDifficultiesWhenStroopMatchingChanceThenEasyMostHardNone() {
        XCTAssertEqual([Difficulty.easy, .medium, .hard].map(ColorClashView.matchingChance), [0.7, 0.25, 0])
    }

    func testGivenDifficultiesWhenDecoysThenEasyHasFewestAndMediumIsOriginal() {
        XCTAssertEqual([Difficulty.easy, .medium, .hard].map(CategoryFluencyView.decoyCount), [3, 5, 7])
    }

    func testGivenNoStoredPlanWhenStoredDifficultyThenMedium() {
        // Own suite: .standard is the host app's, which may hold a family pin.
        let defaults = UserDefaults(suiteName: "DifficultyMappingTests")!
        defaults.removePersistentDomain(forName: "DifficultyMappingTests")
        XCTAssertEqual(Difficulty.stored(.stroop, defaults: defaults), .medium)
    }
}
