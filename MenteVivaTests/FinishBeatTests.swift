import XCTest

@testable import MenteViva

/// #415: the finished board stays on screen for a beat before the celebration covers it.
final class FinishBeatTests: XCTestCase {
    func testGivenTheLastMoveWhenTheBeatIsTimedThenItIsNineTenthsOfASecond() {
        XCTAssertEqual(FinishBeat.seconds, 0.9)
    }

    @MainActor
    func testGivenACancelledBeatWhenWaitingThenTheCelebrationDoesNotShow() async {
        var shown = false
        let task = FinishBeat.after(seconds: 0.05) { shown = true }
        task.cancel()
        await task.value
        XCTAssertFalse(shown)
    }

    @MainActor
    func testGivenABeatWhenTheWaitEndsThenTheCelebrationShows() async {
        var shown = false
        await FinishBeat.after(seconds: 0.05) { shown = true }.value
        XCTAssertTrue(shown)
    }
}
