import XCTest

@testable import MenteViva

/// #379: which warm question goes with which Photo Stories card.
final class ConversationPromptsTests: XCTestCase {
    /// Deterministic generator so the shuffle tests never flake.
    private struct SeededGenerator: RandomNumberGenerator {
        var state: UInt64
        mutating func next() -> UInt64 {
            state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
            return state
        }
    }

    private func catalog() throws -> [String: Any] {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        let data = try Data(contentsOf: root.appendingPathComponent("MenteViva/Localizable.xcstrings"))
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        return try XCTUnwrap(json["strings"] as? [String: Any])
    }

    func testGivenFivePhotoCardsWhenDealingPromptsThenAllFiveAreDistinct() {
        var generator = SeededGenerator(state: 1)
        let prompts = ConversationPrompts.deal(count: 5, photos: true, using: &generator)
        XCTAssertEqual(prompts.count, 5)
        XCTAssertEqual(Set(prompts).count, 5)
        XCTAssertTrue(prompts.allSatisfy(ConversationPrompts.photoKeys.contains))
    }

    func testGivenObjectCardsWhenDealingPromptsThenObjectPromptsAreUsed() {
        var generator = SeededGenerator(state: 1)
        let prompts = ConversationPrompts.deal(count: 5, photos: false, using: &generator)
        XCTAssertEqual(Set(prompts).count, 5)
        XCTAssertTrue(prompts.allSatisfy(ConversationPrompts.objectKeys.contains))
        XCTAssertTrue(Set(prompts).isDisjoint(with: ConversationPrompts.photoKeys))
    }

    func testGivenSameSeedWhenDealingTwiceThenSamePrompts() {
        var first = SeededGenerator(state: 9)
        var second = SeededGenerator(state: 9)
        XCTAssertEqual(
            ConversationPrompts.deal(count: 5, photos: true, using: &first),
            ConversationPrompts.deal(count: 5, photos: true, using: &second))
    }

    func testGivenMoreCardsThanPromptsWhenDealingThenEachPromptIsUsedOnce() {
        var generator = SeededGenerator(state: 4)
        let prompts = ConversationPrompts.deal(count: 99, photos: false, using: &generator)
        XCTAssertEqual(prompts.count, ConversationPrompts.objectKeys.count)
        XCTAssertEqual(Set(prompts).count, prompts.count)
    }

    func testGivenManySessionsWhenDealtThenEveryPhotoPromptAppears() {
        var generator = SeededGenerator(state: 6)
        var seen = Set<String>()
        for _ in 0..<60 { seen.formUnion(ConversationPrompts.deal(count: 5, photos: true, using: &generator)) }
        XCTAssertEqual(seen, Set(ConversationPrompts.photoKeys))
    }

    func testGivenPoolsThenSixteenPhotoAndEightObjectPrompts() {
        XCTAssertEqual(ConversationPrompts.photoKeys.count, 16)
        XCTAssertEqual(ConversationPrompts.objectKeys.count, 8)
        XCTAssertEqual(ConversationPrompts.photoKeys.first, "reminiscence.ask.01")
        XCTAssertEqual(ConversationPrompts.objectKeys.last, "reminiscence.askobject.08")
    }

    func testGivenEveryPromptKeyWhenCatalogReadThenItHasEnglishAndSpanish() throws {
        let strings = try catalog()
        for key in ConversationPrompts.photoKeys + ConversationPrompts.objectKeys {
            let localizations = (strings[key] as? [String: Any])?["localizations"] as? [String: [String: [String: String]]]
            for language in ["en", "es"] {
                let value = localizations?[language]?["stringUnit"]?["value"] ?? ""
                XCTAssertFalse(value.isEmpty, "\(key) has no \(language)")
            }
        }
    }

    /// A prompt invites a story; it never quizzes ("who is this?").
    func testGivenEveryPromptWhenReadThenNoneAsksWhoItIs() throws {
        let strings = try catalog()
        for key in ConversationPrompts.photoKeys + ConversationPrompts.objectKeys {
            let localizations = (strings[key] as? [String: Any])?["localizations"] as? [String: [String: [String: String]]]
            let english = (localizations?["en"]?["stringUnit"]?["value"] ?? "").lowercased()
            let spanish = (localizations?["es"]?["stringUnit"]?["value"] ?? "").lowercased()
            XCTAssertFalse(english.contains("who is") || english.contains("who was"), key)
            XCTAssertFalse(spanish.contains("quién es") || spanish.contains("quién era"), key)
        }
    }

    /// #513: the game is Photo Stories, and a photo invites a story. "Who is this?" stays for naming a photo.
    func testGivenTheCatalogWhenReadThenTheGameIsPhotoStoriesWithAStoryPrompt() throws {
        let strings = try catalog()
        func value(_ key: String, _ language: String) -> String? {
            let localizations = (strings[key] as? [String: Any])?["localizations"] as? [String: [String: [String: String]]]
            return localizations?[language]?["stringUnit"]?["value"]
        }
        XCTAssertEqual(value("game.reminiscence.title", "en"), "Photo Stories")
        XCTAssertEqual(value("game.reminiscence.title", "es"), "Historias en fotos")
        XCTAssertEqual(value("game.reminiscence.prompt.story", "en"), "Tell a story about this photo")
        XCTAssertEqual(value("game.reminiscence.prompt.story", "es"), "Cuéntame una historia de esta foto")
        XCTAssertEqual(value("game.reminiscence.prompt.photo", "en"), "Who is this?", "naming a photo keeps its question")
    }
}
