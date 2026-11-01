import XCTest

@testable import MenteViva

/// #404: leaving a half-finished game asks first; an untouched or finished one just closes.
/// #528: every game has the same back button, but only #404's puzzle games ever ask.
final class LeaveGuardTests: XCTestCase {
    func testGivenNoMovesWhenLeavingThenNoConfirmationNeeded() {
        XCTAssertFalse(LeaveGuard.needsConfirmation(game: .sudoku, inProgress: false, celebrating: false))
    }

    func testGivenMovesMadeWhenLeavingThenConfirmationRequired() {
        XCTAssertTrue(LeaveGuard.needsConfirmation(game: .sudoku, inProgress: true, celebrating: false))
    }

    func testGivenCelebrationShowingWhenLeavingThenNoConfirmationNeeded() {
        // The counters are still above zero while the celebration shows: the board is done.
        XCTAssertFalse(LeaveGuard.needsConfirmation(game: .sudoku, inProgress: true, celebrating: true))
    }

    func testGivenARoundPlayedInEachRoundGameWhenLeavingThenItClosesAtOnce() {
        // What the round games pass in: their own round counter after one round (#528). A round game
        // loses only a few one-tap rounds, so #404 left it without a prompt even then.
        var progress = RoundProgress(totalRounds: 10)
        progress.completeRound()
        let roundGames: [GameID] = [
            .mathStreaks, .stroop, .sayings, .repeatSequence, .quickEyes, .categoryFluency, .reminiscence,
        ]
        for game in roundGames {
            XCTAssertFalse(
                LeaveGuard.needsConfirmation(game: game, inProgress: progress.completedRounds > 0, celebrating: false),
                "\(game)")
        }
    }

    func testGivenEveryGameMidPlayWhenLeavingThenOnlyThePuzzlesFrom404Ask() {
        // The list #404 decided, written out here rather than read from the code under test.
        let puzzles: Set<GameID> = [.sudoku, .tangram, .slidingBlocks, .tilePairs, .upOrDown, .memoryMatch, .photoCaptions]
        for game in GameID.allCases {
            XCTAssertEqual(
                LeaveGuard.needsConfirmation(game: game, inProgress: true, celebrating: false),
                puzzles.contains(game), "\(game)")
        }
    }
}
