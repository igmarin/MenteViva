import XCTest

@testable import MenteViva

/// #139: every string the captions feature adds exists in English and Spanish.
final class CaptionStringsTests: XCTestCase {
    private func catalog() throws -> [String: Any] {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        let data = try Data(contentsOf: root.appendingPathComponent("MenteViva/Localizable.xcstrings"))
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        return try XCTUnwrap(json["strings"] as? [String: Any])
    }

    private func assertBothLanguages(_ keys: [String], file: StaticString = #filePath, line: UInt = #line) throws {
        let strings = try catalog()
        for key in keys {
            let localizations = (strings[key] as? [String: Any])?["localizations"] as? [String: Any]
            XCTAssertNotNil(localizations?["en"], "\(key) has no English", file: file, line: line)
            XCTAssertNotNil(localizations?["es"], "\(key) has no Spanish", file: file, line: line)
        }
    }

    func testGivenCaptionSheetKeysWhenCatalogReadThenEveryKeyHasEnglishAndSpanish() throws {
        try assertBothLanguages([
            "family.caption.title", "family.caption.field", "family.caption.placeholder",
            "family.caption.privacy", "family.caption.save", "family.photos.caption.add",
            "family.game.nolevel", "family.photos.caption.a11y %lld",
            "settings.speak", "settings.speak.hint",
        ])
    }
}
