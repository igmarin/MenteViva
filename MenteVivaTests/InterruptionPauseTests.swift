import XCTest

@testable import MenteViva

/// #415: a call or the app switcher never costs a round, and a round owed is started once on return.
final class InterruptionPauseTests: XCTestCase {
    func testGivenARoundOwedWhenTheAppPassesThroughInactiveOnTheWayBackThenItIsStillOwed() {
        var pause = InterruptionPause()
        pause.leave(roundRunning: true)
        // Coming back from the switcher goes background -> inactive -> active; the inactive
        // step reports nothing running and must not wipe the round already owed.
        pause.leave(roundRunning: false)
        XCTAssertTrue(pause.comeBack())
    }

    func testGivenAFlashRunningWhenTheAppLeavesAndReturnsThenTheRoundIsOwedOnce() {
        var pause = InterruptionPause()
        pause.leave(roundRunning: true)
        XCTAssertTrue(pause.isAway)
        XCTAssertTrue(pause.comeBack())
        XCTAssertFalse(pause.comeBack())
    }

    func testGivenNothingRunningWhenTheAppLeavesAndReturnsThenNothingIsOwed() {
        var pause = InterruptionPause()
        pause.leave(roundRunning: false)
        XCTAssertFalse(pause.comeBack())
    }

    func testGivenTheAppIsActiveWhenARoundStartsThenItMayStart() {
        var pause = InterruptionPause()
        XCTAssertTrue(pause.roundStarts())
        XCTAssertFalse(pause.comeBack())
    }

    func testGivenAnAnswerBeatEndsWhileAwayWhenARoundStartsThenItWaitsForTheReturn() {
        var pause = InterruptionPause()
        pause.leave(roundRunning: false)
        XCTAssertFalse(pause.roundStarts())
        XCTAssertTrue(pause.comeBack())
        XCTAssertTrue(pause.roundStarts())
    }

    func testGivenTheAppReturnedWhenARoundStartsThenItMayStartAgain() {
        var pause = InterruptionPause()
        pause.leave(roundRunning: true)
        _ = pause.comeBack()
        XCTAssertFalse(pause.isAway)
        XCTAssertTrue(pause.roundStarts())
    }
}
