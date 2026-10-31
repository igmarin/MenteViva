import XCTest

@testable import MenteViva

/// #470: Sliding Blocks keeps one board size per deal, and a drag starts only
/// after a clear, mostly straight movement.
final class SlidingBlocksBoardRulesTests: XCTestCase {
    // MARK: - Board size

    func testGivenNoteShowingWhenFirstMoveThenItKeepsItsSpace() {
        let showing = LevelExplainSlot.slot(hasNote: true, hasStarted: false, dismissed: false)
        let afterFirstMove = LevelExplainSlot.slot(hasNote: true, hasStarted: true, dismissed: true)
        XCTAssertEqual(showing, .showing)
        XCTAssertEqual(afterFirstMove, .reserved)
        XCTAssertEqual(showing.takesSpace, afterFirstMove.takesSpace)
    }

    func testGivenNoNoteThisOpenWhenFirstMoveThenNothingIsHeldBack() {
        XCTAssertEqual(LevelExplainSlot.slot(hasNote: false, hasStarted: false, dismissed: false), .none)
        XCTAssertEqual(LevelExplainSlot.slot(hasNote: false, hasStarted: true, dismissed: true), .none)
        XCTAssertFalse(LevelExplainSlot.none.takesSpace)
    }

    func testGivenStartedOnceWhenBackToZeroMovesThenNoteStaysReserved() {
        // First move, undo (or "Start over", or "Play again") back to 0 moves.
        XCTAssertEqual(LevelExplainSlot.slot(hasNote: true, hasStarted: false, dismissed: true), .reserved)
    }

    func testGivenNoteShowingOrReservedWhenCellSizeThenItIsTheSame() {
        // The board gets the page's height minus whatever the note takes.
        let page = CGSize(width: 361, height: 400)
        let noteHeight: CGFloat = 40
        func cell(_ slot: LevelExplainSlot) -> CGFloat {
            let area = CGSize(width: page.width, height: page.height - (slot.takesSpace ? noteHeight : 0))
            return SlidingBoardLayout.cellSize(in: area, columns: 4, rows: 5)
        }
        XCTAssertEqual(cell(.showing), cell(.reserved))
        XCTAssertNotEqual(cell(.showing), cell(.none))
    }

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

    func testGivenAnyTouchWhenFingerLiftsThenItTapsOrDragsTheWayTheFingerLed() {
        // Every touch that did not lock while moving ends here, so none may be dropped:
        // it drags on the axis the finger clearly led on, and only otherwise is a tap.
        for x in stride(from: -60.0, through: 60.0, by: 2.5) {
            for y in stride(from: -60.0, through: 60.0, by: 2.5) {
                let move = CGSize(width: x, height: y)
                switch (SlidingDragRule.onLift(move), SlidingDragRule.axis(for: move)) {
                case (.tap, nil): break
                case (.drag(let dragged), let led?) where dragged == led: break
                case (let touch, let led): XCTFail("\(move): \(touch) but the finger led \(String(describing: led))")
                }
            }
        }
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
}
