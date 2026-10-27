import XCTest

@testable import MenteViva

/// #141: My progress shows rates, never sums. A trend only after 3 plays this
/// week, and only against the player's own earlier weeks of the same game.
final class ProgressRatesTests: XCTestCase {
    private var calendar: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }
    /// Midday UTC, so hour offsets within a day never cross into the next one.
    private let now = Date(timeIntervalSince1970: 1_789_992_000)

    private func session(
        _ game: GameID, daysAgo: Int, hours: Int = 0, level: Difficulty? = nil,
        correct: Int = 0, attempts: Int = 0
    ) -> GameSession {
        let s = GameSession(
            gameID: game, score: 0, rounds: 6, durationSeconds: 30,
            correct: correct, attempts: attempts, difficulty: level)
        s.playedAt = calendar.date(byAdding: .hour, value: -(daysAgo * 24 + hours), to: now)!
        return s
    }

    private func week(_ sessions: [GameSession]) -> [ProgressRates] {
        ProgressRates.week(sessions, now: now, calendar: calendar)
    }

    func testGivenNoSessionsWhenWeekThenEmpty() {
        XCTAssertEqual(week([]), [])
    }

    func testGivenOnlyEarlierWeeksWhenWeekThenTheGameIsNotListed() {
        XCTAssertEqual(week([session(.stroop, daysAgo: 10, correct: 5, attempts: 10)]), [])
    }

    func testGivenPlaysOnThreeDaysWhenWeekThenDaysPlayedIsThreeOfTheLastSeven() {
        let r = week([
            session(.stroop, daysAgo: 0),
            session(.stroop, daysAgo: 0, hours: 1),
            session(.stroop, daysAgo: 2),
            session(.stroop, daysAgo: 6),
            session(.stroop, daysAgo: 7),  // the 8th calendar day back: last week
        ]).first
        XCTAssertEqual(r?.daysPlayed, 3)
        XCTAssertEqual(r?.plays, 4)
    }

    func testGivenTwoPlaysWhenWeekThenAccuracyIsTheMeanPerPlayNotThePooledSum() {
        let r = week([
            session(.stroop, daysAgo: 0, correct: 9, attempts: 10),
            session(.stroop, daysAgo: 1, correct: 1, attempts: 2),
        ]).first
        // (0.9 + 0.5) / 2, not 10 / 12.
        XCTAssertEqual(r?.accuracy ?? -1, 0.7, accuracy: 0.0001)
    }

    func testGivenThreeGamesWhenWeekThenSharesArePartsOfTheWeeksPlays() {
        let rates = week([
            session(.stroop, daysAgo: 0), session(.stroop, daysAgo: 1), session(.stroop, daysAgo: 2),
            session(.memoryMatch, daysAgo: 1),
        ])
        XCTAssertEqual(rates.map(\.game), [.memoryMatch, .stroop])
        XCTAssertEqual(rates.first { $0.game == .stroop }?.share ?? -1, 0.75, accuracy: 0.0001)
        XCTAssertEqual(rates.first { $0.game == .memoryMatch }?.share ?? -1, 0.25, accuracy: 0.0001)
    }

    func testGivenTwoPlaysThisWeekWhenWeekThenNoTrendYet() {
        let r = week([
            session(.stroop, daysAgo: 0, level: Difficulty(level: 6), correct: 10, attempts: 10),
            session(.stroop, daysAgo: 1, level: Difficulty(level: 6), correct: 10, attempts: 10),
            session(.stroop, daysAgo: 9, level: Difficulty(level: 2), correct: 2, attempts: 10),
        ]).first
        XCTAssertNil(r?.accuracyTrend)
        XCTAssertNil(r?.levelTrend)
    }

    func testGivenThreePlaysAboveEarlierWeeksWhenWeekThenTrendsAreUp() {
        let r = week([
            session(.stroop, daysAgo: 0, level: Difficulty(level: 4), correct: 9, attempts: 10),
            session(.stroop, daysAgo: 1, level: Difficulty(level: 4), correct: 9, attempts: 10),
            session(.stroop, daysAgo: 2, level: Difficulty(level: 2), correct: 9, attempts: 10),
            session(.stroop, daysAgo: 9, level: Difficulty(level: 2), correct: 5, attempts: 10),
            session(.stroop, daysAgo: 20, level: Difficulty(level: 2), correct: 7, attempts: 10),
        ]).first
        XCTAssertEqual(r?.accuracyTrend, .up)
        XCTAssertEqual(r?.levelTrend, .up)
        XCTAssertEqual(r?.level, Difficulty(level: 4))
    }

    func testGivenThreePlaysBelowEarlierWeeksWhenWeekThenAccuracyTrendIsDown() {
        let r = week([
            session(.stroop, daysAgo: 0, correct: 5, attempts: 10),
            session(.stroop, daysAgo: 1, correct: 5, attempts: 10),
            session(.stroop, daysAgo: 2, correct: 5, attempts: 10),
            session(.stroop, daysAgo: 8, correct: 9, attempts: 10),
        ]).first
        XCTAssertEqual(r?.accuracyTrend, .down)
    }

    func testGivenASmallChangeWhenWeekThenAccuracyTrendIsSteady() {
        let r = week([
            session(.stroop, daysAgo: 0, correct: 8, attempts: 10),
            session(.stroop, daysAgo: 1, correct: 8, attempts: 10),
            session(.stroop, daysAgo: 2, correct: 8, attempts: 10),
            session(.stroop, daysAgo: 8, correct: 78, attempts: 100),
        ]).first
        XCTAssertEqual(r?.accuracyTrend, .steady)
    }

    func testGivenEarlierPlaysOfAnotherGameOnlyWhenWeekThenNoTrend() {
        let r = week([
            session(.stroop, daysAgo: 0, level: Difficulty(level: 2), correct: 9, attempts: 10),
            session(.stroop, daysAgo: 1, level: Difficulty(level: 2), correct: 9, attempts: 10),
            session(.stroop, daysAgo: 2, level: Difficulty(level: 2), correct: 9, attempts: 10),
            session(.memoryMatch, daysAgo: 9, level: Difficulty(level: 6), correct: 2, attempts: 10),
        ]).first { $0.game == .stroop }
        XCTAssertNil(r?.accuracyTrend)
        XCTAssertNil(r?.levelTrend)
    }

    func testGivenEarlierPlaysOlderThanFourWeeksWhenWeekThenTheyAreNotCompared() {
        let r = week([
            session(.stroop, daysAgo: 0, correct: 9, attempts: 10),
            session(.stroop, daysAgo: 1, correct: 9, attempts: 10),
            session(.stroop, daysAgo: 2, correct: 9, attempts: 10),
            session(.stroop, daysAgo: 7 + 7 * ProgressRates.earlierWeeks, correct: 1, attempts: 10),
        ]).first
        XCTAssertNil(r?.accuracyTrend)
    }

    func testGivenRememberTogetherWhenWeekThenOnlyPlaysAndDaysAreKnown() {
        let r = week([
            session(.reminiscence, daysAgo: 0), session(.reminiscence, daysAgo: 1),
            session(.reminiscence, daysAgo: 1, hours: 2), session(.reminiscence, daysAgo: 9),
        ]).first
        XCTAssertEqual(r?.plays, 3)
        XCTAssertEqual(r?.daysPlayed, 2)
        XCTAssertNil(r?.accuracy)
        XCTAssertNil(r?.level)
        XCTAssertNil(r?.accuracyTrend)
        XCTAssertNil(r?.levelTrend)
    }
}
