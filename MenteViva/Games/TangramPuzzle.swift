import Foundation

/// One tile placed in a shape: which tile, where its origin sits, how many
/// 45° steps it turns, and whether it mirrors. Authoring coordinates, y up.
nonisolated struct TangramPlacement: Sendable {
    let piece: TangramPiece
    let position: CGPoint
    let rotation: Int  // 0...7 steps of 45°
    let flipped: Bool
}

/// The rules for one level (#218): how many tiles start placed, whether the
/// shape outline shows, and whether rotation and mirror must match.
/// Prefill never rises, and no help ever comes back once gone.
nonisolated struct TangramRules: Equatable, Sendable {
    let prefill: Int
    let outline: Bool
    let matchRotation: Bool
    let matchFlip: Bool
}

/// One Tangram round: the shape to fill and where the player has put tiles.
/// Pure logic; the screen (#219) owns dragging and persistence.
nonisolated struct TangramPuzzle: Sendable {
    /// One row per level 1...10: a full ghost at 1, six tiles at 2, four at 3,
    /// two at 4, then bare silhouettes; the outline shows from 3, rotation
    /// must match from 7, mirrors (which only the parallelogram shows) from 9.
    static let rulesPerLevel: [TangramRules] = [
        TangramRules(prefill: 7, outline: false, matchRotation: false, matchFlip: false),
        TangramRules(prefill: 6, outline: false, matchRotation: false, matchFlip: false),
        TangramRules(prefill: 4, outline: true, matchRotation: false, matchFlip: false),
        TangramRules(prefill: 2, outline: true, matchRotation: false, matchFlip: false),
        TangramRules(prefill: 0, outline: true, matchRotation: false, matchFlip: false),
        TangramRules(prefill: 0, outline: true, matchRotation: false, matchFlip: false),
        TangramRules(prefill: 0, outline: true, matchRotation: true, matchFlip: false),
        TangramRules(prefill: 0, outline: true, matchRotation: true, matchFlip: false),
        TangramRules(prefill: 0, outline: true, matchRotation: true, matchFlip: true),
        TangramRules(prefill: 0, outline: true, matchRotation: true, matchFlip: true),
    ]

    /// How close a dropped tile must be, in authoring units (half a unit on
    /// the 8×8 square): generous on purpose, this is a pastime, not an exam.
    static let snapTolerance = 0.5

    let shape: TangramShape
    /// The player's tiles, one per shape tile in the same order.
    var placed: [TangramPlacement]

    static func rules(for difficulty: Difficulty) -> TangramRules {
        difficulty.values(rulesPerLevel)
    }

    /// Tiles that start placed at this level: the first `prefill` targets.
    func prefilled(rules: TangramRules) -> [TangramPlacement] {
        Array(shape.placements.prefix(rules.prefill))
    }

    /// Whether a dropped tile snaps onto its target: the right tile, near the
    /// spot, turned right when the level asks, mirrored right when the level
    /// asks. Mirroring only constrains tiles that show it (the parallelogram).
    static func snapped(
        _ placed: TangramPlacement, to target: TangramPlacement,
        matchRotation: Bool, matchFlip: Bool
    ) -> Bool {
        guard placed.piece == target.piece else { return false }
        let distance = hypot(
            placed.position.x - target.position.x, placed.position.y - target.position.y)
        guard distance <= snapTolerance else { return false }
        if matchRotation, effectiveRotation(placed) != effectiveRotation(target) { return false }
        if matchFlip, target.piece.showsFlip, placed.flipped != target.flipped { return false }
        return true
    }

    /// The turn a placement really means, in 45° steps. Every tile but the
    /// parallelogram mirrors onto its own 90° turn, so a flipped tile counts
    /// as turned two steps further; without this, a visually perfect drop
    /// with the other flip state would never snap.
    static func effectiveRotation(_ placement: TangramPlacement) -> Int {
        let steps = ((placement.rotation % 8) + 8) % 8
        if !placement.piece.showsFlip, placement.flipped {
            return (steps + 2) % 8
        }
        return steps
    }

    /// Wrongly placed tiles: the attempts count the celebration reads.
    func misplaced(matchRotation: Bool, matchFlip: Bool) -> Int {
        zip(placed, shape.placements).filter { own, target in
            !Self.snapped(own, to: target, matchRotation: matchRotation, matchFlip: matchFlip)
        }.count
    }

    /// The round is done when no tile is misplaced.
    func isCorrect(matchRotation: Bool, matchFlip: Bool) -> Bool {
        placed.count == shape.placements.count
            && misplaced(
                matchRotation: matchRotation, matchFlip: matchFlip) == 0
    }

    /// The next shape: an unseen one when any remains, so none repeats until
    /// all 30 have been seen; seeded, so tests control it.
    static func pick<G: RandomNumberGenerator>(
        from shapes: [TangramShape] = TangramShapes.all, seen: Set<String>,
        using generator: inout G
    ) -> TangramShape {
        let unseen = shapes.filter { !seen.contains($0.key) }
        return (unseen.isEmpty ? shapes : unseen).randomElement(using: &generator) ?? shapes[0]
    }
}
