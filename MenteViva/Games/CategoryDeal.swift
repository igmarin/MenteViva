import Foundation

/// Name the Herd's deal (#244): the categories, the items that belong and the
/// decoys that don't. Pure, with the generator passed in, so a test can seed a
/// whole session; the view keeps the grid, the completion beat and the taps.
nonisolated enum CategoryDeal {
    /// The categories a round can ask for. Every item belongs to exactly one
    /// category, so a decoy drawn from another category can never be right.
    nonisolated enum Category: CaseIterable, Hashable {
        case animals, fruits, colors, vehicles, plants, home, kitchen

        /// The category's name as shown and announced.
        var nameKey: String {
            switch self {
            case .animals: "game.category.animals"
            case .fruits: "game.category.fruits"
            case .colors: "game.category.colors"
            case .vehicles: "game.category.vehicles"
            case .plants: "game.category.plants"
            case .home: "game.category.home"
            case .kitchen: "game.category.kitchen"
            }
        }

        /// Categories whose pictures never appear as this category's decoys,
        /// because they overlap in a player's mind (cheese is food as much as a
        /// kitchen thing; a plant bears the fruit). Same-name pictures are
        /// handled apart, by `sameName`.
        /// Symmetric on purpose: if A excludes B, B excludes A.
        var noDecoysFrom: Set<Category> {
            switch self {
            case .kitchen: [.fruits, .home]
            case .home: [.kitchen, .plants]
            case .plants: [.fruits, .home]
            case .fruits: [.kitchen, .plants]
            case .animals, .colors, .vehicles: []
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
            case .plants:
                GamePictures.named(["rose", "tulip", "sunflower", "potted_plant", "tree", "pine", "cactus"])
            case .home:
                GamePictures.named(["clock", "key", "chair", "lamp", "sofa", "telephone", "picture_frame"])
            case .kitchen:
                GamePictures.named(["teapot", "bread", "cheese", "croissant", "honey", "cake", "egg"])
            }
        }
    }

    /// What one tap on a tile does (#415). Pure, so "a tried decoy counts once" is tested, not trusted.
    nonisolated enum TapOutcome: Equatable {
        /// A fresh item of the category: it is picked.
        case found
        /// A fresh decoy: one attempt, a soft cue, and the tile is marked tried.
        case miss
        /// A tile already picked or already tried: nothing happens, no attempt, no sound.
        case ignored
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

    /// Categories per session. Seven exist, so a session sees three of them and the next one likely differs.
    static let roundsPerSession = 3

    /// Decoys per level: one more each step so progress is felt, but never
    /// mid-game. Levels 2/4/6 are 3/5/7 to match the old easy/medium/hard so
    /// migrated players see no change; the board-fit cap keeps every row above the fold.
    static let decoysByLevel: [Int] = [2, 3, 4, 5, 6, 7, 8, 9, 10, 11]
    /// Pictures that share a name with an item of another category; never dealt as that category's decoy.
    /// Keyed by `GamePicture.slug`. Without it a fair tap on "Orange" would count as a miss (#371).
    static let sameName: [Category: Set<String>] = [.colors: ["orange"], .fruits: ["color.orange"]]
    /// Smallest tile that stays tappable (conventions §4).
    static let tileMin: Double = 100
    static let tileGap: Double = 16
    /// Items a player has to find in every category; the rest of the board is decoys.
    static let itemsPerCategory = 7

    /// The pictures that may be a decoy when `category` is asked: every other
    /// category except the ones it overlaps with, minus same-name pictures.
    static func decoyPool(for category: Category) -> [GamePicture] {
        let excluded = category.noDecoysFrom.union([category])
        return Category.allCases.filter { !excluded.contains($0) }
            .flatMap(\.items)
            .filter { !(sameName[category] ?? []).contains($0.slug) }
    }

    /// The smallest decoy pool of any category, so a level's decoy count is
    /// one number that every category can honour.
    static var smallestPoolSize: Int {
        Category.allCases.map { decoyPool(for: $0).count }.min() ?? 0
    }

    /// Decoys for a level, capped to the smallest pool of any category.
    static func decoyCount(for difficulty: Difficulty) -> Int {
        decoyCount(for: difficulty, poolSize: smallestPoolSize)
    }

    /// Decoys for a level, capped to the given pool size.
    static func decoyCount(for difficulty: Difficulty, poolSize: Int) -> Int {
        min(difficulty.values(decoysByLevel), poolSize)
    }

    /// What a tap does: a picked item or a tried decoy is never counted again.
    static func tapOutcome(belongs: Bool, isPicked: Bool, isTried: Bool) -> TapOutcome {
        guard !isPicked, !isTried else { return .ignored }
        return belongs ? .found : .miss
    }

    /// Decoys capped to both the pool and the measured board (#415), so every row stays above the
    /// fold. `size` is the space under the header, not the screen: a tall phone and an SE differ by
    /// rows as much as by columns. `tile` is the column minimum (it grows with the text size) and
    /// never drops under 100pt. A board that holds fewer tiles than the seven items gets no decoys:
    /// the screen scrolls then, which beats hiding an item.
    static func fittedDecoyCount(for difficulty: Difficulty, size: CGSize, tile: Double = tileMin) -> Int {
        fittedDecoyCount(for: difficulty, size: size, poolSize: smallestPoolSize, tile: tile)
    }

    /// As above, for a pool of the given size (a round's real decoy pool).
    static func fittedDecoyCount(
        for difficulty: Difficulty, size: CGSize, poolSize: Int, tile: Double = tileMin
    ) -> Int {
        let side = max(tile, tileMin)
        guard size.width >= side, size.height >= side else { return 0 }
        let columns = Int((Double(size.width) + tileGap) / (side + tileGap))
        let rows = Int((Double(size.height) + tileGap) / (side + tileGap))
        let room = max(0, columns * rows - itemsPerCategory)
        return min(decoyCount(for: difficulty, poolSize: poolSize), room)
    }

    /// Whether the screen should deal now (#415): at once if nothing is dealt, never once a tile has
    /// been tapped (a game in play stays), and otherwise only when the board changes how many decoys fit.
    static func shouldDeal(hasSession: Bool, picks: Int, dealt: Int?, fitted: Int) -> Bool {
        guard hasSession else { return true }
        return picks == 0 && dealt != fitted
    }

    /// Deals a whole session: `roundsPerSession` different categories, each
    /// with its items and its decoys shuffled onto one board. `categories` keeps a session's
    /// categories when it is dealt again for a new fit, so only the boards change (#415).
    static func deal(
        difficulty: Difficulty, size: CGSize, tile: Double = tileMin, categories: [Category]? = nil,
        using generator: inout some RandomNumberGenerator
    ) -> [Round] {
        let chosen = categories ?? Array(Category.allCases.shuffled(using: &generator).prefix(roundsPerSession))
        return chosen.map { category in
            // Decoys come from the other categories only, minus the ones this
            // category overlaps with, so the board never asks for something
            // that does not belong, nor shows two tiles with the same name.
            let pool = decoyPool(for: category)
            let decoys = fittedDecoyCount(for: difficulty, size: size, poolSize: pool.count, tile: tile)
            let from = pool.shuffled(using: &generator).prefix(decoys)
            let tiles =
                category.items.map { Tile(picture: $0, belongs: true) }
                + from.map { Tile(picture: $0, belongs: false) }
            return Round(category: category, tiles: tiles.shuffled(using: &generator))
        }
    }
}
