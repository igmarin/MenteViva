import XCTest

@testable import MenteViva

/// Memory Lane levels 1–10 (#199): the pairs table and the small-screen cap.
final class MemoryMatchLevelsTests: XCTestCase {
    /// 375pt screen minus the 16pt gutters, with a short board area so level
    /// 10 cannot fit uncapped.
    private static let smallBoard = CGSize(width: 343, height: 400)

    func testGivenLevelsTwoFourSixWhenPairCountThenMatchesOldEasyMediumHard() {
        let counts = [2, 4, 6].map { MemoryMatchView.pairCount(for: Difficulty(level: $0)) }
        XCTAssertEqual(counts, [4, 6, 8])
    }

    func testGivenRisingLevelsWhenPairCountThenNeverDecreases() {
        let counts = (1...10).map { MemoryMatchView.pairCount(for: Difficulty(level: $0)) }
        XCTAssertEqual(counts, [3, 4, 5, 6, 7, 8, 9, 10, 11, 12])
        for pair in zip(counts, counts.dropFirst()) {
            XCTAssertLessThanOrEqual(pair.0, pair.1)
        }
    }

    func testGivenLevelTenWhenFacesThenEveryThemeSuppliesTwelvePairs() {
        for theme in MemoryDeal.themes {
            XCTAssertGreaterThanOrEqual(Set(theme).count, 12)
            XCTAssertEqual(MemoryDeal.faces(photos: [], theme: theme, pairs: 12).count, 12)
        }
    }

    func testGivenSmallScreenAtLevelSixWhenPairCountThenTheOldHardBoardStillFits() {
        // Migrated "hard" players keep their 8 pairs on a small iPhone.
        XCTAssertEqual(MemoryMatchView.cappedPairs(for: Difficulty(level: 6), in: Self.smallBoard), 8)
    }

    func testGivenNoRoomEvenForLevelOneWhenPairCountThenLevelOnesBoardIsTheFloor() {
        let tiny = CGSize(width: 100, height: 100)
        XCTAssertEqual(MemoryMatchView.cappedPairs(for: Difficulty(level: 10), in: tiny), 3)
        XCTAssertEqual(MemoryMatchView.cappedPairs(for: Difficulty(level: 1), in: .zero), 3)
    }

    func testGivenSmallScreenAtLevelTenWhenPairCountThenCappedToFit() {
        let pairs = MemoryMatchView.cappedPairs(for: Difficulty(level: 10), in: Self.smallBoard)
        XCTAssertLessThan(pairs, 12)
        let fit = MemoryMatchView.gridFit(count: pairs * 2, in: Self.smallBoard, spacing: 12)
        XCTAssertGreaterThanOrEqual(min(fit.card.width, fit.card.height), MemoryMatchView.minCard)
    }
}
