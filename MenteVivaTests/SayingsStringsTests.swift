import XCTest

@testable import MenteViva

/// #181: every saying slot has both halves in English and Spanish, so the game never
/// shows a raw key.
final class SayingsStringsTests: XCTestCase {
    private func strings() throws -> [String: Any] {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        let data = try Data(contentsOf: root.appendingPathComponent("MenteViva/Localizable.xcstrings"))
        let catalog = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        return try XCTUnwrap(catalog["strings"] as? [String: Any])
    }

    private func value(_ entry: Any?, _ language: String) -> String? {
        let localizations = (entry as? [String: Any])?["localizations"] as? [String: Any]
        let unit = (localizations?[language] as? [String: Any])?["stringUnit"] as? [String: Any]
        return unit?["value"] as? String
    }

    func testGivenEverySayingSlotWhenLookingUpStartAndEndThenEnAndEsAreBothPresentAndNotEmpty() throws {
        let strings = try strings()
        for saying in Sayings.all {
            for key in [saying.startKey, saying.endKey] {
                for language in ["en", "es"] {
                    let text = value(strings[key], language)?.trimmingCharacters(in: .whitespaces) ?? ""
                    XCTAssertFalse(text.isEmpty, "\(key) [\(language)]")
                }
            }
        }
    }

    func testGivenEveryLanguageThenNoTwoSlotsShareAnEnding() throws {
        let strings = try strings()
        for language in ["en", "es"] {
            let endings = Sayings.all.compactMap { value(strings[$0.endKey], language)?.lowercased() }
            XCTAssertEqual(Set(endings).count, endings.count, language)
        }
    }
}
