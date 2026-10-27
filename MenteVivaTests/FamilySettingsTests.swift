import XCTest

@testable import MenteViva

/// #108: the caregiver's per-device choices — pinned difficulty and hidden games.
final class FamilySettingsTests: XCTestCase {
    private var defaults: UserDefaults!

    override func setUp() {
        defaults = UserDefaults(suiteName: "FamilySettingsTests")
        defaults.removePersistentDomain(forName: "FamilySettingsTests")
    }

    func testGivenHiddenGamesWhenStoredAsTextThenTheyRoundTrip() {
        let games: Set<GameID> = [.stroop, .mathStreaks]
        XCTAssertEqual(FamilySettings.hidden(from: FamilySettings.csv(games)), games)
    }

    func testGivenUnknownOrEmptyEntriesWhenReadingHiddenThenTheyAreIgnored() {
        XCTAssertEqual(FamilySettings.hidden(from: "stroop,,nope"), [.stroop])
        XCTAssertEqual(FamilySettings.hidden(from: ""), [])
    }

    func testGivenNothingStoredWhenReadingPinsThenEveryGameIsAuto() {
        XCTAssertEqual(FamilySettings.pinned(defaults: defaults), [:])
    }

    func testGivenAPinAndAnAutoEntryWhenReadingPinsThenOnlyThePinCounts() {
        // Under the 1...10 bridge 2 still reads as a level, not a legacy easy→2 mapping.
        defaults.set(6, forKey: FamilySettings.pinKey(.quickEyes))
        defaults.set(FamilySettings.auto, forKey: FamilySettings.pinKey(.stroop))
        XCTAssertEqual(
            FamilySettings.pinned(defaults: defaults), [.quickEyes: Difficulty(level: 6)])
    }

    func testGivenAPinWhenStoredDifficultyThenThePinWinsOverAuto() {
        defaults.set(try! JSONEncoder().encode(["quick_eyes": 2]), forKey: "jev.difficulty")
        LevelMigration.runOnce(defaults: defaults)
        XCTAssertEqual(Difficulty.stored(.quickEyes, defaults: defaults), Difficulty(level: 6))
        defaults.set(4, forKey: FamilySettings.pinKey(.quickEyes))
        XCTAssertEqual(Difficulty.stored(.quickEyes, defaults: defaults), Difficulty(level: 4))
    }

    // MARK: New-key pins are true levels; 0/1/2 mapping is for legacy pins only (#197)

    func testGivenAPinOfLevelTwoUnderTheNewKeyWhenReadThenItIsLevelTwo() {
        // Set up saves "Level 2" as 2; it used to read back as 6 ([2, 4, 6][2]).
        defaults.set(2, forKey: FamilySettings.pinKey(.sudoku))
        defaults.set(1, forKey: FamilySettings.pinKey(.sayings))
        XCTAssertEqual(
            FamilySettings.pinned(defaults: defaults), [.sudoku: Difficulty(level: 2), .sayings: Difficulty(level: 1)])
    }

    func testGivenLegacyPinsWhenMigratedThenEasyMediumHardBecomeTwoFourSix() {
        defaults.set(0, forKey: FamilySettings.legacyPinKey(.sudoku))
        defaults.set(1, forKey: FamilySettings.legacyPinKey(.sayings))
        defaults.set(2, forKey: FamilySettings.legacyPinKey(.upOrDown))
        // Reads no longer migrate (#264); the launch-time pass does.
        LevelMigration.runOnce(defaults: defaults)
        XCTAssertEqual(
            FamilySettings.pinned(defaults: defaults),
            [.sudoku: Difficulty(level: 2), .sayings: Difficulty(level: 4), .upOrDown: Difficulty(level: 6)])
    }

    // MARK: The 1–10 picker steps and clamps here, the view only shows it (#208)

    func testGivenPinAtFourWhenIncrementedTwiceThenItIsSix() {
        let once = FamilySettings.stepped(4, by: 1)
        XCTAssertEqual(FamilySettings.stepped(once, by: 1), 6)
    }

    func testGivenPinAtTenWhenIncrementedThenStaysTen() {
        XCTAssertEqual(FamilySettings.stepped(10, by: 1), 10)
        XCTAssertFalse(FamilySettings.canStep(10, by: 1))
        XCTAssertTrue(FamilySettings.canStep(10, by: -1))
    }

    func testGivenPinAtOneWhenDecrementedThenStaysOne() {
        XCTAssertEqual(FamilySettings.stepped(1, by: -1), 1)
        XCTAssertFalse(FamilySettings.canStep(1, by: -1))
        XCTAssertTrue(FamilySettings.canStep(1, by: 1))
    }

    func testGivenAutoWhenSteppedThenItStaysAutoAndNoStepIsOffered() {
        XCTAssertEqual(FamilySettings.stepped(FamilySettings.auto, by: 1), FamilySettings.auto)
        XCTAssertFalse(FamilySettings.canStep(FamilySettings.auto, by: 1))
        XCTAssertFalse(FamilySettings.canStep(FamilySettings.auto, by: -1))
    }

    func testGivenAutoWhenTurnedOffThenThePinStartsAtTheCurrentLevel() {
        XCTAssertEqual(
            FamilySettings.settingAuto(false, from: FamilySettings.auto, currentLevel: 5), 5)
    }

    func testGivenAPinWhenAutoIsTurnedOnThenTheGameIsAuto() {
        XCTAssertEqual(FamilySettings.settingAuto(true, from: 7, currentLevel: 7), FamilySettings.auto)
    }

    func testGivenAPinWhenAutoIsTurnedOffAgainThenThePinIsKept() {
        XCTAssertEqual(FamilySettings.settingAuto(false, from: 7, currentLevel: 3), 7)
    }

    func testGivenAnExtremeStoredPinWhenSteppedThenItClampsWithoutOverflow() {
        XCTAssertEqual(FamilySettings.stepped(Int.max, by: 1), 10)
        XCTAssertEqual(FamilySettings.stepped(Int.min, by: -1), 1)
        XCTAssertFalse(FamilySettings.canStep(Int.max, by: 1))
        XCTAssertFalse(FamilySettings.canStep(Int.min, by: -1))
    }
}
