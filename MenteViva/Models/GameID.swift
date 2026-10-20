import Foundation

/// The games, by the stable IDs stored in sessions and sent (anonymized) to Jev.
nonisolated enum GameID: String, CaseIterable, Codable {
    case memoryMatch = "memory_match"
    case stroop = "stroop"
    case categoryFluency = "category_fluency"
    case mathStreaks = "math_streaks"
    case quickEyes = "quick_eyes"
    case reminiscence = "reminiscence"
    case sudoku = "sudoku"

    var emoji: String {
        switch self {
        case .memoryMatch: "🧩"
        case .stroop: "🎨"
        case .categoryFluency: "🐾"
        case .mathStreaks: "🔢"
        case .quickEyes: "👀"
        case .reminiscence: "📷"
        case .sudoku: "✏️"
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
        }
    }

    /// Whether the game has easy/medium/hard. Remember Together has none: nothing in it
    /// can be answered wrongly, so there is no level to reach or pin (#139).
    var hasLevels: Bool { self != .reminiscence }
}
