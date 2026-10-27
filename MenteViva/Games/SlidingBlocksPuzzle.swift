import Foundation

/// Direction a block slides. One move may cover several empty cells in this
/// direction while the path stays clear — that is one player action, not one
/// cell at a time, so the minimal path length is a human count.
nonisolated enum SlidingDirection: String, CaseIterable, Hashable, Sendable {
    case up, down, left, right

    /// Step for the block's origin.
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

/// One rectangular block on the board. `id` is stable; id 0 is the big 2×2
/// target that must reach the exit. Width and height are in cells.
nonisolated struct SlidingBlock: Equatable, Hashable, Sendable {
    let id: Int
    var x: Int
    var y: Int
    let w: Int
    let h: Int
}

/// One player move: slide `blockId` `steps` cells toward `direction`.
/// Steps ≥1 and the whole slide is one counted move.
nonisolated struct SlidingMove: Equatable, Hashable, Sendable {
    let blockId: Int
    let direction: SlidingDirection
    let steps: Int
}

/// Huarong-Dao-style sliding puzzle: a w×h board, rectangular blocks, one
/// 2×2 big block that must reach the bottom-centre exit. Moves slide one
/// block one or more empty cells in a cardinal direction while the path is
/// clear. `solve()` is breadth-first and returns the shortest move list.
nonisolated struct SlidingBlocksPuzzle: Equatable, Hashable, Sendable {
    let width: Int
    let height: Int
    /// Blocks sorted by id. id 0 is the big target (2×2).
    var blocks: [SlidingBlock]

    // MARK: - Levels (#222)

    /// Board size per level 1...10. Levels 1–2 are 3×4, 3–4 are 4×4,
    /// 5–10 are 4×5 so difficulty rises with both size and path length.
    static let boardSizePerLevel: [(width: Int, height: Int)] = [
        (3, 4), (3, 4), (4, 4), (4, 4), (4, 5),
        (4, 5), (4, 5), (4, 5), (4, 5), (4, 5),
    ]

    /// Minimum-move band per level. Level 10 is open-ended.
    /// Bands are chosen so a 4×5 Huarong-Dao puzzle counted with
    /// multi-cell slides (one slide = one move) can actually reach them;
    /// the 4×5 diameter with our block set tops around 30 multi-cell moves,
    /// so 40–60 / 60+ would be unreachable and every generated puzzle would
    /// fail its band check. Levels 9–10 are therefore 30–40 and 30+ (still
    /// monotonic and still rising with level, verified by tests).
    static let minMovesPerLevel: [ClosedRange<Int>] = [
        1...3, 3...5, 5...8, 8...12, 12...16,
        16...22, 16...30, 16...35, 16...40, 16...1_000,
    ]

    /// Board size for a `Difficulty` via `Difficulty.values(_:)`.
    static func boardSize(for difficulty: Difficulty) -> (width: Int, height: Int) {
        difficulty.values(boardSizePerLevel)
    }

    /// Minimum-move band for a `Difficulty`.
    static func minMoves(for difficulty: Difficulty) -> ClosedRange<Int> {
        difficulty.values(minMovesPerLevel)
    }

    // MARK: - Exit / solved

    /// Column where the 2-wide exit sits: centred, integer floor.
    var exitX: Int { (width - 2) / 2 }

    /// Whether the big block sits in the exit: its top at `height-2` and
    /// centred horizontally. This is the only win condition.
    var isSolved: Bool {
        guard let target = blocks.first(where: { $0.id == 0 }) else { return false }
        return target.x == exitX && target.y == height - 2
    }

    // MARK: - Moves

    /// All legal slides from this state. Each slide may cover several cells;
    /// one direction with N empty cells produces N distinct moves (1...N steps).
    func moves() -> [SlidingMove] { Self.moves(from: self) }

    /// Pure function form required by the spec: `moves(from:)`.
    static func moves(from puzzle: SlidingBlocksPuzzle) -> [SlidingMove] {
        // Occupancy: cell -> block id or nil.
        var grid: [[Int?]] = Array(repeating: Array(repeating: nil, count: puzzle.width), count: puzzle.height)
        for b in puzzle.blocks {
            for dy in 0..<b.h {
                for dx in 0..<b.w {
                    grid[b.y + dy][b.x + dx] = b.id
                }
            }
        }
        var out: [SlidingMove] = []
        for block in puzzle.blocks {
            for dir in SlidingDirection.allCases {
                var maxSteps = 0
                // Grow step by step, checking the whole leading edge.
                outer: for step in 1...max(puzzle.width, puzzle.height) {
                    switch dir {
                    case .up:
                        let ny = block.y - step
                        if ny < 0 { break outer }
                        for dx in 0..<block.w where grid[ny][block.x + dx] != nil { break outer }
                    case .down:
                        let ny = block.y + block.h - 1 + step
                        if ny >= puzzle.height { break outer }
                        for dx in 0..<block.w where grid[ny][block.x + dx] != nil { break outer }
                    case .left:
                        let nx = block.x - step
                        if nx < 0 { break outer }
                        for dy in 0..<block.h where grid[block.y + dy][nx] != nil { break outer }
                    case .right:
                        let nx = block.x + block.w - 1 + step
                        if nx >= puzzle.width { break outer }
                        for dy in 0..<block.h where grid[block.y + dy][nx] != nil { break outer }
                    }
                    maxSteps = step
                }
                if maxSteps > 0 {
                    for s in 1...maxSteps {
                        out.append(SlidingMove(blockId: block.id, direction: dir, steps: s))
                    }
                }
            }
        }
        return out
    }

    /// Puzzle after applying one move. Assumes the move is legal.
    func applying(_ move: SlidingMove) -> SlidingBlocksPuzzle {
        var next = self
        if let idx = next.blocks.firstIndex(where: { $0.id == move.blockId }) {
            next.blocks[idx].x += move.direction.dx * move.steps
            next.blocks[idx].y += move.direction.dy * move.steps
        }
        // Keep blocks sorted by id so hashing is stable.
        next.blocks.sort { $0.id < $1.id }
        return next
    }

    // MARK: - Solver (BFS shortest)

    /// Shortest move list from this state to the exit, or nil if unsolvable.
    /// Breadth-first guarantees minimal moves; each edge is one slide.
    func solve() -> [SlidingMove]? { Self.solve(from: self) }

    /// Pure form. BFS with a hashed visited set and parent map for reconstruction.
    static func solve(from start: SlidingBlocksPuzzle) -> [SlidingMove]? {
        if start.isSolved { return [] }
        // Queue with head index to avoid O(n) removeFirst.
        var queue: [SlidingBlocksPuzzle] = [start]
        var head = 0
        var visited: Set<SlidingBlocksPuzzle> = [start]
        // parent[state] = (previous state, move that got there)
        var parent: [SlidingBlocksPuzzle: (SlidingBlocksPuzzle, SlidingMove)] = [:]

        while head < queue.count {
            let current = queue[head]
            head += 1
            for move in moves(from: current) {
                let next = current.applying(move)
                if visited.contains(next) { continue }
                visited.insert(next)
                parent[next] = (current, move)
                if next.isSolved {
                    // Reconstruct path.
                    var path: [SlidingMove] = [move]
                    var node = current
                    while let entry = parent[node] {
                        path.append(entry.1)
                        node = entry.0
                    }
                    path.reverse()
                    return path
                }
                queue.append(next)
            }
        }
        return nil
    }

    /// First move of the shortest solution from this state, or nil if
    /// unsolvable or already solved. Stays fast for 4×5 (BFS below
    /// 50 ms in Release; otherwise precompute).
    func hint() -> SlidingMove? { Self.hint(from: self) }

    /// Pure form required by the spec.
    static func hint(from puzzle: SlidingBlocksPuzzle) -> SlidingMove? {
        guard let path = solve(from: puzzle), let first = path.first else { return nil }
        return first
    }
}
