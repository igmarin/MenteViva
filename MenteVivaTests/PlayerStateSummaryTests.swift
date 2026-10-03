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

    private func build(_ sessions: [GameSession]) -> PlayerStateSummary {
        .build(from: sessions, difficulty: [:], now: now)
    }

    func testGivenNoSessionsWhenBuildThenEveryGameIsPresentAndIdle() {
        let g = build([]).games["stroop"]
        XCTAssertEqual(g?.sessionsLast14Days, 0)
        XCTAssertEqual(g?.daysSinceLastPlayed, 14)
        XCTAssertNil(g?.meanAccuracy)
        XCTAssertEqual(g?.currentDifficulty, .medium)
        XCTAssertEqual(build([]).games.count, GameID.allCases.count)
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
}
