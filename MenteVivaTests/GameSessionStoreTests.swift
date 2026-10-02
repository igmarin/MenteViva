import XCTest
import SwiftData
@testable import MenteViva

/// #106: finished games went missing from My Week. A second context on the same
/// container sees only what reached the store — the same thing a relaunch sees.
final class GameSessionStoreTests: XCTestCase {
    func testGivenRecordedSessionWhenReadFromAnotherContextThenItIsThere() throws {
        let container = try ModelContainer(for: GameSession.self,
                                           configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let playing = ModelContext(container)
        playing.autosaveEnabled = false   // the app may die before autosave runs

        playing.record(GameSession(gameID: .memoryMatch, score: 0, rounds: 6, durationSeconds: 40,
                                   correct: 6, attempts: 9))

        let relaunched = ModelContext(container)
        XCTAssertEqual(try relaunched.fetchCount(FetchDescriptor<GameSession>()), 1)
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
