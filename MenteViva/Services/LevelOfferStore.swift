import Foundation

/// On-device remember-flags for #207, kept in `UserDefaults` (no sync, no
/// network, like `PlanStore`). Two maps: game rawValue → dayStamp "yyyy-MM-dd".
/// Pure policy lives in `LevelExplainPolicy`; this store is the only `UserDefaults` touch.
nonisolated enum LevelOfferStore {
    private static let explainSeenKey = "level.explainSeen"
    private static let offeredKey = "level.offeredToday"

    // MARK: - Explain seen

    static func hasSeenExplain(for game: GameID, today: String, defaults: UserDefaults = .standard) -> Bool {
        seenMap(defaults: defaults)[game.rawValue] == today
    }

    static func markExplainSeen(for game: GameID, today: String, defaults: UserDefaults = .standard) {
        var map = seenMap(defaults: defaults)
        map[game.rawValue] = today
        save(map, key: explainSeenKey, defaults: defaults)
    }

    // MARK: - Offered today

    static func hasOfferedToday(for game: GameID, today: String, defaults: UserDefaults = .standard) -> Bool {
        offeredMap(defaults: defaults)[game.rawValue] == today
    }

    static func markOffered(for game: GameID, today: String, defaults: UserDefaults = .standard) {
        var map = offeredMap(defaults: defaults)
        map[game.rawValue] = today
        save(map, key: offeredKey, defaults: defaults)
    }

    // MARK: - Chosen level up

    /// Player tapped "Yes, let's try" (#207 3): one level higher right now,
    /// stored like a staircase change with reason `.chosen` so the staircase
    /// then counts from there. Guarded to once per day — a second tap cannot
    /// lift the level again, even if the view races a double-tap (#262).
    static func applyChosen(for game: GameID, today: String, defaults: UserDefaults = .standard) {
        guard !hasOfferedToday(for: game, today: today, defaults: defaults) else { return }
        let before = PlanStore.storedDifficulty(defaults: defaults)
        let current = before[game] ?? Difficulty(level: 4)
        guard current.level < 10 else { return }
        let next = Difficulty(level: current.level + 1)
        var levels = before
        levels[game] = next
        if let data = try? JSONEncoder().encode(
            Dictionary(uniqueKeysWithValues: levels.map { ($0.key.rawValue, $0.value.level) }))
        {
            defaults.set(data, forKey: "level.byGame")
        }
        var changes = PlanStore.lastDifficultyChange(defaults: defaults)
        changes[game] = today
        if let data = try? JSONEncoder().encode(
            Dictionary(uniqueKeysWithValues: changes.map { ($0.key.rawValue, $0.value) }))
        {
            defaults.set(data, forKey: "jev.difficultyChangedOn")
        }
        // Patch cached today plan in place so Home and next opens keep the same day.
        if let cached = PlanStore.cachedPlan(defaults: defaults), cached.dayStamp == today {
            var diff = cached.difficulty
            diff[game] = next
            var ch = cached.changes
            ch[game] = LevelChange(previous: current, reason: .chosen)
            let patched = DailyPlan(dayStamp: cached.dayStamp, games: cached.games, difficulty: diff, changes: ch)
            if let data = try? JSONEncoder().encode(patched) {
                defaults.set(data, forKey: "jev.dailyPlan")
            }
        }
    }

    // MARK: - Internals

    private static func seenMap(defaults: UserDefaults) -> [String: String] {
        defaults.data(forKey: explainSeenKey)
            .flatMap { try? JSONDecoder().decode([String: String].self, from: $0) } ?? [:]
    }

    private static func offeredMap(defaults: UserDefaults) -> [String: String] {
        defaults.data(forKey: offeredKey)
            .flatMap { try? JSONDecoder().decode([String: String].self, from: $0) } ?? [:]
    }

    private static func save(_ map: [String: String], key: String, defaults: UserDefaults) {
        if let data = try? JSONEncoder().encode(map) {
            defaults.set(data, forKey: key)
        }
    }
}
