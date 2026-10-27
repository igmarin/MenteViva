import Foundation

/// A game's level from 1 to 10 (#197). Each game turns it into its own knobs
/// with `values(_:)`; there are no easy/medium/hard names left (#209). Codable
/// as a single Int so plans and summaries keep their shape.
nonisolated struct Difficulty: Codable, Hashable, Comparable {
    /// Valid levels; everything else clamps into range on creation.
    static let range = 1...10

    var level: Int

    /// Any Int becomes a level: below 1 reads as 1, above 10 as 10.
    init(level: Int) {
        self.level = min(10, max(1, level))
    }

    init(from decoder: Decoder) throws {
        self.init(level: try decoder.singleValueContainer().decode(Int.self))
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(level)
    }

    static func < (lhs: Difficulty, rhs: Difficulty) -> Bool {
        lhs.level < rhs.level
    }

    /// Today's difficulty for a game: the family's pin if set (#108), else the
    /// rules' level, level 4 for a new player. Games read it once when they open,
    /// so it never shifts under the player mid-game.
    static func stored(_ game: GameID, defaults: UserDefaults = .standard) -> Difficulty {
        FamilySettings.pinned(defaults: defaults)[game]
            ?? PlanStore.storedDifficulty(defaults: defaults)[game] ?? Difficulty(level: 4)
    }

    /// The per-game value for this level from a ten-row table, one row per
    /// level 1...10 in order. Every per-game levels ticket builds on this.
    func values<T>(_ table: [T]) -> T {
        precondition(table.count == 10, "values(_:) needs one row per level 1...10")
        return table[level - 1]
    }
}

extension Difficulty {
    /// The level's name for the family screens: "Level 4" / "Nivel 4".
    var title: String.LocalizationValue {
        "Level \(level)"
    }
}
