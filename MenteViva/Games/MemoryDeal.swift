import Foundation

/// One face on a Memory Lane card: a family photo, or one of the theme's pictures.
/// Top-level and `nonisolated` because default actor isolation is MainActor
/// (Xcode 27), and a test drives the deal from outside the main actor.
nonisolated enum MemoryFace: Hashable {
    case picture(GamePicture)
    case photo(URL)
    /// A photo's caption, on its own card (#142).
    case caption(String)
}

/// Memory Lane's deal (#244): the theme, the pairs the board shows and the
/// order the cards lie in. Pure, with the generator passed in, so a test can
/// seed a whole game; the view keeps the layout, the taps and the animation.
nonisolated struct MemoryDeal: Equatable {
    /// Four grown-up sets of 12 pairs (#199 needs 12 faces at level 10). One is
    /// drawn per game. No two pictures in a theme share a silhouette (#324:
    /// honey and egg replace tea and the baguette, the accordion the guitar).
    static let themes: [[GamePicture]] = [
        // kitchen table
        GamePictures.named([
            "coffee", "teapot", "bread", "cheese", "wine_glass", "croissant", "lemon", "olives", "honey", "egg",
            "cake", "chocolate",
        ]),
        // the garden
        GamePictures.named([
            "rose", "sunflower", "tulip", "potted_plant", "pear", "tree", "butterfly", "bee", "apple", "pine",
            "ladybug", "grapes",
        ]),
        // travels
        GamePictures.named([
            "sailboat", "train", "airplane", "map", "suitcase", "mountain", "beach", "bicycle", "car", "tent",
            "lighthouse", "helicopter",
        ]),
        // music and home
        GamePictures.named([
            "violin", "trumpet", "piano", "radio", "clock", "book", "yarn", "chair", "accordion", "picture_frame",
            "telephone", "sofa",
        ]),
    ]

    /// The pairs the board shows, one face each.
    let faces: [MemoryFace]
    /// Which card lies where: an index into `faces` per card, each used twice,
    /// so a face always lies on exactly two cards.
    let order: [Int]

    /// The board's pairs: photos first, then the theme's pictures for any pairs
    /// the photos don't cover. The caller decides the photos' order.
    static func faces(photos: [URL], theme: [GamePicture], pairs: Int) -> [MemoryFace] {
        let fromPhotos = photos.prefix(pairs).map(MemoryFace.photo)
        return fromPhotos + theme.prefix(pairs - fromPhotos.count).map(MemoryFace.picture)
    }

    /// Deals one board: a theme drawn with the generator, the pairs it shows,
    /// and the shuffled order the cards lie in.
    static func make(photos: [URL], pairs: Int, using generator: inout some RandomNumberGenerator) -> MemoryDeal {
        let theme = themes[Int.random(in: themes.indices, using: &generator)]
        let faces = faces(photos: photos.shuffled(using: &generator), theme: theme, pairs: pairs)
        let order = (0..<(faces.count * 2)).map { $0 / 2 }.shuffled(using: &generator)
        return MemoryDeal(faces: faces, order: order)
    }
}
