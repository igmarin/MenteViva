import XCTest

@testable import MenteViva

/// The onboarding answers (#211): stored on the device, every one optional, and a game with no saved
/// level starts where the chosen pace says.
final class PlayerProfileTests: XCTestCase {
    private var defaults: UserDefaults!

    override func setUp() {
        defaults = UserDefaults(suiteName: "PlayerProfileTests")
        defaults.removePersistentDomain(forName: "PlayerProfileTests")
    }

    func testGivenNothingSavedWhenLoadedThenTheProfileIsEmpty() {
        XCTAssertEqual(ProfileStore.load(defaults: defaults), PlayerProfile())
    }

    func testGivenAFullProfileWhenSavedThenItLoadsBackTheSame() {
        let profile = PlayerProfile(
            forWhom: .familyMember, focus: [.memory, .words], minutesPerDay: 15, startPace: .challenge)
        ProfileStore.save(profile, defaults: defaults)
        XCTAssertEqual(ProfileStore.load(defaults: defaults), profile)
    }

    func testGivenUnreadableDataWhenLoadedThenTheProfileIsEmpty() {
        defaults.set(Data("not a profile".utf8), forKey: ProfileStore.key)
        XCTAssertEqual(ProfileStore.load(defaults: defaults), PlayerProfile())
    }

    func testGivenEachPaceWhenStartingLevelThenTwoFourSix() {
        let levels = [PlayerProfile.StartPace.calm, .normal, .challenge].map {
            DailyPolicy.startingLevel(for: PlayerProfile(startPace: $0)).level
        }
        XCTAssertEqual(levels, [2, 4, 6])
        XCTAssertEqual(DailyPolicy.startingLevel(for: PlayerProfile()), Difficulty(level: 4))
    }

    func testGivenFamilyMemberWithoutAPaceWhenStartingLevelThenCalm() {
        XCTAssertEqual(DailyPolicy.startingLevel(for: PlayerProfile(forWhom: .familyMember)), Difficulty(level: 2))
        XCTAssertEqual(
            DailyPolicy.startingLevel(for: PlayerProfile(forWhom: .familyMember, startPace: .challenge)),
            Difficulty(level: 6))
        XCTAssertEqual(DailyPolicy.startingLevel(for: PlayerProfile(forWhom: .me)), Difficulty(level: 4))
    }

    func testGivenCalmProfileWhenStoredDifficultyThenUnsavedGamesStartAtTwoAndSavedOnesKeepTheirLevel() {
        defaults.set(try! JSONEncoder().encode(["sudoku": 7]), forKey: "level.byGame")
        ProfileStore.save(PlayerProfile(startPace: .calm), defaults: defaults)
        let levels = PlanStore.storedDifficulty(defaults: defaults)
        XCTAssertEqual(levels[.sudoku], Difficulty(level: 7))
        XCTAssertEqual(levels[.stroop], Difficulty(level: 2))
    }
}
