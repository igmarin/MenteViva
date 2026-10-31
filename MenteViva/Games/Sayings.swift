import Foundation

/// The 120 saying slots and their themes (#181). The words are in `Localizable.xcstrings`
/// (`saying.NN.start` / `.end`). Nothing about age, memory, illness or death.
/// 61-120 are the second pack (#414): 15 games of 8 before any saying comes back.
enum Sayings {
    private static let themes: [(Saying.Theme, ClosedRange<Int>)] = [
        (.animals, 1...8), (.money, 9...15), (.time, 16...23), (.food, 24...31),
        (.work, 32...38), (.weather, 39...45), (.friends, 46...53), (.home, 54...60),
        (.animals, 61...67), (.money, 68...75), (.time, 76...82), (.food, 83...89),
        (.work, 90...97), (.weather, 98...105), (.friends, 106...112), (.home, 113...120),
    ]

    static let all: [Saying] = themes.flatMap { theme, ids in ids.map { Saying(id: $0, theme: theme) } }
}
