import SwiftData
import XCTest

@testable import MenteViva

/// #106: finished games went missing from My Week. A second context on the same
/// container sees only what reached the store — the same thing a relaunch sees.
final class GameSessionStoreTests: XCTestCase {
    func testGivenRecordedSessionWhenReadFromAnotherContextThenItIsThere() throws {
        let container = try ModelContainer(
            for: GameSession.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let playing = ModelContext(container)
        playing.autosaveEnabled = false  // the app may die before autosave runs

        playing.record(
            GameSession(
                gameID: .memoryMatch, score: 0, rounds: 6, durationSeconds: 40,
                correct: 6, attempts: 9))

        let relaunched = ModelContext(container)
        XCTAssertEqual(try relaunched.fetchCount(FetchDescriptor<GameSession>()), 1)
    }

    /// Card Table (#157 review): Home and the end-of-game screen read only this
    /// calendar week's sessions, so the fetch doesn't grow with years of history.
    func testGivenSessionsAcrossWeeksWhenFetchingThisWeekThenOnlyThisWeeksComeBackOldestFirst() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        calendar.firstWeekday = 2  // Monday
        let now = Date(timeIntervalSince1970: 1_791_712_800)  // Sunday 11 Oct 2026, 10:00 UTC
        let context = ModelContext(
            try ModelContainer(
                for: GameSession.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true)))
        for (game, daysAgo) in [(GameID.stroop, 8.0), (.quickEyes, 1), (.memoryMatch, 6)] {
            let session = GameSession(gameID: game, score: 0, rounds: 1, durationSeconds: 1)
            session.playedAt = now.addingTimeInterval(-daysAgo * 86_400)
            context.insert(session)
        }

        let week = try context.fetch(GameSession.thisWeek(now: now, calendar: calendar))

        XCTAssertEqual(week.compactMap(\.game), [.memoryMatch, .quickEyes], "last week's Saturday is left out")
    }

    /// #124: a store that can't open (failed migration, damaged file) used to
    /// crash every launch. Play must go on with an in-memory store instead.
    func testGivenAStoreThatCannotOpenWhenMakingTheContainerThenPlayStillSaves() throws {
        let schema = Schema([GameSession.self])
        // A regular file where the store's folder should be: it can never open there.
        let blocker = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try Data("not a folder".utf8).write(to: blocker)
        defer { try? FileManager.default.removeItem(at: blocker) }
        let broken = ModelConfiguration(schema: schema, url: blocker.appendingPathComponent("default.store"))

        let container = MenteVivaApp.makeContainer(trying: [broken], schema: schema)
        let context = ModelContext(container)
        context.record(GameSession(gameID: .stroop, score: 10, rounds: 10, durationSeconds: 30))

        XCTAssertEqual(try context.fetchCount(FetchDescriptor<GameSession>()), 1)
    }
}
