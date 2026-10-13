import XCTest

@testable import MenteViva

final class DayGroupingTests: XCTestCase {
    private var cal = Calendar(identifier: .gregorian)
    private lazy var now: Date = cal.date(from: DateComponents(year: 2026, month: 9, day: 30, hour: 12))!

    override func setUp() { cal.timeZone = TimeZone(identifier: "UTC")! }

    private func ago(days: Int, hour: Int = 9) -> Date {
        let day = cal.date(byAdding: .day, value: -days, to: cal.startOfDay(for: now))!
        return cal.date(byAdding: .hour, value: hour, to: day)!
    }

    func testGivenTwoSessionsOnOneDayWhenGroupedThenOneGroupWithBoth() {
        let dates = [ago(days: 1, hour: 8), ago(days: 1, hour: 20), ago(days: 2)]
        let groups = DayGrouping.byDay(dates, date: { $0 }, calendar: cal)
        XCTAssertEqual(groups.count, 2)
        XCTAssertEqual(groups[0].items.count, 2)
    }

    func testGivenSeveralDaysWhenGroupedThenNewestDayFirst() {
        let dates = [ago(days: 4), ago(days: 0), ago(days: 2)]
        let days = DayGrouping.byDay(dates, date: { $0 }, calendar: cal).map(\.day)
        XCTAssertEqual(days, days.sorted(by: >))
        XCTAssertEqual(days.first, cal.startOfDay(for: now))
    }

    func testGivenNoSessionsWhenGroupedThenEmpty() {
        XCTAssertTrue(DayGrouping.byDay([Date](), date: { $0 }, calendar: cal).isEmpty)
    }
}

/// #140: My Week shows one row per day with a count per game.
final class DayTallyTests: XCTestCase {
    private var cal = Calendar(identifier: .gregorian)
    private lazy var now: Date = cal.date(from: DateComponents(year: 2026, month: 9, day: 30, hour: 12))!

    override func setUp() { cal.timeZone = TimeZone(identifier: "UTC")! }

    private func at(days: Int, hour: Int = 9) -> Date {
        let day = cal.date(byAdding: .day, value: -days, to: cal.startOfDay(for: now))!
        return cal.date(byAdding: .hour, value: hour, to: day)!
    }

    private func tally(_ plays: [(Date, GameID?)]) -> [DayTally] {
        DayGrouping.tally(plays, date: { $0.0 }, game: { $0.1 }, calendar: cal)
    }

    func testGivenNoSessionsWhenCountingThenNoRows() {
        XCTAssertTrue(tally([]).isEmpty)
    }

    func testGivenTwoMemoryAndOneQuickEyesTodayWhenCountingThenOneRowWithTwoChips() {
        let rows = tally([
            (at(days: 0, hour: 10), .memoryMatch), (at(days: 0, hour: 11), .quickEyes),
            (at(days: 0, hour: 8), .memoryMatch),
        ])
        XCTAssertEqual(
            rows,
            [
                DayTally(
                    day: cal.startOfDay(for: now),
                    games: [.init(game: .memoryMatch, count: 2), .init(game: .quickEyes, count: 1)])
            ])
    }

    func testGivenSeveralDaysWhenCountingThenNewestDayFirst() {
        let rows = tally([(at(days: 4), .stroop), (at(days: 0), .stroop), (at(days: 2), .mathStreaks)])
        XCTAssertEqual(rows.map(\.day), [0, 2, 4].map { cal.startOfDay(for: at(days: $0)) })
    }

    func testGivenGamesInADayWhenCountingThenChipsFollowTheFirstPlay() {
        let rows = tally([(at(days: 1, hour: 15), .stroop), (at(days: 1, hour: 9), .reminiscence)])
        XCTAssertEqual(rows.first?.games.map(\.game), [.reminiscence, .stroop])
    }

    func testGivenUnknownGameIDsWhenCountingThenTheyAreSkipped() {
        let rows = tally([(at(days: 0), nil), (at(days: 0), .quickEyes), (at(days: 1), nil)])
        XCTAssertEqual(rows, [DayTally(day: cal.startOfDay(for: now), games: [.init(game: .quickEyes, count: 1)])])
    }
}
