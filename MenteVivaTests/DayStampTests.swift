import XCTest
@testable import MenteViva

/// Policy: the day stamp is the cache key for "one plan per local day".
/// Its format is a contract between dailyPlan() and the UserDefaults cache.
final class DayStampTests: XCTestCase {

    func testGivenKnownDateWhenStampedThenFormatIsYearMonthDay() throws {
        var components = DateComponents()
        components.year = 2026
        components.month = 3
        components.day = 7
        let date = try XCTUnwrap(Calendar.current.date(from: components))
        XCTAssertEqual(JevService.dayStamp(date), "2026-03-07")
    }

    func testGivenSingleDigitMonthAndDayWhenStampedThenZeroPadded() throws {
        var components = DateComponents()
        components.year = 2026
        components.month = 1
        components.day = 5
        let date = try XCTUnwrap(Calendar.current.date(from: components))
        XCTAssertEqual(JevService.dayStamp(date), "2026-01-05")
    }

    func testGivenNowWhenStampedThenMatchesExpectedShape() {
        let stamp = JevService.dayStamp()
        let pattern = #"^\d{4}-\d{2}-\d{2}$"#
        XCTAssertNotNil(stamp.range(of: pattern, options: .regularExpression),
                        "stamp '\(stamp)' must be yyyy-MM-dd")
    }

    func testGivenTwoDatesOnDifferentDaysWhenStampedThenStampsDiffer() throws {
        let day1 = try XCTUnwrap(Calendar.current.date(from: DateComponents(year: 2026, month: 6, day: 1)))
        let day2 = try XCTUnwrap(Calendar.current.date(from: DateComponents(year: 2026, month: 6, day: 2)))
        XCTAssertNotEqual(JevService.dayStamp(day1), JevService.dayStamp(day2))
    }
}
