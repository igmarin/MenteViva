import Foundation

/// Today's mix and each game's level; valid only for its day.
nonisolated struct DailyPlan: Codable, Equatable {
    let dayStamp: String  // local "yyyy-MM-dd"; valid only for its day
    let games: [GameID]  // recommended mix, best first
    let difficulty: [GameID: Difficulty]
}

/// Today's plan decided by rules, on the device: no model, no network, no key (#101).
///
/// - Mix: the most worthwhile games first, nudged toward games not touched lately.
/// - Difficulty: errorless-first. Moves one level at a time, only with evidence,
///   then holds for a week so it never shifts under the player.
///
/// Jev (when a proxy is configured) can still override this plan; see JevService.
nonisolated enum DailyPolicy {
    /// How worthwhile each game is for the target player (Jev 008/010 utility
    /// matrix). The star marks "best for today", not a schedule, so the two
    /// low-value games rarely get one. Playtest #6 kept these values; the
    /// family can now hide a game instead (#47, #108), and hidden games are never picked.
    static let value: [GameID: Double] = [
        .memoryMatch: 1.0, .quickEyes: 0.8, .categoryFluency: 0.7, .stroop: 0.3, .mathStreaks: 0.3,
    ]
    static let gamesPerDay = 3
    /// Days a difficulty stays put after it changes. The 14-day accuracy window
    /// would otherwise trigger another step on old sessions the next morning.
    static let holdDays = 7
    static let easeBelowAccuracy = 0.65
    static let raiseAtAccuracy = 0.90
    static let raiseNeedsSessions = 3

    /// `lastChange`: game -> day stamp when its difficulty last moved.
    /// `pinned` / `hidden`: the family's choices (#108). A pinned game keeps its
    /// level, and since the plan's levels become the stored ones, switching back
    /// to Auto resumes from the pin. Hidden games are never picked.
    static func plan(
        state: PlayerStateSummary,
        lastChange: [GameID: String] = [:],
        dayStamp: String,
        pinned: [GameID: Difficulty] = [:],
        hidden: Set<GameID> = []
    ) -> DailyPlan {
        let ranked = GameID.allCases.filter { !hidden.contains($0) }.enumerated()
            .map { (index: $0.offset, game: $0.element, score: mixScore($0.element, state)) }
            .sorted { $0.score != $1.score ? $0.score > $1.score : $0.index < $1.index }
        var difficulty: [GameID: Difficulty] = [:]
        for game in GameID.allCases {
            difficulty[game] =
                pinned[game]
                ?? nextDifficulty(
                    state.games[game.rawValue],
                    changedOn: lastChange[game], today: dayStamp)
        }
        return DailyPlan(
            dayStamp: dayStamp,
            games: ranked.prefix(gamesPerDay).map(\.game),
            difficulty: difficulty)
    }

    private static func mixScore(_ game: GameID, _ state: PlayerStateSummary) -> Double {
        let daysAway = Double(min(state.games[game.rawValue]?.daysSinceLastPlayed ?? 14, 7))
        return (value[game] ?? 0.5) * (0.5 + 0.5 * daysAway / 7)
    }

    private static func nextDifficulty(
        _ stats: PlayerStateSummary.GameStats?,
        changedOn: String?, today: String
    ) -> Difficulty {
        let current = stats?.currentDifficulty ?? .medium
        guard let stats, stats.sessionsLast14Days > 0, let accuracy = stats.meanAccuracy else { return current }
        if let changedOn, daysBetween(changedOn, today) < holdDays { return current }
        if accuracy < easeBelowAccuracy {
            return Difficulty(rawValue: current.rawValue - 1) ?? .easy
        }
        if accuracy >= raiseAtAccuracy && stats.sessionsLast14Days >= raiseNeedsSessions {
            return Difficulty(rawValue: current.rawValue + 1) ?? .hard
        }
        return current
    }

    /// Whole days from `from` to `to` (both "yyyy-MM-dd"); large when unparseable, so a bad stamp never blocks a change.
    private static func daysBetween(_ from: String, _ to: String) -> Int {
        guard let a = PlanStore.day(fromStamp: from), let b = PlanStore.day(fromStamp: to) else { return .max }
        return Calendar.current.dateComponents([.day], from: a, to: b).day ?? .max
    }
}
