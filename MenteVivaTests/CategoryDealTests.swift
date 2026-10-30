import XCTest

@testable import MenteViva

/// #244: Name the Herd's deal — three categories, their items and the decoys —
/// with the generator passed in, so a seeded run reproduces and a thousand
/// seeds can be checked for boards where a decoy is never right.
final class CategoryDealTests: XCTestCase {
    /// Deterministic generator so the property runs never flake.
    private struct SeededGenerator: RandomNumberGenerator {
        var state: UInt64
        mutating func next() -> UInt64 {
            state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
            return state
        }
    }

    private static let wide = 700.0

    private func deal(_ level: Int, seed: UInt64, width: Double = wide) -> [CategoryDeal.Round] {
        var generator = SeededGenerator(state: seed)
        return CategoryDeal.deal(difficulty: Difficulty(level: level), width: width, using: &generator)
    }

    func testGivenTheSameSeedWhenDealtTwiceThenTheSameSession() {
        XCTAssertEqual(deal(4, seed: 11), deal(4, seed: 11))
    }

    func testGivenDifferentSeedsWhenDealtThenTheSessionsDiffer() {
        XCTAssertNotEqual(deal(4, seed: 1), deal(4, seed: 2))
    }

    func testGivenEveryCategoryThenItsSevenItemsBelongToNoOtherCategory() {
        for category in CategoryDeal.Category.allCases {
            XCTAssertEqual(category.items.count, 7)
            XCTAssertEqual(Set(category.items).count, 7)
            let others = CategoryDeal.Category.allCases.filter { $0 != category }.flatMap(\.items)
            XCTAssertTrue(Set(category.items).isDisjoint(with: Set(others)), "\(category.nameKey)")
        }
    }

    func testGivenOneThousandSeedsWhenDealtThenEverySessionIsValid() {
        for level in [1, 4, 7, 10] {
            let decoys = CategoryDeal.fittedDecoyCount(for: Difficulty(level: level), width: Self.wide)
            for seed in 1...1000 {
                let session = deal(level, seed: UInt64(seed))
                XCTAssertEqual(session.count, CategoryDeal.roundsPerSession, "level \(level) seed \(seed)")
                XCTAssertEqual(Set(session.map(\.category)).count, session.count, "level \(level) seed \(seed)")
                for round in session {
                    let right = round.tiles.filter(\.belongs)
                    let wrong = round.tiles.filter { !$0.belongs }
                    // Every item of the category once, and nothing else belongs.
                    XCTAssertEqual(
                        right.map(\.picture.slug).sorted(), round.category.items.map(\.slug).sorted(),
                        "level \(level) seed \(seed)")
                    // Decoys are all from other categories, never repeated.
                    XCTAssertEqual(wrong.count, decoys, "level \(level) seed \(seed)")
                    XCTAssertEqual(Set(wrong.map(\.picture)).count, wrong.count, "level \(level) seed \(seed)")
                    XCTAssertTrue(
                        wrong.allSatisfy { !round.category.items.contains($0.picture) },
                        "level \(level) seed \(seed)")
                    XCTAssertEqual(Set(round.tiles.map(\.picture)).count, round.tiles.count, "level \(level) seed \(seed)")
                }
            }
        }
    }

    func testGivenAnyCategoryWhenDealtThenNoDecoyComesFromItselfOrAnExcludedCategory() {
        for level in [1, 6, 10] {
            for seed in 1...300 {
                for round in deal(level, seed: UInt64(seed)) {
                    let excluded = round.category.noDecoysFrom.union([round.category])
                    let forbidden = Set(excluded.flatMap(\.items))
                    for tile in round.tiles where !tile.belongs {
                        XCTAssertFalse(forbidden.contains(tile.picture), "level \(level) seed \(seed)")
                    }
                }
            }
        }
    }

    func testGivenKitchenRoundWhenDealtThenNoFruitOrHomeDecoyAppears() {
        let banned = Set(CategoryDeal.Category.fruits.items + CategoryDeal.Category.home.items)
        var kitchenRounds = 0
        for level in [1, 10] {
            for seed in 1...300 {
                for round in deal(level, seed: UInt64(seed)) where round.category == .kitchen {
                    kitchenRounds += 1
                    XCTAssertTrue(
                        round.tiles.allSatisfy { $0.belongs || !banned.contains($0.picture) },
                        "level \(level) seed \(seed)")
                }
            }
        }
        XCTAssertGreaterThan(kitchenRounds, 0)
    }

    /// A potted plant on an "Around the house" board is a fair tap, so plants never decoy home.
    func testGivenHomeRoundWhenDealtThenNoPlantOrKitchenDecoyAppears() {
        let banned = Set(CategoryDeal.Category.plants.items + CategoryDeal.Category.kitchen.items)
        var homeRounds = 0
        for level in [1, 10] {
            for seed in 1...300 {
                for round in deal(level, seed: UInt64(seed)) where round.category == .home {
                    homeRounds += 1
                    XCTAssertTrue(
                        round.tiles.allSatisfy { $0.belongs || !banned.contains($0.picture) },
                        "level \(level) seed \(seed)")
                }
            }
        }
        XCTAssertGreaterThan(homeRounds, 0)
    }

    func testGivenTheExclusionsThenTheyAreSymmetricAndNeverSelf() {
        for category in CategoryDeal.Category.allCases {
            XCTAssertFalse(category.noDecoysFrom.contains(category))
            for other in category.noDecoysFrom {
                XCTAssertTrue(other.noDecoysFrom.contains(category), "\(category) / \(other)")
            }
        }
    }

    func testGivenSevenCategoriesWhenDealingManySeedsThenEveryCategoryAppears() {
        XCTAssertEqual(CategoryDeal.Category.allCases.count, 7)
        var seen = Set<CategoryDeal.Category>()
        for seed in 1...200 {
            seen.formUnion(deal(4, seed: UInt64(seed)).map(\.category))
        }
        XCTAssertEqual(seen, Set(CategoryDeal.Category.allCases))
    }

    /// The pool is the real one per category, not a fixed 21: kitchen loses
    /// fruits and home, so its pool is smaller than animals'.
    func testGivenEachCategoryThenItsDecoyPoolIsTheRealOne() {
        XCTAssertEqual(CategoryDeal.decoyPool(for: .animals).count, 42)
        XCTAssertEqual(CategoryDeal.decoyPool(for: .kitchen).count, 28)
        XCTAssertEqual(CategoryDeal.decoyPool(for: .home).count, 28)  // minus kitchen, plants
        XCTAssertEqual(CategoryDeal.decoyPool(for: .plants).count, 28)  // minus fruits, home
        XCTAssertEqual(CategoryDeal.decoyPool(for: .fruits).count, 27)  // minus kitchen, plants, the orange swatch
        XCTAssertEqual(CategoryDeal.smallestPoolSize, 27)
        XCTAssertGreaterThanOrEqual(CategoryDeal.smallestPoolSize, CategoryDeal.decoysByLevel.max() ?? 0)
    }

    /// The 100pt floor itself comes from the view's `GridItem(.adaptive(minimum: 100))`;
    /// this pins only the decoy cap and the tile count that follows from it.
    func testGivenLevelTenOnTheNarrowestPhoneWhenDealtThenDecoysAreCappedAtFive() {
        let width = 343.0
        XCTAssertEqual(CategoryDeal.fittedDecoyCount(for: Difficulty(level: 10), width: width), 5)
        for seed in 1...100 {
            for round in deal(10, seed: UInt64(seed), width: width) {
                XCTAssertEqual(round.tiles.count, 7 + 5, "seed \(seed)")
            }
        }
    }

    func testGivenLevelsTwoFourSixWhenDecoysThenMatchesOldEasyMediumHard() {
        let counts = [2, 4, 6].map { CategoryDeal.decoyCount(for: Difficulty(level: $0)) }
        XCTAssertEqual(counts, [3, 5, 7])
    }

    func testGivenRisingLevelsWhenDecoysThenNeverFewer() {
        let counts = (1...10).map { CategoryDeal.decoyCount(for: Difficulty(level: $0)) }
        XCTAssertEqual(counts, [2, 3, 4, 5, 6, 7, 8, 9, 10, 11])
        for pair in zip(counts, counts.dropFirst()) {
            XCTAssertLessThanOrEqual(pair.0, pair.1)
        }
    }

    func testGivenANarrowScreenAtLevelTenWhenDealtThenDecoysAreCappedForTheWidth() {
        // 343pt (iPhone SE) fits fewer tiles than the table wants.
        let wide = CategoryDeal.fittedDecoyCount(for: Difficulty(level: 10), width: Self.wide)
        let narrow = CategoryDeal.fittedDecoyCount(for: Difficulty(level: 10), width: 343)
        XCTAssertLessThan(narrow, wide)
        for round in deal(10, seed: 3, width: 343) {
            XCTAssertEqual(round.tiles.count, 7 + narrow)
        }
    }

    /// A fair pick is never a miss (#371): the orange fruit and the orange
    /// colour share a name, so neither may be dealt against the other's category.
    func testGivenColorsCategoryWhenDealtWithManySeedsThenTheOrangeFruitIsNeverADecoy() {
        for level in 1...10 {
            for seed in 1...500 {
                for round in deal(level, seed: UInt64(seed)) where round.category == .colors {
                    XCTAssertFalse(round.tiles.contains { $0.picture.slug == "orange" }, "level \(level) seed \(seed)")
                }
            }
        }
    }

    func testGivenFruitsCategoryWhenDealtWithManySeedsThenTheOrangeSwatchIsNeverADecoy() {
        for level in 1...10 {
            for seed in 1...500 {
                for round in deal(level, seed: UInt64(seed)) where round.category == .fruits {
                    XCTAssertFalse(
                        round.tiles.contains { $0.picture.slug == "color.orange" }, "level \(level) seed \(seed)")
                }
            }
        }
    }

    /// The general guard for new categories: compares the names a player and
    /// VoiceOver get, in both languages, not slugs.
    func testGivenAnyDealWhenTilesLocalizedThenNoDecoyShareANameWithAnItemOfTheAskedCategory() throws {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        let data = try Data(contentsOf: root.appendingPathComponent("MenteViva/Localizable.xcstrings"))
        let catalog = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let strings = try XCTUnwrap(catalog["strings"] as? [String: Any])
        func name(_ picture: GamePicture, _ language: String) -> String? {
            let entry = strings[picture.nameKey] as? [String: Any]
            let localizations = entry?["localizations"] as? [String: Any]
            let unit = (localizations?[language] as? [String: Any])?["stringUnit"] as? [String: Any]
            return (unit?["value"] as? String)?.lowercased()
        }
        for language in ["en", "es"] {
            for level in 1...10 {
                for seed in 1...200 {
                    for round in deal(level, seed: UInt64(seed)) {
                        let asked = Set(round.category.items.compactMap { name($0, language) })
                        for tile in round.tiles where !tile.belongs {
                            let decoyName = try XCTUnwrap(name(tile.picture, language))
                            XCTAssertFalse(
                                asked.contains(decoyName),
                                "\(decoyName) [\(language)] level \(level) seed \(seed)")
                        }
                    }
                }
            }
        }
    }

    func testGivenLevelTenWhenAnyRoundIsDealtThenItHasSevenItemsPlusTheLevelsDecoys() {
        let decoys = CategoryDeal.fittedDecoyCount(for: Difficulty(level: 10), width: Self.wide)
        XCTAssertEqual(decoys, 11)
        for seed in 1...200 {
            for round in deal(10, seed: UInt64(seed)) {
                XCTAssertEqual(round.tiles.count, 7 + decoys, "seed \(seed)")
            }
        }
    }

    /// The category name is dropped into two sentences (the completion beat and
    /// the read-aloud line); every name must read naturally after them, in both languages.
    func testGivenEachCategoryWhenFormattedIntoTheSentencesThenNoBrokenGrammar() throws {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        let data = try Data(contentsOf: root.appendingPathComponent("MenteViva/Localizable.xcstrings"))
        let catalog = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let strings = try XCTUnwrap(catalog["strings"] as? [String: Any])
        func text(_ key: String, _ language: String) throws -> String {
            let entry = try XCTUnwrap(strings[key] as? [String: Any], key)
            let localizations = try XCTUnwrap(entry["localizations"] as? [String: Any], key)
            let unit = try XCTUnwrap((localizations[language] as? [String: Any])?["stringUnit"] as? [String: Any], key)
            return try XCTUnwrap(unit["value"] as? String, key)
        }
        let broken = ["the In", "the Around", "the Plants", "sean ", "todos: "]
        for language in ["en", "es"] {
            let complete = try text("game.category.complete %@", language)
            let instruction = try text("game.category.instruction", language)
            for category in CategoryDeal.Category.allCases {
                let name = try text(category.nameKey, language)
                let sentences = [String(format: complete, name), instruction + " " + name]
                for sentence in sentences {
                    for fragment in broken {
                        XCTAssertFalse(sentence.contains(fragment), "\(sentence) [\(language)]")
                    }
                }
            }
        }
    }

    /// #392: a decoy tap is silent on screen, but VoiceOver hears this warm line, so the
    /// key must exist in both languages and never scold.
    func testGivenNewCategoryMissKeyWhenCatalogCheckedThenEnglishAndSpanishPresent() throws {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        let data = try Data(contentsOf: root.appendingPathComponent("MenteViva/Localizable.xcstrings"))
        let catalog = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let strings = try XCTUnwrap(catalog["strings"] as? [String: Any])
        let entry = try XCTUnwrap(strings["game.category.miss"] as? [String: Any])
        let localizations = try XCTUnwrap(entry["localizations"] as? [String: Any])
        for language in ["en", "es"] {
            let unit = try XCTUnwrap((localizations[language] as? [String: Any])?["stringUnit"] as? [String: Any])
            let text = try XCTUnwrap(unit["value"] as? String).trimmingCharacters(in: .whitespaces)
            XCTAssertFalse(text.isEmpty, language)
        }
    }
}
