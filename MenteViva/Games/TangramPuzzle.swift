import CoreGraphics
import Foundation

/// One tile placed in a shape: which tile, where its origin sits, how many
/// 45° steps it turns, and whether it mirrors. Authoring coordinates, y up.
nonisolated struct TangramPlacement: Equatable, Sendable {
    let piece: TangramPiece
    let position: CGPoint
    let rotation: Int  // 0...7 steps of 45°
    let flipped: Bool
}

/// The rules for one level (#218): how many slots start filled, how many slot
/// outlines show inside the silhouette, and whether turn and mirror must match.
nonisolated struct TangramRules: Equatable, Sendable {
    let prefill: Int
    /// Slot outlines drawn inside the silhouette; 7 means every slot.
    let outlines: Int
    let matchRotation: Bool
    let matchFlip: Bool
}

/// What happened to a dropped tile (#218). Every miss says what to try next,
/// warmly; there is no "wrong".
nonisolated enum TangramPlaceResult: Equatable, Sendable {
    /// It went home, into this slot.
    case snapped(slot: Int)
    /// Near a slot it fits, but turned the other way (levels 7+).
    case turnIt
    /// Near the parallelogram's slot, but mirrored (levels 9+).
    case flipIt
    /// Not near any free slot that takes this tile.
    case tryAnotherSpot
}

/// One Tangram round (#218): the shape to fill and which of its slots are filled.
/// Pure logic; the screen (#219) owns taps, drags and drawing. A miss never
/// leaves a tile lying on the board: it goes back to the tray with a hint.
nonisolated struct TangramPuzzle: Sendable {
    /// One row per level 1...10. Four slots start filled at level 1 and none
    /// from 4; every slot shows its outline up to 3, then four, two, none; the
    /// turn must match from 7 and the mirror (only the parallelogram has one)
    /// from 9. Below 7 a tile dropped near its slot turns itself into place.
    static let rulesPerLevel: [TangramRules] = [
        TangramRules(prefill: 4, outlines: 7, matchRotation: false, matchFlip: false),
        TangramRules(prefill: 3, outlines: 7, matchRotation: false, matchFlip: false),
        TangramRules(prefill: 1, outlines: 7, matchRotation: false, matchFlip: false),
        TangramRules(prefill: 0, outlines: 4, matchRotation: false, matchFlip: false),
        TangramRules(prefill: 0, outlines: 2, matchRotation: false, matchFlip: false),
        TangramRules(prefill: 0, outlines: 0, matchRotation: false, matchFlip: false),
        TangramRules(prefill: 0, outlines: 0, matchRotation: true, matchFlip: false),
        TangramRules(prefill: 0, outlines: 0, matchRotation: true, matchFlip: false),
        TangramRules(prefill: 0, outlines: 0, matchRotation: true, matchFlip: true),
        TangramRules(prefill: 0, outlines: 0, matchRotation: true, matchFlip: true),
    ]

    /// How near a tile's middle must land to a slot's middle, as a share of the
    /// tile's size (its bounding diagonal). Generous on purpose: for a shaky
    /// hand this is a pastime, not an exam (the issue asks for at least 30%).
    static let snapShare = 0.35

    let shape: TangramShape
    let rules: TangramRules
    /// Slots already home, as indices into `shape.placements`.
    private(set) var filled: Set<Int>
    /// Placements tried and placements that went home: the session's
    /// `attempts` and `correct`. "Show me one" counts as neither.
    private(set) var attempts = 0
    private(set) var correct = 0

    init(shape: TangramShape, rules: TangramRules) {
        self.shape = shape
        self.rules = rules
        filled = Set(shape.placements.indices.prefix(rules.prefill))
    }

    static func rules(for difficulty: Difficulty) -> TangramRules {
        difficulty.values(rulesPerLevel)
    }

    /// Slots still to fill, in shape order: the tray holds one tile for each.
    var freeSlots: [Int] { shape.placements.indices.filter { !filled.contains($0) } }

    var isComplete: Bool { filled.count == shape.placements.count }

    /// Whether this slot's own outline shows inside the silhouette.
    func showsOutline(_ slot: Int) -> Bool { slot < rules.outlines }

    /// Free slots this tile could fill (the twin triangles fit each other's).
    func fittingSlots(for piece: TangramPiece) -> [Int] {
        freeSlots.filter { shape.placements[$0].piece.kind == piece.kind }
    }

    /// A tile dropped with its middle at `point` (authoring units), turned and
    /// mirrored as the player left it. It goes into the nearest free slot of
    /// its kind within reach, turning itself when the level allows; a slot it
    /// fits wins over a nearer one it would need turning for.
    mutating func place(
        _ piece: TangramPiece, at point: CGPoint, rotation: Int, flipped: Bool
    ) -> TangramPlaceResult {
        attempts += 1
        let reach = Self.snapShare * piece.diagonal
        let near = fittingSlots(for: piece)
            .map { (slot: $0, distance: Self.distance(point, Self.middle(of: shape.placements[$0]))) }
            .filter { $0.distance <= reach }
            .sorted { $0.distance < $1.distance }
        guard let nearest = near.first else { return .tryAnotherSpot }
        let fitting = near.first {
            Self.fits(piece, rotation: rotation, flipped: flipped, into: shape.placements[$0.slot], rules: rules)
        }
        if let fitting {
            filled.insert(fitting.slot)
            correct += 1
            return .snapped(slot: fitting.slot)
        }
        let target = shape.placements[nearest.slot]
        let mirrorFits =
            piece.showsFlip
            && Self.sameOutline(piece, rotation: rotation, flipped: !flipped, as: target)
        return mirrorFits ? .flipIt : .turnIt
    }

    /// The VoiceOver way (#219): the player names the tile and the slot, and
    /// the tile goes there turned right. Choosing which tile goes where is the
    /// puzzle; fine turning by ear is not, so this works at every level.
    mutating func place(_ piece: TangramPiece, inSlot slot: Int) -> TangramPlaceResult {
        attempts += 1
        guard fittingSlots(for: piece).contains(slot) else { return .tryAnotherSpot }
        filled.insert(slot)
        correct += 1
        return .snapped(slot: slot)
    }

    /// "Show me one": the first free slot fills itself. Returns it, or nil when done.
    mutating func showOne() -> Int? {
        guard let slot = freeSlots.first else { return nil }
        filled.insert(slot)
        return slot
    }

    /// Whether a tile turned this way sits in `target` the way the level asks:
    /// any turn below level 7; from 7 the same outline, with the parallelogram
    /// allowed either mirror until 9.
    static func fits(
        _ piece: TangramPiece, rotation: Int, flipped: Bool, into target: TangramPlacement,
        rules: TangramRules
    ) -> Bool {
        guard rules.matchRotation else { return true }
        if sameOutline(piece, rotation: rotation, flipped: flipped, as: target) { return true }
        return !rules.matchFlip && piece.showsFlip
            && sameOutline(piece, rotation: rotation, flipped: !flipped, as: target)
    }

    /// Whether the tile, turned and mirrored so, covers exactly the target's
    /// outline once their middles meet. Comparing corners, not turn counts,
    /// keeps every symmetry right: a square turned 90° or a parallelogram
    /// turned 180° is the same outline, and a mirrored triangle is a turned one.
    static func sameOutline(
        _ piece: TangramPiece, rotation: Int, flipped: Bool, as target: TangramPlacement
    ) -> Bool {
        let own = TangramPiece.placedCorners(piece, position: .zero, rotation: rotation, flipped: flipped)
        let goal = TangramPiece.placedCorners(
            target.piece, position: target.position, rotation: target.rotation, flipped: target.flipped)
        guard own.count == goal.count else { return false }
        let ownMiddle = average(own)
        let goalMiddle = average(goal)
        let moved = own.map { CGPoint(x: $0.x - ownMiddle.x + goalMiddle.x, y: $0.y - ownMiddle.y + goalMiddle.y) }
        return moved.allSatisfy { corner in goal.contains { distance($0, corner) < 0.01 } }
    }

    /// A placement's middle (the average of its corners), where taps aim.
    static func middle(of placement: TangramPlacement) -> CGPoint {
        average(
            TangramPiece.placedCorners(
                placement.piece, position: placement.position,
                rotation: placement.rotation, flipped: placement.flipped))
    }

    /// The next shape: an unseen one when any remains, so none repeats until
    /// all have been seen; seeded, so tests control it. `shapes` must not be
    /// empty: the library always has 30, and an empty one is a programming error.
    static func pick<G: RandomNumberGenerator>(
        from shapes: [TangramShape] = TangramShapes.all, seen: Set<String>,
        using generator: inout G
    ) -> TangramShape {
        precondition(!shapes.isEmpty, "TangramPuzzle.pick needs at least one shape")
        let unseen = shapes.filter { !seen.contains($0.key) }
        let pool = unseen.isEmpty ? shapes : unseen
        return pool[Int.random(in: pool.indices, using: &generator)]
    }

    private static func average(_ points: [CGPoint]) -> CGPoint {
        let count = CGFloat(max(points.count, 1))
        return CGPoint(
            x: points.map(\.x).reduce(0, +) / count, y: points.map(\.y).reduce(0, +) / count)
    }

    private static func distance(_ a: CGPoint, _ b: CGPoint) -> Double {
        Double(hypot(a.x - b.x, a.y - b.y))
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

    /// Where a tile's target sits in the figure, for VoiceOver slot actions:
    /// thirds of the silhouette, top meaning visually on top.
    static func slot(of placement: TangramPlacement, in shape: TangramShape) -> TangramSlot {
        let box = boundingBox(of: shape)
        let center = Self.middle(of: placement)
        let across: TangramSlot.Column =
            center.x < box.minX + box.width / 3 ? .left : center.x > box.maxX - box.width / 3 ? .right : .middle
        let down: TangramSlot.Row =
            center.y > box.maxY - box.height / 3 ? .top : center.y < box.minY + box.height / 3 ? .bottom : .middle
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
