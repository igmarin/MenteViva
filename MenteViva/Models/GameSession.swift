import Foundation
import SwiftData

/// CloudKit mirroring audit: no unique constraints, no relationships, and
/// every property has a default — satisfies SwiftData + CloudKit constraints.
@Model
final class GameSession {
    var gameID: String = ""
    var score: Int = 0
    var rounds: Int = 0
    var durationSeconds: Int = 0
    var playedAt: Date = Date.now

    init(gameID: String, score: Int, rounds: Int, durationSeconds: Int) {
        self.gameID = gameID
        self.score = score
        self.rounds = rounds
        self.durationSeconds = durationSeconds
        self.playedAt = .now
    }
}
