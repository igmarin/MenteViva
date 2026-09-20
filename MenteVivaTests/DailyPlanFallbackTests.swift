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

    func testGivenDayRotationWhenFallbackThenMixIsARotationOfAllGames() {
        // Rotation semantics: the 3-game mix must be a contiguous slice of a
        // rotated allCases — it shifts day to day, never shuffles arbitrarily.
        let plan = DailyPlan.fallback(current: current, dayStamp: "2026-03-07")
        let offset = Calendar.current.ordinality(of: .day, in: .year, for: .now) ?? 0
        let all = GameID.allCases
        for (index, game) in plan.games.enumerated() {
            XCTAssertEqual(game, all[(index + offset) % all.count])
        }
    }
}
