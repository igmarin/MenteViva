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

    func testGivenWobbleBelowThresholdWhenFingerLiftsThenItIsATap() {
        XCTAssertTrue(SlidingDragRule.isTap(.zero))
        XCTAssertTrue(SlidingDragRule.isTap(CGSize(width: 12, height: 12)))
        XCTAssertFalse(SlidingDragRule.isTap(CGSize(width: 20, height: 0)))
        // A diagonal wobble under the threshold on both axes is still a tap, not a lost touch.
        XCTAssertTrue(SlidingDragRule.isTap(CGSize(width: 15, height: 15)))
        XCTAssertFalse(SlidingDragRule.isTap(CGSize(width: 25, height: 25)))
    }

    func testGivenAnyTouchWhenFingerLiftsThenItIsATapOrADragNeverNeither() {
        for x in stride(from: -40.0, through: 40.0, by: 5) {
            for y in stride(from: -40.0, through: 40.0, by: 5) {
                let move = CGSize(width: x, height: y)
                let isDragOrDiagonal = max(abs(x), abs(y)) >= SlidingDragRule.startDistance
                XCTAssertNotEqual(SlidingDragRule.isTap(move), isDragOrDiagonal, "\(move)")
            }
        }
    }
}
