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

    // MARK: - Table helpers (#219)

    /// One step clockwise for the Turn button: 45°, wrapping around.
    static func turned(_ placement: TangramPlacement) -> TangramPlacement {
        TangramPlacement(
            piece: placement.piece, position: placement.position,
            rotation: (placement.rotation + 1) % 8, flipped: placement.flipped)
    }

    /// Mirror toggle for the Flip button.
    static func mirrored(_ placement: TangramPlacement) -> TangramPlacement {
        TangramPlacement(
            piece: placement.piece, position: placement.position,
            rotation: placement.rotation, flipped: !placement.flipped)
    }

    /// The first tile still out of place, for "Show me one"; nil when done.
    static func firstMisplacedIndex(
        placed: [TangramPlacement], in shape: TangramShape,
        matchRotation: Bool, matchFlip: Bool
    ) -> Int? {
        for index in placed.indices where index < shape.placements.count {
            if !snapped(
                placed[index], to: shape.placements[index],
                matchRotation: matchRotation, matchFlip: matchFlip)
            {
                return index
            }
        }
        return nil
    }

    /// The silhouette's frame in authoring units, for fitting it on screen.
    static func boundingBox(of shape: TangramShape) -> CGRect {
        let points = shape.placements.flatMap {
            TangramPiece.placedCorners(
                $0.piece, position: $0.position, rotation: $0.rotation, flipped: $0.flipped)
        }
        let xs = points.map(\.x)
        let ys = points.map(\.y)
        guard let minX = xs.min(), let maxX = xs.max(), let minY = ys.min(),
            let maxY = ys.max()
        else { return .zero }
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }

    /// Maps authoring units (y up) into a screen rect (y down), scaled to fit
    /// and centred; the inverse maps a tap back. One transform both ways, so a
    /// tile drawn through `toScreen` is hit through `fromScreen`.
    static func fitTransform(box: CGRect, in size: CGSize) -> (scale: CGFloat, origin: CGPoint) {
        guard box.width > 0, box.height > 0, size.width > 0, size.height > 0 else {
            return (1, .zero)
        }
        let scale = min(size.width / box.width, size.height / box.height)
        let origin = CGPoint(
            x: (size.width - box.width * scale) / 2 - box.minX * scale,
            y: (size.height + box.height * scale) / 2 + box.minY * scale)
        return (scale, origin)
    }

    static func toScreen(
        _ point: CGPoint, scale: CGFloat, origin: CGPoint
    ) -> CGPoint {
        CGPoint(x: origin.x + point.x * scale, y: origin.y - point.y * scale)
    }

    static func fromScreen(
        _ point: CGPoint, scale: CGFloat, origin: CGPoint
    ) -> CGPoint {
        CGPoint(x: (point.x - origin.x) / scale, y: (origin.y - point.y) / scale)
    }

    /// The tile's middle relative to its origin: taps place tiles by the
    /// middle, not the corner, so tapping a ghost's body lands the tile on it.
    static func centroidOffset(of placement: TangramPlacement) -> CGPoint {
        let corners = TangramPiece.placedCorners(
            placement.piece, position: .zero,
            rotation: placement.rotation, flipped: placement.flipped)
        return CGPoint(
            x: corners.map(\.x).reduce(0, +) / CGFloat(corners.count),
            y: corners.map(\.y).reduce(0, +) / CGFloat(corners.count))
    }

    /// How close a tap must land to a tile's middle to pick it up: half the
    /// tile's diagonal, generous on purpose.
    static func grabRadius(of piece: TangramPiece) -> CGFloat {
        let xs = piece.corners.map(\.x)
        let ys = piece.corners.map(\.y)
        return hypot((xs.max() ?? 0) - (xs.min() ?? 0), (ys.max() ?? 0) - (ys.min() ?? 0)) / 2
    }

    /// Where a tile's target sits in the figure, for VoiceOver slot actions:
    /// thirds of the silhouette, top meaning visually on top.
    static func slot(of placement: TangramPlacement, in shape: TangramShape) -> TangramSlot {
        let box = boundingBox(of: shape)
        let offset = centroidOffset(of: placement)
        let middle = CGPoint(
            x: placement.position.x + offset.x, y: placement.position.y + offset.y)
        let across: TangramSlot.Column =
            middle.x < box.minX + box.width / 3 ? .left : middle.x > box.maxX - box.width / 3 ? .right : .middle
        let down: TangramSlot.Row =
            middle.y > box.maxY - box.height / 3 ? .top : middle.y < box.minY + box.height / 3 ? .bottom : .middle
        return TangramSlot(row: down, column: across)
    }
}

/// Nine regions of the silhouette, naming the VoiceOver slot actions (#219).
/// The view localizes each case; the logic only places tiles in thirds.
nonisolated enum TangramSlot: Sendable {
    enum Row: Sendable { case top, middle, bottom }
    enum Column: Sendable { case left, middle, right }

    case topLeft, top, topRight, left, middle, right, bottomLeft, bottom, bottomRight

    init(row: Row, column: Column) {
        switch (row, column) {
        case (.top, .left): self = .topLeft
        case (.top, .middle): self = .top
        case (.top, .right): self = .topRight
        case (.middle, .left): self = .left
        case (.middle, .middle): self = .middle
        case (.middle, .right): self = .right
        case (.bottom, .left): self = .bottomLeft
        case (.bottom, .middle): self = .bottom
        case (.bottom, .right): self = .bottomRight
        }
    }

    /// The string key suffix, so the view reads one key per region.
    var keySuffix: String {
        switch self {
        case .topLeft: "top.left"
        case .top: "top"
        case .topRight: "top.right"
        case .left: "left"
        case .middle: "middle"
        case .right: "right"
        case .bottomLeft: "bottom.left"
        case .bottom: "bottom"
        case .bottomRight: "bottom.right"
        }
    }
}
