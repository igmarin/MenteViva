import Foundation

/// The choices from the Set up screen (#108, #141), kept per device
/// (no sync on a free account). Pins fix a game's difficulty until set back to
/// Auto; hidden games stay off Home and out of the daily picks, code kept (#47).
/// Plain UserDefaults keys so views can bind them with @AppStorage.
nonisolated enum FamilySettings {
    static let hiddenKey = "games.hidden"
    /// Stored pin value meaning "let the rules decide".
    static let auto = -1

    /// Pins saved by earlier versions (0/1/2 or Auto); read once to migrate,
    /// then left in place. New pins save under `pinKey` (#197).
    static func legacyPinKey(_ game: GameID) -> String { "difficulty.pin.\(game.rawValue)" }

    static func pinKey(_ game: GameID) -> String { "level.pin.\(game.rawValue)" }

    /// Hidden games as comma-separated IDs (what @AppStorage holds).
    static func hidden(from csv: String) -> Set<GameID> {
        Set(csv.split(separator: ",").compactMap { GameID(rawValue: String($0)) })
    }

    static func csv(_ games: Set<GameID>) -> String {
        GameID.allCases.filter(games.contains).map(\.rawValue).joined(separator: ",")
    }

    static func hidden(defaults: UserDefaults = .standard) -> Set<GameID> {
        hidden(from: defaults.string(forKey: hiddenKey) ?? "")
    }

    /// A raw pin value as a level: Auto stays absent, legacy 0/1/2 read as
    /// levels 2/4/6, anything else clamps into 1...10 (#197).
    static func pinnedLevel(_ raw: Int) -> Difficulty? {
        guard raw != auto else { return nil }
        if (0...2).contains(raw) { return Difficulty(level: [2, 4, 6][raw]) }
        return Difficulty(level: raw)
    }

    /// One-time upgrade of pre-level pins (#197): legacy values read as
    /// levels 2/4/6 and save under the new keys, which later reads prefer.
    /// Call before binding `@AppStorage` to the new keys so Set up opens on
    /// the migrated pin.
    static func migrateLegacyPins(defaults: UserDefaults = .standard) {
        for game in GameID.allCases {
            guard defaults.object(forKey: pinKey(game)) == nil,
                let old = defaults.object(forKey: legacyPinKey(game)) as? Int,
                old != auto
            else { continue }
            defaults.set(pinnedLevel(old)?.level ?? auto, forKey: pinKey(game))
        }
    }

    /// Games with a fixed difficulty; Auto games are absent.
    static func pinned(defaults: UserDefaults = .standard) -> [GameID: Difficulty] {
        migrateLegacyPins(defaults: defaults)
        return Dictionary(
            uniqueKeysWithValues: GameID.allCases.compactMap { game in
                (defaults.object(forKey: pinKey(game)) as? Int)
                    .flatMap(pinnedLevel)
                    .map { (game, $0) }
            })
    }
}
