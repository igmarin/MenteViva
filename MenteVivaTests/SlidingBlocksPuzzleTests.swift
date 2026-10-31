import XCTest

@testable import MenteViva

/// #222: sliding blocks solver, generated puzzles and levels.
final class SlidingBlocksPuzzleTests: XCTestCase {
    private struct SeededRNG: RandomNumberGenerator {
        var state: UInt64
        mutating func next() -> UInt64 {
            state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
            return state
        }
    }

    private let bands: [ClosedRange<Int>] = [
        1...3, 3...5, 5...8, 8...12, 12...16, 16...22, 22...30, 30...40, 40...60, 60...Int.max,
    ]

    // MARK: - Levels

    func testGivenLevelsWhenBoardSizesThenSpec() {
        let sizes = [(3, 4), (3, 4), (4, 4), (4, 4), (4, 5), (4, 5), (4, 5), (4, 5), (4, 5), (4, 5)]
        for level in 1...10 {
            for data in SlidingBlocksLevels.puzzles(for: level) {
                XCTAssertEqual(data.width, sizes[level - 1].0, "level \(level)")
                XCTAssertEqual(data.height, sizes[level - 1].1, "level \(level)")
                XCTAssertTrue(data.puzzle.isValid, "level \(level) \(data.layout)")
            }
        }
    }

    func testGivenEveryLevelThenThirtyDistinctUnsolvedPuzzlesInBand() {
        var seen = Set<SlidingBlocksPuzzle>()
        for level in 1...10 {
            let puzzles = SlidingBlocksLevels.puzzles(for: level)
            XCTAssertEqual(puzzles.count, 30, "level \(level)")
            for data in puzzles {
                XCTAssertTrue(bands[level - 1].contains(data.minMoves), "level \(level) \(data.layout)")
                XCTAssertFalse(data.puzzle.isSolved, "level \(level) \(data.layout)")
                XCTAssertTrue(seen.insert(data.puzzle).inserted, "duplicate \(data.layout)")
            }
        }
    }

    func testGivenEveryGeneratedPuzzleWhenSolvedThenMinMovesWithinBand() {
        // Every small-board puzzle, and the first of each 4×5 level (those take
        // about a second each in a debug build; the generator measured all 300).
        for level in 1...10 {
            let puzzles = SlidingBlocksLevels.puzzles(for: level)
            for data in level <= 4 ? puzzles : [puzzles[0]] {
                guard let solution = data.puzzle.solve() else { return XCTFail("level \(level) \(data.layout) unsolvable") }
                XCTAssertEqual(solution.count, data.minMoves, "level \(level) \(data.layout)")
                XCTAssertTrue(bands[level - 1].contains(solution.count), "level \(level) \(data.layout)")
            }
        }
    }

    func testGivenDifficultyWhenPuzzlePickedThenFromThatLevel() {
        var rng = SeededRNG(state: 7)
        for level in 1...10 {
            let data = SlidingBlocksLevels.puzzle(for: Difficulty(level: level), using: &rng)
            XCTAssertTrue(SlidingBlocksLevels.puzzles(for: level).contains(data), "level \(level)")
        }
    }

    // MARK: - Moves

    func testGivenSolvedStateWhenSolveThenEmpty() {
        let p = SlidingBlocksPuzzle(width: 3, height: 4, layout: "o.^/..v/BBo/BBo")
        XCTAssertTrue(p.isSolved)
        XCTAssertEqual(p.solve(), [])
        XCTAssertNil(SlidingBlocksMap(from: p).hint(from: p))
    }

    func testGivenLayoutWhenParsedThenBigFirstAndShapes() {
        let p = SlidingBlocksPuzzle(width: 3, height: 4, layout: "BB^/BBv/<>o/.o.")
        XCTAssertEqual(p.bigIndex, 0)
        XCTAssertEqual(
            p.blocks,
            [
                SlidingBlock(x: 0, y: 0, w: 2, h: 2), SlidingBlock(x: 2, y: 0, w: 1, h: 2),
                SlidingBlock(x: 0, y: 2, w: 2, h: 1), SlidingBlock(x: 2, y: 2, w: 1, h: 1),
                SlidingBlock(x: 1, y: 3, w: 1, h: 1),
            ])
    }

    func testGivenIllegalMovesWhenApplyingThenRejected() {
        // Row 3 is "oo.": the corner cell is free, but the left 1×1 can't jump the middle one to reach it.
        let p = SlidingBlocksPuzzle(width: 3, height: 4, layout: "BB^/BBv/<>./oo.")
        let left = p.blocks.firstIndex(of: SlidingBlock(x: 0, y: 3, w: 1, h: 1))!
        let middle = p.blocks.firstIndex(of: SlidingBlock(x: 1, y: 3, w: 1, h: 1))!
        XCTAssertNotNil(p.applying(SlidingMove(block: middle, direction: .right, steps: 1)))
        XCTAssertNil(p.applying(SlidingMove(block: left, direction: .right, steps: 2)), "jumps a block")
        XCTAssertNil(p.applying(SlidingMove(block: middle, direction: .right, steps: 0)), "zero steps")
        XCTAssertNil(p.applying(SlidingMove(block: 0, direction: .right, steps: 1)), "big is blocked")
        for move in p.moves() { XCTAssertNotNil(p.applying(move), "\(move) should be legal") }
    }

    func testGivenSameShapedBlocksSwappedThenSamePosition() {
        let a = SlidingBlocksPuzzle(width: 3, height: 4, layout: "BBo/BBo/^.o/v.o")
        var swapped = a.blocks
        swapped.swapAt(1, 2)
        XCTAssertEqual(SlidingBlocksPuzzle(width: 3, height: 4, blocks: swapped, bigIndex: 0), a)
    }

    // MARK: - Hints

    func testGivenMidGameWhenHintThenLegalAndOneMoveCloser() {
        for level in [2, 4] {
            var p = SlidingBlocksLevels.puzzles(for: level)[0].puzzle
            let map = SlidingBlocksMap(from: p)
            for _ in 0..<2 {
                guard let left = map.minMoves(from: p), let hint = map.hint(from: p) else {
                    return XCTFail("no hint, level \(level)")
                }
                XCTAssertTrue(p.moves().contains(hint), "hint must be legal")
                XCTAssertTrue(p.apply(hint))
                XCTAssertEqual(map.minMoves(from: p), left - 1, "level \(level)")
            }
        }
    }

    /// Structural, not a stopwatch: a wall-clock ceiling flaked on loaded runners.
    /// A hint that is a pure lookup steps one move closer and never changes.
    func testGivenSolvableBoardWhenHintThenMoveReducesMinMovesByOne() {
        let data = SlidingBlocksLevels.puzzles(for: 10)[0]
        var p = data.puzzle
        let map = SlidingBlocksMap(from: p)
        XCTAssertEqual(map.minMoves(from: p), data.minMoves)
        guard let hint = map.hint(from: p) else { return XCTFail("no hint") }
        for _ in 0..<100 {
            XCTAssertEqual(map.hint(from: p), hint, "the same board always gets the same hint")
        }
        XCTAssertTrue(p.apply(hint))
        XCTAssertEqual(map.minMoves(from: p), data.minMoves - 1)
    }
}
