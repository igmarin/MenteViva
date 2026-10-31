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

    func testGivenEveryIdWhenLookingUpStartAndEndThenBothLanguagesExist() throws {
        // #414: checks ids 1-120 directly, so a missing range in `Sayings` can't hide a missing key.
        let strings = try strings()
        for id in 1...120 {
            let saying = Saying(id: id, theme: .animals)
            for key in [saying.startKey, saying.endKey] {
                for language in ["en", "es"] {
                    let text = value(strings[key], language)?.trimmingCharacters(in: .whitespaces) ?? ""
                    XCTAssertFalse(text.isEmpty, "\(key) [\(language)]")
                }
            }
        }
    }

    func testGivenEveryLanguageWhenJoiningStartAndEndThenNoSayingAppearsTwice() throws {
        // #414: the second pack must not repeat a saying from the first.
        let strings = try strings()
        for language in ["en", "es"] {
            let whole = Sayings.all.compactMap { saying -> String? in
                guard let start = value(strings[saying.startKey], language),
                    let end = value(strings[saying.endKey], language)
                else { return nil }
                return "\(start) \(end)".lowercased()
            }
            XCTAssertEqual(Set(whole).count, whole.count, language)
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
