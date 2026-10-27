#!/usr/bin/env swift
import Foundation

struct SeededGenerator: RandomNumberGenerator {
    var state: UInt64
    mutating func next() -> UInt64 {
        state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
        return state
    }
}
enum SlidingDirection: String, CaseIterable, Hashable {
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
struct SlidingBlock: Equatable, Hashable {
    let id: Int
    var x: Int
    var y: Int
    let w: Int
    let h: Int
}
struct SlidingMove: Equatable, Hashable {
    let blockId: Int
    let direction: SlidingDirection
    let steps: Int
}
struct SlidingBlocksPuzzle: Equatable, Hashable {
    let width: Int
    let height: Int
    var blocks: [SlidingBlock]
    var exitX: Int { (width - 2) / 2 }
    var isSolved: Bool {
        guard let t = blocks.first(where: { $0.id == 0 }) else { return false }
        return t.x == exitX && t.y == height - 2
    }
    static func moves(from p: SlidingBlocksPuzzle) -> [SlidingMove] {
        var g = Array(repeating: Array(repeating: nil as Int?, count: p.width), count: p.height)
        for b in p.blocks { for dy in 0..<b.h { for dx in 0..<b.w { g[b.y + dy][b.x + dx] = b.id } } }
        var o: [SlidingMove] = []
        for bl in p.blocks {
            for dir in SlidingDirection.allCases {
                var mx = 0
                outer: for step in 1...max(p.width, p.height) {
                    switch dir {
                    case .up:
                        let ny = bl.y - step
                        if ny < 0 { break outer }
                        for dx in 0..<bl.w where g[ny][bl.x + dx] != nil { break outer }
                    case .down:
                        let ny = bl.y + bl.h - 1 + step
                        if ny >= p.height { break outer }
                        for dx in 0..<bl.w where g[ny][bl.x + dx] != nil { break outer }
                    case .left:
                        let nx = bl.x - step
                        if nx < 0 { break outer }
                        for dy in 0..<bl.h where g[bl.y + dy][nx] != nil { break outer }
                    case .right:
                        let nx = bl.x + bl.w - 1 + step
                        if nx >= p.width { break outer }
                        for dy in 0..<bl.h where g[bl.y + dy][nx] != nil { break outer }
                    }
                    mx = step
                }
                if mx > 0 { for s in 1...mx { o.append(SlidingMove(blockId: bl.id, direction: dir, steps: s)) } }
            }
        }
        return o
    }
    func applying(_ m: SlidingMove) -> SlidingBlocksPuzzle {
        var n = self
        if let i = n.blocks.firstIndex(where: { $0.id == m.blockId }) {
            n.blocks[i].x += m.direction.dx * m.steps
            n.blocks[i].y += m.direction.dy * m.steps
        }
        n.blocks.sort { $0.id < $1.id }
        return n
    }
    static func solve(from s: SlidingBlocksPuzzle) -> [SlidingMove]? { solve(from: s, limit: nil) }
    static func solve(from s: SlidingBlocksPuzzle, limit: Int?) -> [SlidingMove]? {
        if s.isSolved { return [] }
        var q = [s]
        var head = 0
        var vis: Set<SlidingBlocksPuzzle> = [s]
        var parent: [SlidingBlocksPuzzle: (SlidingBlocksPuzzle, SlidingMove)] = [:]
        var depth: [SlidingBlocksPuzzle: Int] = [s: 0]
        while head < q.count {
            let cur = q[head]
            head += 1
            let d = depth[cur]!
            if let limit, d >= limit { continue }
            for m in moves(from: cur) {
                let nxt = cur.applying(m)
                if vis.contains(nxt) { continue }
                vis.insert(nxt)
                parent[nxt] = (cur, m)
                depth[nxt] = d + 1
                if nxt.isSolved {
                    var path: [SlidingMove] = [m]
                    var node = cur
                    while let e = parent[node] {
                        path.append(e.1)
                        node = e.0
                    }
                    path.reverse()
                    return path
                }
                q.append(nxt)
            }
            if vis.count > 500_000 { return nil }
        }
        return nil
    }
}
let boardSizePerLevel: [(Int, Int)] = [(3, 4), (3, 4), (4, 4), (4, 4), (4, 5), (4, 5), (4, 5), (4, 5), (4, 5), (4, 5)]
let minMovesPerLevel: [ClosedRange<Int>] = [1...3, 3...5, 5...8, 8...12, 12...16, 16...22, 16...30, 16...35, 16...40, 16...1_000]
let emptyCellsPerLevel: [Int] = [4, 4, 3, 3, 2, 2, 2, 2, 2, 2]
let sizePool: [(w: Int, h: Int)] = [(1, 1), (1, 1), (1, 1), (1, 2), (2, 1)]
func makeSolvedLayout(width: Int, height: Int, emptyCells: Int, using gen: inout SeededGenerator) -> SlidingBlocksPuzzle? {
    let occ = width * height - emptyCells
    var rem = occ - 4
    let ex = (width - 2) / 2
    let ty = height - 2
    var blocks: [SlidingBlock] = [SlidingBlock(id: 0, x: ex, y: ty, w: 2, h: 2)]
    var g = Array(repeating: Array(repeating: nil as Int?, count: width), count: height)
    for dy in 0..<2 { for dx in 0..<2 { g[ty + dy][ex + dx] = 0 } }
    var nid = 1
    var att = 0
    while rem > 0 && att < 300 {
        att += 1
        let sz = sizePool.randomElement(using: &gen)!
        if sz.w * sz.h > rem { continue }
        let mx = width - sz.w
        let my = height - sz.h
        let x = Int.random(in: 0...mx, using: &gen)
        let y = Int.random(in: 0...my, using: &gen)
        var ok = true
        for dy in 0..<sz.h where ok { for dx in 0..<sz.w where ok { if g[y + dy][x + dx] != nil { ok = false } } }
        if !ok { continue }
        blocks.append(SlidingBlock(id: nid, x: x, y: y, w: sz.w, h: sz.h))
        for dy in 0..<sz.h { for dx in 0..<sz.w { g[y + dy][x + dx] = nid } }
        rem -= sz.w * sz.h
        nid += 1
    }
    if blocks.count < 3 { return nil }
    blocks.sort { $0.id < $1.id }
    return SlidingBlocksPuzzle(width: width, height: height, blocks: blocks)
}
func collectFromBase(
    _ base: SlidingBlocksPuzzle, band: ClosedRange<Int>, need: Int, found: inout [SlidingBlocksPuzzle],
    foundSet: inout Set<SlidingBlocksPuzzle>
) {
    let maxDepth = band.upperBound == 1_000 ? 120 : band.upperBound
    var q = [base]
    var head = 0
    var vis: Set<SlidingBlocksPuzzle> = [base]
    var depth: [SlidingBlocksPuzzle: Int] = [base: 0]
    while head < q.count && found.count < need {
        let cur = q[head]
        head += 1
        let d = depth[cur]!
        if d >= maxDepth { continue }
        for m in SlidingBlocksPuzzle.moves(from: cur) {
            let nxt = cur.applying(m)
            if vis.contains(nxt) { continue }
            vis.insert(nxt)
            let nd = d + 1
            depth[nxt] = nd
            if band.contains(nd) {
                if !foundSet.contains(nxt) {
                    found.append(nxt)
                    foundSet.insert(nxt)
                    if found.count >= need { break }
                }
            }
            if nd < maxDepth { q.append(nxt) }
        }
        if vis.count > 1_000_000 { break }
    }
}
let seed: UInt64 = {
    if CommandLine.arguments.count > 1, let v = UInt64(CommandLine.arguments[1]) { return v }
    return 42
}()
var generator = SeededGenerator(state: seed)
let puzzlesPerLevel = 30
var allLevels: [[SlidingBlocksPuzzle]] = []
for level in 1...10 {
    let (w, h) = boardSizePerLevel[level - 1]
    let band = minMovesPerLevel[level - 1]
    let emptyCells = emptyCellsPerLevel[level - 1]
    var found: [SlidingBlocksPuzzle] = []
    var foundSet = Set<SlidingBlocksPuzzle>()
    // Use BFS collection from base for all levels: one BFS per base gives many puzzles within band, efficient.
    var baseAttempts = 0
    let baseLimit = 20
    while found.count < puzzlesPerLevel && baseAttempts < baseLimit {
        baseAttempts += 1
        guard let base = makeSolvedLayout(width: w, height: h, emptyCells: emptyCells, using: &generator) else { continue }
        collectFromBase(base, band: band, need: puzzlesPerLevel, found: &found, foundSet: &foundSet)
        if baseAttempts % 10 == 0 {
            fputs("level \(level) \(w)x\(h) band \(band) found \(found.count)/\(puzzlesPerLevel) bases \(baseAttempts)\n", stderr)
        }
    }
    // If still short, fallback to walk+verify
    if found.count < puzzlesPerLevel {
        var attempts = 0
        while found.count < puzzlesPerLevel && attempts < 50_000 {
            attempts += 1
            guard let base = makeSolvedLayout(width: w, height: h, emptyCells: emptyCells, using: &generator) else { continue }
            let walkTarget = Int.random(in: band.lowerBound...min(band.upperBound, 30), using: &generator)
            var cur = base
            for _ in 0..<walkTarget {
                let moves = SlidingBlocksPuzzle.moves(from: cur)
                if moves.isEmpty { break }
                cur = cur.applying(moves.randomElement(using: &generator)!)
            }
            if cur.isSolved { continue }
            let limit = band.upperBound == 1_000 ? 120 : band.upperBound
            guard let sol = SlidingBlocksPuzzle.solve(from: cur, limit: limit), band.contains(sol.count) else { continue }
            if !foundSet.contains(cur) {
                found.append(cur)
                foundSet.insert(cur)
            }
        }
    }
    let filtered = found.filter { p in
        if let sol = SlidingBlocksPuzzle.solve(from: p), band.contains(sol.count) { return true }
        return false
    }
    if filtered.count < puzzlesPerLevel {
        fputs("WARN level \(level) filtered \(filtered.count)/\(puzzlesPerLevel) (had \(found.count))\n", stderr)
    }
    var outPuzzles = Array(filtered.prefix(puzzlesPerLevel))
    while outPuzzles.count < puzzlesPerLevel, let dup = filtered.randomElement(using: &generator) {
        outPuzzles.append(dup)
        if outPuzzles.count >= puzzlesPerLevel { break }
    }
    // If still short (should not happen), pad with first
    while outPuzzles.count < puzzlesPerLevel { outPuzzles.append(contentsOf: filtered.prefix(1)) }
    allLevels.append(outPuzzles)
    print(
        "Level \(level) \(w)x\(h) -> \(outPuzzles.count) puzzles sample \(outPuzzles.prefix(3).compactMap{SlidingBlocksPuzzle.solve(from:$0)?.count})"
    )
}
let outPath: String = {
    let script = CommandLine.arguments[0]
    let url = URL(fileURLWithPath: script)
    let toolsDir = url.deletingLastPathComponent()
    let root = toolsDir.deletingLastPathComponent()
    return root.appendingPathComponent("MenteViva/Games/SlidingBlocksLevels.swift").path
}()
var out = ""
out += "// Generated by tools/generate_sliding_blocks.swift — do not edit.\n"
out += "// Seed: \(seed). 30 puzzles per level band, verified by solver.\n"
out += "// Mechanic: Huarong Dao style, public domain; art drawn in code; no classic layouts copied.\n"
out += "import Foundation\n\n"
out += "/// 30 generated puzzles per level 1...10 (#222), verified by breadth-first solver.\n"
out += "/// Each level's band is in `SlidingBlocksPuzzle.minMovesPerLevel` and the board\n"
out += "/// size in `boardSizePerLevel`. Content is our own generated data.\n"
out += "nonisolated enum SlidingBlocksLevels {\n"
out += "    static let puzzlesPerLevel: [[SlidingBlocksPuzzle]] = [\n"
for (idx, levelPuzzles) in allLevels.enumerated() {
    out += "        [ // Level \(idx+1) \(boardSizePerLevel[idx].0)x\(boardSizePerLevel[idx].1) band \(minMovesPerLevel[idx])\n"
    for puzzle in levelPuzzles {
        let blocksLiteral = puzzle.blocks.map { "SlidingBlock(id: \($0.id), x: \($0.x), y: \($0.y), w: \($0.w), h: \($0.h))" }
            .joined(separator: ", ")
        out += "            SlidingBlocksPuzzle(width: \(puzzle.width), height: \(puzzle.height), blocks: [\(blocksLiteral)]),\n"
    }
    out += "        ],\n"
}
out += "    ]\n\n"
out += "    /// One puzzle for a difficulty, deterministically picked with a seed.\n"
out +=
    "    static func puzzle<G: RandomNumberGenerator>(for difficulty: Difficulty, seen: Set<Int> = [], using generator: inout G) -> (puzzle: SlidingBlocksPuzzle, index: Int)? {\n"
out += "        let level = difficulty.level\n"
out += "        guard level >= 1 && level <= puzzlesPerLevel.count else { return nil }\n"
out += "        let pool = puzzlesPerLevel[level - 1]\n"
out += "        let unseen = pool.indices.filter { !seen.contains($0) }\n"
out += "        let pickFrom = unseen.isEmpty ? Array(pool.indices) : unseen\n"
out += "        guard !pickFrom.isEmpty else { return nil }\n"
out += "        let chosen = pickFrom[Int.random(in: pickFrom.indices, using: &generator)]\n"
out += "        return (pool[chosen], chosen)\n"
out += "    }\n"
out += "}\n"
do {
    try out.write(toFile: outPath, atomically: true, encoding: .utf8)
    print("Wrote \(outPath) with \(allLevels.map{$0.count}.reduce(0,+)) puzzles (seed \(seed))")
} catch {
    fputs("Failed \\(outPath): \\(error)\n", stderr)
    exit(1)
}
