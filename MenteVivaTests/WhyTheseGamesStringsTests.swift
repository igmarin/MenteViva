import XCTest

@testable import MenteViva

/// #214: every string the "Why these games" screen shows exists in English and Spanish, the footer
/// is the approved sentence word for word, and no line promises anything: a game exercises.
final class WhyTheseGamesStringsTests: XCTestCase {
    private func root() -> URL {
        URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
    }

    private func catalog() throws -> [String: Any] {
        let data = try Data(contentsOf: root().appendingPathComponent("MenteViva/Localizable.xcstrings"))
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        return try XCTUnwrap(json["strings"] as? [String: Any])
    }

    private func value(_ entry: Any?, _ language: String) -> String? {
        let localizations = (entry as? [String: Any])?["localizations"] as? [String: Any]
        let unit = (localizations?[language] as? [String: Any])?["stringUnit"] as? [String: Any]
        return unit?["value"] as? String
    }

    /// Every `why.*` key the screen and its Settings row ask for, read out of the sources so a
    /// line that forgets its translation fails here rather than on a phone.
    private func keysOfTheScreen() throws -> [String] {
        var keys: Set<String> = []
        let regex = try NSRegularExpression(pattern: #""(why\.[A-Za-z0-9.]*)""#)
        for file in ["MenteViva/WhyTheseGamesView.swift", "MenteViva/SettingsView.swift"] {
            let source = try String(contentsOf: root().appendingPathComponent(file), encoding: .utf8)
            let range = NSRange(source.startIndex..., in: source)
            for match in regex.matches(in: source, range: range) {
                guard let found = Range(match.range(at: 1), in: source) else { continue }
                keys.insert(String(source[found]))
            }
        }
        return keys.sorted()
    }

    func testGivenEveryWhyKeyWhenReadThenEnAndEsAreBothPresentAndNotEmpty() throws {
        let strings = try catalog()
        let keys = try keysOfTheScreen()
        XCTAssertGreaterThan(keys.count, 35, "the three approved parts are more than thirty-five strings")
        for key in keys {
            for language in ["en", "es"] {
                let text = value(strings[key], language)?.trimmingCharacters(in: .whitespaces) ?? ""
                XCTAssertFalse(text.isEmpty, "\(key) [\(language)]")
            }
        }
    }

    /// The footer is the sentence the owner approved for #210, and it closes the screen.
    func testGivenTheFooterWhenReadThenItIsTheApprovedSentenceInBothLanguages() throws {
        let strings = try catalog()
        XCTAssertEqual(value(strings["why.footer"], "en"), "Educational information, not medical advice.")
        XCTAssertEqual(value(strings["why.footer"], "es"), "Información educativa, no consejo médico.")
    }

    /// A game line exercises; it never improves, boosts or prevents anything. Remember Together is
    /// the one line that describes the game instead — nothing in it can be answered wrongly, so it
    /// has no verb to claim with — and the approved copy says that in both languages.
    func testGivenEveryGameLineWhenReadThenItSaysWhatTheGameExercises() throws {
        let strings = try catalog()
        let gameKeys = try keysOfTheScreen().filter { $0.hasPrefix("why.game.") }
        XCTAssertEqual(gameKeys.count, 14, "one line per game (docs/why-these-games.md §2)")
        for key in gameKeys where key != "why.game.reminiscence" {
            for language in ["en", "es"] {
                let text = try XCTUnwrap(value(strings[key], language)).lowercased()
                XCTAssertTrue(
                    text.contains(language == "en" ? "exercises" : "ejercita"),
                    "\(key) [\(language)] does not say what the game exercises: \(text)")
            }
        }
        let reminiscence = strings["why.game.reminiscence"]
        XCTAssertTrue(try XCTUnwrap(value(reminiscence, "en")).contains("no right or wrong answers"))
        XCTAssertTrue(try XCTUnwrap(value(reminiscence, "es")).contains("No hay respuestas buenas ni malas"))
    }

    /// Nothing on this screen promises an outcome: no improvement, no percentage, no score of any
    /// kind (`statistics-rationale.md` §4). Checked on every line, not only the game ones.
    func testGivenAnyWhyLineWhenReadThenItPromisesNothing() throws {
        let strings = try catalog()
        let banned = ["improve", "mejora", "prevent", "previene", "boost", "sharpen", "brain age", "%"]
        for key in try keysOfTheScreen() {
            for language in ["en", "es"] {
                let text = try XCTUnwrap(value(strings[key], language)).lowercased()
                for word in banned {
                    XCTAssertFalse(text.contains(word), "\(key) [\(language)] says \(word): \(text)")
                }
            }
        }
    }

    /// A link says where it goes: someone listening has nothing but the label, so each of the nine
    /// names the place it opens instead of saying "read more".
    func testGivenEverySourceLabelWhenReadThenItNamesWhereItGoes() throws {
        let strings = try catalog()
        let whereItGoes = [
            "why.source.cct": "PubMed Central",
            "why.source.simons": "SAGE Journals",
            "why.source.stanford": "Stanford Longevity",
            "why.source.globalcouncil": "Global Council on Brain Health",
            "why.source.finger": "The Lancet",
            "why.source.fluency": "PubMed Central",
            "why.source.processing": "PubMed Central",
            "why.source.workingmemory": "PubMed",
            "why.source.fda": "FDA",
        ]
        let keys = try keysOfTheScreen().filter { $0.hasPrefix("why.source.") && $0 != "why.source.hint" }
        XCTAssertEqual(keys.sorted(), whereItGoes.keys.sorted(), "one label per outside source")
        for (key, destination) in whereItGoes {
            for language in ["en", "es"] {
                let text = try XCTUnwrap(value(strings[key], language))
                XCTAssertTrue(
                    text.contains(destination), "\(key) [\(language)] does not name \(destination): \(text)")
            }
        }
    }
}
