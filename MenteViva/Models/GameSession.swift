import Foundation
import SwiftData
import OSLog

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

    /// 0...1, or nil when the session predates accuracy tracking.
    var accuracy: Double? {
        attempts > 0 ? min(Double(correct) / Double(attempts), 1) : nil
    }

    init(gameID: GameID, score: Int, rounds: Int, durationSeconds: Int,
         correct: Int = 0, attempts: Int = 0) {
        self.gameID = gameID.rawValue
        self.score = score
        self.rounds = rounds
        self.durationSeconds = durationSeconds
        self.correct = correct
        self.attempts = attempts
        self.playedAt = .now
    }
}

extension ModelContext {
    /// Inserts and saves at once (#106): a finished game must survive the app
    /// being closed before SwiftData's periodic autosave runs. A failed save is
    /// logged, never shown — play is never interrupted.
    func record(_ session: GameSession) {
        insert(session)
        do {
            try save()
        } catch {
            Logger(subsystem: "com.igmarin.MenteViva", category: "store")
                .error("Could not save session: \(String(describing: error), privacy: .public)")
        }
    }
}
