import Foundation

/// The five games, by the stable IDs stored in sessions and sent (anonymized) to Jev.
nonisolated enum GameID: String, CaseIterable, Codable {
    case memoryMatch = "memory_match"
    case stroop = "stroop"
    case categoryFluency = "category_fluency"
    case mathStreaks = "math_streaks"
    case quickEyes = "quick_eyes"

    var emoji: String {
        switch self {
        case .memoryMatch: "🧩"
        case .stroop: "🎨"
        case .categoryFluency: "🐾"
        case .mathStreaks: "🔢"
        case .quickEyes: "👀"
        }
    }

    var title: String.LocalizationValue {
        switch self {
        case .memoryMatch: "game.memory.title"
        case .stroop: "game.colorclash.title"
        case .categoryFluency: "game.category.title"
        case .mathStreaks: "game.math.title"
        case .quickEyes: "game.quickeyes.title"
        }
    }
}
