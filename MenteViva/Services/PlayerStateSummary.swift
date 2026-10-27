import Foundation

/// Aggregated, anonymized gameplay stats — the entire state that leaves the device:
/// counts and ratios only, no identifiers, no dates, English field names.
nonisolated struct PlayerStateSummary: Codable {
    struct GameStats: Codable, Equatable {
        let sessionsLast14Days: Int
        let meanAccuracy: Double?  // 0...1; omitted when no session recorded accuracy
        let meanRoundsCompleted: Double
        let daysSinceLastPlayed: Int
        let currentDifficulty: Difficulty
        /// Accuracies at the current level since it last changed, newest first
        /// (#198). Legacy sessions without accuracy are skipped, so a gap
        /// never reads as 0%.
        let recentAccuracies: [Double]

        init(
            sessionsLast14Days: Int,
            meanAccuracy: Double?,
            meanRoundsCompleted: Double,
            daysSinceLastPlayed: Int,
            currentDifficulty: Difficulty,
            recentAccuracies: [Double] = []
        ) {
            self.sessionsLast14Days = sessionsLast14Days
            self.meanAccuracy = meanAccuracy
            self.meanRoundsCompleted = meanRoundsCompleted
            self.daysSinceLastPlayed = daysSinceLastPlayed
            self.currentDifficulty = currentDifficulty
            self.recentAccuracies = recentAccuracies
        }

        private enum CodingKeys: String, CodingKey {
            case sessionsLast14Days, meanAccuracy, meanRoundsCompleted, daysSinceLastPlayed,
                currentDifficulty, recentAccuracies
        }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            sessionsLast14Days = try c.decode(Int.self, forKey: .sessionsLast14Days)
            meanAccuracy = try c.decodeIfPresent(Double.self, forKey: .meanAccuracy)
            meanRoundsCompleted = try c.decode(Double.self, forKey: .meanRoundsCompleted)
            daysSinceLastPlayed = try c.decode(Int.self, forKey: .daysSinceLastPlayed)
            currentDifficulty = try c.decode(Difficulty.self, forKey: .currentDifficulty)
            recentAccuracies = try c.decodeIfPresent([Double].self, forKey: .recentAccuracies) ?? []
        }
    }
    let games: [String: GameStats]  // keyed by GameID.rawValue

    /// Builds the summary from recent sessions: sessions older than 14 days are
    /// ignored; a game never played in the window reports 0 sessions and 14 days.
    /// `lastChange` filters `recentAccuracies` to sessions at the current level
    /// since it last changed (#198); without it the filter is level equality alone.
    static func build(
        from sessions: [GameSession],
        difficulty: [GameID: Difficulty],
        now: Date = .now,
        calendar: Calendar = .current,
        lastChange: [GameID: String] = [:]
    ) -> PlayerStateSummary {
        let window = 14
        var games: [String: GameStats] = [:]
        for game in GameID.allCases {
            let mine = sessions.filter {
                $0.gameID == game.rawValue
                    && (calendar.dateComponents([.day], from: $0.playedAt, to: now).day ?? window) < window
            }
            let last = mine.map(\.playedAt).max()
            let current = difficulty[game] ?? Difficulty(level: 4)
            let accuracies = recentAccuracies(
                for: game, sessions: sessions, current: current,
                lastChange: lastChange[game], calendar: calendar)
            games[game.rawValue] = GameStats(
                sessionsLast14Days: mine.count,
                meanAccuracy: mine.meanAccuracy,
                meanRoundsCompleted: mine.isEmpty ? 0 : Double(mine.map(\.rounds).reduce(0, +)) / Double(mine.count),
                daysSinceLastPlayed: last.flatMap { calendar.dateComponents([.day], from: $0, to: now).day } ?? window,
                currentDifficulty: current,
                recentAccuracies: accuracies)
        }
        return PlayerStateSummary(games: games)
    }

    /// Accuracies of sessions at `current` since `lastChange`, newest first.
    /// Legacy sessions without accuracy are skipped (#198).
    private static func recentAccuracies(
        for game: GameID, sessions: [GameSession], current: Difficulty,
        lastChange: String?, calendar _: Calendar
    ) -> [Double] {
        let changeDate = lastChange.flatMap { PlanStore.day(fromStamp: $0) }
        let candidates = sessions.filter { session in
            guard session.game == game else { return false }
            guard session.resolvedLevel == current else { return false }
            guard session.accuracy != nil else { return false }
            if let changeDate, session.playedAt < changeDate { return false }
            return true
        }
        return
            candidates
            .sorted { $0.playedAt > $1.playedAt }
            .compactMap(\.accuracy)
    }
}
