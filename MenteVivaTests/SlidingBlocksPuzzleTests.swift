import XCTest
@testable import MenteViva
import Foundation

final class SlidingBlocksPuzzleTests: XCTestCase {

    // MARK: - Helpers

    private func makeSolvedPuzzle(width: Int, height: Int) -> SlidingBlocksPuzzle {
        let ex = (width - 2) / 2
        let ty = height - 2
        return SlidingBlocksPuzzle(width: width, height: height, blocks: [
            SlidingBlock(id: 0, x: ex, y: ty, w: 2, h: 2)
        ])
    }

    // MARK: - Acceptance

    func testGivenEveryGeneratedPuzzleWhenSolvedThenMinMovesWithinBand() {
        for level in 1...10 {
            let band = SlidingBlocksPuzzle.minMovesPerLevel[level - 1]
            let puzzles = SlidingBlocksLevels.puzzlesPerLevel[level - 1]
            XCTAssertEqual(puzzles.count, 30, "level \(level) should have 30 puzzles")
            for (idx, puzzle) in puzzles.enumerated() {
                guard let sol = puzzle.solve() else {
                    XCTFail("level \(level) puzzle \(idx) unsolvable")
                    continue
                }
                XCTAssertTrue(band.contains(sol.count), "level \(level) puzzle \(idx) has \(sol.count) not in \(band)")
            }
        }
    }

    func testGivenSolvedStateWhenSolveThenEmptyList() {
        let puzzle = makeSolvedPuzzle(width: 4, height: 5)
        XCTAssertTrue(puzzle.isSolved)
        let sol = puzzle.solve()
        XCTAssertEqual(sol, [], "solved puzzle should return empty list")
    }

    func testGivenMidGameStateWhenHintThenLegalAndKeepsSolvable() {
        // Take first puzzle of level 5 (4×5) and walk a few moves to a mid state.
        let start = SlidingBlocksLevels.puzzlesPerLevel[4].first!
        guard let full = start.solve() else { XCTFail("start unsolvable"); return }
        XCTAssertFalse(full.isEmpty)
        // Apply first 2 moves to get mid state.
        var mid = start
        let take = min(2, full.count)
        for i in 0..<take { mid = mid.applying(full[i]) }
        XCTAssertFalse(mid.isSolved)
        guard let hint = mid.hint() else { XCTFail("hint nil"); return }
        let legal = mid.moves()
        XCTAssertTrue(legal.contains(hint), "hint must be legal")
        let after = mid.applying(hint)
        XCTAssertNotNil(after.solve(), "hint must keep puzzle solvable")
    }

    func testGivenGeneratorRunTwiceWithSameSeedThenOutputIdentical() {
        // Determinism via SeededGenerator: same seed produces same puzzle sequence.
        // We test the puzzle picker, not the full file generation (which is slow).
        var gen1 = SeededRNG(state: 42)
        var gen2 = SeededRNG(state: 42)
        let diff = Difficulty(level: 5)
        let p1 = SlidingBlocksLevels.puzzle(for: diff, using: &gen1)
        let p2 = SlidingBlocksLevels.puzzle(for: diff, using: &gen2)
        XCTAssertEqual(p1?.index, p2?.index, "same seed must give same puzzle")
        XCTAssertEqual(p1?.puzzle, p2?.puzzle)
    }

    // Minimal seeded RNG for the test above (mirrors tool's SeededGenerator).
    private struct SeededRNG: RandomNumberGenerator {
        var state: UInt64
        mutating func next() -> UInt64 {
            state = state &* 6364136223846793005 &+ 1442695040888963407
            return state
        }
    }

    func testGivenBlockedPathWhenMovesThenOnlyLegalSlides() {
        // 3×4 board, target at (0,0) blocked on right and down by 1×1 blocks.
        let puzzle = SlidingBlocksPuzzle(width: 3, height: 4, blocks: [
            SlidingBlock(id: 0, x: 0, y: 0, w: 2, h: 2),
            SlidingBlock(id: 1, x: 2, y: 0, w: 1, h: 1),
            SlidingBlock(id: 2, x: 0, y: 2, w: 1, h: 1),
            SlidingBlock(id: 3, x: 1, y: 2, w: 1, h: 1),
        ])
        let moves = puzzle.moves()
        // Target at (0,0) on 3×4: can only move down if clear, but (0,2) blocks.
        // So target should have no legal moves.
        let targetMoves = moves.filter { $0.blockId == 0 }
        XCTAssertTrue(targetMoves.isEmpty, "blocked target should have no moves, got \(targetMoves)")
        // Other blocks may have moves, but all must be within board and not overlapping.
        for m in moves {
            let after = puzzle.applying(m)
            // After move, no two blocks overlap and all inside board.
            var occupied = Set<String>()
            for b in after.blocks {
                XCTAssertTrue(b.x >= 0 && b.y >= 0 && b.x + b.w <= after.width && b.y + b.h <= after.height, "block \(b.id) out of bounds after \(m)")
                for dy in 0..<b.h {
                    for dx in 0..<b.w {
                        let key = "\(b.x+dx),\(b.y+dy)"
                        XCTAssertFalse(occupied.contains(key), "overlap at \(key) after \(m)")
                        occupied.insert(key)
                    }
                }
            }
        }
    }

    func testGivenSeedWhenGeneratingThenSolvableAndDifficultyRises() {
        // Use the generated levels to verify solvability and monotonic difficulty.
        var previousMin = 0
        var previousMax = 0
        for level in 1...10 {
            let puzzles = SlidingBlocksLevels.puzzlesPerLevel[level - 1]
            var mins: [Int] = []
            for p in puzzles {
                guard let sol = p.solve() else { XCTFail("level \(level) unsolvable"); continue }
                mins.append(sol.count)
            }
            let avg = mins.reduce(0, +) / max(1, mins.count)
            // Difficulty should not decrease: average of this level >= previous level's average (allow small variance)
            // We check that the minimum of this level is >= minimum of previous level's minimum-1 to allow overlap bands.
            if let minThis = mins.min(), let _ = mins.max() {
                XCTAssertGreaterThanOrEqual(minThis, previousMin - 1, "level \(level) min \(minThis) should not be much less than previous min \(previousMin)")
                // Overall average should be non-decreasing (allow 1 move tolerance due to band overlap)
                XCTAssertGreaterThanOrEqual(avg, previousMax - 2, "level \(level) avg \(avg) should be >= previous max \(previousMax) -2")
                previousMin = minThis
                if let maxThis = mins.max() { previousMax = maxThis }
            }
        }
    }

    func testGivenHintPerformanceThenUnder50ms() {
        // HINT must stay fast for 4×5. Measure solve/hint for a mid 4×5 puzzle.
        let puzzle = SlidingBlocksLevels.puzzlesPerLevel[9].first ?? SlidingBlocksLevels.puzzlesPerLevel[4].first!
        measure {
            _ = puzzle.hint()
        }
        // Also assert single hint < 50ms in a non-measure way (rough).
        let start = CFAbsoluteTimeGetCurrent()
        _ = SlidingBlocksPuzzle.hint(from: puzzle)
        let elapsed = CFAbsoluteTimeGetCurrent() - start
        XCTAssertLessThan(elapsed, 0.05, "hint should be <50ms, was \(elapsed)")
    }
}
