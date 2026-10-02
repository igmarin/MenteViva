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
        defaults.set(Difficulty.easy.rawValue, forKey: FamilySettings.pinKey(.quickEyes))
        defaults.set(FamilySettings.auto, forKey: FamilySettings.pinKey(.stroop))
        XCTAssertEqual(FamilySettings.pinned(defaults: defaults), [.quickEyes: .easy])
    }

    func testGivenAPinWhenStoredDifficultyThenThePinWinsOverAuto() {
        defaults.set(try! JSONEncoder().encode(["quick_eyes": Difficulty.hard.rawValue]), forKey: "jev.difficulty")
        XCTAssertEqual(Difficulty.stored(.quickEyes, defaults: defaults), .hard)
        defaults.set(Difficulty.easy.rawValue, forKey: FamilySettings.pinKey(.quickEyes))
        XCTAssertEqual(Difficulty.stored(.quickEyes, defaults: defaults), .easy)
    }
}
