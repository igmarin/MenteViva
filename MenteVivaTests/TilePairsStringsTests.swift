import XCTest

@testable import MenteViva

/// #418: Tile Pairs' spoken lines name a picture ("Apple"), so each must read as a sentence with
/// one picture name in it. The lines live in views no test can reach, so these read the catalog.
final class TilePairsStringsTests: XCTestCase {
    private func value(_ key: String, _ language: String) throws -> String {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        let data = try Data(contentsOf: root.appendingPathComponent("MenteViva/Localizable.xcstrings"))
        let catalog = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let strings = try XCTUnwrap(catalog["strings"] as? [String: Any])
        let localizations = try XCTUnwrap((strings[key] as? [String: Any])?["localizations"] as? [String: Any])
        let unit = try XCTUnwrap((localizations[language] as? [String: Any])?["stringUnit"] as? [String: Any])
        return try XCTUnwrap(unit["value"] as? String)
    }

    func testGivenAPictureNameWhenAPairMatchesThenEnglishSaysYouMatchedIt() throws {
        let line = String(format: try value("game.tilepairs.matched %@", "en"), "Apple")
        XCTAssertEqual(line, "Nice — you matched the Apple!")
    }

    func testGivenAPictureNameWhenAPairMatchesThenSpanishNamesThePair() throws {
        let line = String(format: try value("game.tilepairs.matched %@", "es"), "Manzana")
        XCTAssertEqual(line, "¡Bien — encontraste el par: Manzana!")
    }

    func testGivenAPictureNameWhenShowMePairThenBothLanguagesNameTheTiles() throws {
        XCTAssertEqual(
            String(format: try value("game.tilepairs.hint %@", "en"), "Apple"), "Look for the two Apple tiles")
        XCTAssertEqual(
            String(format: try value("game.tilepairs.hint %@", "es"), "Manzana"), "Busca las dos fichas de Manzana")
    }
}
