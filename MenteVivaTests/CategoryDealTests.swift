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

    func testGivenEveryCategoryWhenDealtThenNoItemAppearsInTwoCategories() {
        let items = CategoryDeal.Category.allCases.flatMap(\.items)
        XCTAssertEqual(items.count, CategoryDeal.Category.allCases.count * 7)
        XCTAssertEqual(Set(items).count, items.count)
        for seed in 1...200 {
            for round in deal(10, seed: UInt64(seed)) {
                // A tile is right only when it is one of the asked category's seven.
                for tile in round.tiles {
                    XCTAssertEqual(tile.belongs, round.category.items.contains(tile.picture), "seed \(seed)")
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
        XCTAssertEqual(CategoryDeal.decoyPool(for: .fruits).count, 27)  // minus kitchen, plants, the orange swatch
        XCTAssertEqual(CategoryDeal.smallestPoolSize, 27)
        XCTAssertGreaterThanOrEqual(CategoryDeal.smallestPoolSize, CategoryDeal.decoysByLevel.max() ?? 0)
    }

    func testGivenLevelTenOnTheNarrowestPhoneWhenDealtThenEveryTileFitsAtLeastTheMinimum() {
        let width = 343.0
        let columns = Int(
            (width - CategoryDeal.horizontalPadding + CategoryDeal.tileGap)
                / (CategoryDeal.tileMin + CategoryDeal.tileGap))
        let tileWidth =
            (width - CategoryDeal.horizontalPadding - Double(columns - 1) * CategoryDeal.tileGap)
            / Double(columns)
        XCTAssertGreaterThanOrEqual(tileWidth, CategoryDeal.tileMin)
        for seed in 1...100 {
            for round in deal(10, seed: UInt64(seed), width: width) {
                XCTAssertLessThanOrEqual(round.tiles.count, columns * 6, "seed \(seed)")
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
}
