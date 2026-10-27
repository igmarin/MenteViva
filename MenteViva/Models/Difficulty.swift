import Foundation

/// A game's level from 1 to 10 (#197). Each game turns it into its own knobs
/// with `values(_:)`; `pick(_:_:_:)` is the temporary bridge that keeps games
/// on easy/medium/hard until their own levels ticket lands. Codable as a
/// single Int so plans and summaries keep their shape.
nonisolated struct Difficulty: Codable, Hashable, Comparable {
    /// Valid levels; everything else clamps into range on creation.
    static let range = 1...10

    /// Temporary bridges so games compare levels exactly as they compared
    /// easy/medium/hard: 2/4/6, the migrated values. The per-game levels
    /// tickets remove each use; only `pick` below is formally deprecated, to
    /// keep these call sites warning-free until then.
    static let easy = Difficulty(level: 2)
    static let medium = Difficulty(level: 4)
    static let hard = Difficulty(level: 6)

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

    /// Temporary bridge until every game has ten steps (levels epic): levels
    /// 1–3 read as easy, 4–5 as medium, 6–10 as hard, so every game behaves
    /// exactly as it did until its own ticket lands.
    @available(*, deprecated, message: "Use values(_:) — levels epic")
    func pick<T>(_ easy: T, _ medium: T, _ hard: T) -> T {
        switch level {
        case 1...3: easy
        case 4...5: medium
        default: hard
        }
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
