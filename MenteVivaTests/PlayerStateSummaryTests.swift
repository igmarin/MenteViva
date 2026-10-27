import XCTest

@testable import MenteViva

final class PlayerStateSummaryTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    private func session(
        _ game: GameID, daysAgo: Int, correct: Int = 0, attempts: Int = 0,
        rounds: Int = 10
    ) -> GameSession {
        let s = GameSession(
            gameID: game, score: 0, rounds: rounds, durationSeconds: 1,
            correct: correct, attempts: attempts)
        s.playedAt = Calendar.current.date(byAdding: .day, value: -daysAgo, to: now)!
        return s
    }

    private func build(
        _ sessions: [GameSession], difficulty: [GameID: Difficulty] = [:],
        lastChange: [GameID: String] = [:]
    ) -> PlayerStateSummary {
        .build(from: sessions, difficulty: difficulty, now: now, lastChange: lastChange)
    }

    func testGivenNoSessionsWhenBuildThenEveryGameIsPresentAndIdle() {
        let g = build([]).games["stroop"]
        XCTAssertEqual(g?.sessionsLast14Days, 0)
        XCTAssertEqual(g?.daysSinceLastPlayed, 14)
        XCTAssertNil(g?.meanAccuracy)
        XCTAssertEqual(g?.currentDifficulty, Difficulty(level: 4))
        XCTAssertEqual(build([]).games.count, GameID.allCases.count)
        XCTAssertEqual(g?.recentAccuracies, [])
    }

    func testGivenSessionsWhenBuildThenAveragesOnlyThatGamesRecentSessions() {
        let g = build([
            session(.stroop, daysAgo: 2, correct: 10, attempts: 10),
            session(.stroop, daysAgo: 5, correct: 5, attempts: 10, rounds: 8),
            session(.stroop, daysAgo: 30, correct: 0, attempts: 10),
            session(.quickEyes, daysAgo: 1, correct: 1, attempts: 10),
        ]).games["stroop"]
        XCTAssertEqual(g?.sessionsLast14Days, 2)
        XCTAssertEqual(g?.meanAccuracy ?? -1, 0.75, accuracy: 0.0001)
        XCTAssertEqual(g?.meanRoundsCompleted ?? -1, 9, accuracy: 0.0001)
        XCTAssertEqual(g?.daysSinceLastPlayed, 2)
    }

    func testGivenLegacySessionWithoutAccuracyWhenBuildThenAccuracyOmitted() {
        let g = build([session(.mathStreaks, daysAgo: 1)]).games["math_streaks"]
        XCTAssertEqual(g?.sessionsLast14Days, 1)
        XCTAssertNil(g?.meanAccuracy)
    }

    func testGivenSessionsAtCurrentLevelWhenBuildThenRecentAccuraciesNewestFirst() {
        // Levels come from resolvedLevel, not just any session.
        let a = session(.stroop, daysAgo: 2, correct: 9, attempts: 10)
        a.level = Difficulty(level: 4).level
        let b = session(.stroop, daysAgo: 1, correct: 5, attempts: 10)
        b.level = Difficulty(level: 4).level
        let c = session(.stroop, daysAgo: 0, correct: 9, attempts: 10)
        c.level = Difficulty(level: 4).level
        let otherLevel = session(.stroop, daysAgo: 0, correct: 10, attempts: 10)
        otherLevel.level = Difficulty(level: 5).level
        let legacy = session(.stroop, daysAgo: 0)  // attempts 0 → accuracy nil
        legacy.level = Difficulty(level: 4).level

        let g = build(
            [a, b, c, otherLevel, legacy],
            difficulty: [.stroop: Difficulty(level: 4)]
        ).games["stroop"]

        XCTAssertEqual(g?.recentAccuracies ?? [], [0.9, 0.5, 0.9])
    }

    func testGivenSessionsBeforeLastChangeWhenBuildThenTheyAreNotInRecentAccuracies() {
        let change = PlanStore.dayStamp(Date(timeIntervalSince1970: 1_800_000_000 - 86400))
        let older = session(.stroop, daysAgo: 2, correct: 10, attempts: 10)
        older.level = Difficulty(level: 4).level
        older.playedAt = Calendar.current.date(
            byAdding: .day, value: -2, to: PlanStore.day(fromStamp: change)!)!
        let newer = session(.stroop, daysAgo: 0, correct: 9, attempts: 10)
        newer.level = Difficulty(level: 4).level

        let g = build(
            [older, newer], difficulty: [.stroop: Difficulty(level: 4)],
            lastChange: [.stroop: change]
        ).games["stroop"]

        XCTAssertEqual(g?.recentAccuracies, [0.9])
    }
}
