import Foundation
import OSLog
import SwiftData

/// CloudKit mirroring audit: no unique constraints, no relationships, and
/// every property has a default — satisfies SwiftData + CloudKit constraints.
///
/// Uniform semantics (#58), same for every game:
/// - `rounds`: rounds/items the session was made of (Memory: pairs), not taps.
/// - `attempts`: answers or picks the player made (Memory: moves).
/// - `correct`: how many of those attempts were right.
/// Sessions saved before these fields existed have `attempts == 0` and are
/// skipped when averaging (`accuracy` is nil), never counted as 0%.
@Model
final class GameSession {
    var gameID: String = ""
    var score: Int = 0
    var rounds: Int = 0
    var durationSeconds: Int = 0
    var correct: Int = 0
    var attempts: Int = 0
    var playedAt: Date = Date.now
    /// Difficulty the game was played at (#107); -1 for sessions saved before
    /// it was recorded, which never count toward a level trend.
    var difficulty: Int = -1

    /// 0...1, or nil when the session predates accuracy tracking.
    var accuracy: Double? {
        attempts > 0 ? min(Double(correct) / Double(attempts), 1) : nil
    }

    /// nil for legacy sessions without a recorded difficulty.
    var level: Difficulty? { Difficulty(rawValue: difficulty) }

    /// The game this session belongs to; "memory" is Memory Lane's pre-#57 ID.
    var game: GameID? { GameID(rawValue: gameID) ?? (gameID == "memory" ? .memoryMatch : nil) }

    init(
        gameID: GameID, score: Int, rounds: Int, durationSeconds: Int,
        correct: Int = 0, attempts: Int = 0, difficulty: Difficulty? = nil
    ) {
        self.gameID = gameID.rawValue
        self.score = score
        self.rounds = rounds
        self.durationSeconds = durationSeconds
        self.correct = correct
        self.attempts = attempts
        self.difficulty = difficulty?.rawValue ?? -1
        self.playedAt = .now
    }
}

extension Sequence<GameSession> {
    /// Mean accuracy of the sessions that recorded one; nil when none did (#122).
    nonisolated var meanAccuracy: Double? {
        let values = compactMap(\.accuracy)
        return values.isEmpty ? nil : values.reduce(0, +) / Double(values.count)
    }
}

extension ModelContext {
    /// Inserts and saves at once (#106): a finished game must survive the app
    /// being closed before SwiftData's periodic autosave runs. A failed save is
    /// logged, never shown — play is never interrupted.
    func record(_ session: GameSession) {
        insert(session)
        do {
            try HotPath.measure("session.save") { try save() }
        } catch {
            Logger(subsystem: "com.igmarin.MenteViva", category: "store")
                .error("Could not save session: \(String(describing: error), privacy: .public)")
        }
    }
}
