import CoreGraphics
import XCTest

@testable import MenteViva

/// Tangram logic (#218): tiles, the 30-shape library, levels and snapping.
final class TangramPuzzleTests: XCTestCase {
    /// Deterministic generator so the property runs never flake.
    private struct SeededGenerator: RandomNumberGenerator {
        var state: UInt64
        mutating func next() -> UInt64 {
            state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
            return state
        }
    }

    // MARK: - Tiles

    func testGivenSevenTilesWhenAreasThenClassicSizes() {
        let areas = Dictionary(
            uniqueKeysWithValues: TangramPiece.allCases.map { ($0, area(of: $0.corners)) })
        XCTAssertEqual(areas[.large] ?? 0, 16, accuracy: 0.001)
        XCTAssertEqual(areas[.large2] ?? 0, 16, accuracy: 0.001)
        XCTAssertEqual(areas[.medium] ?? 0, 8, accuracy: 0.001)
        XCTAssertEqual(areas[.small] ?? 0, 4, accuracy: 0.001)
        XCTAssertEqual(areas[.small2] ?? 0, 4, accuracy: 0.001)
        XCTAssertEqual(areas[.square] ?? 0, 8, accuracy: 0.001)
        XCTAssertEqual(areas[.parallelogram] ?? 0, 8, accuracy: 0.001)
    }

    // MARK: - The library

    func testGivenEveryShapeWhenCheckedThenSevenTilesNoOverlap() {
        XCTAssertEqual(TangramShapes.all.count, 23)
        for shape in TangramShapes.all {
            XCTAssertEqual(
                shape.placements.map(\.piece.rawValue).sorted(),
                TangramPiece.allCases.map(\.rawValue).sorted(), shape.key)
            let polys = shape.placements.map {
                TangramPiece.placedCorners(
                    $0.piece, position: $0.position, rotation: $0.rotation, flipped: $0.flipped)
            }
            // No area sum here: rigid motion keeps every tile's area, so it is always 64 (#395).
            for i in polys.indices {
                for j in polys.indices where j > i {
                    XCTAssertLessThan(intersection(polys[i], polys[j]), 0.000_001, shape.key)
                }
            }
        }
    }

    func testGivenAMirroredTileWhenIntersectedWithItselfThenOverlapIsItsArea() {
        let mirrored = TangramPiece.placedCorners(
            .large, position: CGPoint(x: 6, y: 0), rotation: 0, flipped: true)
        XCTAssertEqual(intersection(mirrored, mirrored), 16, accuracy: 0.001)
    }

    func testGivenAMirroredTileOverlappingAnotherWhenIntersectedThenAreaIsPositive() {
        // The mirrored small tile fills the medium's left half, as removed Armchair did (#395).
        let medium = TangramPiece.placedCorners(.medium, position: .zero, rotation: 0, flipped: false)
        let small = TangramPiece.placedCorners(
            .small, position: CGPoint(x: 2, y: 2), rotation: 1, flipped: true)
        XCTAssertEqual(intersection(medium, small), 4, accuracy: 0.001)
        XCTAssertEqual(intersection(small, medium), 4, accuracy: 0.001)
    }

    func testGivenEveryShapeWhenCheckedThenFitsOnTheBoard() {
        for shape in TangramShapes.all {
            let polys = shape.placements.map {
                TangramPiece.placedCorners(
                    $0.piece, position: $0.position, rotation: $0.rotation, flipped: $0.flipped)
            }
            let xs = polys.flatMap { $0.map(\.x) }
            let ys = polys.flatMap { $0.map(\.y) }
            // Corners at 0 come out of the turn as ±0.000000000000001: allow that rounding.
            XCTAssertGreaterThanOrEqual(xs.min() ?? 0, -0.000_001, shape.key)
            XCTAssertGreaterThanOrEqual(ys.min() ?? 0, -0.000_001, shape.key)
            XCTAssertLessThanOrEqual((xs.max() ?? 0) - (xs.min() ?? 0), 32, shape.key)
            XCTAssertLessThanOrEqual((ys.max() ?? 0) - (ys.min() ?? 0), 32, shape.key)
        }
    }

    func testGivenEveryShapeWhenNamedThenKeysAreTheKeptTwentyThree() {
        // 04, 13, 17, 20, 22, 24 and 30 overlapped and were removed (#395).
        let removed: Set = [4, 13, 17, 20, 22, 24, 30]
        XCTAssertEqual(
            TangramShapes.all.map(\.key),
            (1...30).filter { !removed.contains($0) }.map { String(format: "tangram.shape.%02d", $0) })
    }

    // MARK: - Levels

    func testGivenLevelsWhenRulesThenTheIssueTable() {
        let rules = (1...10).map { TangramPuzzle.rules(for: Difficulty(level: $0)) }
        XCTAssertEqual(rules.map(\.prefill), [4, 3, 1, 0, 0, 0, 0, 0, 0, 0])
        XCTAssertEqual(rules.map(\.outlines), [7, 7, 7, 4, 2, 0, 0, 0, 0, 0])
        XCTAssertEqual(rules.map(\.matchRotation), Array(repeating: false, count: 6) + Array(repeating: true, count: 4))
        XCTAssertEqual(rules.map(\.matchFlip), Array(repeating: false, count: 8) + Array(repeating: true, count: 2))
    }

    func testGivenRisingLevelsWhenRulesThenNeverEasier() {
        let rules = (1...10).map { TangramPuzzle.rules(for: Difficulty(level: $0)) }
        for (lower, higher) in zip(rules, rules.dropFirst()) {
            XCTAssertLessThanOrEqual(higher.prefill, lower.prefill)
            XCTAssertLessThanOrEqual(higher.outlines, lower.outlines)
            XCTAssertTrue(!lower.matchRotation || higher.matchRotation)
            XCTAssertTrue(!lower.matchFlip || higher.matchFlip)
        }
    }

    // MARK: - Placing

    func testGivenLevelOneWhenDealtThenFourSlotsFilledAndThreeLeft() {
        let puzzle = TangramPuzzle(shape: TangramShapes.all[0], rules: rules(level: 1))
        XCTAssertEqual(puzzle.filled.count, 4)
        XCTAssertEqual(puzzle.freeSlots.count, 3)
        XCTAssertFalse(puzzle.isComplete)
    }

    func testGivenLevelOneWhenATileLandsNearItsSlotTurnedAnyWayThenItSnaps() {
        for shape in TangramShapes.all {
            var puzzle = TangramPuzzle(shape: shape, rules: rules(level: 1))
            for slot in puzzle.freeSlots {
                let target = shape.placements[slot]
                let middle = TangramPuzzle.middle(of: target)
                // A little off the middle and turned three steps: it still goes home, turned for the player.
                let result = puzzle.place(
                    target.piece, at: CGPoint(x: middle.x + 0.4, y: middle.y - 0.3),
                    rotation: target.rotation + 3, flipped: !target.flipped)
                XCTAssertEqual(result, .snapped(slot: slot), shape.key)
            }
            XCTAssertTrue(puzzle.isComplete, shape.key)
        }
    }

    func testGivenAFarDropWhenPlacedThenTryAnotherSpotAndNothingFills() {
        var puzzle = TangramPuzzle(shape: TangramShapes.all[0], rules: rules(level: 4))
        let target = TangramShapes.all[0].placements[0]
        let result = puzzle.place(target.piece, at: CGPoint(x: 100, y: 100), rotation: target.rotation, flipped: false)
        XCTAssertEqual(result, .tryAnotherSpot)
        XCTAssertTrue(puzzle.filled.isEmpty)
        XCTAssertEqual(puzzle.attempts, 1)
        XCTAssertEqual(puzzle.correct, 0)
    }

    func testGivenLevelSevenAndAWrongTurnWhenPlacedThenTurnItAndItStaysOut() {
        let shape = TangramShapes.all[0]
        var puzzle = TangramPuzzle(shape: shape, rules: rules(level: 7))
        let slot = shape.placements.firstIndex { $0.piece == .medium }!
        let target = shape.placements[slot]
        let result = puzzle.place(
            target.piece, at: TangramPuzzle.middle(of: target), rotation: target.rotation + 1, flipped: target.flipped)
        XCTAssertEqual(result, .turnIt)
        XCTAssertFalse(puzzle.filled.contains(slot))
    }

    func testGivenLevelTenAndTheRightTurnWhenEveryTileIsPlacedThenTheShapeIsDone() {
        for shape in TangramShapes.all {
            var puzzle = TangramPuzzle(shape: shape, rules: rules(level: 10))
            for target in shape.placements {
                let result = puzzle.place(
                    target.piece, at: TangramPuzzle.middle(of: target), rotation: target.rotation, flipped: target.flipped)
                guard case .snapped = result else { return XCTFail("\(shape.key) \(target.piece): \(result)") }
            }
            XCTAssertTrue(puzzle.isComplete, shape.key)
            XCTAssertEqual(puzzle.correct, 7, shape.key)
        }
    }

    func testGivenASquareTurnedAQuarterWhenPlacedAtLevelTenThenItStillFits() {
        let shape = TangramShapes.all[0]
        var puzzle = TangramPuzzle(shape: shape, rules: rules(level: 10))
        let slot = shape.placements.firstIndex { $0.piece == .square }!
        let target = shape.placements[slot]
        let result = puzzle.place(
            .square, at: TangramPuzzle.middle(of: target), rotation: target.rotation + 2, flipped: target.flipped)
        XCTAssertEqual(result, .snapped(slot: slot))
    }

    func testGivenAMirroredParallelogramWhenPlacedThenFlipMattersOnlyFromNine() {
        let shape = TangramShapes.all[0]
        let slot = shape.placements.firstIndex { $0.piece == .parallelogram }!
        let target = shape.placements[slot]
        let middle = TangramPuzzle.middle(of: target)
        var eight = TangramPuzzle(shape: shape, rules: rules(level: 8))
        XCTAssertEqual(
            eight.place(.parallelogram, at: middle, rotation: target.rotation, flipped: !target.flipped),
            .snapped(slot: slot))
        var nine = TangramPuzzle(shape: shape, rules: rules(level: 9))
        XCTAssertEqual(nine.place(.parallelogram, at: middle, rotation: target.rotation, flipped: !target.flipped), .flipIt)
    }

    func testGivenTwinTrianglesWhenOneLandsOnTheOthersSlotThenItFitsThere() {
        let shape = TangramShapes.all[0]
        var puzzle = TangramPuzzle(shape: shape, rules: rules(level: 10))
        let slot = shape.placements.firstIndex { $0.piece == .large2 }!
        let target = shape.placements[slot]
        // The tray's other large triangle is the same tile to the player.
        let result = puzzle.place(
            .large, at: TangramPuzzle.middle(of: target), rotation: target.rotation, flipped: target.flipped)
        XCTAssertEqual(result, .snapped(slot: slot))
        XCTAssertEqual(puzzle.fittingSlots(for: .large2).count, 1)
    }

    func testGivenASmallTileAndAMinimumReachWhenDroppedJustOutsideShareReachThenItSnaps() {
        // A board at 15pt per unit, and the 60pt target the view asks for: 30pt of reach (#396).
        let (shape, slot, point) = drop(.small, twin: .small2, units: 29.0 / 15)
        XCTAssertGreaterThan(29.0 / 15, TangramPuzzle.snapShare * TangramPiece.small.diagonal)
        var puzzle = TangramPuzzle(shape: shape, rules: rules(level: 7))
        let target = shape.placements[slot]
        let result = puzzle.place(
            .small, at: point, rotation: target.rotation, flipped: target.flipped, minimumReach: 30.0 / 15)
        XCTAssertEqual(result, .snapped(slot: slot))
    }

    func testGivenNoMinimumReachWhenDroppedOutsideShareReachThenTryAnotherSpot() {
        let (shape, slot, point) = drop(.small, twin: .small2, units: 29.0 / 15)
        var puzzle = TangramPuzzle(shape: shape, rules: rules(level: 7))
        let target = shape.placements[slot]
        let result = puzzle.place(.small, at: point, rotation: target.rotation, flipped: target.flipped)
        XCTAssertEqual(result, .tryAnotherSpot)
        XCTAssertTrue(puzzle.filled.isEmpty)
    }

    func testGivenAMinimumReachWhenDroppedPastItThenTryAnotherSpot() {
        // The 60pt target is a floor, not a magnet: 31pt off at 15pt per unit stays outside it.
        let (shape, slot, point) = drop(.small, twin: .small2, units: 31.0 / 15)
        var puzzle = TangramPuzzle(shape: shape, rules: rules(level: 7))
        let target = shape.placements[slot]
        let result = puzzle.place(
            .small, at: point, rotation: target.rotation, flipped: target.flipped, minimumReach: 30.0 / 15)
        XCTAssertEqual(result, .tryAnotherSpot)
        XCTAssertTrue(puzzle.filled.isEmpty)
    }

    func testGivenALargeTileAndASmallerMinimumReachWhenDroppedWithinShareReachThenItStillSnaps() {
        // On a big board (iPad) the share reach is already past 60pt, and it stays as it was.
        let shareReach = TangramPuzzle.snapShare * TangramPiece.large.diagonal
        let (shape, slot, point) = drop(.large, twin: .large2, units: shareReach * 0.9)
        var puzzle = TangramPuzzle(shape: shape, rules: rules(level: 7))
        let target = shape.placements[slot]
        let result = puzzle.place(
            .large, at: point, rotation: target.rotation, flipped: target.flipped, minimumReach: 1)
        XCTAssertEqual(result, .snapped(slot: slot))
    }

    func testGivenVoiceOverWhenATileIsPlacedInANamedSlotThenItGoesHomeAtAnyLevel() {
        let shape = TangramShapes.all[0]
        var puzzle = TangramPuzzle(shape: shape, rules: rules(level: 10))
        let slot = shape.placements.firstIndex { $0.piece == .medium }!
        let other = shape.placements.firstIndex { $0.piece == .square }!
        XCTAssertEqual(puzzle.place(.medium, inSlot: other), .tryAnotherSpot)
        XCTAssertEqual(puzzle.place(.medium, inSlot: slot), .snapped(slot: slot))
        XCTAssertEqual(puzzle.attempts, 2)
        XCTAssertEqual(puzzle.correct, 1)
    }

    func testGivenShowMeOneWhenAskedThenTheFirstFreeSlotFillsWithoutCountingAnAttempt() {
        var puzzle = TangramPuzzle(shape: TangramShapes.all[0], rules: rules(level: 5))
        XCTAssertEqual(puzzle.showOne(), 0)
        XCTAssertEqual(puzzle.filled, [0])
        XCTAssertEqual(puzzle.attempts, 0)
        while puzzle.showOne() != nil {}
        XCTAssertTrue(puzzle.isComplete)
        XCTAssertNil(puzzle.showOne())
    }

    func testGivenLevelsWhenOutlinesThenTheFirstSlotsShowTheirs() {
        let puzzle = TangramPuzzle(shape: TangramShapes.all[0], rules: rules(level: 4))
        XCTAssertEqual(TangramShapes.all[0].placements.indices.filter(puzzle.showsOutline), [0, 1, 2, 3])
    }

    // MARK: - Pick

    func testGivenSeedWhenPickThenDeterministic() {
        var first = SeededGenerator(state: 7)
        var second = SeededGenerator(state: 7)
        XCTAssertEqual(
            TangramPuzzle.pick(from: TangramShapes.all, seen: [], using: &first).key,
            TangramPuzzle.pick(from: TangramShapes.all, seen: [], using: &second).key)
    }

    func testGivenPicksWhenSeenThenEveryShapeBeforeAnyRepeat() {
        var generator = SeededGenerator(state: 1)
        var seen: Set<String> = []
        var keys: [String] = []
        for _ in TangramShapes.all.indices {
            let next = TangramPuzzle.pick(from: TangramShapes.all, seen: seen, using: &generator)
            keys.append(next.key)
            seen.insert(next.key)
        }
        XCTAssertEqual(Set(keys).count, TangramShapes.all.count)
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

    // MARK: - Tray (#396)

    func testGivenTheThreeTrianglesAtOneTurnWhenDrawnInTheTrayThenTheirLegsKeepTheirRatio() {
        for rotation in 0..<8 {
            for flipped in [false, true] {
                let legs = [TangramPiece.large, .medium, .small].map { piece in
                    let points = TangramPuzzle.trayPoints(
                        of: TangramPlacement(piece: piece, position: .zero, rotation: rotation, flipped: flipped))
                    // Corner 0 is the right angle, corner 1 the end of a leg.
                    return Double(hypot(points[1].x - points[0].x, points[1].y - points[0].y))
                }
                // 4 : 2√2 : 2, the same as on the board.
                XCTAssertEqual(legs[0] / legs[2], 2, accuracy: 0.000_001, "turn \(rotation)")
                XCTAssertEqual(legs[1] / legs[2], sqrt(2), accuracy: 0.000_001, "turn \(rotation)")
            }
        }
    }

    func testGivenAnyTileAtAnyOfEightTurnsWhenDrawnInTheTrayThenItFitsCentredInItsCell() {
        for piece in TangramPiece.allCases {
            for rotation in 0..<8 {
                for flipped in [false, true] {
                    let points = TangramPuzzle.trayPoints(
                        of: TangramPlacement(piece: piece, position: .zero, rotation: rotation, flipped: flipped))
                    let xs = points.map(\.x)
                    let ys = points.map(\.y)
                    let label = "\(piece) turn \(rotation) flipped \(flipped)"
                    XCTAssertGreaterThanOrEqual(xs.min() ?? -1, 0, label)
                    XCTAssertLessThanOrEqual(xs.max() ?? 101, 100, label)
                    XCTAssertGreaterThanOrEqual(ys.min() ?? -1, 0, label)
                    XCTAssertLessThanOrEqual(ys.max() ?? 101, 100, label)
                    XCTAssertEqual(((xs.min() ?? 0) + (xs.max() ?? 0)) / 2, 50, accuracy: 0.000_001, label)
                    XCTAssertEqual(((ys.min() ?? 0) + (ys.max() ?? 0)) / 2, 50, accuracy: 0.000_001, label)
                }
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

    private func rules(level: Int) -> TangramRules {
        TangramPuzzle.rules(for: Difficulty(level: level))
    }

    /// The first shape's slot for `piece` and a point `units` from its middle, heading away from its
    /// twin's slot, so no other slot the tile fits is nearer than its own.
    private func drop(
        _ piece: TangramPiece, twin: TangramPiece, units: Double
    ) -> (shape: TangramShape, slot: Int, point: CGPoint) {
        let shape = TangramShapes.all[0]
        let slot = shape.placements.firstIndex { $0.piece == piece }!
        let middle = TangramPuzzle.middle(of: shape.placements[slot])
        let other = TangramPuzzle.middle(of: shape.placements[shape.placements.firstIndex { $0.piece == twin }!])
        let away = hypot(middle.x - other.x, middle.y - other.y)
        let point = CGPoint(
            x: middle.x + (middle.x - other.x) / away * units, y: middle.y + (middle.y - other.y) / away * units)
        return (shape, slot, point)
    }

    private func area(of poly: [CGPoint]) -> Double {
        let next = Array(poly[1...]) + [poly[0]]
        let twice = zip(poly, next).map { a, b in Double(a.x * b.y - b.x * a.y) }.reduce(0, +)
        return abs(twice) / 2
    }

    /// Intersection area of two convex polygons (all tiles are convex). The clip
    /// keeps the left of each edge, so both run counter-clockwise first: a flipped
    /// tile turns clockwise and would otherwise clip everything away (#395).
    private func intersection(_ subject: [CGPoint], _ clip: [CGPoint]) -> Double {
        let clip = counterClockwise(clip)
        var out = counterClockwise(subject)
        for i in clip.indices {
            let edge: (Double, Double) = (
                Double(clip[(i + 1) % clip.count].x - clip[i].x),
                Double(clip[(i + 1) % clip.count].y - clip[i].y)
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

    /// The same polygon with its corners counter-clockwise (positive signed area).
    private func counterClockwise(_ poly: [CGPoint]) -> [CGPoint] {
        let next = Array(poly[1...]) + [poly[0]]
        let twice = zip(poly, next).map { a, b in Double(a.x * b.y - b.x * a.y) }.reduce(0, +)
        return twice < 0 ? poly.reversed() : poly
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
