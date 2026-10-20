import Foundation

/// The 60 saying slots and their themes (#181). The words are in `Localizable.xcstrings`
/// (`saying.NN.start` / `.end`). Nothing about age, memory, illness or death.
enum Sayings {
    private static let themes: [(Saying.Theme, ClosedRange<Int>)] = [
        (.animals, 1...8), (.money, 9...15), (.time, 16...23), (.food, 24...31),
        (.work, 32...38), (.weather, 39...45), (.friends, 46...53), (.home, 54...60),
    ]

    static let all: [Saying] = themes.flatMap { theme, ids in ids.map { Saying(id: $0, theme: theme) } }
}
