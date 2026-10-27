import Foundation

/// Which games have shown their first-play guide (#243), one flag per game in
/// `UserDefaults` (no sync, no network). Kept out of the view so tests can inject
/// a suite; Settings clears every flag through `resetAll`.
nonisolated enum FirstPlayGuideStore {
    private static func key(_ game: GameID) -> String { "guide.seen.\(game.rawValue)" }

    /// True until the player has dismissed this game's guide once.
    static func shouldShow(_ game: GameID, defaults: UserDefaults = .standard) -> Bool {
        !defaults.bool(forKey: key(game))
    }

    static func markSeen(_ game: GameID, defaults: UserDefaults = .standard) {
        defaults.set(true, forKey: key(game))
    }

    /// Settings → "Show the game guides again": every game, not just the ones with a guide
    /// today, so a game that adopts the guide later is covered without touching Settings.
    static func resetAll(defaults: UserDefaults = .standard) {
        for game in GameID.allCases {
            defaults.removeObject(forKey: key(game))
        }
    }
}
