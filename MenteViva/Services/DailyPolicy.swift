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
    /// matrix). The star marks "best for today", not a schedule. Color Clash and
    /// Number Trail sat at 0.3, which never won a place in the daily three. At 0.55
    /// each is dealt about 2 days in 14, with no profile and with any one focus area
    /// (0.5 was enough without a profile, but a focus crowded them out again; #277).
    /// The family can hide a game instead (#47, #108); hidden games are never picked.
    static let value: [GameID: Double] = [
        .memoryMatch: 1.0, .quickEyes: 0.8, .categoryFluency: 0.7, .stroop: 0.55, .mathStreaks: 0.55,
        .reminiscence: 0.7, .sudoku: 0.8, .upOrDown: 0.8, .sayings: 0.8,
        .repeatSequence: 0.8, .tangram: 0.8, .tilePairs: 0.8, .slidingBlocks: 0.8,
    ]
    static let gamesPerDay = 3

    // MARK: - The player's profile (#211)

    /// What each game mostly exercises, for the profile's focus: one area per game.
    static let focus: [GameID: PlayerProfile.Focus] = [
        /// Memory Lane: where each picture was.
        .memoryMatch: .memory,
        /// Color Clash: the ink, not the word.
        .stroop: .attention,
        /// Name the Herd: words that belong together.
        .categoryFluency: .words,
        /// Number Trail: sums.
        .mathStreaks: .numbers,
        /// Quick Eyes: one picture among four, quickly.
        .quickEyes: .attention,
        /// Remember Together: family faces and names.
        .reminiscence: .memory,
        /// Sudoku: numbers that fit a square.
        .sudoku: .numbers,
        /// Up or Down: a card one higher or one lower.
        .upOrDown: .numbers,
        /// Finish the Saying: the familiar ending.
        .sayings: .words,
        /// Repeat the Sequence: the order things lit up in.
        .repeatSequence: .memory,
        /// Tangram: shapes that fill a silhouette.
        .tangram: .attention,
        /// Tile Pairs: matching free tiles on a crowded table.
        .tilePairs: .attention,
        /// Sliding Blocks: the moves that free a block.
        .slidingBlocks: .attention,
    ]

    /// A game in a chosen area counts this much more in the mix score. Only the order of the scores
    /// decides the deal, so `value` keeps its 0...1 scale and the boosted score needs no cap.
    static let focusBoost = 1.5

    /// Games dealt a day from the minutes chosen: 5 → 2, 10 → 3, 15 → 5; unset keeps today's 3.
    static func dealSize(for profile: PlayerProfile) -> Int {
        switch profile.minutesPerDay {
        case 5: 2
        case 15: 5
        default: gamesPerDay
        }
    }

    /// Where a game with no saved level starts: calm 2, normal 4, challenge 6. A player set up by a
    /// family member starts calm unless a pace was chosen; an empty profile starts at 4, as before.
    static func startingLevel(for profile: PlayerProfile) -> Difficulty {
        switch profile.startPace ?? (profile.forWhom == .familyMember ? .calm : .normal) {
        case .calm: Difficulty(level: 2)
        case .normal: Difficulty(level: 4)
        case .challenge: Difficulty(level: 6)
        }
    }

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
    /// `profile` (#211) sets how many games, which areas count more and where a new game starts;
    /// the empty profile gives exactly the plan from before profiles.
    static func plan(
        state: PlayerStateSummary,
        lastChange: [GameID: String] = [:],
        dayStamp: String,
        pinned: [GameID: Difficulty] = [:],
        hidden: Set<GameID> = [],
        profile: PlayerProfile = PlayerProfile()
    ) -> DailyPlan {
        let visible = GameID.released.filter { !hidden.contains($0) }
        let ranked = visible.enumerated()
            .map { (index: $0.offset, game: $0.element, score: mixScore($0.element, state, focus: profile.focus)) }
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
                stats, game: game, changedOn: lastChange[game], today: dayStamp, start: startingLevel(for: profile))
            difficulty[game] = next
            if let change {
                changes[game] = change
            }
        }
        return DailyPlan(
            dayStamp: dayStamp,
            games: withLongestWaiting(Array(ranked.prefix(dealSize(for: profile)).map(\.game)), from: visible, state),
            difficulty: difficulty,
            changes: changes)
    }

    /// Days a game may go undealt before it is owed a place (#279).
    static let restLimit = 7

    /// A visible game that has rested `restLimit` days or more takes the deal's last place (#279): the
    /// longest-rested one, ties in `GameID` order, and only from a game that has rested less. A rule and
    /// not a weight, because with a focus or a short deal no weight keeps every game coming round, while
    /// this one does. The first places never change, and a brand-new player (every game equally rested)
    /// keeps the ranked deal.
    private static func withLongestWaiting(
        _ deal: [GameID], from visible: [GameID], _ state: PlayerStateSummary
    ) -> [GameID] {
        guard deal.count > 1, let last = deal.last else { return deal }
        let rested = { (game: GameID) in state.games[game.rawValue]?.daysSinceLastPlayed ?? 14 }
        let waiting = visible.filter { !deal.contains($0) && rested($0) >= restLimit }
        guard let longest = waiting.max(by: { rested($0) < rested($1) }), rested(longest) > rested(last) else {
            return deal
        }
        return Array(deal.dropLast()) + [longest]
    }

    /// Worth, times the focus boost, times how long the game has rested: a focus moves a game up the
    /// deal but never stops the rest from resting into it, so variety still holds.
    private static func mixScore(
        _ game: GameID, _ state: PlayerStateSummary, focus chosen: Set<PlayerProfile.Focus>
    ) -> Double {
        let daysAway = Double(min(state.games[game.rawValue]?.daysSinceLastPlayed ?? 14, 7))
        let boosted = focus[game].map { chosen.contains($0) } ?? false
        let boost = boosted ? focusBoost : 1
        return (value[game] ?? 0.5) * boost * (0.5 + 0.5 * daysAway / 7)
    }

    /// Staircase (#198): at most one move per game per day, never mid-game.
    /// - newest hard-going (< weak) → −1
    /// - newest strong and previous strong too → +2
    /// - newest strong → +1
    /// - else unchanged. Clamped 1...10.
    private static func nextDifficulty(
        _ stats: PlayerStateSummary.GameStats?,
        game: GameID,
        changedOn: String?, today: String, start: Difficulty
    ) -> (Difficulty, LevelChange?) {
        let current = stats?.currentDifficulty ?? start
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
}
