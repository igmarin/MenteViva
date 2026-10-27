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

    /// One row per level 1...10 (#201): the wanted board and, when its squares
    /// would drop under 60pt, the fallback board (`nil` where the wanted board
    /// fits everywhere the app runs). Levels 2/4/6 keep the old easy/medium/hard
    /// boards (4×4 with 4/8 blanks, 6×6 with 18) so migrated players notice
    /// nothing; boards grow 4×4 → 6×6 → 9×9 and blanks never shrink, so a higher
    /// level is never easier.
    typealias BoardSpec = (size: Int, blanks: Int)
    static let layoutsPerLevel: [(wanted: BoardSpec, fallback: BoardSpec?)] = [
        ((4, 3), nil),
        ((4, 4), nil),
        ((4, 6), nil),
        ((4, 8), nil),
        ((4, 10), nil),
        ((6, 18), (4, 10)),
        ((6, 21), (4, 11)),
        ((6, 24), (4, 12)),
        ((9, 40), (6, 26)),
        ((9, 46), (6, 28)),
    ]

    /// Board size and blanks for a level: the wanted board where its squares
    /// keep 60pt, else its fallback, else a 4×4 that fits everywhere the app
    /// runs (4×60 + 3×2 = 246pt, under the narrowest board). The last resort
    /// keeps the table's hardest 4×4 blanks, never more cells than exist.
    static func layout(for difficulty: Difficulty, width: Double) -> (size: Int, blanks: Int) {
        let row = difficulty.values(layoutsPerLevel)
        if squaresFit(row.wanted.size, in: width) { return row.wanted }
        if let fallback = row.fallback, squaresFit(fallback.size, in: width) { return fallback }
        return (4, min(row.fallback?.blanks ?? row.wanted.blanks, 12))
    }

    /// Box shape per board size: 4×4 and 6×6 as before, 9×9 in 3×3 boxes.
    static func boxes(for size: Int) -> (rows: Int, columns: Int) {
        switch size {
        case 9: (3, 3)
        case 6: (2, 3)
        default: (2, 2)
        }
    }

    static func make<G: RandomNumberGenerator>(
        difficulty: Difficulty, width: Double, using generator: inout G
    ) -> SudokuPuzzle {
        let (size, blanks) = layout(for: difficulty, width: width)
        let (boxRows, boxColumns) = boxes(for: size)
        var best: (puzzle: SudokuPuzzle, removed: Int)?
        for _ in 0..<attempts {
            let solution = solvedGrid(size: size, boxRows: boxRows, boxColumns: boxColumns, using: &generator)
            var grid = solution.map { Optional($0) }
            var removed = 0
            // Keep a removal only while the board still has exactly one solution.
            for index in grid.indices.shuffled(using: &generator) where removed < blanks {
                let kept = grid[index]
                grid[index] = nil
                if solutionCount(grid, size: size, boxRows: boxRows, boxColumns: boxColumns, limit: 2) == 1 {
                    removed += 1
                } else {
                    grid[index] = kept
                }
            }
            let puzzle = SudokuPuzzle(
                size: size, boxRows: boxRows, boxColumns: boxColumns, solution: solution,
                givens: Set(grid.indices.filter { grid[$0] != nil }))
            if removed == blanks { return puzzle }
            if removed > best?.removed ?? -1 { best = (puzzle, removed) }
        }
        return best!.puzzle
    }

    /// Whether this board's squares keep 60pt at `width`. A 6×6 board dealt in landscape
    /// on a small iPhone stops fitting when the phone turns to portrait.
    func fits(width: Double) -> Bool { Self.squaresFit(size, in: width) }

    /// A finished row, column or box (#239). Indices are 0-based.
    enum Unit: Equatable {
        case row(Int)
        case column(Int)
        case box(Int)
    }

    /// Every square of a unit, row-major.
    func squares(of unit: Unit) -> [Int] {
        switch unit {
        case .row(let row):
            return (0..<size).map { row * size + $0 }
        case .column(let column):
            return (0..<size).map { $0 * size + column }
        case .box(let box):
            let across = size / boxColumns
            let top = (box / across) * boxRows
            let left = (box % across) * boxColumns
            return (0..<boxRows).flatMap { row in
                (0..<boxColumns).map { column in (top + row) * size + left + column }
            }
        }
    }

    /// The units that the entry at `index` just finished. `entries` holds every
    /// filled square (givens plus placed); a unit counts when all its squares
    /// hold their solution digit. Only the row, column and box through `index`
    /// can be new, so only those are reported, in that order.
    func completedUnits(after index: Int, entries: [Int: Int]) -> [Unit] {
        guard solution.indices.contains(index) else { return [] }
        let row = index / size
        let column = index % size
        let box = (row / boxRows) * (size / boxColumns) + column / boxColumns
        func finished(_ squares: [Int]) -> Bool {
            squares.allSatisfy { square in
                guard let placed = entries[square] else { return false }
                return placed == solution[square]
            }
        }
        var units: [Unit] = []
        if finished(squares(of: .row(row))) { units.append(.row(row)) }
        if finished(squares(of: .column(column))) { units.append(.column(column)) }
        if finished(squares(of: .box(box))) { units.append(.box(box)) }
        return units
    }

    private static func squaresFit(_ count: Int, in width: Double) -> Bool {
        (width - gap * Double(count - 1)) / Double(count) >= minTarget
    }

    /// Solutions of a partly filled grid, counting no further than `limit`.
    /// Backtracking via `allows(_:at:in:size:boxRows:boxColumns:)`; recursion depth ≤81, safe for 9×9.
    /// Called by `make(difficulty:width:using:)` to keep only boards with exactly one solution.
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
