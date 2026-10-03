import Foundation

/// Aggregated, anonymized gameplay stats — the entire state that leaves the device:
/// counts and ratios only, no identifiers, no dates, English field names.
nonisolated struct PlayerStateSummary: Codable {
    struct GameStats: Codable {
        let sessionsLast14Days: Int
        let meanAccuracy: Double?     // 0...1; omitted when no session recorded accuracy
        let meanRoundsCompleted: Double
        let daysSinceLastPlayed: Int
        let currentDifficulty: Difficulty
    }
    let games: [String: GameStats]    // keyed by GameID.rawValue

    /// Builds the summary from recent sessions: sessions older than 14 days are
    /// ignored; a game never played in the window reports 0 sessions and 14 days.
    static func build(from sessions: [GameSession],
                      difficulty: [GameID: Difficulty],
                      now: Date = .now,
                      calendar: Calendar = .current) -> PlayerStateSummary {
        let window = 14
        var games: [String: GameStats] = [:]
        for game in GameID.allCases {
            let mine = sessions.filter {
                $0.gameID == game.rawValue
                    && (calendar.dateComponents([.day], from: $0.playedAt, to: now).day ?? window) < window
            }
            let accuracies = mine.compactMap(\.accuracy)
            let last = mine.map(\.playedAt).max()
            games[game.rawValue] = GameStats(
                sessionsLast14Days: mine.count,
                meanAccuracy: accuracies.isEmpty ? nil : accuracies.reduce(0, +) / Double(accuracies.count),
                meanRoundsCompleted: mine.isEmpty ? 0 : Double(mine.map(\.rounds).reduce(0, +)) / Double(mine.count),
                daysSinceLastPlayed: last.flatMap { calendar.dateComponents([.day], from: $0, to: now).day } ?? window,
                currentDifficulty: difficulty[game] ?? .medium)
        }
        return PlayerStateSummary(games: games)
    }
}
