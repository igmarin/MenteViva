import Foundation

/// The caregiver's choices from the For family screen (#108), kept per device
/// (no sync on a free account). Pins fix a game's difficulty until set back to
/// Auto; hidden games stay off Home and out of the daily picks, code kept (#47).
/// Plain UserDefaults keys so views can bind them with @AppStorage.
nonisolated enum FamilySettings {
    static let hiddenKey = "games.hidden"
    /// Stored pin value meaning "let the rules decide".
    static let auto = -1

    static func pinKey(_ game: GameID) -> String { "difficulty.pin.\(game.rawValue)" }

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

    /// Games with a fixed difficulty; Auto games are absent.
    static func pinned(defaults: UserDefaults = .standard) -> [GameID: Difficulty] {
        Dictionary(uniqueKeysWithValues: GameID.allCases.compactMap { game in
            (defaults.object(forKey: pinKey(game)) as? Int)
                .flatMap(Difficulty.init(rawValue:))
                .map { (game, $0) }
        })
    }
}
