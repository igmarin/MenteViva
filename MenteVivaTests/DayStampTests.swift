import XCTest

@testable import MenteViva

/// Policy: the day stamp is the cache key for "one plan per local day".
/// Its format is a contract between dailyPlan() and the UserDefaults cache.
final class DayStampTests: XCTestCase {

    /// Noon on the given local day: dayStamp formats in the device's timezone,
    /// so building dates at noon keeps the expected stamp independent of it
    /// (no midnight/DST-boundary drift on any runner or device).
    private func localNoon(_ year: Int, _ month: Int, _ day: Int) throws -> Date {
        try XCTUnwrap(Calendar.current.date(from: DateComponents(year: year, month: month, day: day, hour: 12)))
    }

    func testGivenKnownDateWhenStampedThenFormatIsYearMonthDay() throws {
        let date = try localNoon(2026, 3, 7)
        XCTAssertEqual(PlanStore.dayStamp(date), "2026-03-07")
    }

    func testGivenSingleDigitMonthAndDayWhenStampedThenZeroPadded() throws {
        let date = try localNoon(2026, 1, 5)
        XCTAssertEqual(PlanStore.dayStamp(date), "2026-01-05")
    }

    func testGivenNowWhenStampedThenMatchesExpectedShape() {
        let stamp = PlanStore.dayStamp()
        let pattern = #"^\d{4}-\d{2}-\d{2}$"#
        XCTAssertNotNil(
            stamp.range(of: pattern, options: .regularExpression),
            "stamp '\(stamp)' must be yyyy-MM-dd")
    }

    func testGivenTwoDatesOnDifferentDaysWhenStampedThenStampsDiffer() throws {
        let day1 = try localNoon(2026, 6, 1)
        let day2 = try localNoon(2026, 6, 2)
        XCTAssertNotEqual(PlanStore.dayStamp(day1), PlanStore.dayStamp(day2))
    }
}
