import XCTest

@testable import MenteViva

/// #470: Sliding Blocks keeps one board size per deal, and a drag starts only
/// after a clear, mostly straight movement.
final class SlidingBlocksBoardRulesTests: XCTestCase {
    // MARK: - Board size

    func testGivenSameDealAndScreenWhenNoteShowsOrIsDismissedThenItStillTakesItsSpace() {
        let showing = SlidingBoardLayout.NoteSlot.slot(hasNote: true, hasStarted: false)
        let afterFirstMove = SlidingBoardLayout.NoteSlot.slot(hasNote: true, hasStarted: true)
        XCTAssertEqual(showing, .showing)
        XCTAssertEqual(afterFirstMove, .reserved)
        XCTAssertEqual(showing.takesSpace, afterFirstMove.takesSpace)
    }

    func testGivenNoNoteThisDealWhenFirstMoveThenNothingIsHeldBack() {
        XCTAssertEqual(SlidingBoardLayout.NoteSlot.slot(hasNote: false, hasStarted: false), .none)
        XCTAssertEqual(SlidingBoardLayout.NoteSlot.slot(hasNote: false, hasStarted: true), .none)
        XCTAssertFalse(SlidingBoardLayout.NoteSlot.none.takesSpace)
    }

    func testGivenSameAreaWhenCellSizeAskedTwiceThenItIsTheSame() {
        let area = CGSize(width: 361, height: 380)
        XCTAssertEqual(
            SlidingBoardLayout.cellSize(in: area, columns: 4, rows: 5),
            SlidingBoardLayout.cellSize(in: area, columns: 4, rows: 5))
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
        XCTAssertFalse(SlidingDragRule.isTap(CGSize(width: 15, height: 15)))
    }
}
