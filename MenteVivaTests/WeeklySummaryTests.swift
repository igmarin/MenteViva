import XCTest
@testable import MenteViva

final class WeeklySummaryTests: XCTestCase {
    private let calendar = Calendar(identifier: .gregorian)
    private let now = Date(timeIntervalSince1970: 1_790_000_000)

    private func daysAgo(_ n: Int, hoursOffset: Int = 0) -> Date {
        calendar.date(byAdding: .hour, value: hoursOffset,
                      to: calendar.date(byAdding: .day, value: -n, to: now)!)!
    }

    func testGivenNoSessionsWhenSummarizingThenEverythingIsZero() {
        let s = WeeklySummary(playedAt: [], now: now, calendar: calendar)
        XCTAssertEqual(s, WeeklySummary(playedAt: [], now: now, calendar: calendar))
        XCTAssertEqual([s.daysPlayed, s.gamesPlayed, s.streak], [0, 0, 0])
    }

    func testGivenTwoGamesOneDayWhenSummarizingThenCountsOneDayTwoGames() {
        let s = WeeklySummary(playedAt: [now, now.addingTimeInterval(-60)], now: now, calendar: calendar)
        XCTAssertEqual([s.daysPlayed, s.gamesPlayed, s.streak], [1, 2, 1])
    }

    func testGivenThreeConsecutiveDaysWhenSummarizingThenStreakIsThree() {
        let s = WeeklySummary(playedAt: [now, daysAgo(1), daysAgo(2)], now: now, calendar: calendar)
        XCTAssertEqual(s.streak, 3)
    }

    func testGivenNothingTodayButYesterdayWhenSummarizingThenStreakSurvives() {
        let s = WeeklySummary(playedAt: [daysAgo(1), daysAgo(2)], now: now, calendar: calendar)
        XCTAssertEqual(s.streak, 2)
    }

    func testGivenAGapWhenSummarizingThenStreakStopsAtTheGap() {
        let s = WeeklySummary(playedAt: [now, daysAgo(2)], now: now, calendar: calendar)
        XCTAssertEqual(s.streak, 1)
        XCTAssertEqual(s.daysPlayed, 2)
    }

    func testGivenSessionsOlderThanAWeekWhenSummarizingThenTheyAreExcludedFromCounts() {
        let s = WeeklySummary(playedAt: [now, daysAgo(10)], now: now, calendar: calendar)
        XCTAssertEqual([s.daysPlayed, s.gamesPlayed], [1, 1])
    }
}
