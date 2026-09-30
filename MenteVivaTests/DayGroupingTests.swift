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

    func testGivenSessionsOlderThanAWeekWhenLastWeekThenTheyAreDropped() {
        let dates = [ago(days: 0), ago(days: 3), ago(days: 8), ago(days: 30)]
        let kept = DayGrouping.lastWeek(dates, date: { $0 }, now: now, calendar: cal)
        XCTAssertEqual(kept, [ago(days: 0), ago(days: 3)])
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
