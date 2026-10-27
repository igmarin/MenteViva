import XCTest

@testable import MenteViva

/// Games registered ahead of their views (#215) stay invisible until each ships.
final class GameIDTests: XCTestCase {

    func testGivenAllGameIDsWhenRawValuesThenUniqueAndExistingUnchanged() {
        let raw = GameID.allCases.map(\.rawValue)
        XCTAssertEqual(Set(raw).count, raw.count)
        let existing = [
            "memory_match", "stroop", "category_fluency", "math_streaks", "quick_eyes",
            "reminiscence", "sudoku", "up_or_down", "sayings",
        ]
        XCTAssertEqual(Array(raw.prefix(existing.count)), existing)
        XCTAssertEqual(
            Set(raw).subtracting(existing), ["repeat_sequence", "tangram", "tile_pairs", "sliding_blocks"])
    }

    func testGivenUnreleasedGamesWhenReleasedThenTheyAreLeftOut() {
        XCTAssertEqual(GameID.unreleased.count, 1)
        XCTAssertTrue(Set(GameID.released).isDisjoint(with: GameID.unreleased))
        XCTAssertEqual(GameID.released.count, GameID.allCases.count - 1)
        XCTAssertTrue(GameID.released.contains(.tilePairs))
        XCTAssertTrue(GameID.released.contains(.tangram))
        XCTAssertTrue(GameID.released.contains(.repeatSequence))
    }
}
