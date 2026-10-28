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

// Alias so the spec's `Move` name works inside and outside the puzzle.
typealias Move = SlidingMove

// MARK: - Puzzle

/// A Huarong-Dao-style sliding puzzle (#222). The board is w×h cells, filled with
/// rectangular blocks and one 2×2 big block that must reach the exit at the
/// bottom centre. A move slides one block one or more cells in a cardinal
/// direction while the path stays clear; each slide counts as one move.
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

    /// Minimum moves from the current position, or nil if unsolvable. Kept small
    /// and pure so tests and the hint can call it directly.
    var minMoves: Int? { solve()?.count }

    // MARK: - Moves

    /// Legal slides from the current board.
    func moves() -> [SlidingMove] { Self.legalMoves(width: width, height: height, blocks: blocks) }

    /// Spec spelling: legal slides from `state`.
    func moves(from state: SlidingBlocksPuzzle) -> [SlidingMove] {
        Self.legalMoves(width: state.width, height: state.height, blocks: state.blocks)
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

    /// Board after `move`, or nil if illegal.
    func applying(_ move: SlidingMove) -> SlidingBlocksPuzzle? {
        guard blocks.indices.contains(move.block) else { return nil }
        let block = blocks[move.block]
        let nx = block.x + move.direction.dx * move.steps
        let ny = block.y + move.direction.dy * move.steps
        guard nx >= 0, ny >= 0, nx + block.w <= width, ny + block.h <= height else { return nil }
        let grid = Self.occupancy(width: width, height: height, blocks: blocks)
        for dy in 0..<block.h {
            for dx in 0..<block.w {
                let x = nx + dx
                let y = ny + dy
                if let owner = grid[y * width + x], owner != move.block { return nil }
            }
        }
        var next = self
        next.blocks[move.block].x = nx
        next.blocks[move.block].y = ny
        // Don't carry history/movesMade into solver states.
        next.history = []
        next.movesMade = 0
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
    /// returns an empty list. Stores predecessors to avoid copying paths.
    func solve() -> [SlidingMove]? {
        if isSolved { return [] }
        var queue: [SlidingBlocksPuzzle] = [self]
        var cameFrom: [Int] = [-1]
        var moveFrom: [SlidingMove?] = [nil]
        var visited: Set<SlidingBlocksPuzzle> = [self]
        var head = 0
        while head < queue.count {
            let current = queue[head]
            head += 1
            let currentIndex = head - 1
            for move in current.moves() {
                guard let next = current.applying(move) else { continue }
                if visited.contains(next) { continue }
                if next.isSolved {
                    // Reconstruct path.
                    var path: [SlidingMove] = [move]
                    var idx = currentIndex
                    while idx != 0 {
                        if let m = moveFrom[idx] { path.append(m) }
                        idx = cameFrom[idx]
                    }
                    return path.reversed()
                }
                visited.insert(next)
                queue.append(next)
                cameFrom.append(currentIndex)
                moveFrom.append(move)
            }
            if visited.count > 800000 { break }
        }
        return nil
    }

    /// Spec spelling that takes an explicit state.
    func solve(from state: SlidingBlocksPuzzle) -> [SlidingMove]? { state.solve() }

    /// First step of the shortest solution from the current board, or nil when
    /// solved or unsolvable. Stays fast on 4×5 by reusing `solve()`; the
    /// generator and tests bound its cost under 50 ms or precompute it.
    func hint() -> SlidingMove? { solve()?.first }

    /// Spec spelling.
    func hint(from state: SlidingBlocksPuzzle) -> SlidingMove? { state.hint() }

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

    // Hash only the layout, not the transient history/movesMade, so the solver's
    // visited set does not treat the same board as different after undo.
    func hash(into hasher: inout Hasher) {
        hasher.combine(width)
        hasher.combine(height)
        hasher.combine(bigIndex)
        for block in blocks {
            hasher.combine(block.x)
            hasher.combine(block.y)
            hasher.combine(block.w)
            hasher.combine(block.h)
        }
    }

    static func == (lhs: SlidingBlocksPuzzle, rhs: SlidingBlocksPuzzle) -> Bool {
        lhs.width == rhs.width && lhs.height == rhs.height && lhs.bigIndex == rhs.bigIndex
            && lhs.blocks == rhs.blocks
    }
}
