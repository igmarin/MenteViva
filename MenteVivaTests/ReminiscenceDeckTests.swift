import UIKit
import XCTest

@testable import MenteViva

/// #139: which cards a Photo Stories session shows.
final class ReminiscenceDeckTests: XCTestCase {
    private func photos(_ count: Int) -> [URL] {
        (0..<count).map { URL(fileURLWithPath: "/\($0).jpg") }
    }

    func testGivenCardsWhenAskingForThePromptThenItMatchesWhatTheScreenAsks() {
        let url = URL(fileURLWithPath: "/0.jpg")
        let object = EverydayObjects.all[0]
        XCTAssertEqual(
            ReminiscenceCard(id: 0, picture: .photo(url), caption: "Ana").promptKey, "game.reminiscence.prompt.story")
        XCTAssertEqual(
            ReminiscenceCard(id: 0, picture: .object(object), caption: "Cup").promptKey,
            "game.reminiscence.prompt.object")
        XCTAssertEqual(
            ReminiscenceCard(id: 0, picture: .photo(url), caption: nil).promptKey, "game.reminiscence.prompt.story",
            "a photo with no name still invites a story")
    }

    func testGivenNoFamilyPhotosWhenCheckedThenPhotoStoriesIsUnavailable() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: folder) }
        XCTAssertTrue(GameAvailability.unavailable(in: folder).contains(.reminiscence))
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        XCTAssertTrue(GameAvailability.unavailable(in: folder).contains(.reminiscence), "an empty album")
        try Data([0xFF]).write(to: folder.appendingPathComponent("0.jpg"))
        XCTAssertFalse(GameAvailability.unavailable(in: folder).contains(.reminiscence), "one photo is enough")
    }

    func testGivenSevenPhotosWhenDealtThenFiveInGivenOrder() {
        let urls = photos(7)
        let cards = ReminiscenceDeck.deal(photos: urls, captions: [:])
        XCTAssertEqual(cards.map(\.picture), urls.prefix(5).map(ReminiscenceCard.Picture.photo))
        XCTAssertEqual(cards.map(\.id), [0, 1, 2, 3, 4])
    }

    func testGivenThreePhotosWhenDealtThenOnlyThoseThree() {
        XCTAssertEqual(ReminiscenceDeck.deal(photos: photos(3), captions: [:]).count, 3)
    }

    func testGivenOnePhotoWhenDealtThenOneCardAndNoObjects() {
        let cards = ReminiscenceDeck.deal(photos: photos(1), captions: [:])
        XCTAssertEqual(cards.count, 1)
        XCTAssertEqual(cards[0].picture, .photo(URL(fileURLWithPath: "/0.jpg")))
    }

    func testGivenNoPhotosWhenDealtThenFiveObjectCardsNamedByLocalizedKey() {
        let cards = ReminiscenceDeck.deal(photos: [], captions: [:], localize: { "L:" + $0 })
        XCTAssertEqual(cards.count, 5)
        XCTAssertEqual(cards[0].picture, .object(EverydayObjects.all[0]))
        XCTAssertEqual(cards[0].caption, "L:" + EverydayObjects.all[0].nameKey)
        XCTAssertEqual(EverydayObjects.all[0].nameKey, "object.cup")
    }

    func testGivenPhotoWithoutCaptionWhenDealtThenCaptionIsNil() {
        let urls = photos(2)
        let cards = ReminiscenceDeck.deal(photos: urls, captions: [urls[0]: "Ana"])
        XCTAssertEqual(cards[0].caption, "Ana")
        XCTAssertNil(cards[1].caption)
    }

    /// Deterministic generator so the shuffle test never flakes.
    private struct SeededGenerator: RandomNumberGenerator {
        var state: UInt64
        mutating func next() -> UInt64 {
            state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
            return state
        }
    }

    func testGivenNoPhotosWhenManySessionsDealtThenEveryObjectAppears() {
        var generator = SeededGenerator(state: 7)
        var seen = Set<String>()
        for _ in 0..<30 {
            let cards = ReminiscenceDeck.dealSession(photos: [], captions: [:], using: &generator)
            seen.formUnion(
                cards.compactMap { card in
                    if case .object(let object) = card.picture { object.symbol } else { nil }
                })
        }
        XCTAssertEqual(seen, Set(EverydayObjects.all.map(\.symbol)))
    }

    func testGivenPhotosWhenSessionDealtThenOnlyPhotosAndAtMostFive() {
        var generator = SeededGenerator(state: 3)
        let urls = photos(8)
        let cards = ReminiscenceDeck.dealSession(photos: urls, captions: [:], using: &generator)
        XCTAssertEqual(cards.count, 5)
        XCTAssertTrue(cards.allSatisfy { if case .photo(let url) = $0.picture { urls.contains(url) } else { false } })
    }

    func testGivenEveryObjectSymbolThenItResolvesToAnImage() {
        for object in EverydayObjects.all {
            XCTAssertNotNil(UIImage(systemName: object.symbol), object.symbol)
        }
        XCTAssertEqual(EverydayObjects.all.count, 8)
    }

    // MARK: - Conversation prompts (#379)

    func testGivenPhotoSessionWhenDealtThenEveryCardHasADistinctPhotoPrompt() {
        var generator = SeededGenerator(state: 11)
        let cards = ReminiscenceDeck.dealSession(photos: photos(8), captions: [:], using: &generator)
        let prompts = cards.compactMap(\.question)
        XCTAssertEqual(prompts.count, 5)
        XCTAssertEqual(Set(prompts).count, 5)
        XCTAssertTrue(prompts.allSatisfy(ConversationPrompts.photoKeys.contains))
    }

    func testGivenObjectSessionWhenDealtThenEveryCardHasAnObjectPrompt() {
        var generator = SeededGenerator(state: 5)
        let cards = ReminiscenceDeck.dealSession(photos: [], captions: [:], using: &generator)
        let prompts = cards.compactMap(\.question)
        XCTAssertEqual(prompts.count, 5)
        XCTAssertEqual(Set(prompts).count, 5)
        XCTAssertTrue(prompts.allSatisfy(ConversationPrompts.objectKeys.contains))
    }

    func testGivenTwoPhotosWhenSessionDealtThenOnlyTwoPrompts() {
        var generator = SeededGenerator(state: 2)
        let cards = ReminiscenceDeck.dealSession(photos: photos(2), captions: [:], using: &generator)
        XCTAssertEqual(cards.compactMap(\.question).count, 2)
    }
}
