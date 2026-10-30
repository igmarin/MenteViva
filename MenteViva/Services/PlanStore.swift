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
            hidden: FamilySettings.hidden(defaults: defaults).union(GameAvailability.unavailable()),
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
        let current = storedDifficulty(defaults: defaults)[game] ?? Difficulty(level: 4)
        guard current.level < Difficulty.range.upperBound else { return nil }
        let next = Difficulty(level: current.level + 1)
        move(game, to: next, reason: .chosen, today: today, defaults: defaults)
        return next
    }

    /// One level change made right now, outside the daily staircase (a chosen "Yes, let's try" or a
    /// warm-up session, #213): stores the level, counts the staircase from today, and patches today's
    /// saved plan in place so Home and the next open agree.
    static func move(
        _ game: GameID, to next: Difficulty, reason: LevelChange.Reason, today: String,
        defaults: UserDefaults = .standard
    ) {
        var levels = storedDifficulty(defaults: defaults)
        let current = levels[game] ?? Difficulty(level: 4)
        levels[game] = next
        save(levels: levels, defaults: defaults)
        var changed = lastDifficultyChange(defaults: defaults)
        changed[game] = today
        save(changes: changed, defaults: defaults)
        if let cached = cachedPlan(defaults: defaults), cached.dayStamp == today {
            var difficulty = cached.difficulty
            difficulty[game] = next
            var changes = cached.changes
            changes[game] = LevelChange(previous: current, reason: reason)
            save(
                plan: DailyPlan(dayStamp: today, games: cached.games, difficulty: difficulty, changes: changes),
                defaults: defaults)
        }
    }

    /// Replaces today's plan with the warm-up's games (#213), each at `level`, and counts the
    /// staircase from today so earlier sessions don't weigh in. Other games keep their levels.
    static func beginWarmUp(games: [GameID], at level: Difficulty, today: String, defaults: UserDefaults = .standard) {
        var levels = storedDifficulty(defaults: defaults)
        var changed = lastDifficultyChange(defaults: defaults)
        for game in games {
            levels[game] = level
            changed[game] = today
        }
        save(levels: levels, defaults: defaults)
        save(changes: changed, defaults: defaults)
        save(plan: DailyPlan(dayStamp: today, games: games, difficulty: levels), defaults: defaults)
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
    /// Called by `Difficulty.stored(_:)` and `PlanStore.todaysPlan`/`PlanStore.cache`,
    /// and read by `HomeView.refreshPlan` to seed `CelebrationView` offers via `LevelPolicy`.
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

    /// Local calendar day as "yyyy-MM-dd": a plan is valid only for its day. The calendar (and its
    /// time zone) is a parameter so a test can pin where midnight falls (#376).
    static func dayStamp(_ date: Date = .now, calendar: Calendar = .current) -> String {
        stampFormat(calendar: calendar).string(from: date)
    }

    /// The day a stamp names, or nil when it isn't one.
    static func day(fromStamp stamp: String) -> Date? {
        stampFormat().date(from: stamp)
    }

    /// The one definition of the stamp format (#122). Made per call:
    /// DateFormatter isn't Sendable, and this runs a few times a day.
    private static func stampFormat(calendar: Calendar = .current) -> DateFormatter {
        let f = DateFormatter()
        f.calendar = calendar
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = calendar.timeZone
        f.dateFormat = "yyyy-MM-dd"
        return f
    }
}
