import Foundation

/// The six inks Color Clash paints with. Each carries the word it can show,
/// the colour name it is read as, and a shape of its own, so colour never
/// carries the answer alone (WCAG 1.4.1, conventions.md §4).
///
/// Pure: it holds localization keys, never localized text (the same shape as
/// `PlayingCard.nameKey`), and the SwiftUI `Color` it paints with lives in
/// `ColorClashView`.
nonisolated enum Ink: String, CaseIterable {
    case red, blue, green, orange, purple, yellow

    /// Key of the word this ink can show; the word is the decoy, the ink is the answer.
    var wordKey: String { "game.colorclash.word.\(rawValue)" }

    /// Key of the colour's name: VoiceOver reads it, and it names the right answer.
    var labelKey: String { "game.colorclash.color.\(rawValue)" }

    /// The shape drawn beside the word, a cue that is not colour.
    var shape: String {
        switch self {
        case .red: "circle.fill"
        case .blue: "triangle.fill"
        case .green: "square.fill"
        case .orange: "diamond.fill"
        case .purple: "hexagon.fill"
        case .yellow: "star.fill"
        }
    }

    /// Key of the shape's name, read after the colour by VoiceOver.
    var shapeNameKey: String {
        switch self {
        case .red: "game.colorclash.shape.circle"
        case .blue: "game.colorclash.shape.triangle"
        case .green: "game.colorclash.shape.square"
        case .orange: "game.colorclash.shape.diamond"
        case .purple: "game.colorclash.shape.hexagon"
        case .yellow: "game.colorclash.shape.star"
        }
    }
}

/// Color Clash's deal (#244): the ink the word is painted in and the word
/// itself. Pure, with the generator passed in, so a test can seed a round; the
/// view keeps the grid, the answer beat and the celebration.
nonisolated enum ColorClashDeal {
    /// Matching chance per level: high at 1, 0 from 6 onward. Levels 2/4/6
    /// are 0.7/0.25/0 to match old easy/medium/hard.
    static let matchingChanceByLevel: [Double] = [0.85, 0.7, 0.45, 0.25, 0.1, 0, 0, 0, 0, 0]

    /// Chance the word already matches its ink.
    static func matchingChance(for difficulty: Difficulty) -> Double {
        difficulty.values(matchingChanceByLevel)
    }

    /// Available inks per level. More distinct colour+shape choices increase
    /// Stroop interference without shrinking targets or using colour alone,
    /// and reuses the existing shape cue infrastructure.
    static func availableInks(for difficulty: Difficulty) -> [Ink] {
        // Levels 1-8 show 4 options, 9-10 show 6 so difficulty rises via larger choice set.
        let count = difficulty.values([4, 4, 4, 4, 4, 4, 4, 4, 6, 6])
        return Array(Ink.allCases.prefix(count))
    }

    /// One stimulus: the ink the player taps, and the word shown in that ink.
    nonisolated struct Stimulus: Equatable {
        let ink: Ink
        let word: Ink
    }

    /// Deals one word: an ink from the level's pool, and a word that either
    /// matches it or is another ink from the same pool.
    static func make(difficulty: Difficulty, using generator: inout some RandomNumberGenerator) -> Stimulus {
        let pool = availableInks(for: difficulty)
        let ink = pool[Int.random(in: pool.indices, using: &generator)]
        let matches = Double.random(in: 0..<1, using: &generator) < matchingChance(for: difficulty)
        let word = matches ? ink : (pool.filter { $0 != ink }.randomElement(using: &generator) ?? .red)
        return Stimulus(ink: ink, word: word)
    }
}
