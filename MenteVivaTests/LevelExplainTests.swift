import XCTest

@testable import MenteViva

/// Policy for #207's two prompts: a pure layer next to `DailyPolicy`.
/// Views only show what this decides.
final class LevelExplainTests: XCTestCase {
    func testGivenRaisedByTwoTodayWhenFirstOpenThenShowsTwoStepsLine() {
        let change = LevelChange(previous: Difficulty(level: 4), reason: .raised(by: 2))
        XCTAssertEqual(LevelExplainPolicy.key(for: change), "level.explain.raised2")
        XCTAssertTrue(LevelExplainPolicy.shouldShow(change: change, alreadySeenToday: false))
    }
    func testGivenRaisedByOneThenShowsOneStepLine() {
        let change = LevelChange(previous: Difficulty(level: 4), reason: .raised(by: 1))
        XCTAssertEqual(LevelExplainPolicy.key(for: change), "level.explain.raised1")
        XCTAssertTrue(LevelExplainPolicy.shouldShow(change: change, alreadySeenToday: false))
    }
    func testGivenEasedWhenFirstOpenThenShowsCalmerLine() {
        let change = LevelChange(previous: Difficulty(level: 4), reason: .eased)
        XCTAssertEqual(LevelExplainPolicy.key(for: change), "level.explain.eased")
        XCTAssertTrue(LevelExplainPolicy.shouldShow(change: change, alreadySeenToday: false))
    }
    func testGivenSecondOpenTodayWhenOpenThenNoLine() {
        let change = LevelChange(previous: Difficulty(level: 4), reason: .raised(by: 1))
        XCTAssertFalse(LevelExplainPolicy.shouldShow(change: change, alreadySeenToday: true))
    }
    func testGivenNoChangeWhenOpenThenNoLine() {
        XCTAssertNil(LevelExplainPolicy.key(for: nil))
        XCTAssertFalse(LevelExplainPolicy.shouldShow(change: nil, alreadySeenToday: false))
    }
    func testGivenChosenReasonWhenOpenThenNoLine() {
        let change = LevelChange(previous: Difficulty(level: 4), reason: .chosen)
        XCTAssertNil(LevelExplainPolicy.key(for: change))
        XCTAssertFalse(LevelExplainPolicy.shouldShow(change: change, alreadySeenToday: false))
    }
    func testGivenStrongGameBelowTenWhenFinishedThenOffersNextLevel() {
        XCTAssertTrue(
            LevelExplainPolicy.shouldOffer(
                accuracy: 1.0, game: .stroop, level: Difficulty(level: 4), isPinned: false, alreadyOfferedToday: false))
    }
    func testGivenStrongThresholdExactlyWhenFinishedThenOffers() {
        XCTAssertTrue(
            LevelExplainPolicy.shouldOffer(
                accuracy: DailyPolicy.strongAccuracy(for: .stroop), game: .stroop, level: Difficulty(level: 4), isPinned: false,
                alreadyOfferedToday: false))
    }
    func testGivenWeakGameWhenFinishedThenNoOffer() {
        XCTAssertFalse(
            LevelExplainPolicy.shouldOffer(
                accuracy: 0.5, game: .stroop, level: Difficulty(level: 4), isPinned: false, alreadyOfferedToday: false))
    }
    func testGivenNilAccuracyWhenFinishedThenNoOffer() {
        XCTAssertFalse(
            LevelExplainPolicy.shouldOffer(
                accuracy: nil, game: .reminiscence, level: Difficulty(level: 4), isPinned: false, alreadyOfferedToday: false))
    }
    func testGivenPinnedOrTopLevelWhenFinishedThenNoOffer() {
        XCTAssertFalse(
            LevelExplainPolicy.shouldOffer(
                accuracy: 1.0, game: .stroop, level: Difficulty(level: 4), isPinned: true, alreadyOfferedToday: false))
        XCTAssertFalse(
            LevelExplainPolicy.shouldOffer(
                accuracy: 1.0, game: .stroop, level: Difficulty(level: 10), isPinned: false, alreadyOfferedToday: false))
    }
    func testGivenAlreadyOfferedTodayWhenFinishedThenNoOffer() {
        XCTAssertFalse(
            LevelExplainPolicy.shouldOffer(
                accuracy: 1.0, game: .stroop, level: Difficulty(level: 4), isPinned: false, alreadyOfferedToday: true))
    }
    func testGivenReminiscenceDespiteStrongWhenFinishedThenNoOffer() {
        XCTAssertFalse(
            LevelExplainPolicy.shouldOffer(
                accuracy: 1.0, game: .reminiscence, level: Difficulty(level: 4), isPinned: false, alreadyOfferedToday: false))
    }
    func testGivenYesWhenChosenThenLevelUpByOneWithChosenReason() {
        let defaults = UserDefaults(suiteName: "LevelExplainTests.chosen")!
        defaults.removePersistentDomain(forName: "LevelExplainTests.chosen")
        let today = "2026-11-07"
        let plan = DailyPlan(
            dayStamp: today, games: [.memoryMatch, .stroop, .quickEyes], difficulty: [.stroop: Difficulty(level: 4)], changes: [:]
        )
        PlanStore.cache(plan, defaults: defaults)
        LevelOfferStore.applyChosen(for: .stroop, today: today, defaults: defaults)
        XCTAssertEqual(PlanStore.storedDifficulty(defaults: defaults)[.stroop], Difficulty(level: 5))
        XCTAssertEqual(PlanStore.lastDifficultyChange(defaults: defaults)[.stroop], today)
        let patched = PlanStore.cachedPlan(defaults: defaults)
        XCTAssertEqual(patched?.difficulty[.stroop], Difficulty(level: 5))
        XCTAssertEqual(patched?.changes[.stroop], LevelChange(previous: Difficulty(level: 4), reason: .chosen))
    }
    func testGivenAtTopLevelWhenChosenThenNoChange() {
        let defaults = UserDefaults(suiteName: "LevelExplainTests.chosenTop")!
        defaults.removePersistentDomain(forName: "LevelExplainTests.chosenTop")
        let today = "2026-11-07"
        let plan = DailyPlan(dayStamp: today, games: [], difficulty: [.stroop: Difficulty(level: 10)], changes: [:])
        PlanStore.cache(plan, defaults: defaults)
        LevelOfferStore.applyChosen(for: .stroop, today: today, defaults: defaults)
        XCTAssertEqual(PlanStore.storedDifficulty(defaults: defaults)[.stroop], Difficulty(level: 10))
        XCTAssertNil(PlanStore.cachedPlan(defaults: defaults)?.changes[.stroop])
    }
    func testGivenFirstOpenTodayWhenMarkedSeenThenSecondOpenHidesLine() {
        let defaults = UserDefaults(suiteName: "LevelExplainTests.seen")!
        defaults.removePersistentDomain(forName: "LevelExplainTests.seen")
        let today = "2026-11-07"
        XCTAssertFalse(LevelOfferStore.hasSeenExplain(for: .stroop, today: today, defaults: defaults))
        LevelOfferStore.markExplainSeen(for: .stroop, today: today, defaults: defaults)
        XCTAssertTrue(LevelOfferStore.hasSeenExplain(for: .stroop, today: today, defaults: defaults))
        XCTAssertFalse(LevelOfferStore.hasSeenExplain(for: .quickEyes, today: today, defaults: defaults))
    }
    func testGivenOfferWhenMarkedThenSecondOfferBlockedSameDay() {
        let defaults = UserDefaults(suiteName: "LevelExplainTests.offered")!
        defaults.removePersistentDomain(forName: "LevelExplainTests.offered")
        let today = "2026-11-07"
        XCTAssertFalse(LevelOfferStore.hasOfferedToday(for: .stroop, today: today, defaults: defaults))
        LevelOfferStore.markOffered(for: .stroop, today: today, defaults: defaults)
        XCTAssertTrue(LevelOfferStore.hasOfferedToday(for: .stroop, today: today, defaults: defaults))
    }
    func testGivenMemoryLanesThresholdWhenStrongThenOffered() {
        XCTAssertTrue(
            LevelExplainPolicy.shouldOffer(
                accuracy: 0.65, game: .memoryMatch, level: Difficulty(level: 4), isPinned: false, alreadyOfferedToday: false))
        XCTAssertFalse(
            LevelExplainPolicy.shouldOffer(
                accuracy: 0.64, game: .memoryMatch, level: Difficulty(level: 4), isPinned: false, alreadyOfferedToday: false))
    }

    func testGivenYesWhenTappedTwiceSameDayThenLevelOnlyRisesOnce() {
        let defaults = UserDefaults(suiteName: "LevelExplainTests.doubleTap")!
        defaults.removePersistentDomain(forName: "LevelExplainTests.doubleTap")
        let today = "2026-11-07"
        let plan = DailyPlan(
            dayStamp: today, games: [.memoryMatch, .stroop, .quickEyes], difficulty: [.stroop: Difficulty(level: 4)],
            changes: [:]
        )
        PlanStore.cache(plan, defaults: defaults)
        LevelOfferStore.applyChosen(for: .stroop, today: today, defaults: defaults)
        LevelOfferStore.markOffered(for: .stroop, today: today, defaults: defaults)
        LevelOfferStore.applyChosen(for: .stroop, today: today, defaults: defaults)
        XCTAssertEqual(PlanStore.storedDifficulty(defaults: defaults)[.stroop], Difficulty(level: 5))
        XCTAssertEqual(
            PlanStore.cachedPlan(defaults: defaults)?.changes[.stroop],
            LevelChange(previous: Difficulty(level: 4), reason: .chosen))
    }

    // Play again re-reads `Difficulty.stored` before dealing (#368); these pin the store contract it relies on.
    func testGivenLevelRaisedByChoiceWhenStoredReadAgainThenReturnsNextLevel() {
        let defaults = UserDefaults(suiteName: "LevelExplainTests.playAgain")!
        defaults.removePersistentDomain(forName: "LevelExplainTests.playAgain")
        let today = "2026-11-07"
        PlanStore.cache(
            DailyPlan(dayStamp: today, games: [.stroop], difficulty: [.stroop: Difficulty(level: 4)], changes: [:]),
            defaults: defaults)
        XCTAssertEqual(Difficulty.stored(.stroop, defaults: defaults), Difficulty(level: 4))
        LevelOfferStore.applyChosen(for: .stroop, today: today, defaults: defaults)
        XCTAssertEqual(Difficulty.stored(.stroop, defaults: defaults), Difficulty(level: 5))
    }

    func testGivenPinnedLevelWhenStoredReadThenPinnedWinsOverPlanLevel() {
        let defaults = UserDefaults(suiteName: "LevelExplainTests.pinnedWins")!
        defaults.removePersistentDomain(forName: "LevelExplainTests.pinnedWins")
        let today = "2026-11-07"
        PlanStore.cache(
            DailyPlan(dayStamp: today, games: [.stroop], difficulty: [.stroop: Difficulty(level: 4)], changes: [:]),
            defaults: defaults)
        defaults.set(3, forKey: FamilySettings.pinKey(.stroop))
        // The UI hides the offer for a pinned game; this raise stands in for any plan change.
        PlanStore.raiseByChoice(.stroop, today: today, defaults: defaults)
        XCTAssertEqual(Difficulty.stored(.stroop, defaults: defaults), Difficulty(level: 3))
    }

    // MARK: - One open's note (#470)

    func testGivenNoteShowingWhenGameStartsThenNoteIsDismissed() {
        var note = LevelExplainNote(
            change: LevelChange(previous: Difficulty(level: 4), reason: .eased), seenToday: false)
        XCTAssertEqual(note.slot(hasStarted: false), .showing)
        XCTAssertEqual(note.slot(hasStarted: true), .reserved)
    }

    func testGivenNoteDismissedWhenPlayAgainResetsProgressThenNoteNeverReturns() {
        // "Play again", "Start over" or undo take the game's progress back to zero.
        var note = LevelExplainNote(
            change: LevelChange(previous: Difficulty(level: 4), reason: .raised(by: 1)), seenToday: false)
        _ = note.slot(hasStarted: false)
        _ = note.slot(hasStarted: true)
        for _ in 0..<3 {
            XCTAssertNotEqual(note.slot(hasStarted: false), .showing)
            XCTAssertNotEqual(note.slot(hasStarted: true), .showing)
        }
    }

    func testGivenGameAlreadyStartedWhenNoteFirstReadThenItNeverShows() {
        // A game restored mid-play opens with progress already made.
        var note = LevelExplainNote(
            change: LevelChange(previous: Difficulty(level: 4), reason: .eased), seenToday: false)
        XCTAssertEqual(note.slot(hasStarted: true), .reserved)
        XCTAssertEqual(note.slot(hasStarted: false), .reserved)
    }

    func testGivenNoteSeenTodayWhenOpenThenNoNoteAndNothingHeldBack() {
        var note = LevelExplainNote(
            change: LevelChange(previous: Difficulty(level: 4), reason: .eased), seenToday: true)
        XCTAssertNil(note.key)
        XCTAssertEqual(note.slot(hasStarted: false), .none)
    }

    // MARK: - Slot (#470)

    func testGivenNoteShowingWhenFirstMoveThenItKeepsItsSpace() {
        let showing = LevelExplainSlot.slot(hasNote: true, hasStarted: false, dismissed: false)
        let afterFirstMove = LevelExplainSlot.slot(hasNote: true, hasStarted: true, dismissed: true)
        XCTAssertEqual(showing, .showing)
        XCTAssertEqual(afterFirstMove, .reserved)
        XCTAssertEqual(showing.takesSpace, afterFirstMove.takesSpace)
    }

    func testGivenNoNoteThisOpenWhenFirstMoveThenNothingIsHeldBack() {
        XCTAssertEqual(LevelExplainSlot.slot(hasNote: false, hasStarted: false, dismissed: false), .none)
        XCTAssertEqual(LevelExplainSlot.slot(hasNote: false, hasStarted: true, dismissed: true), .none)
        XCTAssertFalse(LevelExplainSlot.none.takesSpace)
    }

    func testGivenStartedOnceWhenBackToZeroMovesThenNoteStaysReserved() {
        // First move, undo (or "Start over", or "Play again") back to 0 moves.
        XCTAssertEqual(LevelExplainSlot.slot(hasNote: true, hasStarted: false, dismissed: true), .reserved)
    }
}
