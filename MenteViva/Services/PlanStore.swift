import Foundation

/// Today's plan and each game's level, kept on this device in UserDefaults
/// (#121: moved out of JevService, which now only talks to Jev). The key names
/// predate the move and stay, so stored levels and week-long holds survive it.
nonisolated enum PlanStore {
    private static let planKey = "jev.dailyPlan"
    private static let difficultyKey = "jev.difficulty"
    private static let changeKey = "jev.difficultyChangedOn"

    /// The last plan saved, whatever its day; callers check `dayStamp`.
    static func cachedPlan(defaults: UserDefaults = .standard) -> DailyPlan? {
        defaults.data(forKey: planKey)
            .flatMap { try? JSONDecoder().decode(DailyPlan.self, from: $0) }
    }

    /// Saves the plan, its levels as the stored ones, and the day each level
    /// that moved changed on (DailyPolicy holds a change for a week).
    static func cache(_ plan: DailyPlan, defaults: UserDefaults = .standard) {
        if let data = try? JSONEncoder().encode(plan) {
            defaults.set(data, forKey: planKey)
        }
        let before = storedDifficulty(defaults: defaults)
        var changed = lastDifficultyChange(defaults: defaults)
        for (game, level) in plan.difficulty where before[game] != level { changed[game] = plan.dayStamp }
        if let data = try? JSONEncoder().encode(Dictionary(uniqueKeysWithValues: changed.map { ($0.key.rawValue, $0.value) })) {
            defaults.set(data, forKey: changeKey)
        }
        if let data = try? JSONEncoder().encode(Dictionary(uniqueKeysWithValues: plan.difficulty.map { ($0.key.rawValue, $0.value.rawValue) })) {
            defaults.set(data, forKey: difficultyKey)
        }
    }

    /// Each game's level from the last saved plan (medium for a new player).
    /// Only changes when a new daily plan is saved.
    static func storedDifficulty(defaults: UserDefaults = .standard) -> [GameID: Difficulty] {
        let raw = defaults.data(forKey: difficultyKey)
            .flatMap { try? JSONDecoder().decode([String: Int].self, from: $0) } ?? [:]
        return Dictionary(uniqueKeysWithValues: GameID.allCases.map { game in
            (game, raw[game.rawValue].flatMap(Difficulty.init(rawValue:)) ?? .medium)
        })
    }

    /// Day stamp of each game's last level change.
    static func lastDifficultyChange(defaults: UserDefaults = .standard) -> [GameID: String] {
        let raw = defaults.data(forKey: changeKey)
            .flatMap { try? JSONDecoder().decode([String: String].self, from: $0) } ?? [:]
        return Dictionary(uniqueKeysWithValues: raw.compactMap { key, stamp in GameID(rawValue: key).map { ($0, stamp) } })
    }

    /// Local calendar day as "yyyy-MM-dd": a plan is valid only for its day.
    static func dayStamp(_ date: Date = .now) -> String {
        let f = DateFormatter()
        f.calendar = Calendar.current
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = .current
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }
}
