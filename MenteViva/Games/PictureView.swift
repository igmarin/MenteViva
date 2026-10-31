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
        // A colour is drawn, not pictured: the circle is the same on every phone, where an emoji
        // would borrow Apple's art (#418).
        if let swatch = picture.swatch {
            ColorSwatch(color: swatch, size: size)
        } else {
            pictureBody
        }
    }

    @ViewBuilder private var pictureBody: some View {
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
    /// more than 60% of the screen width, so a narrow phone keeps room around it. At accessibility
    /// text sizes it also stops at 120pt, its old size: the instruction takes many lines there, and a
    /// bigger picture pushes the "Got it" tile below the fold.
    static func flashTarget(ceiling: CGFloat, width: CGFloat, isAccessibilitySize: Bool) -> CGFloat {
        min(ceiling, width * 0.6, isAccessibilitySize ? 120 : .infinity)
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

extension GamePicture {
    /// The fill of a `color.*` picture, or nil for every other slug (#418). Name the Herd's Colors
    /// round shows these as plain circles; the VoiceOver name still comes from `nameKey`.
    var swatch: Color? {
        switch slug {
        case "color.red": Color(UIColor(rgb: 0xC8372D))
        case "color.blue": Color(UIColor(rgb: 0x2F62B5))
        case "color.green": Color(UIColor(rgb: 0x2E7D4F))
        case "color.yellow": Color(UIColor(rgb: 0xE7AC45))
        case "color.orange": Color(UIColor(rgb: 0xE07B2A))
        case "color.purple": Color(UIColor(rgb: 0x6B3FA0))
        case "color.brown": Color(UIColor(rgb: 0x7A4B2A))
        default: nil
        }
    }
}

/// A colour as a filled circle with a 3pt espresso outline and a 3pt paper ring, so the edge holds
/// on a tile in light and dark mode (yellow on cream would otherwise melt away). Drawn at 0.8 of
/// `size` to match the visual weight of the illustrations.
private struct ColorSwatch: View {
    let color: Color
    let size: CGFloat

    var body: some View {
        Circle()
            .fill(color)
            .overlay { Circle().strokeBorder(Color.espresso, lineWidth: 3) }
            .padding(3)
            .background(Color.paper, in: .circle)
            .frame(width: size * 0.8, height: size * 0.8)
            .frame(width: size, height: size)
    }
}
