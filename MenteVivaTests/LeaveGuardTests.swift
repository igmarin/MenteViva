import XCTest

@testable import MenteViva

/// #404: leaving a half-finished game asks first; an untouched or finished one just closes.
final class LeaveGuardTests: XCTestCase {
    func testGivenNoMovesWhenLeavingThenNoConfirmationNeeded() {
        XCTAssertFalse(LeaveGuard.needsConfirmation(inProgress: false, celebrating: false))
    }

    func testGivenMovesMadeWhenLeavingThenConfirmationRequired() {
        XCTAssertTrue(LeaveGuard.needsConfirmation(inProgress: true, celebrating: false))
    }

    func testGivenCelebrationShowingWhenLeavingThenNoConfirmationNeeded() {
        // The counters are still above zero while the celebration shows: the board is done.
        XCTAssertFalse(LeaveGuard.needsConfirmation(inProgress: true, celebrating: true))
    }
}
