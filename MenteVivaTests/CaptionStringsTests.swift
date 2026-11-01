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

    /// The notice shown while typing a name must match where it is stored: in the
    /// app's folder, kept out of new device backups at every launch (#419).
    func testGivenCaptionPrivacyNoticeWhenReadThenItMentionsDeviceBackups() throws {
        let entry = try XCTUnwrap(catalog()["family.caption.privacy"] as? [String: Any])
        let localizations = try XCTUnwrap(entry["localizations"] as? [String: [String: [String: String]]])
        XCTAssertTrue(try XCTUnwrap(localizations["en"]?["stringUnit"]?["value"]).contains("excluded from new device backups"))
        XCTAssertTrue(
            try XCTUnwrap(localizations["es"]?["stringUnit"]?["value"]).contains("se excluyen de las nuevas copias de seguridad"))
    }

    func testGivenCaptionSheetKeysWhenCatalogReadThenEveryKeyHasEnglishAndSpanish() throws {
        try assertBothLanguages([
            "family.caption.title", "family.caption.field", "family.caption.placeholder",
            "family.caption.privacy", "family.caption.save", "family.photos.noname", "family.photos.edit", "family.photos.why",
            "family.game.nolevel", "family.photos.caption.a11y %lld",
            "settings.speak", "settings.speak.hint", "family.caption.save.problem",
        ])
    }
}
