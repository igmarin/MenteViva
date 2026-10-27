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
}
