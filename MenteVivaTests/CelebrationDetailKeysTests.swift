import XCTest

@testable import MenteViva

/// #394: a celebration says the player finished, never how many they got right. These scan the
/// catalog and the sources, because the lines live in views no test can reach.
final class CelebrationDetailKeysTests: XCTestCase {
    private static let scoreShapedKeys = [
        "game.celebration.spotted %lld %lld",
        "game.celebration.streak %lld",
    ]

    private var root: URL {
        URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
    }

    func testGivenCelebrationDetailKeysWhenCatalogScannedThenNoScoreShapedKeysRemain() throws {
        let data = try Data(contentsOf: root.appendingPathComponent("MenteViva/Localizable.xcstrings"))
        let catalog = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let strings = try XCTUnwrap(catalog["strings"] as? [String: Any])
        for key in Self.scoreShapedKeys {
            XCTAssertNil(strings[key], key)
        }
    }

    func testGivenScoreShapedKeysWhenSourcesScannedThenNoSwiftFileReferencesThem() throws {
        let sources = root.appendingPathComponent("MenteViva")
        let files = try XCTUnwrap(FileManager.default.enumerator(at: sources, includingPropertiesForKeys: nil))
        for case let file as URL in files where file.pathExtension == "swift" {
            let text = try String(contentsOf: file, encoding: .utf8)
            for key in Self.scoreShapedKeys {
                XCTAssertFalse(text.contains(key), "\(file.lastPathComponent) uses \(key)")
            }
        }
    }
}
