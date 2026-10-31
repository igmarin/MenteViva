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

    /// An iPad-sized board: room for every decoy of every level.
    private static let wide = CGSize(width: 700, height: 2000)
    /// The board on an iPhone SE: three columns, and the height left under the banner and the header
    /// for three rows (3 x 100pt and two 16pt gaps is 332pt), so two decoys fit.
    private static let iPhoneSE = CGSize(width: 343, height: 351)
    /// The board on a tall iPhone: three columns and three rows.
    private static let tallPhone = CGSize(width: 361, height: 430)

    private func deal(
        _ level: Int, seed: UInt64, size: CGSize = wide, categories: [CategoryDeal.Category]? = nil
    ) -> [CategoryDeal.Round] {
        var generator = SeededGenerator(state: seed)
        return CategoryDeal.deal(
            difficulty: Difficulty(level: level), size: size, categories: categories, using: &generator)
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
            let decoys = CategoryDeal.fittedDecoyCount(for: Difficulty(level: level), size: Self.wide)
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

    /// The tiles that fit the measured board (#415): 3 columns x 3 rows on a tall phone is 9 tiles,
    /// so 7 items leave room for 2 decoys, whatever the level asks for.
    func testGivenLevelTenOnATallPhoneWhenDealtThenDecoysFillOnlyTheRowsThatFit() {
        XCTAssertEqual(CategoryDeal.fittedDecoyCount(for: Difficulty(level: 10), size: Self.tallPhone), 2)
        for seed in 1...100 {
            for round in deal(10, seed: UInt64(seed), size: Self.tallPhone) {
                XCTAssertEqual(round.tiles.count, 7 + 2, "seed \(seed)")
            }
        }
    }

    func testGivenABoardTooShortForTheSevenItemsWhenFittedThenNoDecoysAndNeverBelowZero() {
        let short = CGSize(width: 343, height: 200)  // 3 x 1 tiles: fewer than the 7 items
        for level in 1...10 {
            XCTAssertEqual(CategoryDeal.fittedDecoyCount(for: Difficulty(level: level), size: short), 0)
        }
        XCTAssertEqual(CategoryDeal.fittedDecoyCount(for: Difficulty(level: 10), size: CGSize(width: 90, height: 900)), 0)
        XCTAssertEqual(CategoryDeal.fittedDecoyCount(for: Difficulty(level: 10), size: .zero), 0)
    }

    func testGivenTheSameWidthWhenTheBoardGrowsTallerThenMoreDecoysFitUpToTheLevel() {
        let heights = [300.0, 430, 550, 650, 2000]
        let counts = heights.map {
            CategoryDeal.fittedDecoyCount(
                for: Difficulty(level: 10), size: CGSize(width: 361, height: $0))
        }
        XCTAssertEqual(counts, [0, 2, 5, 8, 11])
    }

    /// Larger text widens the column minimum, so fewer tiles fit the same board.
    func testGivenATileWiderThanTheFloorWhenFittedThenFewerDecoysFit() {
        let size = CGSize(width: 361, height: 700)
        let normal = CategoryDeal.fittedDecoyCount(for: Difficulty(level: 10), size: size)
        let large = CategoryDeal.fittedDecoyCount(for: Difficulty(level: 10), size: size, tile: 140)
        XCTAssertLessThan(large, normal)
        XCTAssertEqual(CategoryDeal.fittedDecoyCount(for: Difficulty(level: 10), size: size, tile: 40), normal)
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

    /// An iPhone SE fits fewer tiles than the table wants, but never none: a board with no wrong
    /// answer is not the game (#415).
    func testGivenANarrowScreenAtLevelTenWhenDealtThenDecoysAreCappedForTheBoardButNeverZero() {
        let wide = CategoryDeal.fittedDecoyCount(for: Difficulty(level: 10), size: Self.wide)
        let narrow = CategoryDeal.fittedDecoyCount(for: Difficulty(level: 10), size: Self.iPhoneSE)
        XCTAssertGreaterThan(narrow, 0)
        XCTAssertLessThan(narrow, wide)
        XCTAssertEqual(narrow, 2)
        for level in 1...10 {
            XCTAssertGreaterThan(
                CategoryDeal.fittedDecoyCount(for: Difficulty(level: level), size: Self.iPhoneSE), 0, "level \(level)")
        }
        for round in deal(10, seed: 3, size: Self.iPhoneSE) {
            XCTAssertEqual(round.tiles.count, 7 + narrow)
            XCTAssertEqual(round.tiles.filter { !$0.belongs }.count, narrow)
        }
    }

    // MARK: - When to deal (#415)

    func testGivenNoSessionWhenShouldDealThenDeal() {
        XCTAssertTrue(CategoryDeal.shouldDeal(hasSession: false, picks: 0, dealt: nil, fitted: 2))
        XCTAssertTrue(CategoryDeal.shouldDeal(hasSession: false, picks: 0, dealt: 2, fitted: 2))
    }

    func testGivenAPickWhenTheFitChangesThenNeverDeal() {
        XCTAssertFalse(CategoryDeal.shouldDeal(hasSession: true, picks: 1, dealt: 2, fitted: 5))
        XCTAssertFalse(CategoryDeal.shouldDeal(hasSession: true, picks: 9, dealt: 5, fitted: 0))
    }

    func testGivenTheSameFitWhenNothingPickedThenDoNotDealAgain() {
        XCTAssertFalse(CategoryDeal.shouldDeal(hasSession: true, picks: 0, dealt: 2, fitted: 2))
    }

    func testGivenAChangedFitWhenNothingPickedThenDealAgain() {
        XCTAssertTrue(CategoryDeal.shouldDeal(hasSession: true, picks: 0, dealt: 2, fitted: 5))
        XCTAssertTrue(CategoryDeal.shouldDeal(hasSession: true, picks: 0, dealt: nil, fitted: 2))
    }

    /// A deal again for a new fit keeps the categories, so the screen never swaps the name under the
    /// player's eyes or announces a second one.
    func testGivenTheSessionsCategoriesWhenDealtAgainThenTheSameCategoriesInTheSameOrder() {
        for seed in 1...50 {
            let first = deal(10, seed: UInt64(seed), size: Self.iPhoneSE)
            let again = deal(
                10, seed: UInt64(seed) + 1000, size: Self.tallPhone, categories: first.map(\.category))
            XCTAssertEqual(again.map(\.category), first.map(\.category), "seed \(seed)")
            for round in again {
                XCTAssertEqual(round.tiles.filter(\.belongs).count, 7)
            }
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
        let decoys = CategoryDeal.fittedDecoyCount(for: Difficulty(level: 10), size: Self.wide)
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

    // MARK: - Tried decoys (#415)

    func testGivenAnUntouchedItemWhenTappedThenItIsFound() {
        XCTAssertEqual(CategoryDeal.tapOutcome(belongs: true, isPicked: false, isTried: false), .found)
    }

    func testGivenAnUntouchedDecoyWhenTappedThenItIsAMiss() {
        XCTAssertEqual(CategoryDeal.tapOutcome(belongs: false, isPicked: false, isTried: false), .miss)
    }

    /// A tried decoy counts once: a second tap adds no attempt and plays no sound.
    func testGivenATriedDecoyWhenTappedAgainThenItIsIgnored() {
        XCTAssertEqual(CategoryDeal.tapOutcome(belongs: false, isPicked: false, isTried: true), .ignored)
    }

    func testGivenAFoundItemWhenTappedAgainThenItIsIgnored() {
        XCTAssertEqual(CategoryDeal.tapOutcome(belongs: true, isPicked: true, isTried: false), .ignored)
    }

    func testGivenTriedKeyWhenCatalogCheckedThenEnglishAndSpanishPresent() throws {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        let data = try Data(contentsOf: root.appendingPathComponent("MenteViva/Localizable.xcstrings"))
        let catalog = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let strings = try XCTUnwrap(catalog["strings"] as? [String: Any])
        let entry = try XCTUnwrap(strings["game.category.a11y.tried"] as? [String: Any])
        let localizations = try XCTUnwrap(entry["localizations"] as? [String: Any])
        let expected = ["en": "Not in this group", "es": "No es de este grupo"]
        for (language, line) in expected {
            let unit = try XCTUnwrap((localizations[language] as? [String: Any])?["stringUnit"] as? [String: Any])
            XCTAssertEqual(unit["value"] as? String, line, language)
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
        let expected = [
            "en": "Not in this group, try another",
            "es": "Ese no es de este grupo, prueba otro",
        ]
        for (language, line) in expected {
            let unit = try XCTUnwrap((localizations[language] as? [String: Any])?["stringUnit"] as? [String: Any])
            XCTAssertEqual(unit["value"] as? String, line, language)
        }
    }
}
