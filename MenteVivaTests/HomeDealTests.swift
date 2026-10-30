import XCTest

@testable import MenteViva

/// Home's deal (#383): the saved plan is on the table in the first frame, and each day is dealt once.
final class HomeDealTests: XCTestCase {

    private let games: [GameID] = [.memoryMatch, .stroop, .sudoku]

    private func plan(day: String) -> DailyPlan {
        DailyPlan(dayStamp: day, games: games, difficulty: [:])
    }

    private func isolatedDefaults() throws -> UserDefaults {
        let name = "HomeDealTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: name))
        addTeardownBlock { defaults.removePersistentDomain(forName: name) }
        return defaults
    }

    func testGivenSavedPlanForTodayWhenHomeInitThenPlanIsPreloaded() throws {
        let defaults = try isolatedDefaults()
        PlanStore.cache(plan(day: "2026-10-30"), defaults: defaults)

        let preloaded = HomeDeal.preloadedPlan(
            cached: PlanStore.cachedPlan(defaults: defaults), today: "2026-10-30")

        XCTAssertEqual(preloaded, games)
    }

    func testGivenSavedPlanFromYesterdayWhenHomeInitThenPlanIsEmpty() throws {
        let defaults = try isolatedDefaults()
        PlanStore.cache(plan(day: "2026-10-29"), defaults: defaults)

        let preloaded = HomeDeal.preloadedPlan(
            cached: PlanStore.cachedPlan(defaults: defaults), today: "2026-10-30")

        XCTAssertTrue(preloaded.isEmpty)
    }

    func testGivenNoSavedPlanWhenHomeInitThenPlanIsEmpty() {
        XCTAssertTrue(HomeDeal.preloadedPlan(cached: nil, today: "2026-10-30").isEmpty)
    }

    func testGivenDealtDayEqualsPlanDayWhenPlanRefreshesThenNoSecondDeal() {
        XCTAssertFalse(HomeDeal.needsDeal(plan: games, dealtDay: "2026-10-30", planDay: "2026-10-30"))
    }

    func testGivenPlanAndNothingDealtYetWhenHomeAppearsThenCardsAreDealt() {
        XCTAssertTrue(HomeDeal.needsDeal(plan: games, dealtDay: nil, planDay: "2026-10-30"))
    }

    func testGivenDealtYesterdayWhenNewDayArrivesThenCardsAreDealtAgain() {
        XCTAssertTrue(HomeDeal.needsDeal(plan: games, dealtDay: "2026-10-29", planDay: "2026-10-30"))
    }

    func testGivenEmptyPlanWhenCheckingThenNothingToDeal() {
        XCTAssertFalse(HomeDeal.needsDeal(plan: [], dealtDay: nil, planDay: "2026-10-30"))
    }

    func testGivenCardsWhenDelayThenSeventyMillisecondsApart() {
        XCTAssertEqual(HomeDeal.delay(forCardAt: 0), 0, accuracy: 0.0001)
        XCTAssertEqual(HomeDeal.delay(forCardAt: 4), 0.28, accuracy: 0.0001)
    }
}
