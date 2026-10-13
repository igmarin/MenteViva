import SwiftUI
import XCTest

@testable import MenteViva

/// #118: "Today's pick" must be readable on its tile (WCAG AA: 4.5:1 for
/// text) in light and dark mode. Since the Card Table theme each tile is its
/// game's ink at 22% over the background, so every game is checked. Game inks
/// also tint text (back buttons), and primary buttons put the background
/// colour on a brand-teal fill.
final class ContrastTests: XCTestCase {
    private typealias RGB = (Double, Double, Double)
    private let styles: [UIUserInterfaceStyle] = [.light, .dark]

    private func rgb(_ color: UIColor, _ style: UIUserInterfaceStyle) -> RGB {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        color.resolvedColor(with: UITraitCollection(userInterfaceStyle: style)).getRed(&r, green: &g, blue: &b, alpha: &a)
        return (Double(r), Double(g), Double(b))
    }

    private func luminance(_ c: RGB) -> Double {
        func lin(_ v: Double) -> Double { v <= 0.03928 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4) }
        return 0.2126 * lin(c.0) + 0.7152 * lin(c.1) + 0.0722 * lin(c.2)
    }

    private func contrast(_ x: RGB, _ y: RGB) -> Double {
        let (l1, l2) = (luminance(x), luminance(y))
        return (max(l1, l2) + 0.05) / (min(l1, l2) + 0.05)
    }

    private func contrastOnTile(_ ink: Color, _ style: UIUserInterfaceStyle) -> Double {
        let text = rgb(UIColor(Color.todaysPick), style)
        let tint = rgb(UIColor(ink), style)
        let base = rgb(.systemBackground, style)
        let a = 0.22
        let tile = (tint.0 * a + base.0 * (1 - a), tint.1 * a + base.1 * (1 - a), tint.2 * a + base.2 * (1 - a))
        return contrast(text, tile)
    }

    func testGivenLightModeWhenTodaysPickOnEveryGameTileThenTextContrastIsAtLeastAA() {
        for game in GameID.allCases {
            XCTAssertGreaterThanOrEqual(contrastOnTile(game.ink, .light), 4.5, "\(game)")
        }
    }

    func testGivenDarkModeWhenTodaysPickOnEveryGameTileThenTextContrastIsAtLeastAA() {
        for game in GameID.allCases {
            XCTAssertGreaterThanOrEqual(contrastOnTile(game.ink, .dark), 4.5, "\(game)")
        }
    }

    func testGivenEveryGameInkWhenUsedAsTextThenContrastIsAtLeastAAInBothModes() {
        for style in styles {
            for game in GameID.allCases {
                let ratio = contrast(rgb(UIColor(game.ink), style), rgb(.systemBackground, style))
                XCTAssertGreaterThanOrEqual(ratio, 4.5, "\(game), style \(style.rawValue)")
            }
        }
    }

    func testGivenBrandButtonWhenLabelUsesTheBackgroundColorThenContrastIsAtLeastAAInBothModes() {
        for style in styles {
            let ratio = contrast(rgb(.systemBackground, style), rgb(UIColor(Color.brand), style))
            XCTAssertGreaterThanOrEqual(ratio, 4.5, "style \(style.rawValue)")
        }
    }
}
