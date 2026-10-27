import XCTest

@testable import MenteViva

/// #179: Sudoku boards are made on the device, new every time, with exactly one solution.
final class SudokuPuzzleTests: XCTestCase {
    /// Deterministic generator so the property runs never flake.
    private struct SeededGenerator: RandomNumberGenerator {
        var state: UInt64
        mutating func next() -> UInt64 {
            state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
            return state
        }
    }

    private static let wide = 700.0
    private static let iPhoneSE = 343.0  // 375pt screen minus the 16pt gutters

    /// Every level on both widths: easy, medium, hard (6×6) and hard on a narrow screen (4×4).
    private static let cases: [(Difficulty, Double)] = [
        (.easy, wide), (.medium, wide), (.hard, wide), (.hard, iPhoneSE),
    ]

    private func puzzles(_ difficulty: Difficulty, width: Double, count: Int = 50) -> [SudokuPuzzle] {
        (1...count).map { seed in
            var generator = SeededGenerator(state: UInt64(seed))
            return SudokuPuzzle.make(difficulty: difficulty, width: width, using: &generator)
        }
    }

    func testGivenEachLevelOnAWideScreenWhenLayoutThenSizeAndBlanksMatchSpec() {
        XCTAssertEqual(SudokuPuzzle.layout(for: .easy, width: Self.wide).size, 4)
        XCTAssertEqual(SudokuPuzzle.layout(for: .easy, width: Self.wide).blanks, 4)
        XCTAssertEqual(SudokuPuzzle.layout(for: .medium, width: Self.wide).size, 4)
        XCTAssertEqual(SudokuPuzzle.layout(for: .medium, width: Self.wide).blanks, 8)
        XCTAssertEqual(SudokuPuzzle.layout(for: .hard, width: Self.wide).size, 6)
        XCTAssertEqual(SudokuPuzzle.layout(for: .hard, width: Self.wide).blanks, 18)
    }

    func testGivenHardOnAnIPhoneSEWidthWhenLayoutThenItFallsBackToFourByFourWithTenBlanks() {
        // 343 / 6 = 57pt, under the 60pt floor.
        XCTAssertEqual(SudokuPuzzle.layout(for: .hard, width: Self.iPhoneSE).size, 4)
        XCTAssertEqual(SudokuPuzzle.layout(for: .hard, width: Self.iPhoneSE).blanks, 10)
    }

    func testGivenTopLevelsOnAnIPhoneSEWidthWhenLayoutThenFourByFourThatFits() {
        // 9×9 wants 9×60 + 8×2 = 556pt and the 6×6 fallback wants 370pt:
        // neither fits 343pt, so levels 9–10 step down to a 4×4 that does
        // ((343 − 3×2) / 4 = 84pt a square).
        for level in [9, 10] {
            let layout = SudokuPuzzle.layout(
                for: Difficulty(level: level), width: Self.iPhoneSE)
            XCTAssertEqual(layout.size, 4, "level \(level)")
            XCTAssertEqual(layout.blanks, 12, "level \(level)")
        }
    }

    func testGivenAWidthThatFitsSixSquaresButNotTheirGapsWhenHardLayoutThenFourByFour() {
        // (365 - 5 gaps × 2pt) / 6 = 59.2pt: under the floor once the gaps count.
        XCTAssertEqual(SudokuPuzzle.layout(for: .hard, width: 365).size, 4)
        // (370 - 10) / 6 = 60pt: just fits.
        XCTAssertEqual(SudokuPuzzle.layout(for: .hard, width: 370).size, 6)
    }

    func testGivenASixBySixBoardWhenTheScreenNarrowsThenItNoLongerFits() {
        // Dealt in landscape on an iPhone SE, then turned to portrait.
        var generator = SeededGenerator(state: 1)
        let board = SudokuPuzzle.make(difficulty: .hard, width: 600, using: &generator)
        XCTAssertEqual(board.size, 6)
        XCTAssertTrue(board.fits(width: 600))
        XCTAssertFalse(board.fits(width: Self.iPhoneSE))
    }

    func testGivenFiftySeedsWhenMakeThenEverySolutionIsAValidGrid() {
        for (difficulty, width) in Self.cases {
            for puzzle in puzzles(difficulty, width: width) {
                let n = puzzle.size
                let all = Set(1...n)
                for r in 0..<n {
                    XCTAssertEqual(Set((0..<n).map { puzzle.solution[r * n + $0] }), all, "row \(r)")
                }
                for c in 0..<n {
                    XCTAssertEqual(Set((0..<n).map { puzzle.solution[$0 * n + c] }), all, "column \(c)")
                }
                for top in stride(from: 0, to: n, by: puzzle.boxRows) {
                    for left in stride(from: 0, to: n, by: puzzle.boxColumns) {
                        let box = (0..<puzzle.boxRows).flatMap { r in
                            (0..<puzzle.boxColumns).map { c in puzzle.solution[(top + r) * n + left + c] }
                        }
                        XCTAssertEqual(Set(box), all, "box at \(top),\(left)")
                    }
                }
            }
        }
    }

    func testGivenFiftySeedsWhenMakeThenGivensHaveExactlyOneSolution() {
        for (difficulty, width) in Self.cases {
            for puzzle in puzzles(difficulty, width: width) {
                let grid = puzzle.solution.indices.map { puzzle.givens.contains($0) ? puzzle.solution[$0] : nil }
                XCTAssertEqual(
                    SudokuPuzzle.solutionCount(
                        grid, size: puzzle.size, boxRows: puzzle.boxRows, boxColumns: puzzle.boxColumns, limit: 2),
                    1)
            }
        }
    }

    func testGivenFiftySeedsWhenMakeThenBlankCountEqualsLayout() {
        for (difficulty, width) in Self.cases {
            let layout = SudokuPuzzle.layout(for: difficulty, width: width)
            for puzzle in puzzles(difficulty, width: width) {
                XCTAssertEqual(puzzle.size, layout.size)
                XCTAssertEqual(puzzle.size * puzzle.size - puzzle.givens.count, layout.blanks)
            }
        }
    }

    func testGivenTheSameSeedWhenMakeTwiceThenPuzzlesAreEqual() {
        XCTAssertEqual(puzzles(.hard, width: Self.wide, count: 3), puzzles(.hard, width: Self.wide, count: 3))
    }

    func testGivenDifferentSeedsWhenMakeThenBoardsVary() {
        XCTAssertGreaterThan(Set(puzzles(.medium, width: Self.wide).map(\.solution)).count, 10)
    }

    func testGivenAnEmptyFourByFourWhenCountingWithLimitTwoThenItStopsAtTwo() {
        let empty = [Int?](repeating: nil, count: 16)
        XCTAssertEqual(SudokuPuzzle.solutionCount(empty, size: 4, boxRows: 2, boxColumns: 2, limit: 2), 2)
    }

    // MARK: - #201: ten levels

    func testGivenLevelsTwoFourSixWhenLayoutThenMatchesOldEasyMediumHard() {
        let wide = [2, 4, 6].map { SudokuPuzzle.layout(for: Difficulty(level: $0), width: Self.wide) }
        XCTAssertEqual(wide.map(\.size), [4, 4, 6])
        XCTAssertEqual(wide.map(\.blanks), [4, 8, 18])
        let narrow = [2, 4, 6].map { SudokuPuzzle.layout(for: Difficulty(level: $0), width: Self.iPhoneSE) }
        XCTAssertEqual(narrow.map(\.size), [4, 4, 4])
        XCTAssertEqual(narrow.map(\.blanks), [4, 8, 10])
    }

    func testGivenRisingLevelsWhenLayoutThenNeverEasier() {
        let layouts = (1...10).map { SudokuPuzzle.layout(for: Difficulty(level: $0), width: Self.wide) }
        XCTAssertEqual(layouts.map(\.size), [4, 4, 4, 4, 4, 6, 6, 6, 9, 9])
        for pair in zip(layouts.map(\.blanks), layouts.map(\.blanks).dropFirst()) {
            XCTAssertLessThanOrEqual(pair.0, pair.1)
        }
    }

    func testGivenMidWidthAtLevelNineWhenLayoutThenFallsBackToSixBySix() {
        // 400pt fits the 6×6 fallback (6×60 + 5×2 = 370pt) but not 9×9 (556pt).
        XCTAssertEqual(SudokuPuzzle.layout(for: Difficulty(level: 9), width: 400).size, 6)
        XCTAssertEqual(SudokuPuzzle.layout(for: Difficulty(level: 9), width: 400).blanks, 26)
    }

    func testGivenNineByNineSeedsWhenGeneratedThenExactlyOneSolutionAndFullBlanks() {
        for seed in 1...3 {
            var generator = SeededGenerator(state: UInt64(seed))
            let puzzle = SudokuPuzzle.make(
                difficulty: Difficulty(level: 10), width: Self.wide, using: &generator)
            XCTAssertEqual(puzzle.size, 9)
            XCTAssertEqual(puzzle.size * puzzle.size - puzzle.givens.count, 46)
            let grid = puzzle.solution.indices.map {
                puzzle.givens.contains($0) ? puzzle.solution[$0] : nil
            }
            XCTAssertEqual(
                SudokuPuzzle.solutionCount(
                    grid, size: 9, boxRows: 3, boxColumns: 3, limit: 2),
                1)
        }
    }

    // MARK: - #239: a small reward for every finished row, column and box

    /// A valid 4×4 solution; these tests fill its rows and boxes by hand.
    private static let tinySolution = [1, 2, 3, 4, 3, 4, 1, 2, 2, 1, 4, 3, 4, 3, 2, 1]

    private func tinyPuzzle() -> SudokuPuzzle {
        SudokuPuzzle(size: 4, boxRows: 2, boxColumns: 2, solution: Self.tinySolution, givens: [])
    }

    func testGivenLastSquareOfRowWhenPlacedThenRowCompleted() {
        let entries = [0: 1, 1: 2, 2: 3, 3: 4]
        XCTAssertEqual(tinyPuzzle().completedUnits(after: 3, entries: entries), [.row(0)])
    }

    func testGivenPlacementCompletingRowAndBoxWhenPlacedThenBothReported() {
        // Square 1 finishes row 0 {0, 1, 2, 3} and box 0 {0, 1, 4, 5} together.
        let entries = [0: 1, 1: 2, 2: 3, 3: 4, 4: 3, 5: 4]
        XCTAssertEqual(tinyPuzzle().completedUnits(after: 1, entries: entries), [.row(0), .box(0)])
    }

    func testGivenWrongDigitWhenPlacedThenNoUnitCompleted() {
        let entries = [0: 1, 1: 2, 2: 3, 3: 1]
        XCTAssertEqual(tinyPuzzle().completedUnits(after: 3, entries: entries), [])
    }

    func testGivenUnitDoneKeysWhenCatalogReadThenEveryKeyHasEnglishAndSpanish() throws {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        let data = try Data(contentsOf: root.appendingPathComponent("MenteViva/Localizable.xcstrings"))
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let strings = try XCTUnwrap(json["strings"] as? [String: Any])
        for key in ["game.sudoku.done.row %lld", "game.sudoku.done.column %lld", "game.sudoku.done.box %lld"] {
            let localizations = (strings[key] as? [String: Any])?["localizations"] as? [String: Any]
            XCTAssertNotNil(localizations?["en"], "\(key) has no English")
            XCTAssertNotNil(localizations?["es"], "\(key) has no Spanish")
        }
    }
}
