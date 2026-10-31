import SwiftUI

extension View {
    /// Shows the screen as laid out when it fits, and scrolls it only when it
    /// doesn't (#117): at the largest text sizes an instruction must never be
    /// cut short. At everyday sizes nothing moves.
    func fitOrScroll() -> some View {
        ViewThatFits(in: .vertical) {
            self
            ScrollView { self }
        }
    }

    /// Keeps a game's controls in a readable centred column (#400). On a phone the
    /// column is as wide as the screen, in either orientation, so nothing moves; on an
    /// iPad the tiles stop stretching edge to edge. Apply it before the padding and
    /// `fitOrScroll()`.
    func gameColumn(maxWidth: CGFloat = GameColumn.maxWidth) -> some View {
        frame(maxWidth: GameColumn.isPad ? maxWidth : .infinity).frame(maxWidth: .infinity)
    }
}

/// The width and type-size rules behind `gameColumn`, as plain values so they can be tested (#400).
enum GameColumn {
    /// Widest a game's controls get, in points.
    static let maxWidth: CGFloat = 640

    /// The iPad rules apply on an iPad only. A Plus or Pro Max iPhone on its side also
    /// reports a regular width, and the phone layouts must not change.
    static var isPad: Bool { UIDevice.current.userInterfaceIdiom == .pad }

    /// Whether this screen gets the iPad layout: an iPad with a regular width (not a
    /// narrow Split View or Slide Over window).
    static func usesPadLayout(_ sizeClass: UserInterfaceSizeClass?) -> Bool {
        isPad && sizeClass == .regular
    }

    /// How much to enlarge a game's big word or sum: the iPad has the room and its
    /// reader sits further away; the phone keeps its size.
    static func textScale(isRegularWidth: Bool) -> CGFloat {
        isRegularWidth ? 1.3 : 1
    }
}
