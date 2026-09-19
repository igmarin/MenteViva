import Foundation
import SwiftData

@Model
final class GameSession {
    var gameID: String
    var score: Int
    var rounds: Int
    var durationSeconds: Int
    var playedAt: Date

    init(gameID: String, score: Int, rounds: Int, durationSeconds: Int) {
        self.gameID = gameID
        self.score = score
        self.rounds = rounds
        self.durationSeconds = durationSeconds
        self.playedAt = .now
    }
}
