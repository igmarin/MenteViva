import XCTest

@testable import MenteViva

/// #470, #482: Sliding Blocks sizes its board from the space, a drag starts
/// only after a clear, mostly straight movement, and a lift never does nothing.
final class SlidingBlocksBoardRulesTests: XCTestCase {
    // MARK: - Board size

    func testGivenWideAreaWhenCellSizeThenHeightLimits() {
        XCTAssertEqual(SlidingBoardLayout.cellSize(in: CGSize(width: 400, height: 340), columns: 4, rows: 5), 68)
    }

    func testGivenTallAreaWhenCellSizeThenWidthLimits() {
        XCTAssertEqual(SlidingBoardLayout.cellSize(in: CGSize(width: 240, height: 900), columns: 4, rows: 5), 60)
    }

    // MARK: - Drag start

    func testGivenWobbleBelowThresholdWhenAxisThenNoDrag() {
        XCTAssertNil(SlidingDragRule.axis(for: CGSize(width: 19, height: 0)))
        XCTAssertNil(SlidingDragRule.axis(for: CGSize(width: -3, height: 19.9)))
    }

    func testGivenDiagonalThatLeadsOnNeitherAxisWhenAxisThenNoDrag() {
        XCTAssertNil(SlidingDragRule.axis(for: CGSize(width: 25, height: 25)))
        XCTAssertNil(SlidingDragRule.axis(for: CGSize(width: 30, height: -24)))
    }

    func testGivenClearHorizontalMovementWhenAxisThenHorizontal() {
        XCTAssertEqual(SlidingDragRule.axis(for: CGSize(width: -20, height: 0)), .horizontal)
        XCTAssertEqual(SlidingDragRule.axis(for: CGSize(width: 40, height: 20)), .horizontal)
    }

    func testGivenClearVerticalMovementWhenAxisThenVertical() {
        XCTAssertEqual(SlidingDragRule.axis(for: CGSize(width: 0, height: 22)), .vertical)
        XCTAssertEqual(SlidingDragRule.axis(for: CGSize(width: 5, height: -30)), .vertical)
    }

    func testGivenWobbleOrUnclearDiagonalWhenFingerLiftsThenItIsATap() {
        XCTAssertEqual(SlidingDragRule.onLift(.zero), .tap)
        XCTAssertEqual(SlidingDragRule.onLift(CGSize(width: 15, height: 15)), .tap)
        // At least 20pt, but leading on neither axis: picked, not lost.
        XCTAssertEqual(SlidingDragRule.onLift(CGSize(width: 25, height: 25)), .tap)
        XCTAssertEqual(SlidingDragRule.onLift(CGSize(width: -40, height: 30)), .tap)
    }

    func testGivenClearLeadWhenFingerLiftsBeforeAnyLockThenItDrags() {
        XCTAssertEqual(SlidingDragRule.onLift(CGSize(width: 45, height: 4)), .drag(.horizontal))
        XCTAssertEqual(SlidingDragRule.onLift(CGSize(width: 20, height: 31)), .drag(.vertical))
    }

    // MARK: - Drag axis

    func testGivenBlockThatMovesOnlySidewaysWhenFingerLeadsDownThenItSlidesSideways() {
        let finger = SlidingDragRule.axis(for: CGSize(width: 20, height: 31))
        XCTAssertEqual(finger, .vertical)
        XCTAssertEqual(SlidingDragRule.blockAxis(finger: .vertical, canSide: true, canUpDown: false), .horizontal)
    }

    func testGivenBlockThatMovesOnlyUpDownWhenFingerLeadsSidewaysThenItSlidesUpDown() {
        XCTAssertEqual(SlidingDragRule.blockAxis(finger: .horizontal, canSide: false, canUpDown: true), .vertical)
    }

    func testGivenBlockThatMovesBothWaysWhenDraggedThenItFollowsTheFinger() {
        XCTAssertEqual(SlidingDragRule.blockAxis(finger: .horizontal, canSide: true, canUpDown: true), .horizontal)
        XCTAssertEqual(SlidingDragRule.blockAxis(finger: .vertical, canSide: true, canUpDown: true), .vertical)
    }

    func testGivenBlockThatCannotMoveWhenDraggedThenItKeepsTheFingersAxis() {
        XCTAssertEqual(SlidingDragRule.blockAxis(finger: .vertical, canSide: false, canUpDown: false), .vertical)
        XCTAssertEqual(SlidingDragRule.blockAxis(finger: .horizontal, canSide: false, canUpDown: false), .horizontal)
    }

    // MARK: - Lift (#482)

    private let cell: CGFloat = 68

    /// A block that can slide up to `forward` cells right and `back` left.
    private func sideways(back: Int = 0, forward: Int = 0, finger: SlidingDragRule.Axis = .horizontal)
        -> SlidingDragLimits
    {
        var reach: [SlidingDirection: Int] = [:]
        if back > 0 { reach[.left] = back }
        if forward > 0 { reach[.right] = forward }
        return SlidingDragLimits(reach: reach, finger: finger)
    }

    func testGivenA25ptStraightWobbleWhenFingerLiftsThenTheBlockIsSelected() {
        let limits = sideways(forward: 2)
        XCTAssertEqual(SlidingDragRule.lift(CGSize(width: 25, height: 0), limits: limits, cell: cell), .select)
        XCTAssertEqual(SlidingDragRule.lift(CGSize(width: -25, height: 0), limits: sideways(back: 2), cell: cell), .select)
    }

    func testGivenBlockThatCannotMoveWhenDraggedAndReleasedThenItIsSelected() {
        let stuck = sideways()
        XCTAssertEqual(stuck.back, 0)
        XCTAssertEqual(stuck.forward, 0)
        XCTAssertEqual(SlidingDragRule.lift(CGSize(width: 120, height: 4), limits: stuck, cell: cell), .select)
        XCTAssertEqual(SlidingDragRule.lift(CGSize(width: -120, height: 4), limits: stuck, cell: cell), .select)
    }

    func testGivenTouchThatNeverLockedWhenFingerLiftsThenTheBlockIsSelected() {
        XCTAssertEqual(SlidingDragRule.lift(CGSize(width: 8, height: 3), limits: nil, cell: cell), .select)
    }

    func testGivenClearDragWhenFingerLiftsThenTheBlockSlidesTheNearestWholeCells() {
        let limits = sideways(back: 2, forward: 2)
        XCTAssertEqual(
            SlidingDragRule.lift(CGSize(width: 70, height: 5), limits: limits, cell: cell), .slide(.right, steps: 1))
        XCTAssertEqual(
            SlidingDragRule.lift(CGSize(width: -140, height: 0), limits: limits, cell: cell), .slide(.left, steps: 2))
    }

    func testGivenDragPastTheClearCellsWhenFingerLiftsThenItStopsAtTheLastClearCell() {
        XCTAssertEqual(
            SlidingDragRule.lift(CGSize(width: 300, height: 0), limits: sideways(forward: 1), cell: cell),
            .slide(.right, steps: 1))
    }

    func testGivenVerticalBlockWhenDraggedDownThenItSlidesDown() {
        let limits = SlidingDragLimits(reach: [.down: 3], finger: .vertical)
        XCTAssertEqual(
            SlidingDragRule.lift(CGSize(width: 2, height: 140), limits: limits, cell: cell), .slide(.down, steps: 2))
    }

    func testGivenSidewaysOnlyBlockWhenFingerLeadsDownBarelySidewaysThenItIsSelected() {
        // The finger leads down, so the block takes its own axis, but only 15pt went that way.
        let limits = sideways(forward: 2, finger: .vertical)
        let wobble = CGSize(width: 15, height: 90)
        XCTAssertTrue(limits.isFallback)
        XCTAssertEqual(limits.clamped(wobble, cell: 20), .zero)
        XCTAssertEqual(SlidingDragRule.lift(wobble, limits: limits, cell: 20), .select)
    }

    func testGivenSidewaysOnlyBlockWhenFingerLeadsDownAndGoesSidewaysEnoughThenItSlides() {
        let limits = sideways(forward: 2, finger: .vertical)
        XCTAssertEqual(
            SlidingDragRule.lift(CGSize(width: 40, height: 70), limits: limits, cell: cell), .slide(.right, steps: 1))
        // Exactly the start distance is enough.
        XCTAssertEqual(
            SlidingDragRule.lift(CGSize(width: 20, height: 90), limits: limits, cell: 20), .slide(.right, steps: 1))
    }

    func testGivenBlockThatFollowsTheFingerWhenFingerGoesLessThanStartDistanceThenNoGateApplies() {
        let limits = sideways(forward: 2)
        XCTAssertFalse(limits.isFallback)
        XCTAssertEqual(limits.clamped(CGSize(width: 15, height: 0), cell: 20), CGSize(width: 15, height: 0))
    }
}
