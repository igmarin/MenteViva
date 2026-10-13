import XCTest

@testable import MenteViva

/// #124: counts read naturally in both languages ("1 game", never "1 games").
final class PluralStringsTests: XCTestCase {
    /// The language's own bundle: `locale:` alone formats, it doesn't pick the translation.
    private func text(_ value: String.LocalizationValue, _ language: String) -> String {
        let bundle = Bundle.main.path(forResource: language, ofType: "lproj").flatMap(Bundle.init(path:)) ?? .main
        return String(localized: value, bundle: bundle, locale: Locale(identifier: language))
    }

    func testGivenOnePlayWhenMyProgressPlaysLineThenItIsSingular() {
        XCTAssertEqual(text("progress.plays \(1)", "en"), "Played 1 time this week")
        XCTAssertEqual(text("progress.plays \(1)", "es"), "Jugaste 1 vez esta semana")
    }

    func testGivenSeveralPlaysWhenMyProgressPlaysLineThenItIsPlural() {
        XCTAssertEqual(text("progress.plays \(3)", "en"), "Played 3 times this week")
        XCTAssertEqual(text("progress.plays \(0)", "es"), "Jugaste 0 veces esta semana")
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

    func testGivenOnePlayWhenMyWeekChipIsSpokenThenItSaysOnce() {
        XCTAssertEqual(text("history.day.times \(1)", "en"), "once")
        XCTAssertEqual(text("history.day.times \(1)", "es"), "una vez")
    }

    func testGivenTwoPlaysWhenMyWeekChipIsSpokenThenItSaysTimes() {
        XCTAssertEqual(text("history.day.times \(2)", "en"), "2 times")
        XCTAssertEqual(text("history.day.times \(2)", "es"), "2 veces")
    }
}
