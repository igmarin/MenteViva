import XCTest

@testable import MenteViva

final class InterruptionPauseTests: XCTestCase {
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
