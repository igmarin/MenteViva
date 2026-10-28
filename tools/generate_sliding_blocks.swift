// Generates MenteViva/Games/SlidingBlocksLevels.swift: 30 puzzles per level (#222).
// Run: swift -O tools/generate_sliding_blocks.swift [seed]   (default seed 42; ~15 s)
// Foundation only. The same seed writes the same file, byte for byte; CI checks it.
//
// How: lay out a random board, explore every position it can reach, then
// measure each position's true minimum moves with one breadth-first search
// that starts from *all* solved positions at once. A position joins a level
// when its minimum falls in that level's band. One move = one block sliding
// any number of cells in one direction. Same-shaped blocks are
// interchangeable, so a position is its grid of cell codes, not a block order.
import Foundation

// MARK: - Positions (mirror MenteViva/Games/SlidingBlocksPuzzle.swift)

// Cell codes, 3 bits each, row-major: 0 empty, 1 big 2×2, 2 small 1×1,
// 3/4 wide 2×1 left/right, 5/6 tall 1×2 top/bottom.
let layoutCharacters: [Character] = [".", "B", "o", "<", ">", "^", "v"]

struct Block {
    var x: Int
    var y: Int
    var w: Int
    var h: Int
}

struct Board {
    let width: Int
    let height: Int
    var exitX: Int { (width - 2) / 2 }
    var exitY: Int { height - 2 }

    func key(_ blocks: [Block]) -> UInt64 {
        var key: UInt64 = 0
        for (index, b) in blocks.enumerated() {
            for dy in 0..<b.h {
                for dx in 0..<b.w {
                    let code: UInt64
                    if index == 0 {
                        code = 1
                    } else if b.w == 2 {
                        code = dx == 0 ? 3 : 4
                    } else if b.h == 2 {
                        code = dy == 0 ? 5 : 6
                    } else {
                        code = 2
                    }
                    key |= code << UInt64(3 * ((b.y + dy) * width + b.x + dx))
                }
            }
        }
        return key
    }

    /// Big block first, the rest in reading order.
    func blocks(_ key: UInt64) -> [Block] {
        var big: Block?
        var others: [Block] = []
        for cell in 0..<(width * height) {
            let x = cell % width
            let y = cell / width
            switch (key >> UInt64(3 * cell)) & 7 {
            case 1 where big == nil: big = Block(x: x, y: y, w: 2, h: 2)
            case 2: others.append(Block(x: x, y: y, w: 1, h: 1))
            case 3: others.append(Block(x: x, y: y, w: 2, h: 1))
            case 5: others.append(Block(x: x, y: y, w: 1, h: 2))
            default: break
            }
        }
        return [big!] + others
    }

    func isSolved(_ key: UInt64) -> Bool {
        // Big cells on both corners of the exit square: the 2×2 is exactly there.
        func code(_ x: Int, _ y: Int) -> UInt64 { (key >> UInt64(3 * (y * width + x))) & 7 }
        return code(exitX, exitY) == 1 && code(exitX + 1, exitY + 1) == 1
    }

    func neighbours(_ key: UInt64) -> [UInt64] {
        let blocks = blocks(key)
        var owner = [Int](repeating: -1, count: width * height)
        for (index, b) in blocks.enumerated() {
            for dy in 0..<b.h { for dx in 0..<b.w { owner[(b.y + dy) * width + b.x + dx] = index } }
        }
        var out: [UInt64] = []
        for (index, b) in blocks.enumerated() {
            for (dx, dy) in [(0, -1), (0, 1), (-1, 0), (1, 0)] {
                var steps = 1
                while true {
                    let nx = b.x + dx * steps
                    let ny = b.y + dy * steps
                    guard nx >= 0, ny >= 0, nx + b.w <= width, ny + b.h <= height else { break }
                    var clear = true
                    for cy in ny..<(ny + b.h) {
                        for cx in nx..<(nx + b.w) where owner[cy * width + cx] != -1 && owner[cy * width + cx] != index {
                            clear = false
                        }
                    }
                    guard clear else { break }
                    var moved = blocks
                    moved[index].x = nx
                    moved[index].y = ny
                    out.append(self.key(moved))
                    steps += 1
                }
            }
        }
        return out
    }

    func layout(_ key: UInt64) -> String {
        var rows: [String] = []
        for y in 0..<height {
            rows.append(String((0..<width).map { layoutCharacters[Int((key >> UInt64(3 * (y * width + $0))) & 7)] }))
        }
        return rows.joined(separator: "/")
    }
}

// MARK: - Seeded RNG

struct SeededRNG: RandomNumberGenerator {
    var state: UInt64
    mutating func next() -> UInt64 {
        state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
        return state
    }
}

// MARK: - Levels

struct Level {
    let width: Int
    let height: Int
    let minMoves: Int
    let maxMoves: Int?
    func contains(_ moves: Int) -> Bool { moves >= minMoves && moves <= (maxMoves ?? .max) }
}

let levels: [Level] = [
    Level(width: 3, height: 4, minMoves: 1, maxMoves: 3),
    Level(width: 3, height: 4, minMoves: 3, maxMoves: 5),
    Level(width: 4, height: 4, minMoves: 5, maxMoves: 8),
    Level(width: 4, height: 4, minMoves: 8, maxMoves: 12),
    Level(width: 4, height: 5, minMoves: 12, maxMoves: 16),
    Level(width: 4, height: 5, minMoves: 16, maxMoves: 22),
    Level(width: 4, height: 5, minMoves: 22, maxMoves: 30),
    Level(width: 4, height: 5, minMoves: 30, maxMoves: 40),
    Level(width: 4, height: 5, minMoves: 40, maxMoves: 60),
    Level(width: 4, height: 5, minMoves: 60, maxMoves: nil),
]
let perLevel = 30
/// Puzzles one random board may give each level, so a level isn't 30 near-copies.
let perBoardPerLevel = 3

// MARK: - Generation

/// A random full board: the big block anywhere, small pieces until two cells
/// stay empty. Tall pieces are favoured: they are what makes a board deep.
func randomBoard(_ board: Board, rng: inout SeededRNG) -> UInt64 {
    let cells = board.width * board.height
    var filled = [Bool](repeating: false, count: cells)
    let bx = Int.random(in: 0...(board.width - 2), using: &rng)
    let by = Int.random(in: 0...(board.height - 2), using: &rng)
    var blocks = [Block(x: bx, y: by, w: 2, h: 2)]
    for dy in 0..<2 { for dx in 0..<2 { filled[(by + dy) * board.width + bx + dx] = true } }
    var empty = cells - 4
    let shapes: [(w: Int, h: Int)] = [(1, 2), (1, 2), (1, 2), (2, 1), (1, 1), (1, 1)]
    while empty > 2 {
        let open = (0..<cells).filter { !filled[$0] }
        let cell = open[Int.random(in: open.indices, using: &rng)]
        let x = cell % board.width
        let y = cell / board.width
        let shape = shapes[Int.random(in: shapes.indices, using: &rng)]
        let fits =
            shape.w * shape.h <= empty - 2 && x + shape.w <= board.width && y + shape.h <= board.height
            && !filled[(y + shape.h - 1) * board.width + x + shape.w - 1]
        let (w, h) = fits ? shape : (1, 1)
        for dy in 0..<h { for dx in 0..<w { filled[(y + dy) * board.width + x + dx] = true } }
        blocks.append(Block(x: x, y: y, w: w, h: h))
        empty -= w * h
    }
    return board.key(blocks)
}

/// Every position reachable from `start`, in discovery order, with its true
/// minimum moves (nil when no position of the component is solved).
func minimumMoves(from start: UInt64, on board: Board) -> [(key: UInt64, moves: Int)]? {
    var order = [start]
    var index: [UInt64: Int] = [start: 0]
    var edges: [[Int]] = []
    var head = 0
    while head < order.count {
        var next: [Int] = []
        for key in board.neighbours(order[head]) {
            if let known = index[key] {
                next.append(known)
            } else {
                index[key] = order.count
                next.append(order.count)
                order.append(key)
            }
        }
        edges.append(next)
        head += 1
    }
    var moves = [Int](repeating: -1, count: order.count)
    var queue = order.indices.filter { board.isSolved(order[$0]) }
    guard !queue.isEmpty else { return nil }
    for i in queue { moves[i] = 0 }
    head = 0
    while head < queue.count {
        let current = queue[head]
        head += 1
        for n in edges[current] where moves[n] == -1 {
            moves[n] = moves[current] + 1
            queue.append(n)
        }
    }
    return order.indices.map { (order[$0], moves[$0]) }
}

func generate(seed: UInt64) -> [[(key: UInt64, moves: Int)]] {
    var rng = SeededRNG(state: seed)
    var picked: [[(key: UInt64, moves: Int)]] = levels.map { _ in [] }
    var used = Set<UInt64>()
    var boardsTried = 0
    while let level = picked.indices.first(where: { picked[$0].count < perLevel }) {
        boardsTried += 1
        guard boardsTried <= 20_000 else {
            fputs("Gave up: level \(level + 1) has \(picked[level].count) of \(perLevel) puzzles\n", stderr)
            exit(1)
        }
        let board = Board(width: levels[level].width, height: levels[level].height)
        guard let positions = minimumMoves(from: randomBoard(board, rng: &rng), on: board) else { continue }
        for (l, spec) in levels.enumerated()
        where spec.width == board.width && spec.height == board.height && picked[l].count < perLevel {
            var fits = positions.filter { spec.contains($0.moves) && !used.contains($0.key) }
            fits.shuffle(using: &rng)
            for position in fits.prefix(min(perBoardPerLevel, perLevel - picked[l].count)) {
                used.insert(position.key)
                picked[l].append(position)
            }
        }
    }
    fputs("\(boardsTried) random boards explored\n", stderr)
    return picked
}

// MARK: - Emit

func emit(_ picked: [[(key: UInt64, moves: Int)]], seed: UInt64, to path: String) {
    var out = """
        // Generated by tools/generate_sliding_blocks.swift (seed \(seed)). Do not edit.
        // Layout codes: see SlidingBlocksPuzzle.init(width:height:layout:).

        nonisolated extension SlidingBlocksLevels {
            static let all: [[PuzzleData]] = [

        """
    for (l, spec) in levels.enumerated() {
        let board = Board(width: spec.width, height: spec.height)
        let band = spec.maxMoves.map { "\(spec.minMoves)–\($0)" } ?? "\(spec.minMoves)+"
        out += "        [  // Level \(l + 1): \(spec.width)×\(spec.height), \(band) moves\n"
        for position in picked[l] {
            out += "            PuzzleData(width: \(spec.width), height: \(spec.height), minMoves: \(position.moves), "
            out += "layout: \"\(board.layout(position.key))\"),\n"
        }
        out += "        ],\n"
    }
    out += "    ]\n}\n"
    do {
        try out.write(toFile: path, atomically: true, encoding: .utf8)
        print("Wrote \(picked.map(\.count).reduce(0, +)) puzzles to \(path)")
    } catch {
        fputs("Failed to write \(path): \(error)\n", stderr)
        exit(1)
    }
}

// MARK: - Main

let seed = CommandLine.arguments.dropFirst().first.flatMap { UInt64($0) } ?? 42
let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
emit(generate(seed: seed), seed: seed, to: root.appendingPathComponent("MenteViva/Games/SlidingBlocksLevels.swift").path)
