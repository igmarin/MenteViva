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
                    XCTAssertEqual(right.map(\.emoji).sorted(), round.category.items.sorted(), "level \(level) seed \(seed)")
                    // Decoys are all from other categories, never repeated.
                    XCTAssertEqual(wrong.count, decoys, "level \(level) seed \(seed)")
                    XCTAssertEqual(Set(wrong.map(\.emoji)).count, wrong.count, "level \(level) seed \(seed)")
                    XCTAssertTrue(
                        wrong.allSatisfy { !round.category.items.contains($0.emoji) },
                        "level \(level) seed \(seed)")
                    XCTAssertEqual(Set(round.tiles.map(\.emoji)).count, round.tiles.count, "level \(level) seed \(seed)")
                }
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
}
