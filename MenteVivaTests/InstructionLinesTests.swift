import XCTest

@testable import MenteViva

/// #531: every game's instruction is one short verb-first sentence ending in a full stop, in EN and
/// ES. The line is also spoken by the header speaker, so a colon, a question or a second sentence
/// reads badly aloud and, on screen, runs to three lines.
final class InstructionLinesTests: XCTestCase {
    private func catalog() throws -> [String: Any] {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        let data = try Data(contentsOf: root.appendingPathComponent("MenteViva/Localizable.xcstrings"))
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        return try XCTUnwrap(json["strings"] as? [String: Any])
    }

    private func value(_ strings: [String: Any], _ key: String, _ language: String) -> String? {
        let localizations = (strings[key] as? [String: Any])?["localizations"] as? [String: [String: [String: String]]]
        return localizations?[language]?["stringUnit"]?["value"]
    }

    func testGivenEveryGameInstructionWhenReadThenItIsOneShortSentenceEndingInAFullStop() throws {
        let strings = try catalog()
        let keys = strings.keys.filter { $0.hasPrefix("game.") && $0.contains(".instruction") }
        XCTAssertGreaterThanOrEqual(keys.count, 14, "an instruction key went missing")
        for key in keys.sorted() {
            for language in ["en", "es"] {
                let line = try XCTUnwrap(value(strings, key, language), "\(key) [\(language)]")
                XCTAssertTrue(line.hasSuffix("."), "\(key) [\(language)] needs a full stop: \(line)")
                XCTAssertEqual(
                    line.filter { ".?!:".contains($0) }.count, 1,
                    "\(key) [\(language)] is more than one sentence: \(line)")
                XCTAssertLessThanOrEqual(
                    line.split(separator: " ").count, 9, "\(key) [\(language)] is too long: \(line)")
            }
        }
    }

    /// #531: "Show me" means a hint everywhere else; in Photo Stories the button reveals the name.
    func testGivenPhotoStoriesRevealButtonWhenReadThenItSaysItShowsTheName() throws {
        let strings = try catalog()
        XCTAssertEqual(value(strings, "game.reminiscence.show", "en"), "Show the name")
        XCTAssertEqual(value(strings, "game.reminiscence.show", "es"), "Ver el nombre")
    }
}
