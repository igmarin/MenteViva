import Foundation

/// Today's plan and each game's level, kept on this device in UserDefaults
/// (#121). Plans are always decided on the device by `DailyPolicy`.
nonisolated enum PlanStore {
    // The "jev." key names are historical (an outside service once helped pick the plan).
    // They stay so levels and week-long holds saved by earlier versions are still read.
    private static let planKey = "jev.dailyPlan"
    /// Levels saved by earlier versions (0/1/2); read once to migrate, then
    /// left in place. New levels save under `levelKey` (#197).
    private static let legacyDifficultyKey = "jev.difficulty"
    private static let levelKey = "level.byGame"
    private static let changeKey = "jev.difficultyChangedOn"

    /// Today's plan: the one saved for today if there is one, otherwise a fresh
    /// `DailyPolicy` plan, saved so the day keeps one plan. Nothing leaves the device.
    static func todaysPlan(
        state: PlayerStateSummary,
        now: Date = .now,
        defaults: UserDefaults = .standard
    ) -> DailyPlan {
        let stamp = dayStamp(now)
        if let cached = cachedPlan(defaults: defaults), cached.dayStamp == stamp { return cached }
        let plan = DailyPolicy.plan(
            state: state,
            lastChange: lastDifficultyChange(defaults: defaults),
            dayStamp: stamp,
            pinned: FamilySettings.pinned(defaults: defaults),
            hidden: FamilySettings.hidden(defaults: defaults),
            profile: ProfileStore.load(defaults: defaults))
        cache(plan, defaults: defaults)
        return plan
    }

    /// The last plan saved, whatever its day; callers check `dayStamp`.
    static func cachedPlan(defaults: UserDefaults = .standard) -> DailyPlan? {
        defaults.data(forKey: planKey)
            .flatMap { try? JSONDecoder().decode(DailyPlan.self, from: $0) }
    }

    /// Saves the plan, its levels as the stored ones, and the day each level
    /// that moved changed on (the staircase counts sessions from that day, #198).
    static func cache(_ plan: DailyPlan, defaults: UserDefaults = .standard) {
        save(plan: plan, defaults: defaults)
        let before = storedDifficulty(defaults: defaults)
        var changed = lastDifficultyChange(defaults: defaults)
        for (game, level) in plan.difficulty where before[game] != level { changed[game] = plan.dayStamp }
        save(changes: changed, defaults: defaults)
        save(levels: plan.difficulty, defaults: defaults)
    }

    /// The player's own "Yes, let's try" (#207): one level up right now, recorded like a staircase
    /// change with reason `.chosen`, so the staircase counts from the new level. Today's saved plan is
    /// patched in place so Home and the next open agree. Returns the new level, or nil at level 10.
    /// Lives here because only `PlanStore` knows its keys.
    @discardableResult
    static func raiseByChoice(_ game: GameID, today: String, defaults: UserDefaults = .standard) -> Difficulty? {
        var levels = storedDifficulty(defaults: defaults)
        let current = levels[game] ?? Difficulty(level: 4)
        guard current.level < Difficulty.range.upperBound else { return nil }
        let next = Difficulty(level: current.level + 1)
        levels[game] = next
        save(levels: levels, defaults: defaults)
        var changed = lastDifficultyChange(defaults: defaults)
        changed[game] = today
        save(changes: changed, defaults: defaults)
        if let cached = cachedPlan(defaults: defaults), cached.dayStamp == today {
            var difficulty = cached.difficulty
            difficulty[game] = next
            var changes = cached.changes
            changes[game] = LevelChange(previous: current, reason: .chosen)
            save(
                plan: DailyPlan(dayStamp: today, games: cached.games, difficulty: difficulty, changes: changes),
                defaults: defaults)
        }
        return next
    }

    private static func save(plan: DailyPlan, defaults: UserDefaults) {
        if let data = try? JSONEncoder().encode(plan) {
            defaults.set(data, forKey: planKey)
        }
    }

    private static func save(changes: [GameID: String], defaults: UserDefaults) {
        let raw = Dictionary(uniqueKeysWithValues: changes.map { ($0.key.rawValue, $0.value) })
        if let data = try? JSONEncoder().encode(raw) {
            defaults.set(data, forKey: changeKey)
        }
    }

    private static func save(levels: [GameID: Difficulty], defaults: UserDefaults) {
        let raw = Dictionary(uniqueKeysWithValues: levels.map { ($0.key.rawValue, $0.value.level) })
        if let data = try? JSONEncoder().encode(raw) {
            defaults.set(data, forKey: levelKey)
        }
    }

    /// Each game's level from the last saved plan. A game with none yet starts where the profile says
    /// (`DailyPolicy.startingLevel`, #211; level 4 without one). Only changes when a new daily plan is
    /// saved. Pure read — does not migrate (#264); `LevelMigration.runOnce` does that once at launch.
    static func storedDifficulty(defaults: UserDefaults = .standard) -> [GameID: Difficulty] {
        let raw =
            defaults.data(forKey: levelKey)
            .flatMap { try? JSONDecoder().decode([String: Int].self, from: $0) } ?? [:]
        let start = DailyPolicy.startingLevel(for: ProfileStore.load(defaults: defaults))
        return Dictionary(
            uniqueKeysWithValues: GameID.allCases.map { game in
                (game, raw[game.rawValue].map(Difficulty.init(level:)) ?? start)
            })
    }

    /// One-time upgrade of pre-level plans (#197): old 0/1/2 values read as
    /// levels 2/4/6 and save under the new key, which later reads prefer.
    /// Called once by `LevelMigration.runOnce` at launch (#264); reads never
    /// trigger it.
    /// Visible for `LevelMigration` only; reads never call it (#264).
    static func migrateLegacyLevels(defaults: UserDefaults = .standard) {
        guard defaults.data(forKey: levelKey) == nil,
            let old = defaults.data(forKey: legacyDifficultyKey)
                .flatMap({ try? JSONDecoder().decode([String: Int].self, from: $0) })
        else { return }
        let migrated = old.mapValues { $0 >= 0 && $0 <= 2 ? [2, 4, 6][$0] : max(1, $0) }
        if let data = try? JSONEncoder().encode(migrated) {
            defaults.set(data, forKey: levelKey)
        }
    }

    /// Day stamp of each game's last level change.
    static func lastDifficultyChange(defaults: UserDefaults = .standard) -> [GameID: String] {
        let raw =
            defaults.data(forKey: changeKey)
            .flatMap { try? JSONDecoder().decode([String: String].self, from: $0) } ?? [:]
        return Dictionary(uniqueKeysWithValues: raw.compactMap { key, stamp in GameID(rawValue: key).map { ($0, stamp) } })
    }

    /// Local calendar day as "yyyy-MM-dd": a plan is valid only for its day.
    static func dayStamp(_ date: Date = .now) -> String {
        stampFormat().string(from: date)
    }

    /// The day a stamp names, or nil when it isn't one.
    static func day(fromStamp stamp: String) -> Date? {
        stampFormat().date(from: stamp)
    }

    /// The one definition of the stamp format (#122). Made per call:
    /// DateFormatter isn't Sendable, and this runs a few times a day.
    private static func stampFormat() -> DateFormatter {
        let f = DateFormatter()
        f.calendar = Calendar.current
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = .current
        f.dateFormat = "yyyy-MM-dd"
        return f
    }
}
