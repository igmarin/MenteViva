import Foundation

/// One picture a game shows (#324): our illustration `pic.<slug>` once its art
/// batch ships, the emoji until then, and a name of its own in EN and ES, so
/// VoiceOver speaks the app's language rather than the phone's emoji names.
nonisolated struct GamePicture: Hashable {
    let slug: String
    let fallback: String

    var assetName: String { "pic.\(slug)" }
    var nameKey: String { "picture.\(slug)" }

    /// What a view should draw: decided here, with the asset lookup passed in,
    /// so a test can check the fallback without an asset catalogue.
    enum Look: Equatable {
        case asset(String)
        case emoji(String)
    }

    func look(hasAsset: (String) -> Bool) -> Look {
        hasAsset(assetName) ? .asset(assetName) : .emoji(fallback)
    }
}

/// Every game picture in one place, so a slug means the same thing in every
/// game and one image serves them all (the apple in Name the Herd, Quick Eyes
/// and Memory Lane is the same file).
nonisolated enum GamePictures {
    static let all: [GamePicture] = table.map { GamePicture(slug: $0.slug, fallback: $0.fallback) }

    /// Slug and emoji per picture, typed up front so the compiler never has to
    /// infer one long literal.
    private static let table: [(slug: String, fallback: String)] = [
        // Name the Herd: animals, fruits, vehicles
        ("dog", "🐶"), ("cat", "🐱"), ("lion", "🦁"), ("frog", "🐸"), ("turtle", "🐢"),
        ("butterfly", "🦋"), ("elephant", "🐘"),
        ("apple", "🍎"), ("banana", "🍌"), ("grapes", "🍇"), ("orange", "🍊"), ("strawberry", "🍓"),
        ("watermelon", "🍉"), ("peach", "🍑"),
        ("car", "🚗"), ("bus", "🚌"), ("airplane", "✈️"), ("rocket", "🚀"), ("bicycle", "🚲"),
        ("train", "🚂"), ("sailboat", "⛵️"),
        // Name the Herd: colors. Never drawn as art; the coloured circle is the picture.
        ("color.red", "🔴"), ("color.blue", "🔵"), ("color.green", "🟢"), ("color.yellow", "🟡"),
        ("color.orange", "🟠"), ("color.purple", "🟣"), ("color.brown", "🟤"),
        // Quick Eyes
        ("sunflower", "🌻"), ("guitar", "🎸"), ("moon", "🌙"), ("coffee", "☕️"), ("star", "⭐"),
        ("bee", "🐝"), ("cactus", "🌵"),
        // Remember Together (also Name the Herd: home) (its fallback is the object's SF Symbol, kept there)
        ("clock", "🕰️"), ("key", "🔑"), ("house", "🏠"), ("chair", "🪑"), ("umbrella", "☂️"),
        ("book", "📖"), ("lamp", "💡"),
        // Memory Lane: kitchen table (also Name the Herd: kitchen)
        ("teapot", "🫖"), ("bread", "🍞"), ("cheese", "🧀"), ("wine_glass", "🍷"), ("croissant", "🥐"),
        ("lemon", "🍋"), ("olives", "🫒"), ("honey", "🍯"), ("cake", "🍰"), ("chocolate", "🍫"),
        ("egg", "🥚"),
        // Memory Lane: the garden (also Name the Herd: plants)
        ("rose", "🌹"), ("tulip", "🌷"), ("potted_plant", "🪴"), ("pear", "🍐"), ("tree", "🌳"),
        ("pine", "🌲"), ("ladybug", "🐞"),
        // Memory Lane: travels (no lighthouse emoji exists; the island stands in)
        ("map", "🗺️"), ("suitcase", "🧳"), ("mountain", "⛰️"), ("beach", "🏖️"), ("tent", "🏕️"),
        ("lighthouse", "🏝️"), ("helicopter", "🚁"),
        // Memory Lane: music and home (picture_frame, telephone, sofa also Name the Herd: home)
        ("violin", "🎻"), ("trumpet", "🎺"), ("piano", "🎹"), ("radio", "📻"), ("yarn", "🧶"),
        ("accordion", "🪗"), ("picture_frame", "🖼️"), ("telephone", "📞"), ("sofa", "🛋️"),
    ]

    private static let bySlug = Dictionary(uniqueKeysWithValues: all.map { ($0.slug, $0) })

    /// The catalogue's picture for a slug. A typo is a programming error, caught
    /// by the first test that deals the game.
    static func named(_ slug: String) -> GamePicture {
        guard let picture = bySlug[slug] else { preconditionFailure("No game picture named \(slug)") }
        return picture
    }

    /// Several pictures at once, in the order given.
    static func named(_ slugs: [String]) -> [GamePicture] { slugs.map { named($0) } }
}
