import XCTest

@testable import MenteViva

/// Tangram logic (#218): tiles, the 30-shape library, levels and snapping.
final class TangramPuzzleTests: XCTestCase {
    // MARK: - Tiles

    func testGivenSevenTilesWhenAreasThenClassicSizes() {
        let areas = Dictionary(
            uniqueKeysWithValues: TangramPiece.allCases.map { ($0, area(of: $0.corners)) })
        XCTAssertEqual(areas[.large], 16, accuracy: 0.001)
        XCTAssertEqual(areas[.large2], 16, accuracy: 0.001)
        XCTAssertEqual(areas[.medium], 8, accuracy: 0.001)
        XCTAssertEqual(areas[.small], 4, accuracy: 0.001)
        XCTAssertEqual(areas[.small2], 4, accuracy: 0.001)
        XCTAssertEqual(areas[.square], 8, accuracy: 0.001)
        XCTAssertEqual(areas[.parallelogram], 8, accuracy: 0.001)
    }

    // MARK: - The library

    func testGivenEveryShapeWhenCheckedThenSevenTilesNoOverlapFullArea() {
        XCTAssertEqual(TangramShapes.all.count, 30)
        for shape in TangramShapes.all {
            XCTAssertEqual(
                shape.placements.map(\.piece.rawValue).sorted(),
                TangramPiece.allCases.map(\.rawValue).sorted(), shape.key)
            let polys = shape.placements.map {
                TangramPiece.placedCorners(
                    $0.piece, position: $0.position, rotation: $0.rotation, flipped: $0.flipped)
            }
            XCTAssertEqual(polys.map(area).reduce(0, +), 64, accuracy: 0.001, shape.key)
            for i in polys.indices {
                for j in polys.indices where j > i {
                    XCTAssertLessThan(intersection(polys[i], polys[j]), 0.000_001, shape.key)
                }
            }
        }
    }

    func testGivenEveryShapeWhenCheckedThenFitsOnTheBoard() {
        for shape in TangramShapes.all {
            let polys = shape.placements.map {
                TangramPiece.placedCorners(
                    $0.piece, position: $0.position, rotation: $0.rotation, flipped: $0.flipped)
            }
            let xs = polys.flatMap { $0.map(\.x) }
            let ys = polys.flatMap { $0.map(\.y) }
            XCTAssertGreaterThanOrEqual(xs.min() ?? 0, 0, shape.key)
            XCTAssertGreaterThanOrEqual(ys.min() ?? 0, 0, shape.key)
            XCTAssertLessThanOrEqual((xs.max() ?? 0) - (xs.min() ?? 0), 32, shape.key)
            XCTAssertLessThanOrEqual((ys.max() ?? 0) - (ys.min() ?? 0), 32, shape.key)
        }
    }

    func testGivenEveryShapeWhenNamedThenKeysRunOneToThirty() {
        XCTAssertEqual(
            TangramShapes.all.map(\.key),
            (1...30).map { String(format: "tangram.shape.%02d", $0) })
    }

    // MARK: - Levels

    func testGivenLevelsWhenRulesThenPrefillFallsAndHelpsNeverReturn() {
        let rules = (1...10).map { TangramPuzzle.rules(for: Difficulty(level: $0)) }
        XCTAssertEqual(rules.map(\.prefill), [7, 6, 4, 2, 0, 0, 0, 0, 0, 0])
        XCTAssertEqual(rules.map(\.outline), [false, false] + Array(repeating: true, count: 8))
        XCTAssertEqual(
            rules.map(\.matchRotation),
            Array(repeating: false, count: 6) + Array(repeating: true, count: 4))
        XCTAssertEqual(
            rules.map(\.matchFlip),
            Array(repeating: false, count: 8) + Array(repeating: true, count: 2))
    }

    func testGivenLevelOneWhenPrefilledThenWholeGhost() {
        let puzzle = TangramPuzzle(shape: TangramShapes.all[0], placed: [])
        let rules = TangramPuzzle.rules(for: Difficulty(level: 1))
        XCTAssertEqual(puzzle.prefilled(rules: rules).count, 7)
        XCTAssertEqual(
            puzzle.prefilled(rules: TangramPuzzle.rules(for: Difficulty(level: 5))).count, 0)
    }

    // MARK: - Snapping

    func testGivenExactDropWhenSnappedThenTrue() {
        let target = TangramShapes.all[0].placements[0]
        XCTAssertTrue(
            TangramPuzzle.snapped(
                target, to: target, matchRotation: true, matchFlip: true))
    }

    func testGivenFarDropWhenSnappedThenFalse() {
        let target = TangramShapes.all[0].placements[0]
        let far = TangramPlacement(
            piece: target.piece,
            position: CGPoint(x: target.position.x + 1, y: target.position.y),
            rotation: target.rotation, flipped: target.flipped)
        XCTAssertFalse(
            TangramPuzzle.snapped(
                far, to: target, matchRotation: false, matchFlip: false))
    }

    func testGivenWrongTileWhenSnappedThenFalse() {
        let target = TangramShapes.all[0].placements[0]
        let other = TangramPlacement(
            piece: target.piece == .medium ? .square : .medium,
            position: target.position, rotation: target.rotation, flipped: target.flipped)
        XCTAssertFalse(
            TangramPuzzle.snapped(
                other, to: target, matchRotation: false, matchFlip: false))
    }

    func testGivenTurnedTileWhenSnappedThenRotationOnlyMattersFromSeven() {
        let target = TangramShapes.all[0].placements[0]
        let turned = TangramPlacement(
            piece: target.piece, position: target.position,
            rotation: (target.rotation + 1) % 8, flipped: target.flipped)
        XCTAssertTrue(
            TangramPuzzle.snapped(
                turned, to: target, matchRotation: false, matchFlip: false))
        XCTAssertFalse(
            TangramPuzzle.snapped(
                turned, to: target, matchRotation: true, matchFlip: false))
    }

    func testGivenMirroredParallelogramWhenSnappedThenFlipMattersFromNine() {
        let target = TangramShapes.all.map(\.placements).joined().first {
            $0.piece == .parallelogram
        }!
        let mirrored = TangramPlacement(
            piece: target.piece, position: target.position,
            rotation: target.rotation, flipped: !target.flipped)
        XCTAssertTrue(
            TangramPuzzle.snapped(
                mirrored, to: target, matchRotation: true, matchFlip: false))
        XCTAssertFalse(
            TangramPuzzle.snapped(
                mirrored, to: target, matchRotation: true, matchFlip: true))
    }

    func testGivenMirroredTileWhenSnappedThenMirrorEqualsAQuarterTurn() {
        // Every tile but the parallelogram mirrors onto its own 90° turn, so
        // the flip state alone never places one: only the effective turn counts.
        for piece in TangramPiece.allCases where !piece.showsFlip {
            for rotation in 0..<8 {
                let at = CGPoint.zero
                let mirrored = TangramPlacement(
                    piece: piece, position: at, rotation: rotation, flipped: true)
                let turned = TangramPlacement(
                    piece: piece, position: at, rotation: (rotation + 2) % 8, flipped: false)
                XCTAssertTrue(
                    TangramPuzzle.snapped(
                        mirrored, to: turned, matchRotation: true, matchFlip: true),
                    "\(piece) rotation \(rotation)")
                let sameTurn = TangramPlacement(
                    piece: piece, position: at, rotation: rotation, flipped: false)
                XCTAssertFalse(
                    TangramPuzzle.snapped(
                        mirrored, to: sameTurn, matchRotation: true, matchFlip: true),
                    "\(piece) rotation \(rotation)")
                XCTAssertTrue(
                    TangramPuzzle.snapped(
                        mirrored, to: sameTurn, matchRotation: false, matchFlip: false),
                    "\(piece) rotation \(rotation)")
            }
        }
    }

    func testGivenAllTilesHomeWhenCorrectThenNoMisplaced() {
        let shape = TangramShapes.all[0]
        let puzzle = TangramPuzzle(shape: shape, placed: shape.placements)
        XCTAssertTrue(puzzle.isCorrect(matchRotation: true, matchFlip: true))
        XCTAssertEqual(puzzle.misplaced(matchRotation: true, matchFlip: true), 0)
    }

    func testGivenOneTileAwayWhenMisplacedThenCountsOne() {
        let shape = TangramShapes.all[0]
        var placed = shape.placements
        placed[0] = TangramPlacement(
            piece: placed[0].piece,
            position: CGPoint(x: placed[0].position.x + 1, y: placed[0].position.y),
            rotation: placed[0].rotation, flipped: placed[0].flipped)
        let puzzle = TangramPuzzle(shape: shape, placed: placed)
        XCTAssertEqual(puzzle.misplaced(matchRotation: false, matchFlip: false), 1)
        XCTAssertFalse(puzzle.isCorrect(matchRotation: false, matchFlip: false))
    }

    // MARK: - Pick

    func testGivenSeedWhenPickThenDeterministic() {
        var first = SeededGenerator(state: 7)
        var second = SeededGenerator(state: 7)
        XCTAssertEqual(
            TangramPuzzle.pick(from: TangramShapes.all, seen: [], using: &first).key,
            TangramPuzzle.pick(from: TangramShapes.all, seen: [], using: &second).key)
    }

    func testGivenPicksWhenSeenThenAllThirtyBeforeAnyRepeat() {
        var generator = SeededGenerator(state: 1)
        var seen: Set<String> = []
        var keys: [String] = []
        for _ in 0..<30 {
            let next = TangramPuzzle.pick(from: TangramShapes.all, seen: seen, using: &generator)
            keys.append(next.key)
            seen.insert(next.key)
        }
        XCTAssertEqual(Set(keys).count, 30)
    }

    // MARK: - Table helpers (#219)

    func testGivenTurnWhenAppliedEightTimesThenBackToStart() {
        let start = TangramShapes.all[0].placements[0]
        let cycled = (0..<8).reduce(start) { acc, _ in TangramPuzzle.turned(acc) }
        XCTAssertEqual(cycled.rotation, start.rotation)
        XCTAssertEqual(cycled.flipped, start.flipped)
        XCTAssertEqual(
            TangramPuzzle.turned(
                TangramPlacement(
                    piece: .square, position: .zero, rotation: 7, flipped: false)
            ).rotation, 0)
    }

    func testGivenFlipWhenAppliedTwiceThenBackToStart() {
        let start = TangramShapes.all[0].placements[0]
        let flipped = TangramPuzzle.mirrored(TangramPuzzle.mirrored(start))
        XCTAssertEqual(flipped.flipped, start.flipped)
        XCTAssertEqual(flipped.rotation, start.rotation)
    }

    func testGivenTilesOutOfPlaceWhenFirstIndexThenFirstOne() {
        let shape = TangramShapes.all[0]
        XCTAssertEqual(
            TangramPuzzle.firstMisplacedIndex(
                placed: Array(repeating: shape.placements[0], count: shape.placements.count),
                in: shape, matchRotation: false, matchFlip: false), 1)
        XCTAssertNil(
            TangramPuzzle.firstMisplacedIndex(
                placed: shape.placements, in: shape,
                matchRotation: true, matchFlip: true))
    }

    func testGivenBoxWhenFittedThenTapRoundTrips() {
        let box = TangramPuzzle.boundingBox(of: TangramShapes.all[0])
        XCTAssertGreaterThan(box.width, 0)
        XCTAssertGreaterThan(box.height, 0)
        for size in [CGSize(width: 300, height: 300), CGSize(width: 200, height: 400)] {
            let fit = TangramPuzzle.fitTransform(box: box, in: size)
            XCTAssertEqual(fit.scale, min(size.width / box.width, size.height / box.height))
            for point in [
                CGPoint(x: box.minX, y: box.minY), CGPoint(x: box.maxX, y: box.maxY),
                CGPoint(x: (box.minX + box.maxX) / 2, y: (box.minY + box.maxY) / 2),
            ] {
                let screen = TangramPuzzle.toScreen(point, scale: fit.scale, origin: fit.origin)
                XCTAssertGreaterThanOrEqual(screen.x, 0)
                XCTAssertLessThanOrEqual(screen.x, size.width)
                XCTAssertGreaterThanOrEqual(screen.y, 0)
                XCTAssertLessThanOrEqual(screen.y, size.height)
                let back = TangramPuzzle.fromScreen(
                    screen, scale: fit.scale, origin: fit.origin)
                XCTAssertEqual(back.x, point.x, accuracy: 0.000_001)
                XCTAssertEqual(back.y, point.y, accuracy: 0.000_001)
            }
        }
    }

    func testGivenEveryRegionWhenSlotInitThenAllNine() {
        let rows: [TangramSlot.Row] = [.top, .middle, .bottom]
        let columns: [TangramSlot.Column] = [.left, .middle, .right]
        let slots = rows.flatMap { row in columns.map { TangramSlot(row: row, column: $0) } }
        XCTAssertEqual(slots.count, 9)
        XCTAssertEqual(Set(slots.map(\.keySuffix)).count, 9)
    }

    func testGivenSquareWhenCentroidThenMiddle() {
        let middle = TangramPuzzle.centroidOffset(
            of: TangramPlacement(piece: .square, position: .zero, rotation: 0, flipped: false))
        XCTAssertEqual(middle.x, sqrt(2.0), accuracy: 0.000_001)
        XCTAssertEqual(middle.y, sqrt(2.0), accuracy: 0.000_001)
    }

    func testGivenTilesWhenGrabbedThenBiggerTilesForgiveMore() {
        XCTAssertGreaterThan(TangramPuzzle.grabRadius(of: .large), 0)
        XCTAssertGreaterThan(
            TangramPuzzle.grabRadius(of: .large), TangramPuzzle.grabRadius(of: .small))
    }

    func testGivenTilesWhenNamedThenPairsShareAKey() {
        XCTAssertEqual(TangramPiece.large.nameKey, TangramPiece.large2.nameKey)
        XCTAssertEqual(TangramPiece.small.nameKey, TangramPiece.small2.nameKey)
        XCTAssertEqual(
            Set(TangramPiece.allCases.map(\.nameKey)).count, 5)
    }

    func testGivenLibraryWhenSlottedThenTilesSpreadAcrossRegions() {
        let regions = Set(
            TangramShapes.all.flatMap { shape in
                shape.placements.map { TangramPuzzle.slot(of: $0, in: shape) }
            }.map(\.keySuffix))
        XCTAssertGreaterThanOrEqual(regions.count, 3)
    }

    // MARK: - Helpers

    private func area(of poly: [CGPoint]) -> Double {
        abs(
            zip(poly, Array(poly.dropFirst()) + [poly[0]]).map { a, b in
                a.x * b.y - b.x * a.y
            }.reduce(0, +)) / 2
    }

    /// Intersection area of two convex polygons (all tiles are convex).
    private func intersection(_ subject: [CGPoint], _ clip: [CGPoint]) -> Double {
        var out = subject
        for i in clip.indices {
            let edge = (
                clip[(i + 1) % clip.count].x - clip[i].x,
                clip[(i + 1) % clip.count].y - clip[i].y
            )
            var next: [CGPoint] = []
            for j in out.indices {
                let current = out[j]
                let previous = out[(j + out.count - 1) % out.count]
                let currentIn =
                    (current.x - clip[i].x) * edge.1 - (current.y - clip[i].y) * edge.0 <= 0.000_000_001
                let previousIn =
                    (previous.x - clip[i].x) * edge.1 - (previous.y - clip[i].y) * edge.0
                    <= 0.000_000_001
                if currentIn {
                    if !previousIn { next.append(cross(previous, current, clip[i], edge)) }
                    next.append(current)
                } else if previousIn {
                    next.append(cross(previous, current, clip[i], edge))
                }
            }
            out = next
            if out.isEmpty { return 0 }
        }
        return area(of: out)
    }

    private func cross(_ from: CGPoint, _ to: CGPoint, _ base: CGPoint, _ edge: (Double, Double))
        -> CGPoint
    {
        let direction = (to.x - from.x, to.y - from.y)
        let denominator = direction.0 * edge.1 - direction.1 * edge.0
        let amount =
            ((base.x - from.x) * edge.1 - (base.y - from.y) * edge.0) / denominator
        return CGPoint(x: from.x + amount * direction.0, y: from.y + amount * direction.1)
    }
}
