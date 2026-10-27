import XCTest

@testable import MenteViva

/// #324: one catalogue of game pictures, each with a name in EN and ES, our
/// illustration once it ships and the emoji until then.
final class GamePicturesTests: XCTestCase {
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

    func testGivenTheCatalogue_WhenListed_ThenEverySlugIsUnique() {
        let slugs = GamePictures.all.map(\.slug)
        XCTAssertEqual(Set(slugs).count, slugs.count)
        XCTAssertEqual(slugs.count, 76)
    }

    func testGivenEverySlug_WhenLocalized_ThenItHasEnglishAndSpanishNames() throws {
        let strings = try strings()
        for picture in GamePictures.all {
            for language in ["en", "es"] {
                let text = value(strings[picture.nameKey], language)?.trimmingCharacters(in: .whitespaces) ?? ""
                XCTAssertFalse(text.isEmpty, "\(picture.nameKey) [\(language)]")
            }
        }
    }

    func testGivenEachMemoryTheme_ThenItHasTwelveDistinctPictures() {
        XCTAssertEqual(MemoryDeal.themes.count, 4)
        for theme in MemoryDeal.themes {
            XCTAssertEqual(theme.count, 12)
            XCTAssertEqual(Set(theme).count, 12)
        }
    }

    func testGivenEachHerdCategory_ThenNoPictureBelongsToTwoCategories() {
        let items = CategoryDeal.Category.allCases.flatMap(\.items)
        XCTAssertEqual(Set(items).count, items.count)
    }

    func testGivenEveryGame_ThenItOnlyShowsCataloguePictures() {
        let catalogue = Set(GamePictures.all)
        let used =
            MemoryDeal.themes.flatMap { $0 } + CategoryDeal.Category.allCases.flatMap(\.items)
            + QuickEyesDeal.pictures + EverydayObjects.all.map(\.picture)
        XCTAssertTrue(Set(used).isSubset(of: catalogue))
    }

    func testGivenNoAsset_WhenResolved_ThenTheFallbackIsShown() {
        let dog = GamePictures.named("dog")
        XCTAssertEqual(dog.look(hasAsset: { _ in false }), .emoji("🐶"))
    }

    func testGivenTheAsset_WhenResolved_ThenOurPictureIsShown() {
        let dog = GamePictures.named("dog")
        XCTAssertEqual(dog.look(hasAsset: { $0 == "pic.dog" }), .asset("pic.dog"))
    }
}
