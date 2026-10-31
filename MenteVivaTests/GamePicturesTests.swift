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

    // MARK: - Sizes (#413)

    func testGivenAnIPad_WhenTheFlashTargetIsSized_ThenItReachesItsCeiling() {
        XCTAssertEqual(PictureView.flashTarget(ceiling: 240, width: 744, isAccessibilitySize: false), 240)
    }

    func testGivenAnIPhoneSE_WhenTheFlashTargetIsSized_ThenItIsSixtyPercentOfTheWidth() {
        XCTAssertEqual(PictureView.flashTarget(ceiling: 240, width: 375, isAccessibilitySize: false), 225, accuracy: 0.001)
    }

    func testGivenAccessibilityText_WhenTheFlashTargetIsSized_ThenItStopsAt120SoTheButtonStaysOnScreen() {
        XCTAssertEqual(PictureView.flashTarget(ceiling: 600, width: 744, isAccessibilitySize: true), 120)
        XCTAssertEqual(PictureView.flashTarget(ceiling: 600, width: 375, isAccessibilitySize: true), 120)
    }

    func testGivenAccessibilityText_WhenTheScreenIsNarrowerThanTheCap_ThenTheWidthRuleStillWins() {
        XCTAssertEqual(PictureView.flashTarget(ceiling: 600, width: 150, isAccessibilitySize: true), 90, accuracy: 0.001)
    }

    func testGivenTheDefaultSizes_WhenTheHerdColumnIsSized_ThenTheTileStaysAt100() {
        XCTAssertEqual(PictureView.columnMinimum(picture: 72, margin: 14), 100)
    }

    func testGivenLargerText_WhenTheHerdColumnIsSized_ThenItWidensWithThePicture() {
        XCTAssertEqual(PictureView.columnMinimum(picture: 180, margin: 35), 250)
    }

    func testGivenAnIPhoneSE_WhenAChoiceIsSized_ThenItKeepsAll84() {
        // 375 less 32pt of padding and the 8pt gap, halved: 167pt per tile.
        XCTAssertEqual(PictureView.fitted(84, columnWidth: 167.5, margin: 13), 84)
    }

    func testGivenTheLargestText_WhenAChoiceIsSizedForAnSE_ThenItStopsAtWhatTheTileCarries() {
        // At the largest text the picture scales to about 222pt and its margin to about 34pt, in a 167pt tile.
        XCTAssertEqual(PictureView.fitted(222, columnWidth: 167.5, margin: 34.3), 92.9, accuracy: 0.001)
    }
}
