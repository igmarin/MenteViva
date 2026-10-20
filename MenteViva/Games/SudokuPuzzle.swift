import Foundation

/// One Sudoku board (#179), made on the device so no two games look alike. Every
/// board has exactly one solution, so "the right number" is never ambiguous.
nonisolated struct SudokuPuzzle: Equatable {
    let size: Int  // 4 or 6
    let boxRows: Int  // 2
    let boxColumns: Int  // 2 (4×4) or 3 (6×6)
    let solution: [Int]  // row-major, size * size values in 1...size
    let givens: Set<Int>  // indices shown at the start

    /// Smallest square the player taps, in points (conventions §4).
    static let minTarget = 60.0
    /// Space between squares on screen; it counts against the width too.
    static let gap = 2.0
    private static let attempts = 20

    /// Board size and blanks for a level. Hard is 6×6 only where its squares keep 60pt;
    /// on narrower screens (iPhone SE) it stays 4×4 with more blanks.
    static func layout(for difficulty: Difficulty, width: Double) -> (size: Int, blanks: Int) {
        switch difficulty {
        case .easy: (4, 4)
        case .medium: (4, 8)
        case .hard: squaresFit(6, in: width) ? (6, 18) : (4, 10)
        }
    }

    static func make<G: RandomNumberGenerator>(
        difficulty: Difficulty, width: Double, using generator: inout G
    ) -> SudokuPuzzle {
        let (size, blanks) = layout(for: difficulty, width: width)
        let boxColumns = size == 6 ? 3 : 2
        var best: (puzzle: SudokuPuzzle, removed: Int)?
        for _ in 0..<attempts {
            let solution = solvedGrid(size: size, boxRows: 2, boxColumns: boxColumns, using: &generator)
            var grid = solution.map { Optional($0) }
            var removed = 0
            // Keep a removal only while the board still has exactly one solution.
            for index in grid.indices.shuffled(using: &generator) where removed < blanks {
                let kept = grid[index]
                grid[index] = nil
                if solutionCount(grid, size: size, boxRows: 2, boxColumns: boxColumns, limit: 2) == 1 {
                    removed += 1
                } else {
                    grid[index] = kept
                }
            }
            let puzzle = SudokuPuzzle(
                size: size, boxRows: 2, boxColumns: boxColumns, solution: solution,
                givens: Set(grid.indices.filter { grid[$0] != nil }))
            if removed == blanks { return puzzle }
            if removed > best?.removed ?? -1 { best = (puzzle, removed) }
        }
        return best!.puzzle
    }

    /// Whether this board's squares keep 60pt at `width`. A 6×6 board dealt in landscape
    /// on a small iPhone stops fitting when the phone turns to portrait.
    func fits(width: Double) -> Bool { Self.squaresFit(size, in: width) }

    private static func squaresFit(_ count: Int, in width: Double) -> Bool {
        (width - gap * Double(count - 1)) / Double(count) >= minTarget
    }

    /// Solutions of a partly filled grid, counting no further than `limit`.
    static func solutionCount(_ grid: [Int?], size: Int, boxRows: Int, boxColumns: Int, limit: Int) -> Int {
        guard let empty = grid.firstIndex(of: nil) else { return 1 }
        var grid = grid
        var count = 0
        for digit in 1...size where allows(digit, at: empty, in: grid, size: size, boxRows: boxRows, boxColumns: boxColumns) {
            grid[empty] = digit
            count += solutionCount(grid, size: size, boxRows: boxRows, boxColumns: boxColumns, limit: limit - count)
            if count >= limit { break }
        }
        return count
    }

    private static func allows(
        _ digit: Int, at index: Int, in grid: [Int?], size: Int, boxRows: Int, boxColumns: Int
    ) -> Bool {
        let row = index / size
        let column = index % size
        let top = row - row % boxRows
        let left = column - column % boxColumns
        for i in 0..<size {
            if grid[row * size + i] == digit || grid[i * size + column] == digit { return false }
            if grid[(top + i / boxColumns) * size + left + i % boxColumns] == digit { return false }
        }
        return true
    }

    /// A solved grid from the classic base pattern, shuffled by digits, rows inside
    /// bands, bands, columns inside stacks and stacks: all moves that keep it valid.
    private static func solvedGrid<G: RandomNumberGenerator>(
        size: Int, boxRows: Int, boxColumns: Int, using generator: inout G
    ) -> [Int] {
        let digits = Array(1...size).shuffled(using: &generator)
        let rows = order(groups: size / boxRows, of: boxRows, using: &generator)
        let columns = order(groups: size / boxColumns, of: boxColumns, using: &generator)
        return (0..<size * size).map { index in
            let r = rows[index / size]
            let c = columns[index % size]
            return digits[(boxColumns * (r % boxRows) + r / boxRows + c) % size]
        }
    }

    private static func order<G: RandomNumberGenerator>(groups: Int, of length: Int, using generator: inout G) -> [Int] {
        (0..<groups).shuffled(using: &generator).flatMap { group in
            (0..<length).shuffled(using: &generator).map { group * length + $0 }
        }
    }
}
