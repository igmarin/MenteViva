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
    /// `attempts` and `correct`. A shown piece counts as an attempt only.
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

    /// A shown piece adds one attempt and no correct placement; nil means the board is full.
    mutating func showOne() -> Int? {
        guard let slot = freeSlots.first else { return nil }
        attempts += 1
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

    /// UserDefaults key for the shapes already dealt: ids only, so the store stays tiny.
    static let seenKey = "tangram.seen"

    /// The next shape across openings (#416): `pick`, but with the seen ids kept in `defaults`, so a
    /// week of short sessions does not repeat a figure. Ids that are no longer in `shapes` are
    /// ignored and dropped, and the store is cleared the moment every shape has been seen.
    static func nextShape<G: RandomNumberGenerator>(
        from shapes: [TangramShape] = TangramShapes.all, defaults: UserDefaults,
        using generator: inout G
    ) -> TangramShape {
        let known = Set(shapes.map(\.key))
        var seen = Set(defaults.stringArray(forKey: seenKey) ?? []).intersection(known)
        let next = pick(from: shapes, seen: seen, using: &generator)
        seen.insert(next.key)
        if seen.count >= known.count {
            defaults.removeObject(forKey: seenKey)
        } else {
            defaults.set(seen.sorted(), forKey: seenKey)
        }
        return next
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
    /// tile drawn through `toScreen` is hit through `fromScreen`. `maxScale` holds the
    /// figure to the tray's scale (#511), so a tile is the size of its slot.
    static func fitTransform(
        box: CGRect, in size: CGSize, maxScale: CGFloat = .infinity
    ) -> (scale: CGFloat, origin: CGPoint) {
        guard box.width > 0, box.height > 0, size.width > 0, size.height > 0 else {
            return (1, .zero)
        }
        let scale = min(size.width / box.width, size.height / box.height, maxScale)
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

    /// Where a grid tray tile lands (#415): its cell's middle moved by the drag, so a tile held by
    /// its corner drops where the tile is drawn, not under the finger. Both in one coordinate space.
    static func dropPoint(cell: CGRect, translation: CGSize) -> CGPoint {
        CGPoint(x: cell.midX + translation.width, y: cell.midY + translation.height)
    }

    /// The view's 60pt target as a reach in authoring units (#396): `points` from a slot's middle
    /// on a board of `size` showing `shape`. No cap: on an iPhone SE the tall figures draw at under
    /// 10pt per unit, where a large tile's own share is only about 27pt (#481). A board with no size
    /// yet answers 0, since `fitTransform` would fall back to scale 1 and 30 units reaches anywhere.
    static func reachFloor(
        points: Double, shape: TangramShape, in size: CGSize, maxScale: CGFloat = .infinity
    ) -> Double {
        guard size.width > 0, size.height > 0 else { return 0 }
        let scale = fitTransform(box: boundingBox(of: shape), in: size, maxScale: maxScale).scale
        return points / Double(scale)
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

    /// A tray tile's corners in its square cell `cell` points across, in points with y down: turned
    /// and mirrored as the player left it, drawn at the board's `scale` and centred on the cell's middle.
    static func trayPoints(of tile: TangramPlacement, scale: Double, cell: Double = 100) -> [CGPoint] {
        let corners = TangramPiece.placedCorners(
            tile.piece, position: .zero, rotation: tile.rotation, flipped: tile.flipped)
        let xs = corners.map(\.x)
        let ys = corners.map(\.y)
        let midX = ((xs.min() ?? 0) + (xs.max() ?? 0)) / 2
        let midY = ((ys.min() ?? 0) + (ys.max() ?? 0)) / 2
        return corners.map {
            CGPoint(x: cell / 2 + ($0.x - midX) * scale, y: cell / 2 - ($0.y - midY) * scale)
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
/// Slide Over a compact one. Slide Over gets the row until the window is tall enough for the
/// grid's four rows of two (about 1120pt, a 13" iPad), then the grid. The heights are at the
/// default text size; at larger text the page still scrolls when it must (`fitOrScroll`).
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
        // A wrapped grid needs room for the optional level note too; otherwise a row can fit
        // while the grid pushes the whole page into scrolling. A one-row grid is no taller.
        let note = rows > 1 ? 60 + partGap : 0
        if stackedText + board + grid + note <= area.height { return .grid }
        // The row leaves out the level note, on purpose: an upright phone has no other layout than
        // the row, so budgeting 76pt for a note that shows once a day per game would only change
        // which landscape areas stack. Its day scrolls a little, steadily (`keepsSpace`).
        if stackedText + boardMinimum + cell <= area.height || area.height >= area.width { return .row }
        return .sideBySide
    }

    /// Whether the tray is one sliding row, whose tiles travel by system drag.
    var traySlides: Bool { self != .grid }

    // MARK: - One scale for board and tray (#511)

    /// The margin inside a tray cell, around the widest tile, for the cell's edge.
    static let trayInset: CGFloat = 24
    /// The most room any tile takes across or down at any turn, in authoring units (a large
    /// triangle on its long side, 8): every cell is square and holds it at the shared scale.
    static let trayReach = CGFloat(TangramPiece.allCases.map(TangramPuzzle.trayExtent).max() ?? 8)

    /// Points per authoring unit for the figure and the tray alike: the board's fit, held to what
    /// a `tray`-point cell can show. One scale, so a tile in the tray is the size of its slot; the
    /// owner found the tray's tiles, at a third of the figure's scale, confusing.
    static func pieceScale(board: CGSize, tray: CGFloat, figure: CGSize) -> CGFloat {
        guard figure.width > 0, figure.height > 0 else { return (tray - trayInset) / trayReach }
        return min(board.width / figure.width, board.height / figure.height, (tray - trayInset) / trayReach)
    }

    /// The most points per unit the board may draw its figure at. Stacked, the tray's: a tile is
    /// the size of its slot. Side by side, none: the tray keeps its 100pt cell there, and holding
    /// the figure to it drew an 8x8 figure 76pt across on a phone on its side, so the figure fills
    /// its half and the tray's tiles are smaller than their slots.
    func boardCap(tray: CGFloat) -> CGFloat {
        self == .sideBySide ? .infinity : (tray - Self.trayInset) / Self.trayReach
    }

    /// How tall the grid tray stands with `tiles` cells `side` points across in `width`.
    static func gridHeight(side: CGFloat, width: CGFloat, tiles: Int) -> CGFloat {
        let columns = max(1, Int((width + cellGap) / (side + cellGap)))
        let rows = max(1, (tiles + columns - 1) / columns)
        return CGFloat(rows) * side + CGFloat(rows - 1) * cellGap
    }

    /// The tray cell's side, from the measured board and the cell side it was measured with. Stacked,
    /// the board and the tray share one height; this splits it so the figure and the tiles get the
    /// largest scale they can share (the grid also tries each count of rows, at most as wide as the
    /// board). The share doesn't depend on the split, so a second pass returns the same side. Beside
    /// the board the tray keeps its 100pt cell: an iPhone on its side has no height to spare, so
    /// there the figure is drawn larger than the tiles (`boardCap`). Never under 100pt, the touch target.
    func traySide(board: CGSize, tray: CGFloat, figure: CGSize, tiles: Int) -> CGFloat {
        let cell = Self.cell
        guard self != .sideBySide, tiles > 0, figure.width > 0, figure.height > 0, board.width > 0 else { return cell }
        let width = board.width
        let shared = board.height + (self == .grid ? Self.gridHeight(side: tray, width: width, tiles: tiles) : tray)
        var best = (scale: -CGFloat.infinity, side: cell)
        for rows in self == .grid ? Array(1...tiles) : [1] {
            let columns = (tiles + rows - 1) / rows
            let widest = self == .grid ? (width - CGFloat(columns - 1) * Self.cellGap) / CGFloat(columns) : .infinity
            guard widest >= cell else { continue }
            let gaps = CGFloat(rows - 1) * Self.cellGap
            // The scale at which the figure and these rows of cells fill the shared height exactly.
            let filling = (shared - CGFloat(rows) * Self.trayInset - gaps) / (figure.height + CGFloat(rows) * Self.trayReach)
            let fitting = min(width / figure.width, filling, (widest - Self.trayInset) / Self.trayReach)
            // No taller than leaves the board its minimum: under it the page scrolls, the board is
            // measured taller and the side creeps up pass by pass. Whole points: a side a hair over
            // the column's share would drop a column from the grid.
            let room = (shared - gaps - Self.boardMinimum) / CGFloat(rows)
            let side = max(cell, min(room, fitting * Self.trayReach + Self.trayInset).rounded(.down))
            let board = CGSize(width: width, height: shared - CGFloat(rows) * side - gaps)
            let scale = Self.pieceScale(board: board, tray: side, figure: figure)
            if scale > best.scale { best = (scale, side) }
        }
        return best.side
    }
}
