import Foundation

/// A familiar thing shown in Remember Together when no family photos are added
/// (#139): an SF Symbol (no image files, no licensing) and the key of its name.
struct EverydayObject: Equatable {
    let symbol: String
    let nameKey: String
}

enum EverydayObjects {
    static let all: [EverydayObject] = [
        EverydayObject(symbol: "cup.and.saucer", nameKey: "object.cup"),
        EverydayObject(symbol: "clock", nameKey: "object.clock"),
        EverydayObject(symbol: "key", nameKey: "object.key"),
        EverydayObject(symbol: "house", nameKey: "object.house"),
        EverydayObject(symbol: "chair", nameKey: "object.chair"),
        EverydayObject(symbol: "umbrella", nameKey: "object.umbrella"),
        EverydayObject(symbol: "book", nameKey: "object.book"),
        EverydayObject(symbol: "lamp.desk", nameKey: "object.lamp"),
    ]
}
