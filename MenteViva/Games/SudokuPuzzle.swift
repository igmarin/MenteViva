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
    /// level is never easier. A 6×6 board with 28 blanks never comes out
    /// (the best is 27), so level 10's fallback asks for 27 (#415), a count the board reaches.
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
        ((9, 46), (6, 27)),
    ]

    /// Where the number pad sits next to the board (#400).
    enum PadPlacement: Equatable {
        /// Under the board in columns, as on every iPhone and for the 4×4 and 6×6 boards in portrait.
        case stacked
        /// One row of nine keys under a 9×9 board: portrait iPad.
        case row
        /// Three columns of keys beside the board: landscape iPad.
        case beside
    }

    /// Space between the pad's keys, in points.
    static let padSpacing = 8.0
    /// Tallest and shortest a pad key is when the pad is one row (100pt where there is room).
    private static let padKeyMax = 100.0
    /// The "Show me one" button, in points; it keeps its 100pt height.
    static let showMeHeight = 100.0
    /// Spacing the screen puts between its stacked parts.
    private static let stackSpacing = 20.0
    /// Height kept for what sits above the board: the instruction (two lines at the default
    /// text size) and its spacing. The "try another" note is not counted in portrait; see
    /// `layout(for:width:height:)`.
    private static let headerHeight = 80.0
    /// The level banner (one title line and its spacing) shown on the first open after a level
    /// change, which is the day 9×9 first appears. Kept free in landscape, where the board has no
    /// spare height; portrait's note reserve covers it.
    private static let bannerHeight = 48.0
    /// Width the pad needs beside the board: three keys of up to 100pt and the gaps between them.
    private static let padColumnsWidth = 3 * 100.0 + 2 * 12.0
    /// The note shown after a miss, with its spacing, kept free in portrait so a wrong number
    /// never tips the screen into scrolling.
    private static let noteHeight = 72.0
    /// The same note in the narrower column beside the board, where it can take two lines.
    private static let besideNoteHeight = 76.0

    /// Board size and blanks for a level on a screen whose play area (inside its padding) is
    /// `width` by `height` points: the wanted board where `arrangement` keeps its squares at 60pt,
    /// else its fallback, else a 4×4 (9×9 → 6×6 → 4×4). `height == nil` (a phone) asks the width
    /// alone, and 4×4 fits every phone (4×60 + 3×2 = 246pt). Only when even 4×4 cannot fit is it
    /// dealt anyway, and the screen scrolls. The last resort keeps the table's hardest 4×4 blanks,
    /// never more cells than exist. The screen draws the board with `keptArrangement`.
    static func layout(for difficulty: Difficulty, width: Double, height: Double? = nil) -> BoardSpec {
        let row = difficulty.values(layoutsPerLevel)
        let smallest: BoardSpec = (4, min(row.fallback?.blanks ?? row.wanted.blanks, 12))
        let boards = [row.wanted] + (row.fallback.map { [$0] } ?? []) + [smallest]
        return boards.first { arrangement(size: $0.size, width: width, height: height) != nil } ?? smallest
    }

    /// Square side and pad placement for a board of `size`, or nil when its squares (or, in a
    /// pad row, its keys) would drop under 60pt. With the screen's height known (an iPad) the side
    /// is the smaller of what the width and the height allow; without it, the width alone.
    static func arrangement(size: Int, width: Double, height: Double?) -> (side: Double, pad: PadPlacement)? {
        let count = Double(size)
        let gaps = gap * (count - 1)
        let widthSide = min(100, (width - gaps) / count)
        guard let height else {
            return widthSide >= minTarget ? (widthSide, .stacked) : nil
        }
        if width > height {
            // Landscape: board left, pad right. The pad keeps its three columns of keys, so the
            // board takes the width that is left; the instruction and the banner sit above it.
            // The column beside it (keys, Show me one and the miss note) must fit too; the note
            // only shows once he has tried, when the banner has gone.
            let beside = min(100, (width - stackSpacing - padColumnsWidth - gaps) / count)
            let side = min(beside, (height - headerHeight - bannerHeight - gaps) / count)
            let columnFits = besideColumnHeight(size: size) <= height - headerHeight
            return side >= minTarget && columnFits ? (side, .beside) : nil
        }
        // Portrait: a 9×9 board's pad is one row of nine keys, as square as the width allows;
        // the smaller boards keep their columns of 100pt keys (two rows for 6×6).
        let padKey = padKeyHeight(width: width)
        let padHeight = size == 9 ? padKey : Double(size == 6 ? 2 : 1) * 100 + (size == 6 ? 12 : 0)
        let below = padHeight + showMeHeight + stackSpacing * 2
        let side = min(widthSide, (height - headerHeight - noteHeight - below - gaps) / count)
        let keysFit = size != 9 || padKey >= minTarget
        return side >= minTarget && keysFit ? (side, size == 9 ? .row : .stacked) : nil
    }

    /// The arrangement for a board already dealt (#400). When it still fits, as `arrangement`; when
    /// the screen has turned or a window shrunk so it no longer fits the height, the board is kept
    /// (a half-filled board is never thrown away) with its squares at the 60pt floor, and the
    /// screen scrolls. Without a height, or in the frame before a board that fails by width is
    /// dealt again, it is drawn by width alone.
    static func keptArrangement(size: Int, width: Double, height: Double?) -> (side: Double, pad: PadPlacement) {
        if let fits = arrangement(size: size, width: width, height: height) { return fits }
        let count = Double(size)
        let widthSide = max(0, min(100, (width - gap * (count - 1)) / count))
        guard let height else { return (widthSide, .stacked) }
        let side = min(widthSide, minTarget)
        if width > height {
            let room = width - stackSpacing - padColumnsWidth
            return (side, room >= side * count + gap * (count - 1) ? .beside : .stacked)
        }
        return (side, size == 9 && padKeyHeight(width: width) >= minTarget ? .row : .stacked)
    }

    /// Columns of keys in the number pad: nine in a row under a portrait iPad's 9×9; beside the
    /// board three, or the 4×4's four keys in one row; stacked three for 6×6, else four.
    static func padColumns(size: Int, pad: PadPlacement) -> Int {
        switch pad {
        case .row: 9
        case .beside: size == 4 ? 4 : 3
        case .stacked: size == 6 ? 3 : 4
        }
    }

    /// Height of the column beside the board: rows of 100pt keys, Show me one and a two-line
    /// miss note, with the spacing between them.
    static func besideColumnHeight(size: Int) -> Double {
        let columns = padColumns(size: size, pad: .beside)
        let rows = Double((size + columns - 1) / columns)
        return rows * 100 + (rows - 1) * 12 + stackSpacing + showMeHeight + stackSpacing + besideNoteHeight
    }

    /// Height (and width) of one key when the pad is a single row of nine, at most 100pt.
    static func padKeyHeight(width: Double) -> Double {
        min(padKeyMax, (width - padSpacing * 8) / 9)
    }

    /// Width of a pad row of nine under a board of `side`-point squares: the board's own width, but
    /// never so narrow that its keys drop under 60pt, and never wider than the screen.
    static func rowPadWidth(side: Double, width: Double) -> Double {
        let board = side * 9 + gap * 8
        return min(width, max(board, minTarget * 9 + padSpacing * 8))
    }

    /// Widest the game column gets for a board (#531): `column` (the 640pt game column), or the board's own width
    /// when that is wider, so keys never stretch to the window but a board is never squeezed. Beside
    /// the board (landscape) the two share the whole width.
    static func columnWidth(size: Int, side: Double, pad: PadPlacement, column: Double) -> Double {
        guard pad != .beside else { return .infinity }
        return max(column, side * Double(size) + gap * Double(size - 1))
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
        return make(size: size, blanks: blanks, using: &generator)
    }

    /// A board made for the screen's `layout`, which may have been budgeted by height too (#400).
    static func make<G: RandomNumberGenerator>(layout: BoardSpec, using generator: inout G) -> SudokuPuzzle {
        make(size: layout.size, blanks: layout.blanks, using: &generator)
    }

    private static func make<G: RandomNumberGenerator>(
        size: Int, blanks: Int, using generator: inout G
    ) -> SudokuPuzzle {
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
    /// on a small iPhone stops fitting when the phone turns to portrait. Height is not asked
    /// (#400): a board that turns too short for its pad is kept and scrolls, never dealt again.
    func fits(width: Double) -> Bool { Self.squaresFit(size, in: width) }

    /// The numbers with every copy on the board, givens plus the player's `entries` (square ->
    /// number). A number is complete at `size` copies, so the pad can retire its key (#510).
    func completedNumbers(entries: [Int: Int]) -> Set<Int> {
        var copies = [Int: Int]()
        for index in givens { copies[solution[index], default: 0] += 1 }
        for digit in entries.values { copies[digit, default: 0] += 1 }
        return Set(copies.filter { $0.value == size }.keys)
    }

    /// What a tap on a pad key means (#510).
    enum PadTap: Equatable {
        case place(Int)
        /// No square is chosen: a gentle note, no sound, no try counted.
        case chooseSquareFirst
    }

    /// The selection only moves when the player moves it, so a key can be tapped with nothing
    /// chosen; that asks for a square instead of counting a try.
    static func padTap(selected: Int?) -> PadTap {
        selected.map(PadTap.place) ?? .chooseSquareFirst
    }

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
