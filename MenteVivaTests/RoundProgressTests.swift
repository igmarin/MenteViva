import XCTest
@testable import MenteViva

/// Boundary tests for the round counter every game uses. Written after a crash
/// where a counter ran one past the end of an array (#30) — these are the cases
/// that would have caught it.
final class RoundProgressTests: XCTestCase {

    func testGivenFreshSessionWhenStartingThenItIsNotFinished() {
        let progress = RoundProgress(totalRounds: 3)
        XCTAssertFalse(progress.isFinished)
        XCTAssertEqual(progress.completedRounds, 0)
        XCTAssertEqual(progress.displayRound, 1)
    }

    func testGivenMiddleOfSessionWhenAdvancingThenItIsNotFinishedYet() {
        var progress = RoundProgress(totalRounds: 3)
        XCTAssertFalse(progress.completeRound())
        XCTAssertFalse(progress.completeRound())
        XCTAssertEqual(progress.completedRounds, 2)
        XCTAssertEqual(progress.displayRound, 3)
        XCTAssertFalse(progress.isFinished)
    }

    func testGivenLastRoundWhenAdvancingThenItReportsFinished() {
        var progress = RoundProgress(totalRounds: 3)
        _ = progress.completeRound()
        _ = progress.completeRound()
        XCTAssertTrue(progress.completeRound())
        XCTAssertTrue(progress.isFinished)
    }

    func testGivenFinishedSessionWhenAdvancingAgainThenItStaysAtTheEnd() {
        var progress = RoundProgress(totalRounds: 2)
        _ = progress.completeRound()
        _ = progress.completeRound()
        XCTAssertTrue(progress.completeRound())   // idempotent, no over-count
        XCTAssertEqual(progress.completedRounds, 2)
        XCTAssertEqual(progress.displayRound, 2)  // clamps, never 3/2
    }

    func testGivenSingleRoundSessionWhenAdvancingThenItFinishesImmediately() {
        var progress = RoundProgress(totalRounds: 1)
        XCTAssertTrue(progress.completeRound())
        XCTAssertEqual(progress.completedRounds, 1)
    }

    func testGivenZeroRoundSessionThenItIsFinishedAndDisplayIsSane() {
        let progress = RoundProgress(totalRounds: 0)
        XCTAssertTrue(progress.isFinished)
        XCTAssertEqual(progress.displayRound, 1)  // no divide-by-zero-style nonsense
    }

    func testGivenNegativeRoundCountThenItIsTreatedAsZero() {
        let progress = RoundProgress(totalRounds: -5)
        XCTAssertEqual(progress.totalRounds, 0)
        XCTAssertTrue(progress.isFinished)
    }

    func testGivenReplayWhenResettingThenItStartsOver() {
        var progress = RoundProgress(totalRounds: 3)
        _ = progress.completeRound()
        progress.reset()
        XCTAssertEqual(progress.completedRounds, 0)
        XCTAssertFalse(progress.isFinished)
        XCTAssertEqual(progress.displayRound, 1)
    }
}
