import XCTest
@testable import MenteViva

/// Each game's difficulty knob: easy is never harder than medium, medium never
/// harder than hard, and medium keeps the original game exactly.
final class DifficultyMappingTests: XCTestCase {
    func testGivenDifficultiesWhenMemoryPairsThenGridGrows() {
        XCTAssertEqual([Difficulty.easy, .medium, .hard].map(MemoryMatchView.pairCount), [6, 8, 10])
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
        UserDefaults.standard.removeObject(forKey: "jev.difficulty")
        XCTAssertEqual(Difficulty.stored(.stroop), .medium)
    }
}
