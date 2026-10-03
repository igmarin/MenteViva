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

/// Scoring tests keep the formulas independent from SwiftUI rendering and
/// protect the values shown in the celebration screen.
final class GameScoringTests: XCTestCase {

    func testGivenMemoryMovesWhenScoredThenPenaltyIsAppliedWithMinimum() {
        XCTAssertEqual(MemoryMatchView.score(pairCount: 8, moves: 10), 140)
        XCTAssertEqual(MemoryMatchView.score(pairCount: 2, moves: 100), 10)
    }

    func testGivenCorrectAnswersWhenScoredThenColorClashUsesTenPointsEach() {
        XCTAssertEqual(ColorClashView.score(correct: 7), 70)
    }

    func testGivenPickedItemsWhenScoredThenCategoryFluencyUsesTenPointsEach() {
        XCTAssertEqual(CategoryFluencyView.score(totalCorrect: 21), 210)
    }

    func testGivenStreakWhenScoredThenMathAddsTheStreakBonus() {
        XCTAssertEqual(MathStreakView.score(correct: 8, bestStreak: 5), 90)
    }

    func testGivenSpeedBonusWhenScoredThenQuickEyesAddsItToCorrectAnswers() {
        XCTAssertEqual(QuickEyesView.score(correct: 9, speedBonus: 12), 102)
    }
}

final class GameSessionAccuracyTests: XCTestCase {
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
