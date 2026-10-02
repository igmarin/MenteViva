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
}
