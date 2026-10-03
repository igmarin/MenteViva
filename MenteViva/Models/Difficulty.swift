import Foundation

/// A game's level. Each game turns it into its own knobs with `pick`.
nonisolated enum Difficulty: Int, Codable {
    case easy = 0, medium = 1, hard = 2

    init(jevScore: Double) {
        let clamped = min(max(jevScore, 0), 2)
        self = Difficulty(rawValue: Int(clamped.rounded())) ?? .medium
    }

    /// Today's difficulty for a game: the family's pin if set (#108), else the
    /// rules' level, medium for a new player. Games read it once when they open,
    /// so it never shifts under the player mid-game.
    static func stored(_ game: GameID, defaults: UserDefaults = .standard) -> Difficulty {
        FamilySettings.pinned(defaults: defaults)[game]
            ?? PlanStore.storedDifficulty(defaults: defaults)[game] ?? .medium
    }

    /// Picks the easy/medium/hard value of a per-game knob.
    func pick<T>(_ easy: T, _ medium: T, _ hard: T) -> T {
        switch self {
        case .easy: easy
        case .medium: medium
        case .hard: hard
        }
    }
}

extension Difficulty {
    /// The level's name, for the family screens.
    var title: String.LocalizationValue {
        switch self {
        case .easy: "difficulty.easy"
        case .medium: "difficulty.medium"
        case .hard: "difficulty.hard"
        }
    }
}
