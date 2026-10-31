import SwiftUI
import UIKit

/// Draws a game picture at a given size (#324): our illustration when the art
/// batch has shipped it, the emoji until then, so batches land one at a time
/// without touching the games. Callers set the VoiceOver label, because one
/// game (Remember Together) hides the name until it is revealed.
struct PictureView: View {
    let picture: GamePicture
    let size: CGFloat

    var body: some View {
        switch picture.look(hasAsset: Self.bundleHasAsset) {
        case .asset(let name):
            Image(name)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
        case .emoji(let emoji):
            Text(emoji)
                .font(.system(size: size))
        }
    }

    /// Whether the app ships an image of that name.
    nonisolated static func bundleHasAsset(_ name: String) -> Bool {
        UIImage(named: name) != nil
    }

    /// The flash target's size (#413): up to `ceiling` (240pt, scaled with Dynamic Type), but never
    /// more than 60% of the screen width, so a narrow phone keeps room around it.
    static func flashTarget(ceiling: CGFloat, width: CGFloat) -> CGFloat {
        min(ceiling, width * 0.6)
    }

    /// The narrowest grid column that gives a picture its margin (#413). It never drops under the
    /// 100pt tile floor, and it widens with the picture so larger text means fewer, bigger tiles
    /// instead of a picture spilling past its tile.
    static func columnMinimum(picture: CGFloat, margin: CGFloat) -> CGFloat {
        max(100, picture + 2 * margin)
    }

    /// A picture's size once it must fit a tile `columnWidth` wide (#413): the wanted size, or the
    /// widest the margins and the tile's 3pt border leave. Dynamic Type grows the picture only as
    /// far as its tile can hold it.
    static func fitted(_ size: CGFloat, columnWidth: CGFloat, margin: CGFloat) -> CGFloat {
        min(size, max(0, columnWidth - 2 * margin - 6))
    }
}
