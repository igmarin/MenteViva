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
    /// fits wins over a nearer one it would need turning for. `minimumReach`
    /// (authoring units) is a floor under the share-based reach: on a small
    /// board a small tile's share is under a finger's width (#396).
    mutating func place(
        _ piece: TangramPiece, at point: CGPoint, rotation: Int, flipped: Bool, minimumReach: Double = 0
    ) -> TangramPlaceResult {
        attempts += 1
        let reach = max(Self.snapShare * piece.diagonal, minimumReach)
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
    /// empty: the library always has 23, and an empty one is a programming error.
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

    /// The view's 60pt target as a reach in authoring units (#396): `points` from a slot's middle
    /// on a board drawn at `scale` points per unit. Never past a large tile's own share: before the
    /// board has a size, `fitTransform` falls back to scale 1, and 30 units would pull a tile into
    /// a slot from anywhere on the figure.
    static func reachFloor(points: Double, scale: CGFloat) -> Double {
        guard scale > 0 else { return 0 }
        return min(points / Double(scale), snapShare * TangramPiece.large.diagonal)
    }

    /// Each tray tile fits a 76pt square in its 100pt cell, leaving room for the cell's edge.
    static let trayFit = 76.0

    /// Points per authoring unit in the tray, one for every tile in it (#396), so the tiles keep
    /// their true sizes beside each other: fitting each tile to its cell drew the three triangles
    /// the same size. The largest tile still in the tray, at its widest turn, fills the 76pt square;
    /// once the large triangles are home the small tiles grow, from 27pt to 54pt across.
    static func trayScale(for pieces: [TangramPiece]) -> Double {
        trayFit / (pieces.map(trayExtent).max() ?? trayExtent(.large))
    }

    /// The most room a tile takes across or down at any of its eight turns (a mirror is a turned
    /// tile's outline mirrored, so it needs no more): turning a tray tile never overflows its cell.
    static func trayExtent(_ piece: TangramPiece) -> Double {
        (0..<8).map { rotation in
            let corners = TangramPiece.placedCorners(piece, position: .zero, rotation: rotation, flipped: false)
            let xs = corners.map(\.x)
            let ys = corners.map(\.y)
            return Double(max((xs.max() ?? 0) - (xs.min() ?? 0), (ys.max() ?? 0) - (ys.min() ?? 0)))
        }.max() ?? 0
    }

    /// A tray tile's corners in its 100pt cell, in points with y down: turned and mirrored as the
    /// player left it, drawn at the tray's `scale` and centred on the cell's middle.
    static func trayPoints(of tile: TangramPlacement, scale: Double) -> [CGPoint] {
        let corners = TangramPiece.placedCorners(
            tile.piece, position: .zero, rotation: tile.rotation, flipped: tile.flipped)
        let xs = corners.map(\.x)
        let ys = corners.map(\.y)
        let midX = ((xs.min() ?? 0) + (xs.max() ?? 0)) / 2
        let midY = ((ys.min() ?? 0) + (ys.max() ?? 0)) / 2
        return corners.map {
            CGPoint(x: 50 + ($0.x - midX) * scale, y: 50 - ($0.y - midY) * scale)
        }
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

/// How the Tangram table is arranged in the space the game gets (#396). Chosen from the measured
/// area, not the size class: an iPhone Pro Max on its side reports a regular width, and an iPad in
/// Slide Over a compact one. The heights are at the default text size; at larger text the page
/// still scrolls when it must (`fitOrScroll`).
nonisolated enum TangramLayout: Equatable, Sendable {
    /// Board on top, the tray's cells wrapping in a grid under the buttons: a full-screen iPad.
    case grid
    /// Board on top, the tray in one row that slides sideways: an iPhone held upright.
    case row
    /// Board on the left; the hint, buttons and a sliding tray on the right: an iPhone on its side.
    case sideBySide

    /// The board's smallest height: the page fits an iPhone SE without scrolling.
    static let boardMinimum: CGFloat = 200
    /// The board's height before the grid may wrap into a second row and squeeze it.
    static let boardComfortable: CGFloat = 320
    /// A tray cell, and the gap between cells and between the table's parts.
    static let cell: CGFloat = 100
    static let cellGap: CGFloat = 12
    static let partGap: CGFloat = 16
    static let padding: CGFloat = 16
    /// The stacked table's height without board and tray: padding, the instruction's line, the
    /// hint's two reserved lines, the 100pt buttons and the gaps between the five parts.
    static let stackedText: CGFloat = 2 * padding + 30 + 60 + cell + 4 * partGap

    /// The layout for an area of this size holding up to `tiles` tray tiles. A grid of one row is
    /// no taller than the sliding row, so it is used whenever the stack fits; more rows only while
    /// the board keeps a comfortable size. Held upright, the table stacks even when it is short
    /// (and scrolls); on its side it goes side by side once the stack doesn't fit.
    static func choose(for area: CGSize, tiles: Int = TangramPiece.allCases.count) -> TangramLayout {
        let columns = max(1, Int((area.width - 2 * padding + cellGap) / (cell + cellGap)))
        let rows = max(1, (tiles + columns - 1) / columns)
        let grid = CGFloat(rows) * cell + CGFloat(rows - 1) * cellGap
        let board = rows == 1 ? boardMinimum : boardComfortable
        if stackedText + board + grid <= area.height { return .grid }
        if stackedText + boardMinimum + cell <= area.height || area.height >= area.width { return .row }
        return .sideBySide
    }

    /// Whether the tray is one sliding row, whose tiles travel by system drag.
    var traySlides: Bool { self != .grid }
}
