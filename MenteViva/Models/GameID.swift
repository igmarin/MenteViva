import Foundation

/// The games, by the stable IDs stored in sessions.
nonisolated enum GameID: String, CaseIterable, Codable {
    case memoryMatch = "memory_match"
    case stroop = "stroop"
    case categoryFluency = "category_fluency"
    case mathStreaks = "math_streaks"
    case quickEyes = "quick_eyes"
    case reminiscence = "reminiscence"
    case sudoku = "sudoku"
    case upOrDown = "up_or_down"
    case sayings = "sayings"
    case repeatSequence = "repeat_sequence"
    case tangram = "tangram"
    case tilePairs = "tile_pairs"
    case slidingBlocks = "sliding_blocks"
    case photoCaptions = "photo_captions"

    /// Registered but not playable yet: kept out of the deal, Set up, progress and
    /// Home until the game's view ships. That ticket removes its ID here.
    static let unreleased: Set<GameID> = []

    /// The games a player can see, in `allCases` order.
    static var released: [GameID] { allCases.filter { !unreleased.contains($0) } }

    var emoji: String {
        switch self {
        case .memoryMatch: "🧩"
        case .stroop: "🎨"
        case .categoryFluency: "🐾"
        case .mathStreaks: "🔢"
        case .quickEyes: "👀"
        case .reminiscence: "📷"
        case .sudoku: "✏️"
        case .upOrDown: "🃏"
        case .sayings: "💬"
        case .repeatSequence: "🔁"
        case .tangram: "🔷"
        case .tilePairs: "🀄"
        case .slidingBlocks: "🧱"
        case .photoCaptions: "🖼️"
        }
    }

    /// The retro illustration Home and the celebration card show for this game
    /// instead of the emblem (#373). Nil keeps the emblem: four games have no picture
    /// that says what they are yet, and five show a drawn mini board of the game
    /// instead of an unrelated picture (#512, `Emblem.boards`).
    var heroPicture: GamePicture? { heroSlug.map { GamePictures.named($0) } }

    /// The slug behind `heroPicture`, kept apart so a test can check it is in the catalogue
    /// without calling `GamePictures.named`, which traps on a typo.
    var heroSlug: String? {
        switch self {
        case .memoryMatch: "teapot"
        case .photoCaptions: "picture_frame"
        case .categoryFluency: "dog"
        case .sayings: "book"
        case .repeatSequence: "piano"
        case .stroop, .sudoku, .upOrDown, .tilePairs: nil
        case .tangram, .slidingBlocks, .mathStreaks, .quickEyes, .reminiscence: nil
        }
    }

    var title: String.LocalizationValue {
        switch self {
        case .memoryMatch: "game.memory.title"
        case .stroop: "game.colorclash.title"
        case .categoryFluency: "game.category.title"
        case .mathStreaks: "game.math.title"
        case .quickEyes: "game.quickeyes.title"
        case .reminiscence: "game.reminiscence.title"
        case .sudoku: "game.sudoku.title"
        case .upOrDown: "game.upordown.title"
        case .sayings: "game.sayings.title"
        case .repeatSequence: "game.sequence.title"
        case .tangram: "game.tangram.title"
        case .tilePairs: "game.tilepairs.title"
        case .slidingBlocks: "game.sliding.title"
        case .photoCaptions: "game.photocaptions.title"
        }
    }

    /// Whether the game has easy/medium/hard. Remember Together has none: nothing in it
    /// can be answered wrongly, so there is no level to reach or pin (#139).
    var hasLevels: Bool { self != .reminiscence }
}
