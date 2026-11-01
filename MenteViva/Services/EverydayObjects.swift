import Foundation

/// A familiar thing the deck can still show when it is dealt no photos (Photo Stories itself is only dealt
/// with photos, #513)
/// (#139): our picture once its art ships (#324), the SF Symbol until then,
/// and the key of the name the player tries to remember.
nonisolated struct EverydayObject: Equatable {
    let symbol: String
    let picture: GamePicture
    let nameKey: String

    init(symbol: String, picture slug: String, nameKey: String) {
        self.symbol = symbol
        self.picture = GamePictures.named(slug)
        self.nameKey = nameKey
    }
}

enum EverydayObjects {
    static let all: [EverydayObject] = [
        EverydayObject(symbol: "cup.and.saucer", picture: "coffee", nameKey: "object.cup"),
        EverydayObject(symbol: "clock", picture: "clock", nameKey: "object.clock"),
        EverydayObject(symbol: "key", picture: "key", nameKey: "object.key"),
        EverydayObject(symbol: "house", picture: "house", nameKey: "object.house"),
        EverydayObject(symbol: "chair", picture: "chair", nameKey: "object.chair"),
        EverydayObject(symbol: "umbrella", picture: "umbrella", nameKey: "object.umbrella"),
        EverydayObject(symbol: "book", picture: "book", nameKey: "object.book"),
        EverydayObject(symbol: "lamp.desk", picture: "lamp", nameKey: "object.lamp"),
    ]
}
