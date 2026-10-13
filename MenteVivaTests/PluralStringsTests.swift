import XCTest

@testable import MenteViva

/// #124: counts read naturally in both languages ("1 game", never "1 games").
final class PluralStringsTests: XCTestCase {
    /// The language's own bundle: `locale:` alone formats, it doesn't pick the translation.
    private func text(_ value: String.LocalizationValue, _ language: String) -> String {
        let bundle = Bundle.main.path(forResource: language, ofType: "lproj").flatMap(Bundle.init(path:)) ?? .main
        return String(localized: value, bundle: bundle, locale: Locale(identifier: language))
    }

    func testGivenOneGameWhenFamilyWeekLineThenItIsSingular() {
        XCTAssertEqual(text("family.week.this \(1)", "en"), "This week: 1 game")
        XCTAssertEqual(text("family.week.last \(1)", "es"), "Semana anterior: 1 juego")
    }

    func testGivenSeveralGamesWhenFamilyWeekLineThenItIsPlural() {
        XCTAssertEqual(text("family.week.this \(3)", "en"), "This week: 3 games")
        XCTAssertEqual(text("family.week.last \(0)", "es"), "Semana anterior: 0 juegos")
    }

    func testGivenOneGameLeftTodayWhenHomeLineThenItIsSingular() {
        XCTAssertEqual(text("home.today.togo \(1)", "en"), "Nice! 1 more to go.")
        XCTAssertEqual(text("home.today.togo \(1)", "es"), "¡Bien! Falta 1.")
    }

    func testGivenTwoGamesLeftTodayWhenHomeLineThenItIsPlural() {
        XCTAssertEqual(text("home.today.togo \(2)", "en"), "Nice! 2 more to go.")
        XCTAssertEqual(text("home.today.togo \(2)", "es"), "¡Bien! Faltan 2.")
    }

    func testGivenOneSessionWhenWeekHeaderThenItIsSingular() {
        XCTAssertEqual(text("history.summary \(1)", "en"), "You played 1 time this week! 🌟")
        XCTAssertEqual(text("history.summary \(1)", "es"), "¡Jugaste 1 vez esta semana! 🌟")
    }
}
