import XCTest

@testable import MenteViva

/// #139: nothing in Remember Together can be answered wrongly, so a session
/// records plays and days but never accuracy, and the level rules ignore it.
final class ReminiscenceSessionTests: XCTestCase {
    private func sessions(_ count: Int) -> [GameSession] {
        (0..<count).map { _ in ReminiscenceView.makeSession(cards: 5, seconds: 60) }
    }

    func testGivenReminiscenceSessionWhenAccuracyThenNil() {
        let session = ReminiscenceView.makeSession(cards: 4, seconds: 30)
        XCTAssertEqual(session.game, .reminiscence)
        XCTAssertEqual(session.rounds, 4)
        XCTAssertNil(session.accuracy)
    }

    func testGivenOnlyReminiscenceSessionsWhenSummaryThenMeanAccuracyIsNil() {
        let summary = PlayerStateSummary.build(from: sessions(3), difficulty: [:])
        XCTAssertEqual(summary.games["reminiscence"]?.sessionsLast14Days, 3)
        XCTAssertNil(summary.games["reminiscence"]?.meanAccuracy)
    }

    func testGivenReminiscenceSessionsWhenPlanThenItsDifficultyStaysMedium() {
        let summary = PlayerStateSummary.build(from: sessions(10), difficulty: [.reminiscence: Difficulty(level: 4)])
        let plan = DailyPolicy.plan(state: summary, dayStamp: "2026-10-03")
        XCTAssertEqual(plan.difficulty[.reminiscence], Difficulty(level: 4))
    }

    func testGivenOtherGamesHiddenWhenPlanThenReminiscenceIsPicked() {
        let summary = PlayerStateSummary.build(from: [], difficulty: [:])
        let others = Set(GameID.allCases).subtracting([.reminiscence])
        let plan = DailyPolicy.plan(state: summary, dayStamp: "2026-10-03", hidden: others)
        XCTAssertEqual(plan.games, [.reminiscence])
    }

    func testGivenReminiscenceWhenHasLevelsThenFalseAndOthersTrue() {
        XCTAssertFalse(GameID.reminiscence.hasLevels)
        XCTAssertTrue(GameID.allCases.filter { $0 != .reminiscence }.allSatisfy(\.hasLevels))
    }
}
