import Foundation

/// 18 symbols drawn in code: shapes, numbers 1-9 and nature. No copied art (#220).
nonisolated enum TilePairsSymbol: Int, CaseIterable, Hashable {
    case circle, square, triangle, diamond, star, heart,
        number1, number2, number3, number4, number5, number6, number7, number8, number9,
        leaf, sun, flower
}

/// One tile.
nonisolated struct TilePairsTile: Equatable, Hashable {
    let id: Int
    let symbol: TilePairsSymbol
    let x: Int
    let y: Int
    let layer: Int
}

/// Mahjong-solitaire pairs logic: every deal clears, stuck reshuffles warmly (#220).
nonisolated struct TilePairsDeal {
    static let tilesPerLevel = [8, 12, 16, 20, 24, 28, 36, 44, 56, 72]
    static let layersPerLevel = [1, 1, 1, 2, 2, 2, 2, 3, 3, 3]
    static let lookAlikePerLevel = [false, false, false, false, true, true, true, true, true, true]
    static let minTarget = 60.0
    static let gap = 6.0
    private(set) var tiles: [TilePairsTile]
    private(set) var attempts = 0
    private(set) var correct = 0
    let layers: Int
    /// Pairs in construction order — a guaranteed clearing order.
    private(set) var pairOrder: [[Int]]
    var isCleared: Bool { tiles.isEmpty }
    var isStuck: Bool {
        guard !isCleared else { return false }
        let groups = Dictionary(grouping: freeTiles(), by: \.symbol)
        return !groups.values.contains { $0.count >= 2 }
    }
    func freeTiles() -> [TilePairsTile] { tiles.filter { isFree($0) } }
    func isFree(_ t: TilePairsTile) -> Bool {
        if tiles.contains(where: { $0.x == t.x && $0.y == t.y && $0.layer > t.layer }) { return false }
        let left = tiles.contains { $0.x == t.x - 1 && $0.y == t.y && $0.layer == t.layer }
        let right = tiles.contains { $0.x == t.x + 1 && $0.y == t.y && $0.layer == t.layer }
        return !(left && right)
    }
    static func rules(for d: Difficulty) -> (tiles: Int, layers: Int, lookAlike: Bool) {
        (d.values(tilesPerLevel), d.values(layersPerLevel), d.values(lookAlikePerLevel))
    }
    /// Capped count that keeps tiles ≥ 60pt.
    static func layout(for d: Difficulty, width: Double, height: Double) -> (tiles: Int, layers: Int) {
        var tiles = d.values(tilesPerLevel)
        let layers = d.values(layersPerLevel)
        while tiles > 8, !tilesFit(tiles: tiles, layers: layers, width: width, height: height) { tiles -= 2 }
        if tiles < 8 { tiles = 8 }
        if tiles % 2 == 1 { tiles -= 1 }
        return (tiles, layers)
    }
    private static func tilesFit(tiles: Int, layers: Int, width: Double, height: Double) -> Bool {
        let perLayer = (tiles + layers - 1) / layers
        let availH = height * 0.6
        var best = 0.0
        for cols in 1...perLayer {
            let rows = (perLayer + cols - 1) / cols
            let w = (width - Double(cols - 1) * gap) / Double(cols)
            let h = (availH - Double(rows - 1) * gap) / Double(rows)
            best = max(best, min(w, h))
        }
        return best >= minTarget
    }
    static func positions(for count: Int, layers: Int) -> [(x: Int, y: Int, layer: Int)] {
        var out: [(Int, Int, Int)] = []
        var remaining = count
        var layer = 0
        while remaining > 0, layer < layers {
            let left = layers - layer
            let perLayer = (remaining + left - 1) / left
            let cols = Int(ceil(sqrt(Double(perLayer))))
            for i in 0..<perLayer { out.append((i % cols, i / cols, layer)) }
            remaining -= perLayer
            layer += 1
        }
        return out
    }
    @discardableResult mutating func tryPair(_ a: Int, _ b: Int) -> Bool {
        attempts += 1
        guard a != b, let ta = tiles.first(where: { $0.id == a }),
            let tb = tiles.first(where: { $0.id == b }),
            ta.symbol == tb.symbol, isFree(ta), isFree(tb)
        else { return false }
        tiles.removeAll { $0.id == a || $0.id == b }
        correct += 1
        return true
    }
    /// Warm reshuffle keeps the multiset and deals a solvable board.
    mutating func reshuffle<G: RandomNumberGenerator>(using g: inout G) -> Bool {
        guard isStuck else { return false }
        let syms = tiles.map(\.symbol)
        var counts: [TilePairsSymbol: Int] = [:]
        for s in syms { counts[s, default: 0] += 1 }
        var pairSyms: [TilePairsSymbol] = []
        for (s, c) in counts { for _ in 0..<(c / 2) { pairSyms.append(s) } }
        pairSyms.shuffle(using: &g)
        let pos = Self.positions(for: tiles.count, layers: layers)
        for _ in 0..<30 {
            if let built = Self.build(tiles: tiles.count, layers: layers, pairSymbols: pairSyms, positions: pos, using: &g) {
                tiles = built.tiles
                pairOrder = built.order
                return true
            }
            pairSyms.shuffle(using: &g)
        }
        // Deterministic fallback keeps the multiset and guarantees free tiles (spaced line).
        let spaced: [(x: Int, y: Int, layer: Int)] = (0..<tiles.count).map { i in (x: i * 2, y: 0, layer: 0) }
        let fallbackTiles = spaced.enumerated().map { idx, p in
            TilePairsTile(id: idx, symbol: pairSyms[idx / 2 % pairSyms.count], x: p.x, y: p.y, layer: p.layer)
        }
        let pairs = tiles.count / 2
        let fallbackOrder = (0..<pairs).map { i in [i * 2, i * 2 + 1] }
        tiles = fallbackTiles
        pairOrder = fallbackOrder
        return true
    }
    func clearsWithRecordedOrder() -> Bool {
        var rem = tiles
        func free(_ t: TilePairsTile, _ all: [TilePairsTile]) -> Bool {
            if all.contains(where: { $0.x == t.x && $0.y == t.y && $0.layer > t.layer }) { return false }
            let l = all.contains { $0.x == t.x - 1 && $0.y == t.y && $0.layer == t.layer }
            let r = all.contains { $0.x == t.x + 1 && $0.y == t.y && $0.layer == t.layer }
            return !(l && r)
        }
        for pair in pairOrder {
            guard pair.count == 2, let a = rem.first(where: { $0.id == pair[0] }),
                let b = rem.first(where: { $0.id == pair[1] }),
                a.symbol == b.symbol, free(a, rem), free(b, rem)
            else { return false }
            rem.removeAll { $0.id == a.id || $0.id == b.id }
        }
        return rem.isEmpty
    }
    static func make<G: RandomNumberGenerator>(difficulty d: Difficulty, width: Double, height: Double, using g: inout G)
        -> TilePairsDeal
    {
        let (count, layers) = layout(for: d, width: width, height: height)
        let pos = positions(for: count, layers: layers)
        let pairs = count / 2
        let all = TilePairsSymbol.allCases
        let look = d.values(lookAlikePerLevel)
        let pool: [TilePairsSymbol] = look ? all : Array(all.prefix(12))
        let shuffled = pool.shuffled(using: &g)
        var pairSyms: [TilePairsSymbol] = (0..<pairs).map { shuffled[$0 % shuffled.count] }
        pairSyms.shuffle(using: &g)
        for _ in 0..<50 {
            if let b = build(tiles: count, layers: layers, pairSymbols: pairSyms, positions: pos, using: &g) {
                return TilePairsDeal(tiles: b.tiles, layers: layers, pairOrder: b.order)
            }
            pairSyms.shuffle(using: &g)
        }
        // Deterministic guaranteed-clearing fallback: spaced single-layer line where every tile is free.
        let spaced: [(x: Int, y: Int, layer: Int)] = (0..<count).map { i in (x: i * 2, y: 0, layer: 0) }
        let fallbackTiles = spaced.enumerated().map { idx, p in
            TilePairsTile(id: idx, symbol: pairSyms[idx / 2 % pairSyms.count], x: p.x, y: p.y, layer: p.layer)
        }
        let fallbackOrder = (0..<pairs).map { i in [i * 2, i * 2 + 1] }
        return TilePairsDeal(tiles: fallbackTiles, layers: 1, pairOrder: fallbackOrder)
    }
    private static func build<G: RandomNumberGenerator>(
        tiles count: Int, layers: Int, pairSymbols: [TilePairsSymbol], positions pos: [(x: Int, y: Int, layer: Int)],
        using g: inout G
    ) -> (tiles: [TilePairsTile], order: [[Int]])? {
        var rem = Set(pos.indices)
        var assign: [Int: TilePairsSymbol] = [:]
        var order: [[Int]] = []
        let shuffled = pairSymbols.shuffled(using: &g)
        var idx = 0
        func free(_ set: Set<Int>) -> [Int] {
            set.filter { i in
                let p = pos[i]
                if set.contains(where: { j in j != i && pos[j].x == p.x && pos[j].y == p.y && pos[j].layer > p.layer }) {
                    return false
                }
                let l = set.contains { j in pos[j].x == p.x - 1 && pos[j].y == p.y && pos[j].layer == p.layer }
                let r = set.contains { j in pos[j].x == p.x + 1 && pos[j].y == p.y && pos[j].layer == p.layer }
                return !(l && r)
            }
        }
        while !rem.isEmpty {
            let f = free(rem)
            guard f.count >= 2, idx < shuffled.count else { return nil }
            guard let a = f.randomElement(using: &g) else { return nil }
            let pool = f.filter { $0 != a }
            guard let b = pool.randomElement(using: &g) else { return nil }
            assign[a] = shuffled[idx]
            assign[b] = shuffled[idx]
            order.append([a, b])
            rem.remove(a)
            rem.remove(b)
            idx += 1
        }
        let tiles = pos.indices.map { i in TilePairsTile(id: i, symbol: assign[i]!, x: pos[i].x, y: pos[i].y, layer: pos[i].layer)
        }
        return (tiles, order)
    }
}
