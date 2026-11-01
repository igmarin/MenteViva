import SwiftUI
import XCTest

@testable import MenteViva

/// WCAG AA (4.5:1 for text) in light and dark mode for every text pairing the
/// Card Table theme adds, on `paper` (cream, or the dark surround). Game inks
/// carry text both ways: as text on the paper (back buttons), and under the
/// paper colour on each card's name band; contrast is symmetric, so one test
/// covers both. Primary buttons put the paper colour on a brand-jade fill. The
/// warm text that was the "Today's pick" badge (#118) now sits on Quick Eyes'
/// soft mustard note.
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
        let base = rgb(UIColor(Color.paper), style)
        return (
            tint.0 * alpha + base.0 * (1 - alpha), tint.1 * alpha + base.1 * (1 - alpha),
            tint.2 * alpha + base.2 * (1 - alpha)
        )
    }

    func testGivenEveryGameInkWhenUsedAsTextThenContrastIsAtLeastAAInBothModes() {
        for style in styles {
            for game in GameID.allCases {
                let ratio = contrast(rgb(UIColor(game.ink), style), rgb(UIColor(Color.paper), style))
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

    /// Retro tokens (#336): espresso outlines and tomato/blue labels sit on paper.
    func testGivenTheRetroTokensWhenUsedAsTextOrOutlinesOnPaperThenContrastIsAtLeastAAInBothModes() {
        for style in styles {
            let paper = rgb(UIColor(Color.paper), style)
            for (name, color) in [("espresso", Color.espresso), ("tomato", .tomato), ("fadedBlue", .fadedBlue)] {
                let ratio = contrast(rgb(UIColor(color), style), paper)
                XCTAssertGreaterThanOrEqual(ratio, 4.5, "\(name), style \(style.rawValue)")
            }
        }
    }

    func testGivenBrandButtonWhenLabelUsesPaperThenContrastIsAtLeastAAInBothModes() {
        for style in styles {
            let ratio = contrast(rgb(UIColor(Color.paper), style), rgb(UIColor(Color.brand), style))
            XCTAssertGreaterThanOrEqual(ratio, 4.5, "style \(style.rawValue)")
        }
    }

    /// Hint and secondary lines (#527): `.secondary` grey measured 3.3:1 on cream, so every
    /// line a player reads in a quieter voice uses `inkSoft`. It sits on the paper, and on a
    /// list row (white in light mode, the system's raised grey in dark).
    func testGivenInkSoftWhenUsedAsTextOnPaperOrAListRowThenContrastIsAtLeastAAInBothModes() {
        for style in styles {
            let ink = rgb(UIColor(Color.inkSoft), style)
            let surfaces = [
                ("paper", rgb(UIColor(Color.paper), style)),
                ("list row", rgb(.secondarySystemGroupedBackground, style)),
            ]
            for (name, surface) in surfaces {
                XCTAssertGreaterThanOrEqual(contrast(ink, surface), 4.5, "\(name), style \(style.rawValue)")
            }
        }
    }

    /// Pure white is not the list row in dark mode, but the light-mode row is exactly white.
    func testGivenInkSoftWhenUsedOnWhiteThenContrastIsAtLeastAA() {
        let ink = rgb(UIColor(Color.inkSoft), .light)
        XCTAssertGreaterThanOrEqual(contrast(ink, (1, 1, 1)), 4.5)
    }
}
