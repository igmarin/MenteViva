import XCTest

@testable import MenteViva

/// Policy (#101, #198): the daily plan is decided by rules on the device.
/// Difficulty is a staircase (#198): strong → climb 1, two strong → climb 2,
/// hard-going → ease 1; one move per game per day, clamped 1...10.
final class DailyPolicyTests: XCTestCase {

    private typealias Stats = PlayerStateSummary.GameStats

    private func stats(
        sessions: Int = 0, accuracy: Double? = nil, days: Int = 14,
        level: Difficulty = .medium, recent: [Double] = []
    ) -> Stats {
        Stats(
            sessionsLast14Days: sessions, meanAccuracy: accuracy, meanRoundsCompleted: 8,
            daysSinceLastPlayed: days, currentDifficulty: level, recentAccuracies: recent)
    }

    private func state(_ overrides: [GameID: Stats] = [:]) -> PlayerStateSummary {
        PlayerStateSummary(
            games: Dictionary(
                uniqueKeysWithValues: GameID.allCases.map {
                    ($0.rawValue, overrides[$0] ?? stats())
                }))
    }

    private func plan(
        _ s: PlayerStateSummary, lastChange: [GameID: String] = [:],
        day: String = "2026-09-30", pinned: [GameID: Difficulty] = [:],
        hidden: Set<GameID> = []
    ) -> DailyPlan {
        DailyPolicy.plan(state: s, lastChange: lastChange, dayStamp: day, pinned: pinned, hidden: hidden)
    }

    // MARK: Unreleased games (#215)

    func testGivenUnreleasedGamesWhenPlanMadeThenNeverDealt() {
        var dealt = Set<GameID>()
        for day in 1...14 {
            // Unreleased games have never been played, so they look the most overdue.
            let p = plan(state(), day: String(format: "2026-10-%02d", day))
            dealt.formUnion(p.games)
        }
        XCTAssertTrue(dealt.isDisjoint(with: GameID.unreleased))
    }

    // MARK: Family settings (#108)

    func testGivenHiddenGamesWhenPlanThenTheyAreNeverPickedAndTheMixStaysFull() {
        let p = plan(state(), hidden: [.memoryMatch, .quickEyes])
        // The three new games (#179–#181) lead at 0.8, in GameID order.
        XCTAssertEqual(p.games, [.sudoku, .upOrDown, .sayings])
    }

    func testGivenAllButOneGameHiddenWhenPlanThenOnlyThatGameIsPicked() {
        let p = plan(state(), hidden: Set(GameID.allCases).subtracting([.stroop]))
        XCTAssertEqual(p.games, [.stroop])
    }

    func testGivenPinnedGameWithLowAccuracyWhenPlanThenThePinIsKept() {
        // Staircase eases only with a weak recent accuracy; with empty recent
        // accuracies even an unpinned game holds. Pin still wins regardless.
        let s = state([.quickEyes: stats(level: .hard, recent: [0.2])])
        XCTAssertEqual(plan(s, pinned: [.quickEyes: .hard]).difficulty[.quickEyes], .hard)
        XCTAssertEqual(plan(s).difficulty[.quickEyes], Difficulty(level: 5))  // auto eases one level
    }

    // MARK: Mix

    func testGivenBrandNewPlayerWhenPlanThenMostWorthwhileGamesLead() {
        // Sudoku ties Quick Eyes at 0.8; the tie keeps GameID order.
        XCTAssertEqual(plan(state()).games, [.memoryMatch, .quickEyes, .sudoku])
    }

    func testGivenAnyStateWhenPlanThenExactlyThreeDistinctGames() {
        let p = plan(state([.memoryMatch: stats(sessions: 9, accuracy: 0.8, days: 0)]))
        XCTAssertEqual(p.games.count, 3)
        XCTAssertEqual(Set(p.games).count, 3)
    }

    func testGivenSameStateWhenPlannedTwiceThenIdentical() {
        let s = state([.stroop: stats(sessions: 2, accuracy: 0.7, days: 3)])
        XCTAssertEqual(plan(s).games, plan(s).games)
        XCTAssertEqual(plan(s).difficulty, plan(s).difficulty)
    }

    func testGivenTopGamePlayedTodayAndAnotherRestedWhenPlanThenRestedOneOutranksIt() {
        let s = state([
            .memoryMatch: stats(sessions: 5, accuracy: 0.8, days: 0),
            .quickEyes: stats(sessions: 1, accuracy: 0.8, days: 7),
        ])
        let games = plan(s).games
        XCTAssertLessThan(games.firstIndex(of: .quickEyes)!, games.firstIndex(of: .memoryMatch) ?? 99)
    }

    func testGivenGameMissingFromStateWhenPlanThenTreatedAsNeverPlayed() {
        let p = DailyPolicy.plan(state: PlayerStateSummary(games: [:]), dayStamp: "2026-09-30")
        XCTAssertEqual(p.games, [.memoryMatch, .quickEyes, .sudoku])
        XCTAssertTrue(GameID.allCases.allSatisfy { p.difficulty[$0] == .medium })
    }

    // MARK: Staircase (#198)

    func testGivenLevelFourAndOneStrongSessionWhenPlanThenLevelFiveRaisedByOne() {
        let s = state([.stroop: stats(level: Difficulty(level: 4), recent: [0.95])])
        let p = plan(s)
        XCTAssertEqual(p.difficulty[.stroop], Difficulty(level: 5))
        XCTAssertEqual(p.changes[.stroop]?.reason, .raised(by: 1))
        XCTAssertEqual(p.changes[.stroop]?.previous, Difficulty(level: 4))
    }

    func testGivenTwoStrongSessionsInARowAtLevelFiveWhenPlanThenLevelSeven() {
        let s = state([.stroop: stats(level: Difficulty(level: 5), recent: [0.92, 0.95])])
        let p = plan(s)
        XCTAssertEqual(p.difficulty[.stroop], Difficulty(level: 7))
        XCTAssertEqual(p.changes[.stroop]?.reason, .raised(by: 2))
    }

    func testGivenHardGoingNewestSessionAtLevelSevenWhenPlanThenEasesToSixWhateverBefore() {
        let s = state([.stroop: stats(level: Difficulty(level: 7), recent: [0.4, 0.99])])
        let p = plan(s)
        XCTAssertEqual(p.difficulty[.stroop], Difficulty(level: 6))
        XCTAssertEqual(p.changes[.stroop]?.reason, .eased)
    }

    func testGivenStrongSessionAndAlreadyChangedTodayWhenPlanThenNoSecondChange() {
        let s = state([.stroop: stats(level: Difficulty(level: 5), recent: [0.95])])
        let p = plan(s, lastChange: [.stroop: "2026-09-30"])
        XCTAssertEqual(p.difficulty[.stroop], Difficulty(level: 5))
        XCTAssertNil(p.changes[.stroop])
    }

    func testGivenStrongAtTopOrHardAtBottomWhenPlanThenClampedAndNoChangeRecorded() {
        let top = state([.stroop: stats(level: Difficulty(level: 10), recent: [0.95, 0.95])])
        XCTAssertEqual(plan(top).difficulty[.stroop], Difficulty(level: 10))
        XCTAssertNil(plan(top).changes[.stroop])
        let bottom = state([.stroop: stats(level: Difficulty(level: 1), recent: [0.2])])
        XCTAssertEqual(plan(bottom).difficulty[.stroop], Difficulty(level: 1))
        XCTAssertNil(plan(bottom).changes[.stroop])
    }

    func testGivenPinnedGameWhenPlanThenLevelNeverMoves() {
        let s = state([.stroop: stats(level: Difficulty(level: 4), recent: [0.95, 0.95])])
        let p = plan(s, pinned: [.stroop: Difficulty(level: 9)])
        XCTAssertEqual(p.difficulty[.stroop], Difficulty(level: 9))
        XCTAssertNil(p.changes[.stroop])
    }

    func testGivenMiddlingAccuracyOrNoAccuraciesWhenPlanThenDifficultyKeptWithNoChange() {
        let s = state([
            .stroop: stats(level: .medium, recent: [0.80]),
            .mathStreaks: stats(level: .hard, recent: []),
        ])
        XCTAssertEqual(plan(s).difficulty[.stroop], .medium)
        XCTAssertNil(plan(s).changes[.stroop])
        XCTAssertEqual(plan(s).difficulty[.mathStreaks], .hard)
        XCTAssertNil(plan(s).changes[.mathStreaks])
    }

    func testGivenMemoryLaneStrongAndHardGoingWithOwnThresholdsWhenPlanThenMattersThere() {
        // Memory Lane's strong is 0.65, weak is 0.45.
        let strong = state([.memoryMatch: stats(level: Difficulty(level: 4), recent: [0.66])])
        XCTAssertEqual(plan(strong).difficulty[.memoryMatch], Difficulty(level: 5))
        let middling = state([.memoryMatch: stats(level: Difficulty(level: 4), recent: [0.60])])
        XCTAssertEqual(plan(middling).difficulty[.memoryMatch], Difficulty(level: 4))
        XCTAssertNil(plan(middling).changes[.memoryMatch])
        let hard = state([.memoryMatch: stats(level: Difficulty(level: 4), recent: [0.40])])
        XCTAssertEqual(plan(hard).difficulty[.memoryMatch], Difficulty(level: 3))
    }

    func testGivenChangeRecordedWhenPlanThenPreviousLevelKept() {
        let s = state([.stroop: stats(level: Difficulty(level: 6), recent: [0.95])])
        let p = plan(s)
        XCTAssertEqual(p.changes[.stroop]?.previous, Difficulty(level: 6))
        XCTAssertEqual(p.difficulty[.stroop], Difficulty(level: 7))
    }

    // MARK: The real payload (docs/jev-json/011)

    func testGivenArchivedLivePayloadWhenPlanThenSameTopThreeSetAsJevAndSensibleDifficulty() throws {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        let data = try Data(contentsOf: root.appendingPathComponent("docs/jev-json/011-daily-plan.request.json"))
        struct Envelope: Decodable { let state: PlayerStateSummary }
        let summary = try JSONDecoder().decode(Envelope.self, from: data).state
        // The 011 payload lists per-game means but no recentAccuracies array
        // yet — the staircase sees no strong session and holds every level.
        let p = plan(summary, hidden: [.reminiscence, .sudoku, .upOrDown, .sayings, .repeatSequence])
        // Jev picked quick_eyes, category_fluency, memory_match for this payload.
        XCTAssertEqual(Set(p.games), [.quickEyes, .categoryFluency, .memoryMatch])
        XCTAssertEqual(p.difficulty[.stroop], Difficulty(level: 1))
        XCTAssertEqual(p.difficulty[.mathStreaks], Difficulty(level: 1))
        XCTAssertEqual(p.difficulty[.memoryMatch], Difficulty(level: 1))
        XCTAssertTrue(p.changes.isEmpty, "011 payload has no recent accuracies, so nothing climbs")
    }

    // MARK: Today's plan, saved (PlanStore.todaysPlan)

    func testGivenNewDayWhenTodaysPlanThenPolicyPlanSavedAndChangeRecorded() {
        let defaults = UserDefaults(suiteName: "DailyPolicyTests.todaysPlanNewDay")!
        defaults.removePersistentDomain(forName: "DailyPolicyTests.todaysPlanNewDay")
        let stamp = PlanStore.dayStamp(Date(timeIntervalSince1970: 1_790_000_000))
        // Staircase needs a strong recent accuracy at the current level.
        let needingRaise = Stats(
            sessionsLast14Days: 1, meanAccuracy: 0.4,
            meanRoundsCompleted: 10, daysSinceLastPlayed: 1,
            currentDifficulty: Difficulty(level: 4), recentAccuracies: [0.96])
        let state = PlayerStateSummary(games: [GameID.stroop.rawValue: needingRaise])

        let plan = PlanStore.todaysPlan(
            state: state, now: Date(timeIntervalSince1970: 1_790_000_000), defaults: defaults)

        XCTAssertEqual(plan, DailyPolicy.plan(state: state, dayStamp: stamp))
        XCTAssertEqual(plan.difficulty[.stroop], Difficulty(level: 5))
        XCTAssertEqual(PlanStore.cachedPlan(defaults: defaults), plan)
        XCTAssertEqual(PlanStore.storedDifficulty(defaults: defaults)[.stroop], Difficulty(level: 5))
        XCTAssertEqual(PlanStore.lastDifficultyChange(defaults: defaults)[.stroop], stamp)
        XCTAssertNil(PlanStore.lastDifficultyChange(defaults: defaults)[.memoryMatch])
    }

    func testGivenPlanSavedTodayWhenTodaysPlanAgainThenSamePlanEvenIfStateChanged() {
        let defaults = UserDefaults(suiteName: "DailyPolicyTests.todaysPlanCached")!
        defaults.removePersistentDomain(forName: "DailyPolicyTests.todaysPlanCached")
        let now = Date(timeIntervalSince1970: 1_790_000_000)
        let first = PlanStore.todaysPlan(state: PlayerStateSummary(games: [:]), now: now, defaults: defaults)
        let struggling = Stats(
            sessionsLast14Days: 1, meanAccuracy: 0.4,
            meanRoundsCompleted: 10, daysSinceLastPlayed: 1,
            currentDifficulty: Difficulty(level: 3), recentAccuracies: [0.2])
        let changed = PlayerStateSummary(games: [GameID.stroop.rawValue: struggling])

        XCTAssertEqual(PlanStore.todaysPlan(state: changed, now: now, defaults: defaults), first)
    }

    func testGivenStaircaseChangeWhenArchivedThenReloadsViaCodableWithPreviousAndReason() throws {
        let day = "2026-09-30"
        let original = DailyPlan(
            dayStamp: day, games: [.memoryMatch, .quickEyes, .sudoku],
            difficulty: [.stroop: Difficulty(level: 5)],
            changes: [.stroop: LevelChange(previous: Difficulty(level: 4), reason: .raised(by: 1))])
        let restored = try JSONDecoder().decode(DailyPlan.self, from: JSONEncoder().encode(original))
        XCTAssertEqual(restored, original)
        // An old plan without `changes` still decodes.
        let withoutChanges = DailyPlan(dayStamp: day, games: [], difficulty: [:])
        let legacy = try JSONDecoder().decode(
            DailyPlan.self, from: JSONEncoder().encode(withoutChanges))
        XCTAssertEqual(legacy.changes, [:])
    }

    // MARK: A chosen level-up carries into the next days (#266)

    /// Noon, local time, `offset` days after a fixed day: stamps and "days ago" stay stable.
    private func noon(_ offset: Int) -> Date {
        let start = Calendar.current.date(from: DateComponents(year: 2026, month: 11, day: 2, hour: 12))!
        return Calendar.current.date(byAdding: .day, value: offset, to: start)!
    }

    private func played(_ game: GameID, level: Int, correct: Int, on day: Date) -> GameSession {
        let session = GameSession(
            gameID: game, score: 0, rounds: 10, durationSeconds: 1,
            correct: correct, attempts: 10, difficulty: Difficulty(level: level))
        session.playedAt = day
        return session
    }

    /// The app's own path (`HomeView.refreshPlan`): a summary from the sessions, the stored levels
    /// and the days they changed, then today's saved plan.
    private func planThroughStore(on day: Date, sessions: [GameSession], defaults: UserDefaults) -> DailyPlan {
        let state = PlayerStateSummary.build(
            from: sessions, difficulty: PlanStore.storedDifficulty(defaults: defaults), now: day,
            lastChange: PlanStore.lastDifficultyChange(defaults: defaults))
        return PlanStore.todaysPlan(state: state, now: day, defaults: defaults)
    }

    /// Day 1 for a new player: the plan deals Color Clash at level 4, a strong game, then "Yes, let's try".
    private func choseYesOnDayOne(_ defaults: UserDefaults) -> [GameSession] {
        XCTAssertEqual(planThroughStore(on: noon(0), sessions: [], defaults: defaults).difficulty[.stroop], Difficulty(level: 4))
        let strong = played(.stroop, level: 4, correct: 10, on: noon(0))
        PlanStore.raiseByChoice(.stroop, today: PlanStore.dayStamp(noon(0)), defaults: defaults)
        XCTAssertEqual(
            PlanStore.cachedPlan(defaults: defaults)?.changes[.stroop],
            LevelChange(previous: Difficulty(level: 4), reason: .chosen))
        return [strong]
    }

    private func freshDefaults(_ name: String) -> UserDefaults {
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        return defaults
    }

    func testGivenChosenYesterdayWhenNextPlanThenStartsFromChosenLevel() {
        let defaults = freshDefaults("DailyPolicyTests.chosenNextDay")
        let sessions = choseYesOnDayOne(defaults)

        let dayTwo = planThroughStore(on: noon(1), sessions: sessions, defaults: defaults)

        XCTAssertEqual(dayTwo.difficulty[.stroop], Difficulty(level: 5))
        XCTAssertNil(dayTwo.changes[.stroop], "the level-4 game that earned the Yes no longer counts")
    }

    func testGivenChosenYesterdayAndOldSessionsWhenNextPlanThenOldSessionsDontCount() {
        let defaults = freshDefaults("DailyPolicyTests.chosenOldSessions")
        // Played at level 5 before, hard going: it would ease the game if it still counted.
        let old = [
            played(.stroop, level: 5, correct: 2, on: noon(-3)),
            played(.stroop, level: 5, correct: 1, on: noon(-2)),
        ]
        let sessions = old + choseYesOnDayOne(defaults)

        let dayTwo = planThroughStore(on: noon(1), sessions: sessions, defaults: defaults)

        XCTAssertEqual(dayTwo.difficulty[.stroop], Difficulty(level: 5))
        XCTAssertNil(dayTwo.changes[.stroop])
    }

    func testGivenStrongSessionAfterChosenWhenNextPlanThenRaisesOne() {
        let defaults = freshDefaults("DailyPolicyTests.chosenThenStrong")
        var sessions = choseYesOnDayOne(defaults)
        XCTAssertEqual(
            planThroughStore(on: noon(1), sessions: sessions, defaults: defaults).difficulty[.stroop], Difficulty(level: 5))
        sessions.append(played(.stroop, level: 5, correct: 10, on: noon(1)))

        let dayThree = planThroughStore(on: noon(2), sessions: sessions, defaults: defaults)

        XCTAssertEqual(dayThree.difficulty[.stroop], Difficulty(level: 6))
        XCTAssertEqual(dayThree.changes[.stroop], LevelChange(previous: Difficulty(level: 5), reason: .raised(by: 1)))
    }
}
