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
        XCTAssertEqual([s.daysPlayed, s.gamesPlayed], [0, 0])
    }

    func testGivenTwoGamesOneDayWhenSummarizingThenCountsOneDayTwoGames() {
        let s = WeeklySummary(playedAt: [now, now.addingTimeInterval(-60)], now: now, calendar: calendar)
        XCTAssertEqual([s.daysPlayed, s.gamesPlayed], [1, 2])
    }

    func testGivenLastSaturdayAndThisWeekWhenSummarizingThenOnlyThisWeekCounts() {
        // `now` is a Monday; with weeks starting on Sunday, Sunday counts and Saturday doesn't,
        // so the summary agrees with the week board above it.
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = TimeZone(identifier: "UTC")!
        utc.firstWeekday = 1
        let sunday = now.addingTimeInterval(-86_400)
        let saturday = now.addingTimeInterval(-2 * 86_400)
        let s = WeeklySummary(playedAt: [now, sunday, saturday], now: now, calendar: utc)
        XCTAssertEqual([s.daysPlayed, s.gamesPlayed], [2, 2])
    }

    func testGivenSeveralDaysWhenSharingThenNoStreakLine() {
        let s = WeeklySummary(playedAt: [now, daysAgo(1)], now: now, calendar: calendar)
        XCTAssertEqual(s.text.components(separatedBy: "\n").count, 3)
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

    /// The window rules, tested on a rolling week ending `now`.
    private func weekly(_ sessions: [GameSession]) -> [GameProgress] {
        GameProgress.weekly(
            sessions, now: now, calendar: calendar,
            weekStart: calendar.date(byAdding: .day, value: -7, to: now)!)
    }

    func testGivenLastSaturdayAndYesterdayWhenWeeklyOnAMondayThenOnlySundayIsThisWeek() {
        // By default the week is the calendar week, the same as My Week's board.
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = TimeZone(identifier: "UTC")!
        utc.firstWeekday = 1
        let sunday = session(.memoryMatch, daysAgo: 1)
        let saturday = session(.memoryMatch, daysAgo: 2)
        let p = GameProgress.weekly([sunday, saturday], now: now, calendar: utc)
        XCTAssertEqual(p.map(\.sessions), [1])
        XCTAssertEqual(p.map(\.previousSessions), [1])
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
            session(.memoryMatch, daysAgo: 1, level: Difficulty(level: 6)),
            session(.memoryMatch, daysAgo: 4, level: Difficulty(level: 4)),
            session(.memoryMatch, daysAgo: 10, level: Difficulty(level: 4)),
        ]).first
        XCTAssertEqual(p?.level, Difficulty(level: 6))  // latest this week
        XCTAssertEqual(p?.previousLevel, Difficulty(level: 4))
        XCTAssertEqual(p?.levelTrend, .up)
    }

    func testGivenLowerLevelThisWeekWhenWeeklyThenLevelTrendIsDown() {
        let p = weekly([
            session(.quickEyes, daysAgo: 2, level: Difficulty(level: 2)),
            session(.quickEyes, daysAgo: 8, level: Difficulty(level: 4)),
        ]).first
        XCTAssertEqual(p?.levelTrend, .down)
    }

    func testGivenLegacySessionsWithoutLevelWhenWeeklyThenNoLevelTrend() {
        let p = weekly([
            session(.quickEyes, daysAgo: 2, level: Difficulty(level: 6)),
            session(.quickEyes, daysAgo: 8),
        ]).first
        XCTAssertEqual(p?.level, Difficulty(level: 6))
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

/// Ceiling for the `progress.weekly` hot path: it reruns on every redraw of
/// History and Family, so a year of daily play must stay cheap.
///
/// A ceiling, not a benchmark. `measure {}` records timings but fails only
/// against a stored baseline, so on CI it asserted nothing; one generous
/// assert does. The budget it guards is algorithmic (a superlinear rewrite),
/// never device latency — that is read off a trace, see docs/profiling.md.
final class WeeklyProgressPerformanceTests: XCTestCase {
    /// Headroom over the real cost is wide on purpose: shared CI runners are
    /// slow and noisy, and a timing test that flakes gets skipped, not fixed.
    private let ceiling: TimeInterval = 2

    func testGivenAYearOfPlayWhenWeeklyProgressThenItStaysCheap() {
        let sessions = (0..<2_000).map { index in
            let session = GameSession(
                gameID: GameID.allCases[index % GameID.allCases.count], score: 0, rounds: 6,
                durationSeconds: 40, correct: 5, attempts: 6)
            session.playedAt = Date(timeIntervalSinceNow: -Double(index) * 4_000)
            return session
        }
        let started = Date.now
        _ = GameProgress.weekly(sessions)
        let elapsed = Date.now.timeIntervalSince(started)
        print("progress.weekly over 2,000 sessions: \(Int(elapsed * 1_000)) ms (ceiling \(Int(ceiling)) s)")
        XCTAssertLessThan(
            elapsed, ceiling,
            "GameProgress.weekly got dramatically slower; it is probably no longer linear. docs/profiling.md")
    }
}
