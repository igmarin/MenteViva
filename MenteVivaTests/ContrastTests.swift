import SwiftUI
import XCTest

@testable import MenteViva

/// WCAG AA (4.5:1 for text) in light and dark mode for every text pairing the
/// Card Table theme adds. Game inks carry text both ways: as text on the
/// background (back buttons), and under the background colour on each card's
/// name band; contrast is symmetric, so one test covers both. Primary buttons
/// put the background colour on a brand-teal fill. The warm text that was the
/// "Today's pick" badge (#118) now sits on Quick Eyes' soft amber note.
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

    /// `color` at `alpha` over the background, as SwiftUI draws `.opacity(alpha)`.
    private func wash(_ color: Color, _ alpha: Double, _ style: UIUserInterfaceStyle) -> RGB {
        let tint = rgb(UIColor(color), style)
        let base = rgb(.systemBackground, style)
        return (
            tint.0 * alpha + base.0 * (1 - alpha), tint.1 * alpha + base.1 * (1 - alpha),
            tint.2 * alpha + base.2 * (1 - alpha)
        )
    }

    func testGivenEveryGameInkWhenUsedAsTextThenContrastIsAtLeastAAInBothModes() {
        for style in styles {
            for game in GameID.allCases {
                let ratio = contrast(rgb(UIColor(game.ink), style), rgb(.systemBackground, style))
                XCTAssertGreaterThanOrEqual(ratio, 4.5, "\(game), style \(style.rawValue)")
            }
        }
    }

    /// Quick Eyes' "Almost" line (step 3): warm text on a soft amber note.
    func testGivenTheAlmostNoteWhenItsTextSitsOnSoftAmberThenContrastIsAtLeastAAInBothModes() {
        for style in styles {
            let ratio = contrast(rgb(UIColor(Color.todaysPick), style), wash(.amber, 0.24, style))
            XCTAssertGreaterThanOrEqual(ratio, 4.5, "style \(style.rawValue)")
        }
    }

    /// The "Added to your week" stamp and the played tick (step 5): dark text on amber.
    func testGivenTheAmberStampWhenItsTextIsOnAmberThenContrastIsAtLeastAAInBothModes() {
        for style in styles {
            let ratio = contrast(rgb(UIColor(Color.onAmber), style), rgb(UIColor(Color.amber), style))
            XCTAssertGreaterThanOrEqual(ratio, 4.5, "style \(style.rawValue)")
        }
    }

    func testGivenBrandButtonWhenLabelUsesTheBackgroundColorThenContrastIsAtLeastAAInBothModes() {
        for style in styles {
            let ratio = contrast(rgb(.systemBackground, style), rgb(UIColor(Color.brand), style))
            XCTAssertGreaterThanOrEqual(ratio, 4.5, "style \(style.rawValue)")
        }
    }
}
