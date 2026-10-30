import Foundation

/// Names and Faces' deal (#142): which captioned photos make the board, and how its
/// photo and caption cards lie. Pure, with the generator passed in, so a test can seed a
/// whole game; Memory Lane's view keeps the layout, the taps and the animation.
nonisolated enum PhotoCaptionDeal {
    /// The fewest pairs a board has; fewer captioned photos and the game is not offered.
    static let minPairs = 4

    /// Pairs per level 1...10: four at the start, up to eight, the largest board; the album holds
    /// more (`MemoryPhotos.maxCount`), and `make` picks among them.
    static let pairsPerLevel = [4, 4, 5, 5, 6, 6, 7, 7, 8, 8]

    static func pairCount(for difficulty: Difficulty) -> Int {
        difficulty.values(pairsPerLevel)
    }

    /// The photos a board can use: two photos with the same name would make a match
    /// ambiguous, so only the first of each caption (ignoring case and spacing) stays.
    static func eligible(_ captioned: [(photo: URL, caption: String)]) -> [(photo: URL, caption: String)] {
        var seen = Set<String>()
        return captioned.filter { seen.insert(key($0.caption)).inserted }
    }

    private static func key(_ caption: String) -> String {
        caption.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    /// One board: `cards` lie in order, a photo and a caption per pair; `pairIDs` says which cards
    /// belong together, index-aligned with `cards`.
    nonisolated struct Board: Equatable {
        let cards: [MemoryFace]
        let pairIDs: [Int]
    }

    /// Deals up to `pairs` pairs from the eligible captioned photos, chosen and shuffled with the
    /// generator. Ask `GameAvailability` first: fewer than `minPairs` eligible photos is not a game.
    static func make(
        captioned: [(photo: URL, caption: String)], pairs: Int, using generator: inout some RandomNumberGenerator
    ) -> Board {
        let chosen = eligible(captioned).shuffled(using: &generator).prefix(pairs)
        let cards = chosen.enumerated().flatMap { id, item in
            [(MemoryFace.photo(item.photo), id), (MemoryFace.caption(item.caption), id)]
        }.shuffled(using: &generator)
        return Board(cards: cards.map(\.0), pairIDs: cards.map(\.1))
    }
}
