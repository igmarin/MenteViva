import XCTest

@testable import MenteViva

/// Quick Eyes' run rules (#416): the fade, first-try count, flash speed and faster-round invite,
/// tested without a view. `correct` and `attempts` feed the level staircase, so they are pinned here.
final class QuickEyesRunTests: XCTestCase {
    private let sunflower = GamePictures.named("sunflower")
    private let turtle = GamePictures.named("turtle")

    private func pacedRun() -> QuickEyesRun { QuickEyesRun(difficulty: Difficulty(level: 2)) }
    private func flashRun(level: Int = 6) -> QuickEyesRun { QuickEyesRun(difficulty: Difficulty(level: level)) }

    // MARK: Paced fade

    func testGivenAPacedRoundWhenAWrongPickThenItFadesAndTheRoundStaysOpen() {
        var run = pacedRun()
        let outcome = run.pick(turtle, target: sunflower, reactionSeconds: 1)
        XCTAssertEqual(outcome, .faded)
        XCTAssertEqual(run.fadedPictures, [turtle])
        XCTAssertEqual(run.correct, 0)
        XCTAssertFalse(run.missedLastRound)
    }

    func testGivenAFadedMissWhenTheRightPickThenItIsNotCountedAsFirstTry() {
        var run = pacedRun()
        _ = run.pick(turtle, target: sunflower, reactionSeconds: 1)
        let outcome = run.pick(sunflower, target: sunflower, reactionSeconds: 1)
        XCTAssertEqual(outcome, .right(firstTry: false))
        XCTAssertEqual(run.correct, 0)
    }

    func testGivenAPacedRoundWhenTheRightPickFirstThenCounted() {
        var run = pacedRun()
        let outcome = run.pick(sunflower, target: sunflower, reactionSeconds: 1.2)
        XCTAssertEqual(outcome, .right(firstTry: true))
        XCTAssertEqual(run.correct, 1)
    }

    func testGivenAFadeWhenTheNextRoundStartsThenNothingIsFaded() {
        var run = pacedRun()
        _ = run.pick(turtle, target: sunflower, reactionSeconds: 1)
        run.startRound()
        XCTAssertTrue(run.fadedPictures.isEmpty)
    }

    func testGivenAPacedMissWhenPickedThenTheFlashTimeIsUntouched() {
        var run = pacedRun()
        let before = run.displayTime
        _ = run.pick(turtle, target: sunflower, reactionSeconds: 1)
        _ = run.pick(sunflower, target: sunflower, reactionSeconds: 1)
        XCTAssertEqual(run.displayTime, before)
    }

    // MARK: Flash speed

    func testGivenFlashRoundsWhenRightThenTheTimeShrinksButNeverBelowTheFloor() {
        var run = flashRun()
        let floor = QuickEyesRun.displayTimes(for: Difficulty(level: 6)).floor
        var previous = run.displayTime
        for _ in 0..<60 {
            _ = run.pick(sunflower, target: sunflower, reactionSeconds: 1)
            XCTAssertLessThanOrEqual(run.displayTime, previous)
            XCTAssertGreaterThanOrEqual(run.displayTime, floor)
            previous = run.displayTime
        }
        XCTAssertEqual(run.displayTime, floor, accuracy: 0.000_001)
    }

    func testGivenAShrunkFlashWhenAMissThenItRelaxesOneStepAndNeverPastTheStart() {
        var run = flashRun()
        let start = QuickEyesRun.displayTimes(for: Difficulty(level: 6)).start
        _ = run.pick(sunflower, target: sunflower, reactionSeconds: 1)
        _ = run.pick(sunflower, target: sunflower, reactionSeconds: 1)
        let shrunk = run.displayTime
        XCTAssertLessThan(shrunk, start)
        let outcome = run.pick(turtle, target: sunflower, reactionSeconds: 1)
        XCTAssertEqual(outcome, .missed)
        XCTAssertGreaterThan(run.displayTime, shrunk)
        XCTAssertTrue(run.missedLastRound)
        for _ in 0..<60 { _ = run.pick(turtle, target: sunflower, reactionSeconds: 1) }
        XCTAssertEqual(run.displayTime, start, accuracy: 0.000_001)
    }

    func testGivenARightPickAfterAMissThenTheAlmostNoteClears() {
        var run = flashRun()
        _ = run.pick(turtle, target: sunflower, reactionSeconds: 1)
        _ = run.pick(sunflower, target: sunflower, reactionSeconds: 1)
        XCTAssertFalse(run.missedLastRound)
    }

    // MARK: Faster-round invite

    func testGivenThreeQuickFirstTryRoundsWhenPacedThenTheInviteShowsOnce() {
        var run = pacedRun()
        var offers: [Bool] = []
        for _ in 0..<5 {
            _ = run.pick(sunflower, target: sunflower, reactionSeconds: 0.5)
            offers.append(run.roundEnded(lookSeconds: 0.4))
        }
        XCTAssertEqual(offers, [false, false, true, false, false])
    }

    func testGivenALongLookWhenRoundsEndThenNoInvite() {
        var run = pacedRun()
        for _ in 0..<5 {
            _ = run.pick(sunflower, target: sunflower, reactionSeconds: 0.5)
            XCTAssertFalse(run.roundEnded(lookSeconds: 3))
        }
    }

    func testGivenARoundEndedWithoutAPickWhenItEndsThenItDoesNotReuseLastRoundsPick() {
        var run = pacedRun()
        for _ in 0..<2 {
            _ = run.pick(sunflower, target: sunflower, reactionSeconds: 0.5)
            _ = run.roundEnded(lookSeconds: 0.4)
        }
        run.startRound()
        XCTAssertFalse(run.roundEnded(lookSeconds: 0.4))
    }

    func testGivenAFadedRoundWhenItEndsThenTheStreakStartsOver() {
        var run = pacedRun()
        for _ in 0..<2 {
            _ = run.pick(sunflower, target: sunflower, reactionSeconds: 0.5)
            _ = run.roundEnded(lookSeconds: 0.4)
        }
        _ = run.pick(turtle, target: sunflower, reactionSeconds: 0.5)
        _ = run.pick(sunflower, target: sunflower, reactionSeconds: 0.5)
        XCTAssertFalse(run.roundEnded(lookSeconds: 0.4))
        _ = run.pick(sunflower, target: sunflower, reactionSeconds: 0.5)
        XCTAssertFalse(run.roundEnded(lookSeconds: 0.4))
    }

    func testGivenFlashRoundsWhenTheyEndThenNoInvite() {
        var run = flashRun()
        for _ in 0..<5 {
            _ = run.pick(sunflower, target: sunflower, reactionSeconds: 0.5)
            XCTAssertFalse(run.roundEnded(lookSeconds: 0.1))
        }
    }

    func testGivenTheFasterInviteAcceptedWhenAskedThenRoundsFlashFromTheStartTime() {
        var run = pacedRun()
        XCTAssertTrue(run.isPaced)
        run.acceptFaster()
        XCTAssertFalse(run.isPaced)
        XCTAssertEqual(run.displayTime, QuickEyesRun.displayTimes(for: Difficulty(level: 2)).start)
        // Now it shrinks like a flash level.
        _ = run.pick(sunflower, target: sunflower, reactionSeconds: 1)
        XCTAssertLessThan(run.displayTime, QuickEyesRun.displayTimes(for: Difficulty(level: 2)).start)
    }

    func testGivenAFlashLevelWhenAskedThenItIsNeverPaced() {
        XCTAssertFalse(flashRun(level: 6).isPaced)
        XCTAssertTrue(flashRun(level: 5).isPaced)
    }
}
