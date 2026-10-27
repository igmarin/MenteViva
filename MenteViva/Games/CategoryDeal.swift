import Foundation

/// Name the Herd's deal (#244): the categories, the items that belong and the
/// decoys that don't. Pure, with the generator passed in, so a test can seed a
/// whole session; the view keeps the grid, the completion beat and the taps.
nonisolated enum CategoryDeal {
    /// The categories a round can ask for. Every item belongs to exactly one
    /// category, so a decoy drawn from another category can never be right.
    nonisolated enum Category: CaseIterable, Hashable {
        case animals, fruits, colors, vehicles

        /// The category's name as shown and announced.
        var nameKey: String {
            switch self {
            case .animals: "game.category.animals"
            case .fruits: "game.category.fruits"
            case .colors: "game.category.colors"
            case .vehicles: "game.category.vehicles"
            }
        }

        /// The seven items a player has to find.
        var items: [GamePicture] {
            switch self {
            case .animals: GamePictures.named(["dog", "cat", "lion", "frog", "turtle", "butterfly", "elephant"])
            case .fruits:
                GamePictures.named(["apple", "banana", "grapes", "orange", "strawberry", "watermelon", "peach"])
            case .colors:
                GamePictures.named([
                    "color.red", "color.blue", "color.green", "color.yellow", "color.orange", "color.purple",
                    "color.brown",
                ])
            case .vehicles:
                GamePictures.named(["car", "bus", "airplane", "rocket", "bicycle", "train", "sailboat"])
            }
        }
    }

    /// One tile on the board: a picture and whether it belongs to the category.
    nonisolated struct Tile: Equatable {
        let picture: GamePicture
        let belongs: Bool
    }

    /// One round: the category to find and its shuffled board.
    nonisolated struct Round: Equatable {
        let category: Category
        let tiles: [Tile]
    }

    /// Categories per session. Four exist, so every session misses one.
    static let roundsPerSession = 3

    /// Decoys per level: one more each step so progress is felt, but never
    /// mid-game. Levels 2/4/6 are 3/5/7 to match the old easy/medium/hard so
    /// migrated players see no change; the fit cap keeps 100pt targets on SE.
    static let decoysByLevel: [Int] = [2, 3, 4, 5, 6, 7, 8, 9, 10, 11]
    /// Smallest tile that stays tappable (conventions §4).
    static let tileMin: Double = 100
    static let tileGap: Double = 16
    static let horizontalPadding: Double = 32

    /// Decoys for a level, capped to the available pool.
    static func decoyCount(for difficulty: Difficulty) -> Int {
        min(difficulty.values(decoysByLevel), 21)
    }

    /// Test helper with injectable pool size.
    static func decoyCount(for difficulty: Difficulty, poolSize: Int) -> Int {
        min(difficulty.values(decoysByLevel), poolSize)
    }

    /// Decoys capped to both the pool and the width so every tile keeps
    /// 100pt. Width is the full screen width; padding and gaps are removed
    /// before measuring.
    static func fittedDecoyCount(for difficulty: Difficulty, width: Double) -> Int {
        fittedDecoyCount(for: difficulty, width: width, poolSize: 21)
    }

    /// Test helper with injectable pool size.
    static func fittedDecoyCount(for difficulty: Difficulty, width: Double, poolSize: Int) -> Int {
        let poolCapped = decoyCount(for: difficulty, poolSize: poolSize)
        let gridWidth = max(0, width - horizontalPadding)
        // Columns that keep a tile >= 100pt.
        let maxColumns = max(1, Int((gridWidth + tileGap) / (tileMin + tileGap)))
        // If even a single column doesn't fit, no decoy can rescue it.
        guard gridWidth >= tileMin else { return 0 }
        // When the board needs more columns than fit, the tile would shrink
        // below 100pt. Cap decoys so total tiles don't force that.
        // Approximation: total tiles displayed in maxColumns columns.
        let maxTotalTiles = maxColumns * 6  // enough rows before scrolling, keeps 100pt
        let maxDecoysForWidth = max(0, maxTotalTiles - 7)
        return min(poolCapped, maxDecoysForWidth)
    }

    /// Deals a whole session: `roundsPerSession` different categories, each
    /// with its items and its decoys shuffled onto one board.
    static func deal(difficulty: Difficulty, width: Double, using generator: inout some RandomNumberGenerator) -> [Round] {
        let decoys = fittedDecoyCount(for: difficulty, width: width)
        return Category.allCases.shuffled(using: &generator).prefix(roundsPerSession).map { category in
            // Decoys come from the other categories only, so the board never
            // asks for something that does not belong.
            let from = Category.allCases.filter { $0 != category }
                .flatMap(\.items).shuffled(using: &generator).prefix(decoys)
            let tiles =
                category.items.map { Tile(picture: $0, belongs: true) }
                + from.map { Tile(picture: $0, belongs: false) }
            return Round(category: category, tiles: tiles.shuffled(using: &generator))
        }
    }
}
