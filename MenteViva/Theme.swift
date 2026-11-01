import SwiftUI

/// The Card Table palette (docs/design/2026-10-12-card-table.html) in the approved
/// retro colours (docs/design/art-style.md, "App tokens"). Light and dark values
/// live in one colour, built the same way as `todaysPick`; ContrastTests checks
/// every pairing that carries text.
extension Color {
    /// The page and every card's face: cream in light mode, the dark surround in
    /// dark mode. Replaces `systemBackground`, so text on it is checked here.
    static let paper = Color(light: 0xFFF1D0, dark: 0x211E1B)
    /// Outlines and the hard print shadow: espresso on cream, cream on the dark
    /// surround, so a card's edge shows in both modes.
    static let espresso = Color(light: 0x2B2118, dark: 0xFFF1D0)
    /// Muted jade: the app's tint and the fill of primary buttons, whose label
    /// uses `paper` (6.2:1 light, 8.1:1 dark).
    static let brand = Color(light: 0x246456, dark: 0x78C4AE)
    /// Honey mustard: the one warm accent in each emblem, the played tick and the
    /// "Added to your week" stamp. A fill only, never text on paper (1.8:1).
    static let amber = Color(light: 0xE7AC45, dark: 0xE7AC45)
    /// Text and ticks on mustard: espresso in both modes (7.8:1).
    static let onAmber = Color(UIColor(rgb: 0x2B2118))
    /// Dark tomato: warm emphasis text (5.2:1 on cream, 7.5:1 on the dark surround).
    static let tomato = Color(light: 0xAF3F32, dark: 0xF5A290)
    /// Faded blue: the label of secondary actions (6.9:1 on cream).
    static let fadedBlue = Color(light: 0x35566D, dark: 0x9DBBD3)

    /// Hints, helper lines and list headers: the quiet voice that still has to be read. Replaces
    /// `.secondary`, which blends to 3.3:1 on cream (#527). 6.7:1 on cream, 7.6:1 on white,
    /// 8.8:1 on the dark surround.
    static let inkSoft = Color(light: 0x5E5248, dark: 0xC9BC9F)

    init(light: UInt32, dark: UInt32) {
        self.init(UIColor { $0.userInterfaceStyle == .dark ? UIColor(rgb: dark) : UIColor(rgb: light) })
    }
}

extension View {
    /// The page behind a top-level screen (#356): `paper` under the content and
    /// in its navigation bar, so no screen falls back to the system white in
    /// light mode or black in dark mode. The colour follows the device
    /// appearance on its own; there is no in-app appearance switch.
    func pageBackground() -> some View {
        scrollContentBackground(.hidden)
            .background(Color.paper.ignoresSafeArea())
            .toolbarBackground(Color.paper, for: .navigationBar)
    }

    /// `pageBackground` for a `List` (#356): the system grouped background is
    /// hidden so `paper` shows, while rows keep their native surface and stay
    /// one step up from the page in both modes.
    func listPageBackground() -> some View {
        pageBackground()
    }
}

extension ShapeStyle where Self == LinearGradient {
    /// The icon's gradient, jade to mustard: the table Home deals today's games on.
    static var table: LinearGradient {
        LinearGradient(
            colors: [
                Color(light: 0x246456, dark: 0x123F3C), Color(light: 0x7FA58F, dark: 0x2D4A3F),
                Color(light: 0xE7AC45, dark: 0x6A5024),
            ],
            startPoint: .bottomLeading, endPoint: .topTrailing)
    }
}

extension UIColor {
    convenience init(rgb: UInt32) {
        self.init(
            red: CGFloat(rgb >> 16 & 0xFF) / 255, green: CGFloat(rgb >> 8 & 0xFF) / 255,
            blue: CGFloat(rgb & 0xFF) / 255, alpha: 1)
    }
}

extension GameID {
    /// Each game's own colour. Its tiles are tinted with it, and it reads as
    /// text on the background in both modes (at least 5.3:1).
    var ink: Color {
        switch self {
        case .memoryMatch: Color(light: 0x23685F, dark: 0x7CCBBE)
        case .stroop: Color(light: 0xB9442A, dark: 0xF29A80)
        case .categoryFluency: Color(light: 0x56702A, dark: 0xB4CF7E)
        case .mathStreaks: Color(light: 0x37488A, dark: 0xA9B6F2)
        case .quickEyes: Color(light: 0x93601A, dark: 0xEDBE6E)
        case .reminiscence: Color(light: 0x8C3B5A, dark: 0xEBA0BD)
        case .sudoku: Color(light: 0x1F5F7A, dark: 0x86C5DE)
        case .upOrDown: Color(light: 0x6B4F2A, dark: 0xD2B48C)
        case .sayings: Color(light: 0x5B3F8C, dark: 0xC3A8F0)
        case .repeatSequence: Color(light: 0x0F6B3C, dark: 0x6FD39A)
        case .tangram: Color(light: 0xA3246B, dark: 0xF08CC2)
        case .tilePairs: Color(light: 0x4B5563, dark: 0xB8C0CC)
        case .slidingBlocks: Color(light: 0xA14A0E, dark: 0xF2A56B)
        case .photoCaptions: Color(light: 0x6D5A0B, dark: 0xE0CB6A)
        }
    }
}

/// The games opened from Home (step 5): "Next" swaps the finished game for the
/// next one. Shared as an object rather than a closure, so SwiftUI compares it
/// by identity and its readers never redraw just because Home did.
@Observable final class GamePath {
    var games: [GameID] = []
}
