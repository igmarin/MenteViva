import XCTest
@testable import MenteViva

/// Policy: when Jev is unreachable the app must still produce a sane,
/// deterministic daily plan — same day, same answer, player's current
/// difficulty untouched.
final class DailyPlanFallbackTests: XCTestCase {

    private let current: [GameID: Difficulty] = [
        .memoryMatch: .easy, .stroop: .medium, .categoryFluency: .hard,
        .mathStreaks: .medium, .quickEyes: .easy,
    ]

    func testGivenSameDayWhenFallbackCalledTwiceThenPlansAreIdentical() {
        let first = DailyPlan.fallback(current: current, dayStamp: "2026-03-07")
        let second = DailyPlan.fallback(current: current, dayStamp: "2026-03-07")
        XCTAssertEqual(first.games, second.games)
        XCTAssertEqual(first.difficulty, second.difficulty)
        XCTAssertEqual(first.dayStamp, second.dayStamp)
    }

    func testGivenAnyDayWhenFallbackThenExactlyThreeDistinctGames() {
        let plan = DailyPlan.fallback(current: current, dayStamp: "2026-03-07")
        XCTAssertEqual(plan.games.count, 3)
        XCTAssertEqual(Set(plan.games).count, 3)
        XCTAssertTrue(plan.games.allSatisfy(GameID.allCases.contains))
    }

    func testGivenCurrentDifficultyWhenFallbackThenDifficultyIsRespectedUnchanged() {
        let plan = DailyPlan.fallback(current: current, dayStamp: "2026-03-07")
        XCTAssertEqual(plan.difficulty, current)
    }

    func testGivenPartialCurrentDifficultyWhenFallbackThenOnlyThoseKeysExist() {
        let sparse: [GameID: Difficulty] = [.stroop: .hard]
        let plan = DailyPlan.fallback(current: sparse, dayStamp: "2026-03-07")
        XCTAssertEqual(plan.difficulty, sparse)
    }

    func testGivenADayStampWhenFallbackThenStampIsCarriedThrough() {
        let plan = DailyPlan.fallback(current: current, dayStamp: "2026-12-31")
        XCTAssertEqual(plan.dayStamp, "2026-12-31")
    }

    func testGivenKnownDaysWhenFallbackThenMixMatchesConcreteRotation() {
        // Jan 3 = day 3 of the year -> offset 2; Jan 5 -> offset 4 (wraps past the end).
        // Expected values are written out, not derived from the production formula.
        let jan3 = DailyPlan.fallback(current: current, dayStamp: "2026-01-03")
        XCTAssertEqual(jan3.games, [.categoryFluency, .mathStreaks, .quickEyes])
        let jan5 = DailyPlan.fallback(current: current, dayStamp: "2026-01-05")
        XCTAssertEqual(jan5.games, [.quickEyes, .memoryMatch, .stroop])
    }

    func testGivenDifferentDayStampsWhenFallbackThenRotationsFollowThoseStamps() {
        let first = DailyPlan.fallback(current: current, dayStamp: "2026-01-01")
        let second = DailyPlan.fallback(current: current, dayStamp: "2026-01-02")

        XCTAssertNotEqual(first.games, second.games)
    }
}
