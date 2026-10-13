import SwiftUI

/// The Card Table palette (docs/design/2026-10-12-card-table.html), taken from
/// the app icon. Light and dark values live in one colour, built the same way
/// as `todaysPick`; ContrastTests checks every pairing that carries text.
extension Color {
    /// Icon teal: the app's tint and the fill of primary buttons, whose label
    /// uses the background colour (7.8:1 light, 11:1 dark).
    static let brand = Color(light: 0x1E5B57, dark: 0x7CCBBE)

    init(light: UInt32, dark: UInt32) {
        self.init(UIColor { $0.userInterfaceStyle == .dark ? UIColor(rgb: dark) : UIColor(rgb: light) })
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
