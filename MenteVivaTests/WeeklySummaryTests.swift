import XCTest

@testable import MenteViva

final class WeeklySummaryTests: XCTestCase {
    private let calendar = Calendar(identifier: .gregorian)
    private let now = Date(timeIntervalSince1970: 1_790_000_000)

    private func daysAgo(_ n: Int, hoursOffset: Int = 0) -> Date {
        calendar.date(
            byAdding: .hour, value: hoursOffset,
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

/// #107: one game's week against the week before. Level is the progression
/// signal (Jev 012), accuracy the secondary one.
final class GameProgressTests: XCTestCase {
    private let calendar = Calendar(identifier: .gregorian)
    private let now = Date(timeIntervalSince1970: 1_790_000_000)

    private func session(
        _ game: GameID, daysAgo: Int, level: Difficulty? = nil,
        correct: Int = 0, attempts: Int = 0
    ) -> GameSession {
        let s = GameSession(
            gameID: game, score: 0, rounds: 6, durationSeconds: 30,
            correct: correct, attempts: attempts, difficulty: level)
        s.playedAt = calendar.date(byAdding: .day, value: -daysAgo, to: now)!
        return s
    }

    private func weekly(_ sessions: [GameSession]) -> [GameProgress] {
        GameProgress.weekly(sessions, now: now, calendar: calendar)
    }

    func testGivenNoSessionsWhenWeeklyThenEmpty() {
        XCTAssertEqual(weekly([]), [])
    }

    func testGivenSessionsBothWeeksWhenWeeklyThenCountsAndAccuracySplitByWeek() {
        let p = weekly([
            session(.stroop, daysAgo: 1, correct: 9, attempts: 10),
            session(.stroop, daysAgo: 3, correct: 7, attempts: 10),
            session(.stroop, daysAgo: 9, correct: 5, attempts: 10),
            session(.stroop, daysAgo: 20, correct: 0, attempts: 10),
        ]).first
        XCTAssertEqual(p?.game, .stroop)
        XCTAssertEqual(p?.sessions, 2)
        XCTAssertEqual(p?.previousSessions, 1)
        XCTAssertEqual(p?.accuracy ?? -1, 0.8, accuracy: 0.0001)
        XCTAssertEqual(p?.previousAccuracy ?? -1, 0.5, accuracy: 0.0001)
        XCTAssertEqual(p?.accuracyTrend, .up)
    }

    func testGivenHigherLevelThisWeekWhenWeeklyThenLevelTrendIsUp() {
        let p = weekly([
            session(.memoryMatch, daysAgo: 1, level: .hard),
            session(.memoryMatch, daysAgo: 4, level: .medium),
            session(.memoryMatch, daysAgo: 10, level: .medium),
        ]).first
        XCTAssertEqual(p?.level, .hard)  // latest this week
        XCTAssertEqual(p?.previousLevel, .medium)
        XCTAssertEqual(p?.levelTrend, .up)
    }

    func testGivenLowerLevelThisWeekWhenWeeklyThenLevelTrendIsDown() {
        let p = weekly([
            session(.quickEyes, daysAgo: 2, level: .easy),
            session(.quickEyes, daysAgo: 8, level: .medium),
        ]).first
        XCTAssertEqual(p?.levelTrend, .down)
    }

    func testGivenLegacySessionsWithoutLevelWhenWeeklyThenNoLevelTrend() {
        let p = weekly([
            session(.quickEyes, daysAgo: 2, level: .hard),
            session(.quickEyes, daysAgo: 8),
        ]).first
        XCTAssertEqual(p?.level, .hard)
        XCTAssertNil(p?.previousLevel)
        XCTAssertNil(p?.levelTrend)
    }

    func testGivenSmallAccuracyChangeWhenWeeklyThenTrendIsSteady() {
        let p = weekly([
            session(.categoryFluency, daysAgo: 1, correct: 82, attempts: 100),
            session(.categoryFluency, daysAgo: 8, correct: 80, attempts: 100),
        ]).first
        XCTAssertEqual(p?.accuracyTrend, .steady)
    }

    func testGivenAccuracyDropWhenWeeklyThenTrendIsDown() {
        let p = weekly([
            session(.categoryFluency, daysAgo: 1, correct: 6, attempts: 10),
            session(.categoryFluency, daysAgo: 8, correct: 9, attempts: 10),
        ]).first
        XCTAssertEqual(p?.accuracyTrend, .down)
    }

    func testGivenGamePlayedOnlyLastWeekWhenWeeklyThenItIsListedWithZeroSessions() {
        // The family view needs to see a game that went quiet.
        let p = weekly([session(.mathStreaks, daysAgo: 9)])
        XCTAssertEqual(p.map(\.game), [.mathStreaks])
        XCTAssertEqual(p.first?.sessions, 0)
        XCTAssertEqual(p.first?.previousSessions, 1)
    }

    func testGivenSeveralGamesWhenWeeklyThenGameOrderIsStable() {
        let p = weekly([session(.quickEyes, daysAgo: 1), session(.memoryMatch, daysAgo: 2)])
        XCTAssertEqual(p.map(\.game), [.memoryMatch, .quickEyes])
    }

    func testGivenLegacyMemoryIDWhenWeeklyThenItCountsAsMemoryLane() {
        let s = session(.memoryMatch, daysAgo: 1)
        s.gameID = "memory"
        XCTAssertEqual(weekly([s]).first?.game, .memoryMatch)
    }
}
