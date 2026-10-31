import XCTest

@testable import MenteViva

/// #415: "Play again" dealt under the closing cover, and the game's `.onAppear` dealt again as the
/// cover left. The choice now waits for the dismissal and runs exactly once.
final class CelebrationExitTests: XCTestCase {
    func testGivenPlayAgainChosenWhenTheCoverIsStillUpThenNothingRunsYet() {
        var exit = CelebrationExit()

        exit.choose(.playAgain)

        XCTAssertEqual(exit.pending, .playAgain)
    }

    func testGivenPlayAgainChosenWhenTheCoverClosesThenItRunsOnce() {
        var exit = CelebrationExit()
        exit.choose(.playAgain)

        XCTAssertEqual(exit.coverClosed(), .playAgain)
        XCTAssertNil(exit.coverClosed())
    }

    func testGivenNextChosenWhenTheCoverClosesThenThatGameOpens() {
        var exit = CelebrationExit()
        exit.choose(.next(.sudoku))

        XCTAssertEqual(exit.coverClosed(), .next(.sudoku))
    }

    func testGivenNothingChosenWhenTheCoverClosesThenNothingRuns() {
        var exit = CelebrationExit()

        XCTAssertNil(exit.coverClosed())
    }
}
