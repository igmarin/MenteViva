import Foundation

/// How each Tile Pairs symbol looks: one of our illustrations (#411). Visual only, so the deal,
/// its levels and covering rules never learn about art, and the symbol enum stays pure logic.
///
/// The 18 were picked to differ in shape AND colour at 60pt, so two side by side on a 72-tile
/// board are never confused: the round red apple has no round orange neighbour (the orange is
/// a cut slice), only one wedge (cheese), one flower on a stem in yellow and one in red.
/// Every slug has a real `pic.<slug>` asset, so no tile can fall back to an emoji that differs
/// by iOS version and none is blank.
nonisolated extension TilePairsSymbol {
    var picture: GamePicture {
        switch self {
        case .circle: GamePictures.named("apple")
        case .square: GamePictures.named("cheese")
        case .triangle: GamePictures.named("mountain")
        case .diamond: GamePictures.named("grapes")
        case .star: GamePictures.named("sunflower")
        case .heart: GamePictures.named("rose")
        case .number1: GamePictures.named("bread")
        case .number2: GamePictures.named("teapot")
        case .number3: GamePictures.named("coffee")
        case .number4: GamePictures.named("elephant")
        case .number5: GamePictures.named("pear")
        case .number6: GamePictures.named("orange")
        case .number7: GamePictures.named("frog")
        case .number8: GamePictures.named("lighthouse")
        case .number9: GamePictures.named("chocolate")
        case .leaf: GamePictures.named("piano")
        case .sun: GamePictures.named("lamp")
        case .flower: GamePictures.named("bee")
        }
    }
}
