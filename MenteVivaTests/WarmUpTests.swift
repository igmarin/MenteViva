import XCTest

@testable import MenteViva

/// The warm-up (#213): three games that quietly settle starting levels. The staircase moves up to two
/// levels per session while a game is calibrating, then the normal rules come back. Nothing here knows
/// about screens: there is no score or summary to show, which is the point.
final class WarmUpTests: XCTestCase {

    private func freshDefaults(_ name: String) -> UserDefaults {
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        return defaults
    }

    private let today = "2026-10-27"

    /// A warm-up started now, for an empty profile (level 4); returns the games it dealt.
    private func started(_ defaults: UserDefaults, profile: PlayerProfile = PlayerProfile()) -> [GameID] {
        WarmUpStore.start(profile: profile, today: today, defaults: defaults)
    }

    // MARK: Dealing

    func testGivenAnyProfileWhenWarmUpDealtThenThreeGamesFromThreeDifferentFocusAreas() {
        let games = WarmUp.picks(profile: PlayerProfile(), hidden: [], pinned: [:])

        XCTAssertEqual(games.count, 3)
        let areas = games.compactMap { DailyPolicy.focus[$0] }
        XCTAssertEqual(Set(areas).count, 3)
        XCTAssertTrue(games.allSatisfy { $0.hasLevels && !GameID.unreleased.contains($0) })
    }

    func testGivenAFocusAreaWhenWarmUpDealtThenThatAreaIsOneOfTheThree() {
        var profile = PlayerProfile()
        profile.focus = [.words]

        let games = WarmUp.picks(profile: profile, hidden: [], pinned: [:])

        XCTAssertTrue(games.contains { DailyPolicy.focus[$0] == .words })
    }

    func testGivenHiddenAndPinnedGamesWhenWarmUpDealtThenNeitherIsPicked() {
        let hidden: Set<GameID> = [.memoryMatch]
        let pinned: [GameID: Difficulty] = [.quickEyes: Difficulty(level: 3)]

        let games = WarmUp.picks(profile: PlayerProfile(), hidden: hidden, pinned: pinned)

        XCTAssertEqual(games.count, 3)
        XCTAssertTrue(Set(games).isDisjoint(with: hidden.union(pinned.keys)))
    }

    func testGivenAFamilyMemberWhenOfferedThenNotOffered() {
        XCTAssertTrue(WarmUp.isOffered(to: PlayerProfile()))
        XCTAssertTrue(WarmUp.isOffered(to: PlayerProfile(forWhom: .me)))
        XCTAssertFalse(WarmUp.isOffered(to: PlayerProfile(forWhom: .familyMember)))
    }

    func testGivenAcceptedWhenStartedThenThreeGamesAtLevelFourAreCalibrating() {
        let defaults = freshDefaults("WarmUpTests.start")

        let games = started(defaults)

        XCTAssertEqual(PlanStore.cachedPlan(defaults: defaults)?.games, games)
        for game in games {
            XCTAssertEqual(PlanStore.storedDifficulty(defaults: defaults)[game], Difficulty(level: 4))
            XCTAssertTrue(WarmUpStore.isCalibrating(game, defaults: defaults))
        }
        XCTAssertFalse(WarmUpStore.isCalibrating(.reminiscence, defaults: defaults))
    }

    /// First run (#402): onboarding saves each answer as it is given, so by the warm-up offer the saved
    /// profile is the one passed in, and a game with no level yet starts where its pace says.
    func testGivenFreshPlayerWhenWarmUpBeginsThenGamesStartAtProfileLevel() {
        let defaults = freshDefaults("WarmUpTests.pace")
        let profile = PlayerProfile(startPace: .calm)
        ProfileStore.save(profile, defaults: defaults)

        let games = started(defaults, profile: profile)

        XCTAssertEqual(games.count, 3)
        for game in games {
            XCTAssertEqual(PlanStore.storedDifficulty(defaults: defaults)[game], Difficulty(level: 2))
            XCTAssertEqual(PlanStore.cachedPlan(defaults: defaults)?.difficulty[game], Difficulty(level: 2))
        }
    }

    /// A player who climbed Memory Lane and taps "Let's play" in My plan keeps the level (#402); the
    /// warm-up used to drop it back to the profile's start on every tap.
    func testGivenEarnedLevelEightWhenWarmUpBeginsThenLevelEightIsKept() {
        let defaults = freshDefaults("WarmUpTests.earned")
        PlanStore.move(.memoryMatch, to: Difficulty(level: 8), reason: .raised(by: 2), today: "2026-10-20", defaults: defaults)

        let games = started(defaults)

        XCTAssertTrue(games.contains(.memoryMatch))
        XCTAssertEqual(PlanStore.storedDifficulty(defaults: defaults)[.memoryMatch], Difficulty(level: 8))
        XCTAssertEqual(PlanStore.cachedPlan(defaults: defaults)?.difficulty[.memoryMatch], Difficulty(level: 8))
    }

    /// Names and Faces has nothing to deal until the family adds captioned photos, so the warm-up skips
    /// it like the daily plan does (#402). Repeat the Sequence is hidden too: it ties Names and Faces in
    /// the memory area and wins on `GameID` order, so without it the rule would never be reached.
    func testGivenNamesAndFacesUnavailableAndMemoryLaneHiddenWhenWarmUpStartsThenNamesAndFacesIsNotPicked() {
        let defaults = freshDefaults("WarmUpTests.unavailable")
        defaults.set(FamilySettings.csv([.memoryMatch, .repeatSequence]), forKey: FamilySettings.hiddenKey)

        let games = WarmUpStore.start(
            profile: PlayerProfile(), today: today, defaults: defaults, unavailable: [.photoCaptions])

        XCTAssertEqual(games.count, 3)
        XCTAssertFalse(games.contains(.photoCaptions))
    }

    // MARK: The staircase while calibrating

    func testGivenCalibrationAndTwoStrongSessionsTheSameDayAtLevelFourThenTheLevelReachesEightBeforeTheThird() {
        let defaults = freshDefaults("WarmUpTests.strong")
        let game = started(defaults)[0]

        WarmUpStore.sessionFinished(game: game, accuracy: 1.0, today: today, defaults: defaults)
        WarmUpStore.sessionFinished(game: game, accuracy: 1.0, today: today, defaults: defaults)

        XCTAssertEqual(PlanStore.storedDifficulty(defaults: defaults)[game], Difficulty(level: 8))
        XCTAssertTrue(WarmUpStore.isCalibrating(game, defaults: defaults))
    }

    func testGivenAHardGoingCalibratingSessionAtLevelFourThenTheNextSessionIsAtTwo() {
        let defaults = freshDefaults("WarmUpTests.hard")
        let game = started(defaults)[0]

        WarmUpStore.sessionFinished(game: game, accuracy: 0.2, today: today, defaults: defaults)

        XCTAssertEqual(PlanStore.storedDifficulty(defaults: defaults)[game], Difficulty(level: 2))
        XCTAssertEqual(
            PlanStore.cachedPlan(defaults: defaults)?.changes[game],
            LevelChange(previous: Difficulty(level: 4), reason: .eased))
        XCTAssertEqual(PlanStore.cachedPlan(defaults: defaults)?.difficulty[game], Difficulty(level: 2))
    }

    func testGivenAMiddlingCalibratingSessionThenTheLevelStaysAndItStillCounts() {
        let defaults = freshDefaults("WarmUpTests.middling")
        let game = started(defaults)[0]
        let middling = (DailyPolicy.weakAccuracy(for: game) + DailyPolicy.strongAccuracy(for: game)) / 2

        WarmUpStore.sessionFinished(game: game, accuracy: middling, today: today, defaults: defaults)

        XCTAssertEqual(PlanStore.storedDifficulty(defaults: defaults)[game], Difficulty(level: 4))
        XCTAssertEqual(WarmUpStore.remaining(game, defaults: defaults), WarmUp.sessions - 1)
    }

    func testGivenTheLevelIsAtTheEdgeWhenCalibratingThenItStaysInOneToTen() {
        XCTAssertEqual(WarmUp.level(after: 1.0, game: .memoryMatch, current: Difficulty(level: 9)).0.level, 10)
        XCTAssertNil(WarmUp.level(after: 1.0, game: .memoryMatch, current: Difficulty(level: 10)).1)
        XCTAssertEqual(WarmUp.level(after: 0.0, game: .memoryMatch, current: Difficulty(level: 2)).0.level, 1)
    }

    // MARK: Back to the normal rule

    func testGivenTheThirdCalibratingSessionEndsThenNormalStaircaseRulesApplyAgain() {
        let defaults = freshDefaults("WarmUpTests.third")
        let game = started(defaults)[0]
        // Hard going three times: 4 -> 2 -> 1 -> 1.
        for _ in 1...WarmUp.sessions {
            WarmUpStore.sessionFinished(game: game, accuracy: 0.0, today: today, defaults: defaults)
        }
        XCTAssertFalse(WarmUpStore.isCalibrating(game, defaults: defaults))

        // A strong fourth session no longer climbs two on the spot; the daily rule decides, once a day.
        WarmUpStore.sessionFinished(game: game, accuracy: 1.0, today: today, defaults: defaults)

        XCTAssertEqual(PlanStore.storedDifficulty(defaults: defaults)[game], Difficulty(level: 1))
    }

    func testGivenACalibratingGameMovedTodayThenTheNextLevelOfferIsNotMadeThatDay() {
        let defaults = freshDefaults("WarmUpTests.offer")
        let game = started(defaults)[0]

        WarmUpStore.sessionFinished(game: game, accuracy: 1.0, today: today, defaults: defaults)

        XCTAssertTrue(LevelOfferStore.hasOfferedToday(for: game, today: today, defaults: defaults))
    }

    func testGivenAGameNotCalibratingWhenASessionFinishesThenNothingChanges() {
        let defaults = freshDefaults("WarmUpTests.notCalibrating")

        WarmUpStore.sessionFinished(game: .stroop, accuracy: 1.0, today: today, defaults: defaults)

        XCTAssertEqual(PlanStore.storedDifficulty(defaults: defaults)[.stroop], Difficulty(level: 4))
        XCTAssertNil(PlanStore.cachedPlan(defaults: defaults))
    }
}
