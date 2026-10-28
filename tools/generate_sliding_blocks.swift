#!/usr/bin/env swift  // Generates MenteViva/Games/SlidingBlocksLevels.swift — 30 puzzles per level, seeded.  // Run: swift tools/generate_sliding_blocks.swift [seed]  // Foundation only, deterministic.
import Foundation

// MARK: - Shared types (mirror MenteViva/Games/SlidingBlocksPuzzle.swift)

struct SlidingBlock: Hashable, Equatable {
    var x: Int
    var y: Int
    var w: Int
    var h: Int
}

enum SlidingDirection: CaseIterable {
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

struct SlidingMove: Hashable, Equatable {
    var block: Int
    var direction: SlidingDirection
    var steps: Int
}

struct Puzzle: Hashable {
    var width: Int
    var height: Int
    var blocks: [SlidingBlock]
    var bigIndex: Int
    var exitX: Int { (width - blocks[bigIndex].w) / 2 }
    var exitY: Int { height - blocks[bigIndex].h }
    var isSolved: Bool { blocks[bigIndex].x == exitX && blocks[bigIndex].y == exitY }

    func occupancy() -> [Int?] {
        var grid = [Int?](repeating: nil, count: width * height)
        for (idx, b) in blocks.enumerated() {
            for dy in 0..<b.h {
                for dx in 0..<b.w {
                    let x = b.x + dx
                    let y = b.y + dy
                    if x < 0 || x >= width || y < 0 || y >= height { continue }
                    grid[y * width + x] = idx
                }
            }
        }
        return grid
    }

    func legalMoves() -> [SlidingMove] {
        let grid = occupancy()
        var out: [SlidingMove] = []
        for (idx, b) in blocks.enumerated() {
            for dir in SlidingDirection.allCases {
                var steps = 0
                while true {
                    steps += 1
                    let nx = b.x + dir.dx * steps
                    let ny = b.y + dir.dy * steps
                    guard nx >= 0, ny >= 0, nx + b.w <= width, ny + b.h <= height else { break }
                    var clear = true
                    for dy in 0..<b.h where clear {
                        for dx in 0..<b.w where clear {
                            let x = nx + dx
                            let y = ny + dy
                            let cell = grid[y * width + x]
                            if let owner = cell, owner != idx { clear = false }
                        }
                    }
                    if clear {
                        out.append(SlidingMove(block: idx, direction: dir, steps: steps))
                    } else {
                        break
                    }
                }
            }
        }
        return out
    }

    func applying(_ move: SlidingMove) -> Puzzle? {
        guard blocks.indices.contains(move.block) else { return nil }
        let b = blocks[move.block]
        let nx = b.x + move.direction.dx * move.steps
        let ny = b.y + move.direction.dy * move.steps
        guard nx >= 0, ny >= 0, nx + b.w <= width, ny + b.h <= height else { return nil }
        let grid = occupancy()
        for dy in 0..<b.h {
            for dx in 0..<b.w {
                let x = nx + dx
                let y = ny + dy
                if let owner = grid[y * width + x], owner != move.block { return nil }
            }
        }
        var next = self
        next.blocks[move.block].x = nx
        next.blocks[move.block].y = ny
        return next
    }

    func solve() -> [SlidingMove]? {
        if isSolved { return [] }
        var queue: [Puzzle] = [self]
        var paths: [[SlidingMove]] = [[]]
        var visited: Set<Puzzle> = [self]
        var head = 0
        while head < queue.count {
            let cur = queue[head]
            let path = paths[head]
            head += 1
            for move in cur.legalMoves() {
                guard let nxt = cur.applying(move) else { continue }
                if visited.contains(nxt) { continue }
                let nextPath = path + [move]
                if nxt.isSolved { return nextPath }
                visited.insert(nxt)
                queue.append(nxt)
                paths.append(nextPath)
            }
            if visited.count > 600000 { break }
        }
        return nil
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

// MARK: - Band config

let boardSizes: [(w: Int, h: Int)] = [
    (3, 4), (3, 4), (4, 4), (4, 4), (4, 5), (4, 5), (4, 5), (4, 5), (4, 5), (4, 5),
]
let bands: [(min: Int, max: Int?)] = [
    (1, 3), (3, 5), (5, 8), (8, 12), (12, 16), (16, 22), (22, 30), (30, 40), (40, 60), (60, nil),
]
let scrambleStepsPerLevel: [(lo: Int, hi: Int)] = [
    (2, 6), (3, 8), (6, 12), (9, 18), (13, 22), (17, 30), (24, 42), (32, 60), (45, 85), (70, 120),
]

// Group levels by board size to share BFS work.
let sizeGroups: [(size: (w: Int, h: Int), levels: [Int])] = [
    ((3, 4), [0, 1]),
    ((4, 4), [2, 3]),
    ((4, 5), [4, 5, 6, 7, 8, 9]),
]

// MARK: - Random filling

func randomFilling(width: Int, height: Int, bigX: Int, bigY: Int, rng: inout SeededRNG) -> [SlidingBlock]? {
    // Place big first.
    var blocks: [SlidingBlock] = [SlidingBlock(x: bigX, y: bigY, w: 2, h: 2)]
    var grid = [[Bool]](repeating: [Bool](repeating: false, count: width), count: height)
    for dy in 0..<2 {
        for dx in 0..<2 { grid[bigY + dy][bigX + dx] = true }
    }
    var empties = width * height - 4
    // We want exactly 2 empties at the end.
    let targetEmpties = 2
    let targetFilled = width * height - targetEmpties
    var attempts = 0
    let maxAttempts = 500
    while empties > targetEmpties, attempts < maxAttempts {
        attempts += 1
        // Collect empty cells.
        var emptyCells: [(Int, Int)] = []
        for y in 0..<height {
            for x in 0..<width where !grid[y][x] { emptyCells.append((x, y)) }
        }
        guard !emptyCells.isEmpty else { break }
        emptyCells.shuffle(using: &rng)
        let (ex, ey) = emptyCells[0]
        // Pick size.
        let choices: [(Int, Int)] = [(1, 1), (1, 2), (2, 1)]
        let shuffled = choices.shuffled(using: &rng)
        var placed = false
        for (bw, bh) in shuffled {
            if ex + bw > width || ey + bh > height { continue }
            // Need all cells empty.
            var ok = true
            for dy in 0..<bh where ok {
                for dx in 0..<bw where ok {
                    if grid[ey + dy][ex + dx] { ok = false }
                }
            }
            if !ok { continue }
            // Don't leave single isolated cell that can't be filled with allowed sizes?
            // Simple check: remaining empties after placement must be reachable.
            // But we just place.
            for dy in 0..<bh { for dx in 0..<bw { grid[ey + dy][ex + dx] = true } }
            blocks.append(SlidingBlock(x: ex, y: ey, w: bw, h: bh))
            empties -= bw * bh
            placed = true
            break
        }
        if !placed {
            // Try next empty cell next iteration; count as attempt.
            continue
        }
    }
    let filled = blocks.reduce(0) { $0 + $1.w * $1.h }
    if filled != targetFilled { return nil }
    // Validate no overlaps already done.
    return blocks
}

func generateSolvedTemplate(width: Int, height: Int, rng: inout SeededRNG) -> Puzzle? {
    let bigW = 2
    let bigH = 2
    let exitX = (width - bigW) / 2
    let exitY = height - bigH
    guard let blocks = randomFilling(width: width, height: height, bigX: exitX, bigY: exitY, rng: &rng) else { return nil }
    // big is at 0.
    return Puzzle(width: width, height: height, blocks: blocks, bigIndex: 0)
}

func scramble(puzzle: Puzzle, steps: Int, rng: inout SeededRNG) -> Puzzle {
    var cur = puzzle
    for _ in 0..<steps {
        let moves = cur.legalMoves()
        guard !moves.isEmpty else { break }
        let move = moves.randomElement(using: &rng)!
        if let nxt = cur.applying(move) { cur = nxt }
    }
    return cur
}

// MARK: - Generation

func generateAll(seed: UInt64) -> [[Puzzle]] {
    var rng = SeededRNG(state: seed)
    var allLevels: [[Puzzle]] = Array(repeating: [], count: 10)
    // Group by board size to reuse BFS work.
    for group in sizeGroups {
        let (w, h) = (group.size.w, group.size.h)
        let levelIndices = group.levels
        // Pools per level index.
        var pools: [Int: [Puzzle]] = [:]
        for idx in levelIndices { pools[idx] = [] }
        var templatesTried = 0
        let isDeepGroup = levelIndices.contains(9)
        let maxTemplates = isDeepGroup ? 5 : 12
        while pools.contains(where: { $0.value.count < 30 }) && templatesTried < maxTemplates {
            templatesTried += 1
            guard let start = generateSolvedTemplate(width: w, height: h, rng: &rng) else { continue }
            // BFS outward from solved start.
            var queue: [Puzzle] = [start]
            var depth: [Int] = [0]
            var visited: Set<Puzzle> = [start]
            var head = 0
            // Cap visited to keep runtime bounded; deep levels need larger caps.
            let maxVisited = isDeepGroup ? 400000 : 300000
            while head < queue.count {
                let cur = queue[head]
                let d = depth[head]
                head += 1
                if d > 0, !cur.isSolved {
                    for lvl in levelIndices where pools[lvl]!.count < 30 {
                        let band = bands[lvl]
                        let inBand: Bool
                        if let hi = band.max { inBand = d >= band.min && d <= hi } else { inBand = d >= band.min }
                        if inBand {
                            pools[lvl]!.append(cur)
                            break
                        }
                    }
                }
                if pools.allSatisfy({ $0.value.count >= 30 }) { break }
                if d >= 80 { continue }
                for m in cur.legalMoves() {
                    guard let nxt = cur.applying(m) else { continue }
                    if visited.contains(nxt) { continue }
                    visited.insert(nxt)
                    queue.append(nxt)
                    depth.append(d + 1)
                }
                if visited.count > maxVisited { break }
            }
            // Shuffle each pool deterministically to avoid bias toward BFS order.
            for idx in levelIndices {
                pools[idx]!.shuffle(using: &rng)
            }
        }
        // If any level still short, fall back.
        for idx in levelIndices {
            var remaining = 30 - pools[idx]!.count
            if remaining > 0 {
                fputs("Fallback for level \(idx+1): need \(remaining) more\n", stderr)
                var seen = Set(pools[idx]!)
                var attempts = 0
                while remaining > 0, attempts < 80 {
                    attempts += 1
                    if idx < 4 {
                        // Shallow: random fill is fast and accurate.
                        let w = boardSizes[idx].w
                        let h = boardSizes[idx].h
                        let band = bands[idx]
                        let bx = Int.random(in: 0...(w - 2), using: &rng)
                        let by = Int.random(in: 0...(h - 2), using: &rng)
                        if bx == (w - 2) / 2, by == h - 2 { continue }
                        guard let blocks = randomFilling(width: w, height: h, bigX: bx, bigY: by, rng: &rng) else { continue }
                        let cand = Puzzle(width: w, height: h, blocks: blocks, bigIndex: 0)
                        if cand.isSolved { continue }
                        guard let sol = cand.solve() else { continue }
                        let ok: Bool
                        if let hi = band.max { ok = sol.count >= band.min && sol.count <= hi } else { ok = sol.count >= band.min }
                        if ok, !seen.contains(cand) {
                            seen.insert(cand)
                            pools[idx]!.append(cand)
                            remaining -= 1
                        }
                    } else {
                        let isDeep = idx == 9
                        guard let tmpl = generateSolvedTemplate(width: w, height: h, rng: &rng) else { continue }
                        var queue: [Puzzle] = [tmpl]
                        var depthArr: [Int] = [0]
                        var visited: Set<Puzzle> = [tmpl]
                        var head = 0
                        let maxVisited = isDeep ? 600000 : 300000
                        while head < queue.count {
                            let cur = queue[head]
                            let d = depthArr[head]
                            head += 1
                            if d > 0, !cur.isSolved {
                                let band = bands[idx]
                                let inBand: Bool
                                if let hi = band.max { inBand = d >= band.min && d <= hi } else { inBand = d >= band.min }
                                if inBand, !seen.contains(cur) {
                                    seen.insert(cur)
                                    pools[idx]!.append(cur)
                                    remaining -= 1
                                    if remaining == 0 { break }
                                }
                            }
                            if remaining == 0 { break }
                            if d >= 80 { continue }
                            for m in cur.legalMoves() {
                                guard let nxt = cur.applying(m) else { continue }
                                if visited.contains(nxt) { continue }
                                visited.insert(nxt)
                                queue.append(nxt)
                                depthArr.append(d + 1)
                            }
                            if visited.count > maxVisited { break }
                        }
                    }
                }
                if remaining > 0 {
                    fputs("Warning: level \(idx+1) only \(pools[idx]!.count) puzzles\n", stderr)
                }
            }
            allLevels[idx] = pools[idx]!
        }
    }
    // Post-verify only shallow levels (1-4) where solve is fast and band mismatches were common.
    // Deep levels are trusted via depth proxy; test samples them.
    for lvl in 0..<4 {
        let band = bands[lvl]
        for idx in 0..<allLevels[lvl].count {
            let p = allLevels[lvl][idx]
            let ok: Bool
            if let sol = p.solve() {
                if let hi = band.max { ok = sol.count >= band.min && sol.count <= hi } else { ok = sol.count >= band.min }
            } else {
                ok = false
            }
            if ok { continue }
            var found: Puzzle? = nil
            var attempts = 0
            while found == nil, attempts < 300 {
                attempts += 1
                let w = boardSizes[lvl].w
                let h = boardSizes[lvl].h
                let bx = Int.random(in: 0...(w - 2), using: &rng)
                let by = Int.random(in: 0...(h - 2), using: &rng)
                if bx == (w - 2) / 2, by == h - 2 { continue }
                guard let blocks = randomFilling(width: w, height: h, bigX: bx, bigY: by, rng: &rng) else { continue }
                let cand = Puzzle(width: w, height: h, blocks: blocks, bigIndex: 0)
                if cand.isSolved { continue }
                guard let sol2 = cand.solve() else { continue }
                let ok2: Bool
                if let hi = band.max { ok2 = sol2.count >= band.min && sol2.count <= hi } else { ok2 = sol2.count >= band.min }
                if ok2 { found = cand }
            }
            if let f = found { allLevels[lvl][idx] = f }
        }
    }
    return allLevels
}

// MARK: - Emit

func emit(levels: [[Puzzle]], to path: String) {
    var out = ""
    out += "// Generated by tools/generate_sliding_blocks.swift — do not edit.\n"
    out += "// Seed is deterministic; re-running with the same seed writes identical content.\n"
    out += "import Foundation\n\n"
    out += "/// Pre-generated puzzles, 30 per level band (#222). Each puzzle is a\n"
    out += "/// width×height board with rectangular blocks; blocks[0] is the 2×2 big\n"
    out += "/// block that must reach the bottom centre. Generated offline so the app\n"
    out += "/// never invents content at runtime.\n"
    out += "enum SlidingBlocksLevels {\n"
    out += "    struct PuzzleData: Hashable, Sendable {\n"
    out += "        let width: Int\n"
    out += "        let height: Int\n"
    out += "        let blocks: [SlidingBlock]\n"
    out += "        let bigIndex: Int\n"
    out += "    }\n\n"
    out += "    static let all: [[PuzzleData]] = [\n"
    for levelIdx in 0..<levels.count {
        let maxStr = bands[levelIdx].max.map(String.init) ?? "+"
        out +=
            "        [ // Level \(levelIdx + 1) \(boardSizes[levelIdx].w)x\(boardSizes[levelIdx].h)  moves \(bands[levelIdx].min)..\(maxStr)\n"
        for puzzle in levels[levelIdx] {
            let blocksStr = puzzle.blocks.map { "SlidingBlock(x: \($0.x), y: \($0.y), w: \($0.w), h: \($0.h))" }.joined(
                separator: ", ")
            out +=
                "            PuzzleData(width: \(puzzle.width), height: \(puzzle.height), blocks: [\(blocksStr)], bigIndex: \(puzzle.bigIndex)),\n"
        }
        out += "        ],\n"
    }
    out += "    ]\n\n"
    out += "    /// Deterministic pick for a level.\n"
    out +=
        "    static func puzzle(for difficulty: Difficulty, using generator: inout some RandomNumberGenerator) -> SlidingBlocksPuzzle {\n"
    out += "        let idx = Int.random(in: 0..<30, using: &generator)\n"
    out += "        let data = all[difficulty.level - 1][idx]\n"
    out +=
        "        return SlidingBlocksPuzzle(width: data.width, height: data.height, blocks: data.blocks, bigIndex: data.bigIndex)\n"
    out += "    }\n\n"
    out += "    /// Puzzles for a level without randomness (tests).\n"
    out += "    static func puzzles(for level: Int) -> [PuzzleData] {\n"
    out += "        precondition((1...10).contains(level))\n"
    out += "        return all[level - 1]\n"
    out += "    }\n"
    out += "}\n"
    do {
        try out.write(toFile: path, atomically: true, encoding: .utf8)
        print("Wrote \(levels.map(\.count).reduce(0,+)) puzzles to \(path)")
    } catch {
        fputs("Failed to write \(path): \(error)\n", stderr)
        exit(1)
    }
}

// MARK: - Main

let seed: UInt64 = {
    if CommandLine.arguments.count > 1, let v = UInt64(CommandLine.arguments[1]) { return v }
    return 42
}()

let scriptPath =
    CommandLine.arguments.first { $0.hasSuffix("generate_sliding_blocks.swift") } ?? "tools/generate_sliding_blocks.swift"
let root = URL(fileURLWithPath: scriptPath).standardizedFileURL.deletingLastPathComponent().deletingLastPathComponent()
let outPath: String
if FileManager.default.fileExists(atPath: root.appendingPathComponent("MenteViva/Games").path) {
    outPath = root.appendingPathComponent("MenteViva/Games/SlidingBlocksLevels.swift").path
} else {
    outPath = "MenteViva/Games/SlidingBlocksLevels.swift"
}

let levels = generateAll(seed: seed)
emit(levels: levels, to: outPath)
