import XCTest

@testable import MenteViva

/// The plan and levels saved on this device (#419): a game opened after midnight never explains
/// yesterday's level move, and a start pace chosen later still reaches the games never played.
final class PlanStoreTests: XCTestCase {

    private func isolatedDefaults() throws -> UserDefaults {
        let name = "PlanStoreTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: name))
        addTeardownBlock { defaults.removePersistentDomain(forName: name) }
        return defaults
    }

    private let now = Date(timeIntervalSince1970: 1_793_000_000)
    private let raised = LevelChange(previous: Difficulty(level: 4), reason: .raised(by: 1))

    private func savePlan(madeOn day: Date, defaults: UserDefaults) {
        PlanStore.cache(
            DailyPlan(
                dayStamp: PlanStore.dayStamp(day), games: [.stroop], difficulty: [.stroop: Difficulty(level: 5)],
                changes: [.stroop: raised]),
            defaults: defaults)
    }

    // MARK: Today's change

    func testGivenYesterdaysPlanWhenAskingTodaysChangeThenNil() throws {
        let defaults = try isolatedDefaults()
        savePlan(madeOn: now.addingTimeInterval(-86_400), defaults: defaults)

        XCTAssertNil(PlanStore.todaysChange(.stroop, now: now, defaults: defaults))
    }

    func testGivenTodaysPlanWhenAskingTodaysChangeThenItsChange() throws {
        let defaults = try isolatedDefaults()
        savePlan(madeOn: now, defaults: defaults)

        XCTAssertEqual(PlanStore.todaysChange(.stroop, now: now, defaults: defaults), raised)
    }

    // MARK: Planned today (#417)

    func testGivenTodaysPlanWhenAskingPlannedTodayThenItsGames() throws {
        let defaults = try isolatedDefaults()
        savePlan(madeOn: now, defaults: defaults)

        XCTAssertEqual(PlanStore.plannedToday(now: now, defaults: defaults), [.stroop])
    }

    func testGivenYesterdaysPlanWhenAskingPlannedTodayThenNil() throws {
        let defaults = try isolatedDefaults()
        savePlan(madeOn: now.addingTimeInterval(-86_400), defaults: defaults)

        XCTAssertNil(PlanStore.plannedToday(now: now, defaults: defaults))
    }

    func testGivenNoPlanWhenAskingPlannedTodayThenNilAndNothingIsSaved() throws {
        let defaults = try isolatedDefaults()

        XCTAssertNil(PlanStore.plannedToday(now: now, defaults: defaults))
        XCTAssertNil(PlanStore.cachedPlan(defaults: defaults))
    }

    // MARK: Start pace (#212)

    /// Day one: the first plan saves every game at the starting level (4 without a profile), so the
    /// start pace is never read from the profile again.
    private func saveFirstPlan(defaults: UserDefaults) {
        let levels = Dictionary(uniqueKeysWithValues: GameID.allCases.map { ($0, Difficulty(level: 4)) })
        PlanStore.cache(DailyPlan(dayStamp: PlanStore.dayStamp(now), games: [], difficulty: levels), defaults: defaults)
    }

    private let normal = PlayerProfile(startPace: .normal)
    private let calm = PlayerProfile(startPace: .calm)

    func testGivenUnplayedGamesWhenStartPaceChangesToCalmThenTheirLevelsBecomeTwo() throws {
        let defaults = try isolatedDefaults()
        saveFirstPlan(defaults: defaults)

        PlanStore.startPaceChanged(from: normal, to: calm, played: { [] }, defaults: defaults)

        let levels = PlanStore.storedDifficulty(defaults: defaults)
        XCTAssertEqual(levels[.sudoku], Difficulty(level: 2))
        XCTAssertEqual(levels[.tangram], Difficulty(level: 2))
    }

    func testGivenPlayedOrPinnedGameWhenStartPaceChangesThenItsLevelIsKept() throws {
        let defaults = try isolatedDefaults()
        saveFirstPlan(defaults: defaults)
        PlanStore.restart([.memoryMatch], at: Difficulty(level: 7), defaults: defaults)
        PlanStore.restart([.sudoku], at: Difficulty(level: 3), defaults: defaults)
        defaults.set(9, forKey: FamilySettings.pinKey(.sudoku))

        PlanStore.startPaceChanged(from: normal, to: calm, played: { [.memoryMatch] }, defaults: defaults)

        let levels = PlanStore.storedDifficulty(defaults: defaults)
        XCTAssertEqual(levels[.memoryMatch], Difficulty(level: 7), "played")
        XCTAssertEqual(levels[.sudoku], Difficulty(level: 3), "pinned")
        XCTAssertEqual(levels[.tangram], Difficulty(level: 2), "never played, not pinned")
    }

    /// A store that can't be read at all gives no played set: nothing moves.
    func testGivenAnUnreadableStoreWhenStartPaceChangesThenNoLevelMoves() throws {
        let defaults = try isolatedDefaults()
        saveFirstPlan(defaults: defaults)

        PlanStore.startPaceChanged(from: normal, to: calm, played: { nil }, defaults: defaults)

        XCTAssertEqual(PlanStore.storedDifficulty(defaults: defaults)[.tangram], Difficulty(level: 4))
    }

    /// An unreadable session store (#124) shows no game as played; a level that moved is still kept.
    func testGivenALevelThatMovedWhenStartPaceChangesWithNoPlayedGamesThenItIsKept() throws {
        let defaults = try isolatedDefaults()
        saveFirstPlan(defaults: defaults)
        PlanStore.move(.stroop, to: Difficulty(level: 6), reason: .chosen, today: "2026-10-20", defaults: defaults)

        PlanStore.startPaceChanged(from: normal, to: calm, played: { [] }, defaults: defaults)

        XCTAssertEqual(PlanStore.storedDifficulty(defaults: defaults)[.stroop], Difficulty(level: 6))
    }

    func testGivenTheSameStartingLevelWhenAnotherAnswerChangesThenNoLevelMoves() throws {
        let defaults = try isolatedDefaults()
        saveFirstPlan(defaults: defaults)

        // A family member with no pace answer already starts calm, so choosing calm changes nothing.
        PlanStore.startPaceChanged(
            from: PlayerProfile(forWhom: .familyMember), to: PlayerProfile(forWhom: .familyMember, startPace: .calm),
            played: {
                XCTFail("the session store is read only when the starting level changes")
                return []
            }, defaults: defaults)

        XCTAssertEqual(PlanStore.storedDifficulty(defaults: defaults)[.tangram], Difficulty(level: 4))
    }
}
