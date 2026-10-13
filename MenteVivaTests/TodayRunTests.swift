import XCTest

@testable import MenteViva

/// Card Table step 4: Home's table. Which of today's games are done, which one
/// is next, when the day is finished, the greeting, and the week board's days.
final class TodayRunTests: XCTestCase {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        calendar.firstWeekday = 2  // Monday
        return calendar
    }()
    /// Sunday 11 October 2026, 10:00 UTC.
    private let now = Date(timeIntervalSince1970: 1_791_712_800)
    private let plan: [GameID] = [.memoryMatch, .categoryFluency, .quickEyes]

    private func played(_ game: GameID, hoursAgo: Double) -> GameSession {
        let session = GameSession(gameID: game, score: 0, rounds: 1, durationSeconds: 1)
        session.playedAt = now.addingTimeInterval(-hoursAgo * 3600)
        return session
    }

    private func run(_ sessions: [GameSession], hidden: Set<GameID> = []) -> TodayRun {
        TodayRun(plan: plan, hidden: hidden, sessions: sessions, now: now, calendar: calendar)
    }

    // MARK: - Today's run

    func testGivenNothingPlayedTodayWhenRunThenTheFirstPickIsNextAndNoneAreDone() {
        let today = run([])
        XCTAssertEqual(today.next, .memoryMatch)
        XCTAssertTrue(today.done.isEmpty)
        XCTAssertEqual(today.remaining, 3)
        XCTAssertFalse(today.isFinished)
    }

    func testGivenTheFirstPickPlayedTodayWhenRunThenTheSecondIsNext() {
        let today = run([played(.memoryMatch, hoursAgo: 1)])
        XCTAssertEqual(today.next, .categoryFluency)
        XCTAssertEqual(today.done, [.memoryMatch])
        XCTAssertEqual(today.remaining, 2)
    }

    func testGivenTheLastPickPlayedFirstWhenRunThenNextIsTheFirstUnplayedInPlanOrder() {
        XCTAssertEqual(run([played(.quickEyes, hoursAgo: 1)]).next, .memoryMatch)
    }

    func testGivenAllThreePlayedTodayWhenRunThenTheDayIsFinished() {
        let today = run([
            played(.memoryMatch, hoursAgo: 3), played(.categoryFluency, hoursAgo: 2), played(.quickEyes, hoursAgo: 1),
        ])
        XCTAssertNil(today.next)
        XCTAssertTrue(today.isFinished)
        XCTAssertEqual(today.remaining, 0)
    }

    func testGivenAPickPlayedOnlyYesterdayWhenRunThenItIsNotDoneToday() {
        XCTAssertTrue(run([played(.memoryMatch, hoursAgo: 12)]).done.isEmpty)
    }

    func testGivenAGameOutsideThePlanPlayedTodayWhenRunThenItDoesNotCount() {
        let today = run([played(.stroop, hoursAgo: 1)])
        XCTAssertTrue(today.done.isEmpty)
        XCTAssertEqual(today.next, .memoryMatch)
    }

    func testGivenAPickTheFamilyHidWhenRunThenItIsLeftOut() {
        let today = run([], hidden: [.memoryMatch])
        XCTAssertEqual(today.games, [.categoryFluency, .quickEyes])
        XCTAssertEqual(today.next, .categoryFluency)
    }

    func testGivenNoPlanYetWhenRunThenNothingIsNextAndTheDayIsNotFinished() {
        let today = TodayRun(plan: [], sessions: [played(.memoryMatch, hoursAgo: 1)], now: now, calendar: calendar)
        XCTAssertNil(today.next)
        XCTAssertFalse(today.isFinished)
    }

    // MARK: - After a game (step 5)

    func testGivenOneOfTodaysGamesJustFinishedWhenNextAfterThenItIsTheNextUnplayedPick() {
        XCTAssertEqual(run([played(.memoryMatch, hoursAgo: 0.1)]).next(after: .memoryMatch), .categoryFluency)
    }

    func testGivenAGameOutsideTodaysPlanJustFinishedWhenNextAfterThenThereIsNone() {
        XCTAssertNil(run([played(.stroop, hoursAgo: 0.1)]).next(after: .stroop))
    }

    func testGivenTheLastOfTodaysGamesJustFinishedWhenNextAfterThenThereIsNone() {
        let today = run([
            played(.memoryMatch, hoursAgo: 2), played(.categoryFluency, hoursAgo: 1), played(.quickEyes, hoursAgo: 0.1),
        ])
        XCTAssertNil(today.next(after: .quickEyes))
    }

    // MARK: - Greeting

    func testGivenTheHourWhenGreetingThenMorningAfternoonOrEvening() {
        XCTAssertEqual(Greeting.key(hour: 0), "home.greeting.morning")
        XCTAssertEqual(Greeting.key(hour: 11), "home.greeting.morning")
        XCTAssertEqual(Greeting.key(hour: 12), "home.greeting.afternoon")
        XCTAssertEqual(Greeting.key(hour: 17), "home.greeting.afternoon")
        XCTAssertEqual(Greeting.key(hour: 18), "home.greeting.evening")
        XCTAssertEqual(Greeting.key(hour: 23), "home.greeting.evening")
    }

    // MARK: - Week board

    func testGivenSessionsWhenThisWeekThenSevenDaysFromTheFirstWeekdayWithItemsOnTheirDay() {
        let day: TimeInterval = 86_400
        let thursday = now.addingTimeInterval(-3 * day)
        let dates = [now, thursday.addingTimeInterval(3600), thursday, now.addingTimeInterval(-8 * day)]

        let week = DayGrouping.thisWeek(dates, date: { $0 }, now: now, calendar: calendar)

        XCTAssertEqual(week.count, 7)
        XCTAssertEqual(calendar.component(.weekday, from: week[0].day), 2, "starts on Monday")
        XCTAssertEqual(week.map(\.items.count), [0, 0, 0, 2, 0, 0, 1], "last week's Saturday is left out")
        XCTAssertEqual(week[3].items, [thursday, thursday.addingTimeInterval(3600)], "oldest first within a day")
    }
}
