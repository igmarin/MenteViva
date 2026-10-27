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
        XCTAssertEqual(
            FamilySettings.pinned(defaults: defaults),
            [.sudoku: Difficulty(level: 2), .sayings: Difficulty(level: 4), .upOrDown: Difficulty(level: 6)])
    }
}
