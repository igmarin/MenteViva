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
        XCTAssertTrue(progress.completeRound())  // idempotent, no over-count
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

/// The category board decides when to hold its finished state before advancing.
final class CategoryCompletionTests: XCTestCase {
    func testGivenLastItemPickedWhenTappedThenRoundEndsAfterBeat() {
        XCTAssertEqual(
            CategoryFluencyView.completion(found: 7, total: 7, hasNextRound: true),
            .showBeatThenNextCategory)
    }

    func testGivenLastItemOfLastCategoryWhenTappedThenSessionEndsAfterBeat() {
        XCTAssertEqual(
            CategoryFluencyView.completion(found: 7, total: 7, hasNextRound: false),
            .showBeatThenFinish)
    }

    func testGivenItemsStillToFindWhenTappedThenPlayContinues() {
        XCTAssertEqual(
            CategoryFluencyView.completion(found: 6, total: 7, hasNextRound: true),
            .keepPlaying)
    }
}

final class GameSessionAccuracyTests: XCTestCase {
    func testGivenASessionMadeWithoutAScoreWhenReadThenTheStoredScoreIsZero() {
        let s = GameSession(gameID: .memoryMatch, rounds: 8, durationSeconds: 5)
        XCTAssertEqual(s.score, 0)
    }

    func testGivenCorrectAndAttemptsWhenAccuracyThenRatio() {
        let s = GameSession(
            gameID: .stroop, score: 0, rounds: 10, durationSeconds: 5,
            correct: 7, attempts: 10)
        XCTAssertEqual(s.accuracy ?? -1, 0.7, accuracy: 0.0001)
    }

    func testGivenLegacySessionWithoutAttemptsWhenAccuracyThenNil() {
        let s = GameSession(gameID: .memoryMatch, score: 0, rounds: 8, durationSeconds: 5)
        XCTAssertNil(s.accuracy)
    }

    func testGivenMemoryPairsAndMovesWhenAccuracyThenPairsOverMoves() {
        let s = GameSession(
            gameID: .memoryMatch, score: 0, rounds: 8, durationSeconds: 5,
            correct: 8, attempts: 16)
        XCTAssertEqual(s.accuracy ?? -1, 0.5, accuracy: 0.0001)
    }
}
