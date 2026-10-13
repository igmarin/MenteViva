import SwiftUI

/// The Card Table palette (docs/design/2026-10-12-card-table.html), taken from
/// the app icon. Light and dark values live in one colour, built the same way
/// as `todaysPick`; ContrastTests checks every pairing that carries text.
extension Color {
    /// Icon teal: the app's tint and the fill of primary buttons, whose label
    /// uses the background colour (7.8:1 light, 11:1 dark).
    static let brand = Color(light: 0x1E5B57, dark: 0x7CCBBE)
    /// Icon amber: the one warm accent in each emblem, the played tick and the
    /// "Added to your week" stamp. Never used as text itself.
    static let amber = Color(light: 0xF2B24C, dark: 0xF0B45A)
    /// Text and ticks on amber: a dark brown, since amber is light in both modes.
    static let onAmber = Color(UIColor(rgb: 0x2A1A05))

    init(light: UInt32, dark: UInt32) {
        self.init(UIColor { $0.userInterfaceStyle == .dark ? UIColor(rgb: dark) : UIColor(rgb: light) })
    }
}

extension ShapeStyle where Self == LinearGradient {
    /// The icon's gradient, teal to amber: the table Home deals today's games on.
    static var table: LinearGradient {
        LinearGradient(
            colors: [
                Color(light: 0x2F7470, dark: 0x123F3C), Color(light: 0x8DAF98, dark: 0x2D4A3F),
                Color(light: 0xEDBB6C, dark: 0x6A5024),
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
        }
    }
}

extension EnvironmentValues {
    /// Opens a game in place of the one just finished (step 5's "Next" button).
    /// Home provides it; anywhere else it does nothing.
    @Entry var playNext: (GameID) -> Void = { _ in }
}
