import Foundation

/// Why a level moved, kept with the plan so the next screen can explain it (#198).
nonisolated struct LevelChange: Codable, Equatable {
    let previous: Difficulty
    let reason: Reason

    /// Fast climbers, gentle drops: one strong session climbs one, two in a
    /// row climb two; a hard-going session eases one, never more.
    /// `.chosen` is the player's own \"Yes, let's try\" after a strong game (#207).
    enum Reason: Codable, Equatable {
        case raised(by: Int)
        case eased
        case chosen
    }
}

/// Today's mix and each game's level; valid only for its day.
nonisolated struct DailyPlan: Codable, Equatable {
    let dayStamp: String  // local "yyyy-MM-dd"; valid only for its day
    let games: [GameID]  // recommended mix, best first
    let difficulty: [GameID: Difficulty]
    /// For each game whose level moved today, why and from where (#198).
    let changes: [GameID: LevelChange]

    init(dayStamp: String, games: [GameID], difficulty: [GameID: Difficulty], changes: [GameID: LevelChange] = [:]) {
        self.dayStamp = dayStamp
        self.games = games
        self.difficulty = difficulty
        self.changes = changes
    }

    private enum CodingKeys: String, CodingKey { case dayStamp, games, difficulty, changes }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        dayStamp = try c.decode(String.self, forKey: .dayStamp)
        games = try c.decode([GameID].self, forKey: .games)
        difficulty = try c.decode([GameID: Difficulty].self, forKey: .difficulty)
        changes = try c.decodeIfPresent([GameID: LevelChange].self, forKey: .changes) ?? [:]
    }
}

/// Today's plan decided by rules, on the device: no model, no network, no key (#101).
///
/// - Mix: the most worthwhile games first, nudged toward games not touched lately.
/// - Difficulty: a staircase, never mid-game. One strong session climbs one
///   level, two strong in a row climb two; hard-going eases one. The window
///   since the last change is the hold (#198).
nonisolated enum DailyPolicy {
    /// How worthwhile each game is for the target player (Jev 008/010 utility
    /// matrix). The star marks "best for today", not a schedule, so the two
    /// low-value games rarely get one. Playtest #6 kept these values; the
    /// family can now hide a game instead (#47, #108), and hidden games are never picked.
    static let value: [GameID: Double] = [
        .memoryMatch: 1.0, .quickEyes: 0.8, .categoryFluency: 0.7, .stroop: 0.3, .mathStreaks: 0.3,
        .reminiscence: 0.7, .sudoku: 0.8, .upOrDown: 0.8, .sayings: 0.8,
        .repeatSequence: 0.8, .tangram: 0.8, .tilePairs: 0.8, .slidingBlocks: 0.8,
    ]
    static let gamesPerDay = 3

    // MARK: - Staircase thresholds (#198)

    /// Accuracy that counts as strong (at or above) or hard-going (below)
    /// for the staircase. Defaults are 0.90 strong / 0.65 weak.
    struct Threshold: Equatable {
        let strong: Double
        let weak: Double
    }

    /// Per-game strong/weak accuracy. Defaults are 0.90 / 0.65; only Memory
    /// Lane differs (see its comment). Each entry has a /// so the choice is
    /// auditable without opening another file.
    static let thresholds: [GameID: Threshold] = [
        /// Memory Lane counts moves as attempts and pairs as correct
        /// (accuracy = pairs / moves). A tidy 8-pair board finished in 12
        /// moves is 0.66, so even good play hovers near 0.6; thresholds are
        /// lowered to 0.65 strong / 0.45 weak so a clean game still climbs
        /// and a struggling one still eases.
        .memoryMatch: Threshold(strong: 0.65, weak: 0.45),
        /// Color Clash: pick the ink, not the word. Accuracy is picks correct.
        .stroop: Threshold(strong: 0.90, weak: 0.65),
        /// Name the Herd: animal names recalled per category. Accuracy is correct / attempts.
        .categoryFluency: Threshold(strong: 0.90, weak: 0.65),
        /// Number Trail: sums answered. Accuracy is correct / attempts.
        .mathStreaks: Threshold(strong: 0.90, weak: 0.65),
        /// Quick Eyes: picture recognised then picked. Accuracy is correct / attempts.
        .quickEyes: Threshold(strong: 0.90, weak: 0.65),
        /// Remember Together has no levels; never evaluated, kept for completeness.
        .reminiscence: Threshold(strong: 0.90, weak: 0.65),
        /// Sudoku: numbers that fit. Accuracy is placements correct.
        .sudoku: Threshold(strong: 0.90, weak: 0.65),
        /// Up or Down: cards that fit one higher or lower. Accuracy is correct moves.
        .upOrDown: Threshold(strong: 0.90, weak: 0.65),
        /// Finish the Saying: the familiar ending picked. Accuracy is correct / attempts.
        .sayings: Threshold(strong: 0.90, weak: 0.65),
    ]

    /// Strong accuracy for a game (at or above counts as strong).
    static func strongAccuracy(for game: GameID) -> Double {
        thresholds[game]?.strong ?? 0.90
    }

    /// Weak accuracy for a game (below counts as hard-going).
    static func weakAccuracy(for game: GameID) -> Double {
        thresholds[game]?.weak ?? 0.65
    }

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
        let ranked = GameID.released.filter { !hidden.contains($0) }.enumerated()
            .map { (index: $0.offset, game: $0.element, score: mixScore($0.element, state)) }
            .sorted { $0.score != $1.score ? $0.score > $1.score : $0.index < $1.index }
        var difficulty: [GameID: Difficulty] = [:]
        var changes: [GameID: LevelChange] = [:]
        for game in GameID.allCases {
            if let pin = pinned[game] {
                difficulty[game] = pin
                continue
            }
            let stats = state.games[game.rawValue]
            let (next, change) = nextDifficulty(
                stats, game: game, changedOn: lastChange[game], today: dayStamp)
            difficulty[game] = next
            if let change {
                changes[game] = change
            }
        }
        return DailyPlan(
            dayStamp: dayStamp,
            games: ranked.prefix(gamesPerDay).map(\.game),
            difficulty: difficulty,
            changes: changes)
    }

    private static func mixScore(_ game: GameID, _ state: PlayerStateSummary) -> Double {
        let daysAway = Double(min(state.games[game.rawValue]?.daysSinceLastPlayed ?? 14, 7))
        return (value[game] ?? 0.5) * (0.5 + 0.5 * daysAway / 7)
    }

    /// Staircase (#198): at most one move per game per day, never mid-game.
    /// - newest hard-going (< weak) → −1
    /// - newest strong and previous strong too → +2
    /// - newest strong → +1
    /// - else unchanged. Clamped 1...10.
    private static func nextDifficulty(
        _ stats: PlayerStateSummary.GameStats?,
        game: GameID,
        changedOn: String?, today: String
    ) -> (Difficulty, LevelChange?) {
        let current = stats?.currentDifficulty ?? Difficulty(level: 4)
        guard let stats, !stats.recentAccuracies.isEmpty else { return (current, nil) }
        if let changedOn, changedOn == today { return (current, nil) }
        let strong = strongAccuracy(for: game)
        let weak = weakAccuracy(for: game)
        let recent = stats.recentAccuracies  // newest first
        if recent[0] < weak {
            let next = Difficulty(level: current.level - 1)
            guard next.level != current.level else { return (current, nil) }
            return (next, LevelChange(previous: current, reason: .eased))
        }
        if recent[0] >= strong {
            let by: Int
            if recent.count >= 2, recent[1] >= strong { by = 2 } else { by = 1 }
            let next = Difficulty(level: current.level + by)
            guard next.level != current.level else { return (current, nil) }
            let actual = next.level - current.level
            return (next, LevelChange(previous: current, reason: .raised(by: actual)))
        }
        return (current, nil)
    }

    /// Whole days from `from` to `to` (both "yyyy-MM-dd"); large when unparseable, so a bad stamp never blocks a change.
    static func daysBetween(_ from: String, _ to: String) -> Int {
        guard let a = PlanStore.day(fromStamp: from), let b = PlanStore.day(fromStamp: to) else { return .max }
        return Calendar.current.dateComponents([.day], from: a, to: b).day ?? .max
    }
}
