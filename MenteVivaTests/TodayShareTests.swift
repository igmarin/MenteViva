import XCTest

@testable import MenteViva

/// #381: the message the player can send after today's games is warm, short and number-free.
final class TodayShareTests: XCTestCase {
    private let games: [GameID] = [.memoryMatch, .sudoku, .sayings]
    /// Friday 30 October 2026, midday, so no time zone moves it to another day.
    private let date = Date(timeIntervalSince1970: 1_793_361_600)

    private func text(language: String) -> String {
        let name = "TodayShareTests.\(language)"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        AppLanguage.apply(language, to: defaults)
        return TodayShare.text(
            games: games, date: date, locale: Locale(identifier: language),
            localize: { AppLanguage.localized($0, defaults: defaults) })
    }

    func testGivenThreeFinishedGamesWhenBuildingShareTextThenEachGameHasOneLineWithCheck() {
        let lines = text(language: "en").components(separatedBy: "\n")
        XCTAssertEqual(lines.count, 5, "title, three games, footer")
        XCTAssertTrue(lines[0].hasPrefix("MenteViva · "))
        XCTAssertEqual(lines[1], "🧩 Memory Lane ✓")
        XCTAssertEqual(lines[2], "✏️ Sudoku ✓")
        XCTAssertEqual(lines[3], "💬 Finish the Saying ✓")
        XCTAssertEqual(lines[4], "Today's games, done.")
    }

    func testGivenSpanishWhenBuildingShareTextThenTitleAndFooterAreSpanish() {
        let lines = text(language: "es").components(separatedBy: "\n")
        XCTAssertTrue(lines[0].hasPrefix("MenteViva · "))
        XCTAssertTrue(lines[0].contains("octubre"), "the date is in Spanish too")
        XCTAssertEqual(lines.last, "Los juegos de hoy, listos.")
    }

    func testGivenTheShareTextWhenReadThenOnlyTheDateHasANumber() {
        for language in ["en", "es"] {
            let lines = text(language: language).components(separatedBy: "\n")
            XCTAssertTrue(lines[0].contains("30"), "\(language): the date is on line 1")
            let rest = lines.dropFirst().joined()
            XCTAssertNil(rest.rangeOfCharacter(from: .decimalDigits), "\(language): no number but the date")
        }
    }

    func testGivenAnyGameWhenBuildingShareTextThenItsTitleIsOnTheLine() {
        for game in GameID.released {
            let line = TodayShare.line(for: game, localize: { AppLanguage.localized($0) })
            XCTAssertTrue(line.hasSuffix(" ✓"))
            XCTAssertTrue(line.contains(AppLanguage.localized(game.title)))
        }
    }
}
