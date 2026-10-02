import XCTest
import SwiftUI
@testable import MenteViva

/// #118: "Today's pick" must be readable on its tile (WCAG AA: 4.5:1 for
/// text) in light and dark mode. The tile is blue at 22% over the background.
final class ContrastTests: XCTestCase {
    private func rgb(_ color: UIColor, _ style: UIUserInterfaceStyle) -> (Double, Double, Double, Double) {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.resolvedColor(with: UITraitCollection(userInterfaceStyle: style)).getRed(&r, green: &g, blue: &b, alpha: &a)
        return (Double(r), Double(g), Double(b), Double(a))
    }

    private func luminance(_ c: (Double, Double, Double)) -> Double {
        func lin(_ v: Double) -> Double { v <= 0.03928 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4) }
        return 0.2126 * lin(c.0) + 0.7152 * lin(c.1) + 0.0722 * lin(c.2)
    }

    private func contrastOnTile(_ style: UIUserInterfaceStyle) -> Double {
        let text = rgb(UIColor(Color.todaysPick), style)
        let blue = rgb(.systemBlue, style), base = rgb(.systemBackground, style)
        let a = 0.22
        let tile = (blue.0 * a + base.0 * (1 - a), blue.1 * a + base.1 * (1 - a), blue.2 * a + base.2 * (1 - a))
        let (l1, l2) = (luminance((text.0, text.1, text.2)), luminance(tile))
        return (max(l1, l2) + 0.05) / (min(l1, l2) + 0.05)
    }

    func testGivenLightModeWhenTodaysPickOnItsTileThenTextContrastIsAtLeastAA() {
        XCTAssertGreaterThanOrEqual(contrastOnTile(.light), 4.5)
    }

    func testGivenDarkModeWhenTodaysPickOnItsTileThenTextContrastIsAtLeastAA() {
        XCTAssertGreaterThanOrEqual(contrastOnTile(.dark), 4.5)
    }
}
