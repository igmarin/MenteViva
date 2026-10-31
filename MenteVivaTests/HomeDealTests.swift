import XCTest

@testable import MenteViva

/// Home's deal (#383): the saved plan is on the table in the first frame, and each day is dealt once.
final class HomeDealTests: XCTestCase {

    private let games: [GameID] = [.memoryMatch, .stroop, .sudoku]

    func testGivenDealtDayEqualsPlanDayWhenPlanRefreshesThenNoSecondDeal() {
        XCTAssertFalse(HomeDeal.needsDeal(plan: games, dealtDay: "2026-10-30", planDay: "2026-10-30"))
    }

    func testGivenPlanAndNothingDealtYetWhenHomeAppearsThenCardsAreDealt() {
        XCTAssertTrue(HomeDeal.needsDeal(plan: games, dealtDay: nil, planDay: "2026-10-30"))
    }

    func testGivenDealtYesterdayWhenNewDayArrivesThenCardsAreDealtAgain() {
        XCTAssertTrue(HomeDeal.needsDeal(plan: games, dealtDay: "2026-10-29", planDay: "2026-10-30"))
    }

    func testGivenAppKeptOpenPastMidnightWhenDayRollsOverThenYesterdaysCardsAreNotDealt() {
        let stale: [GameID] = []  // `PlanStore.plannedToday()` is nil for yesterday's plan

        XCTAssertFalse(HomeDeal.needsDeal(plan: stale, dealtDay: "2026-10-29", planDay: "2026-10-30"))
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
