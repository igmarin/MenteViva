import Foundation

// MARK: - Blocks and moves

/// One rectangular block on the board. The big block is always 2×2.
nonisolated struct SlidingBlock: Hashable, Equatable, Sendable {
    var x: Int
    var y: Int
    var w: Int
    var h: Int
}

/// Cardinal slide direction.
nonisolated enum SlidingDirection: String, CaseIterable, Hashable, Sendable {
    case up, down, left, right

    var dx: Int {
        switch self {
        case .left: -1
        case .right: 1
        default: 0
        }
    }

    var dy: Int {
        switch self {
        case .up: -1
        case .down: 1
        default: 0
        }
    }
}

/// One slide: block `block` moves `steps` cells toward `direction`.
nonisolated struct SlidingMove: Hashable, Equatable, Sendable {
    var block: Int
    var direction: SlidingDirection
    var steps: Int
}

// MARK: - Puzzle

/// A Huarong-Dao-style sliding puzzle (#222). The board is w×h cells, filled with
/// rectangular blocks and one 2×2 big block that must reach the exit at the
/// bottom centre. A move slides one block one or more cells in a cardinal
/// direction while the path stays clear; each slide counts as one move.
///
/// Two puzzles are equal when their cells are: same-shaped blocks are
/// interchangeable, so swapping two of them is not a new position. That keeps
/// the solver's search to the real number of positions.
nonisolated struct SlidingBlocksPuzzle: Hashable, Sendable {
    let width: Int
    let height: Int
    var blocks: [SlidingBlock]
    /// Index of the big block in `blocks`.
    let bigIndex: Int

    /// Moves the player has made in this session. The view owns undo/stack; the
    /// logic only counts so history can record `attempts = movesMade` and
    /// `correct = minMoves` (efficiency, capped at 1).
    var movesMade: Int = 0
    /// History of block layouts for undo; stores previous `blocks` snapshots.
    var history: [[SlidingBlock]] = []

    /// Where the big block must arrive: centred horizontally, flush with the
    /// bottom. For odd widths the exit favours the left centre.
    var exitX: Int { (width - bigBlock.w) / 2 }
    var exitY: Int { height - bigBlock.h }

    var bigBlock: SlidingBlock { blocks[bigIndex] }

    var isSolved: Bool { bigBlock.x == exitX && bigBlock.y == exitY }

    init(width: Int, height: Int, blocks: [SlidingBlock], bigIndex: Int) {
        self.width = width
        self.height = height
        self.blocks = blocks
        self.bigIndex = bigIndex
    }

    /// A board from its layout: rows joined by "/", one character per cell.
    /// `.` empty, `B` the big block, `o` a 1×1, `<>` a 2×1, `^` over `v` a 1×2.
    /// The big block becomes `blocks[0]`, the rest follow in reading order.
    init(width: Int, height: Int, layout: String) {
        let cells = Array(layout.filter { $0 != "/" })
        precondition(cells.count == width * height, "layout \(layout) is not \(width)×\(height)")
        var big: SlidingBlock?
        var others: [SlidingBlock] = []
        for (index, cell) in cells.enumerated() {
            let x = index % width
            let y = index / width
            switch cell {
            case "B" where big == nil: big = SlidingBlock(x: x, y: y, w: 2, h: 2)
            case "o": others.append(SlidingBlock(x: x, y: y, w: 1, h: 1))
            case "<": others.append(SlidingBlock(x: x, y: y, w: 2, h: 1))
            case "^": others.append(SlidingBlock(x: x, y: y, w: 1, h: 2))
            default: break
            }
        }
        guard let big else { preconditionFailure("layout \(layout) has no big block") }
        self.init(width: width, height: height, blocks: [big] + others, bigIndex: 0)
    }

    // MARK: - Moves

    /// Legal slides from the current board.
    func moves() -> [SlidingMove] { Self.legalMoves(width: width, height: height, blocks: blocks) }

    /// The block the first-play guide points at: the big one when it can move now, otherwise the
    /// first block that can, so the example move always leads to an arrow (nil on a board with no move).
    func guideBlock() -> Int? {
        let legal = moves()
        if legal.contains(where: { $0.block == bigIndex }) { return bigIndex }
        return legal.first?.block
    }

    /// Board occupancy for move checks: cell -> block index or nil.
    static func occupancy(width: Int, height: Int, blocks: [SlidingBlock]) -> [Int?] {
        var grid = [Int?](repeating: nil, count: width * height)
        for (index, block) in blocks.enumerated() {
            for dy in 0..<block.h {
                for dx in 0..<block.w {
                    let x = block.x + dx
                    let y = block.y + dy
                    guard x >= 0, x < width, y >= 0, y < height else { continue }
                    grid[y * width + x] = index
                }
            }
        }
        return grid
    }

    static func legalMoves(width: Int, height: Int, blocks: [SlidingBlock]) -> [SlidingMove] {
        let grid = occupancy(width: width, height: height, blocks: blocks)
        var out: [SlidingMove] = []
        for (index, block) in blocks.enumerated() {
            for direction in SlidingDirection.allCases {
                var steps = 0
                while true {
                    steps += 1
                    let nx = block.x + direction.dx * steps
                    let ny = block.y + direction.dy * steps
                    // Destination rectangle must stay inside the board.
                    guard nx >= 0, ny >= 0, nx + block.w <= width, ny + block.h <= height else { break }
                    var clear = true
                    for dy in 0..<block.h where clear {
                        for dx in 0..<block.w where clear {
                            let x = nx + dx
                            let y = ny + dy
                            let cell = grid[y * width + x]
                            if let owner = cell, owner != index {
                                clear = false
                            }
                        }
                    }
                    if clear {
                        out.append(SlidingMove(block: index, direction: direction, steps: steps))
                    } else {
                        break
                    }
                }
            }
        }
        return out
    }

    /// Board after `move`, or nil if illegal: no zero-step slides, no jumping over a block.
    func applying(_ move: SlidingMove) -> SlidingBlocksPuzzle? {
        guard moves().contains(move) else { return nil }
        var next = moved(move)
        // Don't carry history/movesMade into solver states.
        next.history = []
        next.movesMade = 0
        return next
    }

    /// The board after a move already known to be legal.
    fileprivate func moved(_ move: SlidingMove) -> SlidingBlocksPuzzle {
        var next = self
        next.blocks[move.block].x += move.direction.dx * move.steps
        next.blocks[move.block].y += move.direction.dy * move.steps
        return next
    }

    /// Apply `move` to this mutable puzzle, recording history.
    @discardableResult
    mutating func apply(_ move: SlidingMove) -> Bool {
        guard let next = applying(move) else { return false }
        history.append(blocks)
        blocks = next.blocks
        movesMade += 1
        return true
    }

    mutating func undo() -> Bool {
        guard let previous = history.popLast() else { return false }
        blocks = previous
        movesMade = max(0, movesMade - 1)
        return true
    }

    mutating func reset(to initialBlocks: [SlidingBlock]) {
        blocks = initialBlocks
        history.removeAll()
        movesMade = 0
    }

    // MARK: - Solver (BFS, shortest)

    /// Shortest slide sequence from the current board, or nil if unsolvable.
    /// Breadth-first keeps the first solution shortest; an already solved board
    /// returns an empty list. Searches every reachable position, with no cap:
    /// a 4×5 board has at most a few hundred thousand.
    func solve() -> [SlidingMove]? {
        if isSolved { return [] }
        var start = self
        start.history = []
        start.movesMade = 0
        var cameFrom: [UInt64: UInt64] = [start.layoutKey: start.layoutKey]
        var queue = [start]
        var head = 0
        while head < queue.count {
            let current = queue[head]
            head += 1
            let currentKey = current.layoutKey
            for move in current.moves() {
                let next = current.moved(move)
                let nextKey = next.layoutKey
                guard cameFrom[nextKey] == nil else { continue }
                cameFrom[nextKey] = currentKey
                if next.isSolved { return start.path(to: nextKey, cameFrom: cameFrom) }
                queue.append(next)
            }
        }
        return nil
    }

    /// The moves from this board to `target`, replayed so block indices stay this board's.
    private func path(to target: UInt64, cameFrom: [UInt64: UInt64]) -> [SlidingMove] {
        var keys = [target]
        while let previous = cameFrom[keys[keys.count - 1]], previous != keys[keys.count - 1] {
            keys.append(previous)
        }
        var board = self
        var path: [SlidingMove] = []
        for key in keys.reversed().dropFirst() {
            guard let move = board.moves().first(where: { board.moved($0).layoutKey == key }) else { break }
            path.append(move)
            board = board.moved(move)
        }
        return path
    }

    // MARK: - Helpers for levels

    /// Whether the board has no overlapping blocks and stays inside the frame.
    var isValid: Bool {
        var grid = [Bool](repeating: false, count: width * height)
        for block in blocks {
            if block.x < 0 || block.y < 0 || block.x + block.w > width || block.y + block.h > height { return false }
            for dy in 0..<block.h {
                for dx in 0..<block.w {
                    let index = (block.y + dy) * width + (block.x + dx)
                    if grid[index] { return false }
                    grid[index] = true
                }
            }
        }
        return true
    }

    /// The cells as a number, 3 bits each (empty, big, 1×1, 2×1 left/right,
    /// 1×2 top/bottom): equal for boards that differ only by which same-shaped
    /// block is where. Fits boards up to 21 cells.
    var layoutKey: UInt64 {
        precondition(width * height <= 21, "layoutKey fits 21 cells")
        var key: UInt64 = 0
        for (index, block) in blocks.enumerated() {
            for dy in 0..<block.h {
                for dx in 0..<block.w {
                    let code: UInt64
                    if index == bigIndex {
                        code = 1
                    } else if block.w == 2 {
                        code = dx == 0 ? 3 : 4
                    } else if block.h == 2 {
                        code = dy == 0 ? 5 : 6
                    } else {
                        code = 2
                    }
                    key |= code << UInt64(3 * ((block.y + dy) * width + block.x + dx))
                }
            }
        }
        return key
    }

    // Hash only the layout, not the transient history/movesMade, so the same
    // board compares equal after undo.
    func hash(into hasher: inout Hasher) {
        hasher.combine(width)
        hasher.combine(height)
        hasher.combine(layoutKey)
    }

    static func == (lhs: SlidingBlocksPuzzle, rhs: SlidingBlocksPuzzle) -> Bool {
        lhs.width == rhs.width && lhs.height == rhs.height && lhs.layoutKey == rhs.layoutKey
    }
}

// MARK: - Hints

/// Fewest moves to solve from every position a puzzle can reach. Built once
/// when the puzzle starts (about 0.3 s on a Mac for a 4×5 board, so build it off
/// the main thread) so each "Show me a move" is a lookup, not a search.
nonisolated struct SlidingBlocksMap: Sendable {
    private let movesToSolve: [UInt64: Int]

    /// `isCancelled` lets a background build stop early: the table is then
    /// partial and must be discarded. The default never stops (tests, tools).
    init(from puzzle: SlidingBlocksPuzzle, isCancelled: () -> Bool = { false }) {
        // Every reachable position, then breadth-first back from all solved ones.
        var index: [UInt64: Int] = [puzzle.layoutKey: 0]
        var keys = [puzzle.layoutKey]
        var neighbours: [[Int]] = []
        var solved: [Int] = []
        var queue = [puzzle]
        var head = 0
        while head < queue.count, !isCancelled() {
            let current = queue[head]
            if current.isSolved { solved.append(head) }
            var next: [Int] = []
            for move in current.moves() {
                let board = current.moved(move)
                let key = board.layoutKey
                if let known = index[key] {
                    next.append(known)
                } else {
                    index[key] = keys.count
                    next.append(keys.count)
                    keys.append(key)
                    queue.append(board)
                }
            }
            neighbours.append(next)
            head += 1
        }
        var moves = [Int](repeating: -1, count: keys.count)
        for i in solved { moves[i] = 0 }
        var frontier = solved
        head = 0
        while head < frontier.count, !isCancelled() {
            let current = frontier[head]
            head += 1
            for n in neighbours[current] where moves[n] == -1 {
                moves[n] = moves[current] + 1
                frontier.append(n)
            }
        }
        var table: [UInt64: Int] = [:]
        for (i, key) in keys.enumerated() where moves[i] >= 0 { table[key] = moves[i] }
        movesToSolve = table
    }

    /// Fewest moves to solve `puzzle`, or nil if it can't be solved from there.
    func minMoves(from puzzle: SlidingBlocksPuzzle) -> Int? { movesToSolve[puzzle.layoutKey] }

    /// A legal move one step closer to solved, or nil when solved or unsolvable.
    func hint(from puzzle: SlidingBlocksPuzzle) -> SlidingMove? {
        guard let left = minMoves(from: puzzle), left > 0 else { return nil }
        return puzzle.moves().first { move in
            minMoves(from: puzzle.moved(move)) == left - 1
        }
    }
}

// MARK: - Levels

/// The puzzles, 30 per level (#222). `all` is written by
/// `tools/generate_sliding_blocks.swift` into SlidingBlocksLevels.swift, so the
/// app never invents a puzzle at runtime.
nonisolated enum SlidingBlocksLevels {
    struct PuzzleData: Hashable, Sendable {
        let width: Int
        let height: Int
        /// Fewest moves that solve it, measured by the generator; a session records it as `correct`.
        let minMoves: Int
        let layout: String

        var puzzle: SlidingBlocksPuzzle { SlidingBlocksPuzzle(width: width, height: height, layout: layout) }
    }

    /// A random puzzle for the player's level.
    static func puzzle(for difficulty: Difficulty, using generator: inout some RandomNumberGenerator) -> PuzzleData {
        let pool = puzzles(for: difficulty.level)
        return pool[Int.random(in: pool.indices, using: &generator)]
    }

    /// Every puzzle of a level, 1...10 (tests).
    static func puzzles(for level: Int) -> [PuzzleData] {
        precondition(all.indices.contains(level - 1), "no Sliding Blocks level \(level)")
        return all[level - 1]
    }
}
