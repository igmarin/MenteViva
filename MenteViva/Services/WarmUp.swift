import Foundation

/// The warm-up (#213): three games, one from each of three focus areas, that quietly settle where each
/// game's level starts. It is not a test: the player sees the usual games and the usual warm
/// celebration, never a score, a result or a level summary (research §1). Pure rules; `WarmUpStore`
/// keeps the state.
nonisolated enum WarmUp {
    /// Sessions a game spends calibrating before the normal staircase takes over.
    static let sessions = 3

    /// Whether the end of onboarding offers it. Someone setting the app up for a family member
    /// is not the one who will play, so it is not offered there (it stays in Settings → My plan).
    static func isOffered(to profile: PlayerProfile) -> Bool {
        profile.forWhom != .familyMember
    }

    /// Three games from three different focus areas. Areas the player chose come first, then the
    /// rest; inside an area the most worthwhile game wins, ties in `GameID` order, so the deal is
    /// the same every time. Hidden and pinned games are left alone: the family's choices stand.
    static func picks(profile: PlayerProfile, hidden: Set<GameID>, pinned: [GameID: Difficulty]) -> [GameID] {
        let areas = PlayerProfile.Focus.allCases.filter { $0 != .justFun }
        let ordered = areas.filter(profile.focus.contains) + areas.filter { !profile.focus.contains($0) }
        let candidates = GameID.released.filter { $0.hasLevels && !hidden.contains($0) && pinned[$0] == nil }
        let best = ordered.compactMap { area in
            candidates.filter { DailyPolicy.focus[$0] == area }
                .reduce(nil as GameID?) { best, game in
                    guard let best else { return game }
                    return (DailyPolicy.value[game] ?? 0) > (DailyPolicy.value[best] ?? 0) ? game : best
                }
        }
        return Array(best.prefix(3))
    }

    /// The level after one calibrating session: a strong one climbs two, a hard-going one eases two,
    /// anything between stays. Same thresholds as the staircase, a bigger step, and no once-a-day hold.
    static func level(after accuracy: Double, game: GameID, current: Difficulty) -> (Difficulty, LevelChange?) {
        let step: Int
        if accuracy >= DailyPolicy.strongAccuracy(for: game) {
            step = 2
        } else if accuracy < DailyPolicy.weakAccuracy(for: game) {
            step = -2
        } else {
            return (current, nil)
        }
        let next = Difficulty(level: current.level + step)
        guard next != current else { return (current, nil) }
        let moved = next.level - current.level
        return (next, LevelChange(previous: current, reason: moved > 0 ? .raised(by: moved) : .eased))
    }
}

/// Which games are still calibrating and how many sessions each has left, in UserDefaults like
/// `PlanStore`, injected so tests use their own suite.
nonisolated enum WarmUpStore {
    private static let key = "warmup.remaining"

    /// Starts the warm-up: deals today's three at the player's start level and marks them
    /// calibrating. Returns the games dealt.
    @discardableResult
    static func start(profile: PlayerProfile, today: String, defaults: UserDefaults = .standard) -> [GameID] {
        let games = WarmUp.picks(
            profile: profile, hidden: FamilySettings.hidden(defaults: defaults),
            pinned: FamilySettings.pinned(defaults: defaults))
        PlanStore.beginWarmUp(
            games: games, at: DailyPolicy.startingLevel(for: profile), today: today, defaults: defaults)
        save(Dictionary(uniqueKeysWithValues: games.map { ($0, WarmUp.sessions) }), defaults: defaults)
        return games
    }

    /// Calibrating sessions this game has left; 0 when it is not calibrating.
    static func remaining(_ game: GameID, defaults: UserDefaults = .standard) -> Int {
        load(defaults: defaults)[game] ?? 0
    }

    static func isCalibrating(_ game: GameID, defaults: UserDefaults = .standard) -> Bool {
        remaining(game, defaults: defaults) > 0
    }

    /// Called after every saved session. For a calibrating game it moves the level at once (so the
    /// next session of the same day already starts there), counts the session, and skips today's
    /// "next level?" offer so the two never stack. Any other game is left alone.
    static func sessionFinished(game: GameID, accuracy: Double?, today: String, defaults: UserDefaults = .standard) {
        var left = load(defaults: defaults)
        guard let count = left[game], count > 0 else { return }
        left[game] = count > 1 ? count - 1 : nil
        save(left, defaults: defaults)
        guard let accuracy else { return }
        let current = PlanStore.storedDifficulty(defaults: defaults)[game] ?? Difficulty(level: 4)
        let (next, change) = WarmUp.level(after: accuracy, game: game, current: current)
        guard let change else { return }
        PlanStore.move(game, to: next, reason: change.reason, today: today, defaults: defaults)
        LevelOfferStore.markOffered(for: game, today: today, defaults: defaults)
    }

    private static func load(defaults: UserDefaults) -> [GameID: Int] {
        let raw =
            defaults.data(forKey: key)
            .flatMap { try? JSONDecoder().decode([String: Int].self, from: $0) } ?? [:]
        return Dictionary(uniqueKeysWithValues: raw.compactMap { name, count in GameID(rawValue: name).map { ($0, count) } })
    }

    private static func save(_ remaining: [GameID: Int], defaults: UserDefaults) {
        let raw = Dictionary(uniqueKeysWithValues: remaining.map { ($0.key.rawValue, $0.value) })
        if let data = try? JSONEncoder().encode(raw) {
            defaults.set(data, forKey: key)
        }
    }
}
