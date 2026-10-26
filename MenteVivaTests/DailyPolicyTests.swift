import XCTest

@testable import MenteViva

/// Policy (#101): the daily plan is decided by rules on the device. Same state,
/// same answer; errorless-first; difficulty moves one level and then holds.
final class DailyPolicyTests: XCTestCase {

    private typealias Stats = PlayerStateSummary.GameStats

    private func stats(
        sessions: Int = 0, accuracy: Double? = nil, days: Int = 14,
        level: Difficulty = .medium
    ) -> Stats {
        Stats(
            sessionsLast14Days: sessions, meanAccuracy: accuracy, meanRoundsCompleted: 8,
            daysSinceLastPlayed: days, currentDifficulty: level)
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
        let s = state([.quickEyes: stats(sessions: 4, accuracy: 0.3, level: .hard)])
        XCTAssertEqual(plan(s, pinned: [.quickEyes: .hard]).difficulty[.quickEyes], .hard)
        XCTAssertEqual(plan(s).difficulty[.quickEyes], .medium)  // auto would have eased it
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

    // MARK: Difficulty

    func testGivenLowAccuracyWhenPlanThenOneLevelEasier() {
        let p = plan(state([.stroop: stats(sessions: 1, accuracy: 0.6, level: .medium)]))
        XCTAssertEqual(p.difficulty[.stroop], .easy)
        let hard = plan(state([.stroop: stats(sessions: 1, accuracy: 0.6, level: .hard)]))
        XCTAssertEqual(hard.difficulty[.stroop], .medium, "never two levels in one day")
    }

    func testGivenEasiestLevelAndLowAccuracyWhenPlanThenStaysEasy() {
        let p = plan(state([.stroop: stats(sessions: 4, accuracy: 0.2, level: .easy)]))
        XCTAssertEqual(p.difficulty[.stroop], .easy)
    }

    func testGivenHighAccuracyAndEnoughSessionsWhenPlanThenOneLevelHarder() {
        let p = plan(state([.categoryFluency: stats(sessions: 3, accuracy: 0.95)]))
        XCTAssertEqual(p.difficulty[.categoryFluency], .hard)
    }

    func testGivenHighAccuracyButThinDataWhenPlanThenDifficultyKept() {
        let p = plan(state([.categoryFluency: stats(sessions: 2, accuracy: 1.0)]))
        XCTAssertEqual(p.difficulty[.categoryFluency], .medium)
    }

    func testGivenHardAndHighAccuracyWhenPlanThenStaysHard() {
        let p = plan(state([.quickEyes: stats(sessions: 6, accuracy: 0.99, level: .hard)]))
        XCTAssertEqual(p.difficulty[.quickEyes], .hard)
    }

    func testGivenMiddlingAccuracyOrNoSessionsWhenPlanThenDifficultyKept() {
        let p = plan(
            state([
                .memoryMatch: stats(sessions: 6, accuracy: 0.78, level: .easy),
                .mathStreaks: stats(sessions: 0, accuracy: nil, level: .hard),
            ]))
        XCTAssertEqual(p.difficulty[.memoryMatch], .easy)
        XCTAssertEqual(p.difficulty[.mathStreaks], .hard)
    }

    func testGivenSessionsWithoutAccuracyWhenPlanThenDifficultyKept() {
        let p = plan(state([.memoryMatch: stats(sessions: 5, accuracy: nil)]))
        XCTAssertEqual(p.difficulty[.memoryMatch], .medium)
    }

    func testGivenRecentChangeWhenPlanThenHeldUntilTheHoldExpires() {
        let low = state([.stroop: stats(sessions: 3, accuracy: 0.5, level: .medium)])
        // changed 3 days ago -> held
        XCTAssertEqual(plan(low, lastChange: [.stroop: "2026-09-27"]).difficulty[.stroop], .medium)
        // changed exactly holdDays ago -> free to move again
        XCTAssertEqual(plan(low, lastChange: [.stroop: "2026-09-23"]).difficulty[.stroop], .easy)
        // unparseable stamp never blocks a change
        XCTAssertEqual(plan(low, lastChange: [.stroop: "garbage"]).difficulty[.stroop], .easy)
    }

    // MARK: The real payload (docs/jev-json/011)

    func testGivenArchivedLivePayloadWhenPlanThenSameTopThreeSetAsJevAndSensibleDifficulty() throws {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        let data = try Data(contentsOf: root.appendingPathComponent("docs/jev-json/011-daily-plan.request.json"))
        struct Envelope: Decodable { let state: PlayerStateSummary }
        let summary = try JSONDecoder().decode(Envelope.self, from: data).state
        // The payload predates the sixth to ninth games, so compare in the five-game world.
        let p = plan(summary, hidden: [.reminiscence, .sudoku, .upOrDown, .sayings])
        // Jev picked quick_eyes, category_fluency, memory_match for this payload.
        XCTAssertEqual(Set(p.games), [.quickEyes, .categoryFluency, .memoryMatch])
        XCTAssertEqual(p.difficulty[.stroop], .easy)  // 0.60 accuracy, one session
        XCTAssertEqual(p.difficulty[.mathStreaks], .medium)  // no sessions: no evidence, no change
        XCTAssertEqual(p.difficulty[.memoryMatch], .medium)
    }

    // MARK: Today's plan, saved (PlanStore.todaysPlan)

    func testGivenNewDayWhenTodaysPlanThenPolicyPlanSavedAndChangeRecorded() {
        let defaults = UserDefaults(suiteName: "DailyPolicyTests.todaysPlan")!
        defaults.removePersistentDomain(forName: "DailyPolicyTests.todaysPlan")
        let struggling = Stats(
            sessionsLast14Days: 2, meanAccuracy: 0.4,
            meanRoundsCompleted: 10, daysSinceLastPlayed: 1, currentDifficulty: .medium)
        let state = PlayerStateSummary(games: [GameID.stroop.rawValue: struggling])

        let plan = PlanStore.todaysPlan(
            state: state, now: Date(timeIntervalSince1970: 1_790_000_000), defaults: defaults)

        XCTAssertEqual(plan, DailyPolicy.plan(state: state, dayStamp: plan.dayStamp))
        XCTAssertEqual(plan.difficulty[.stroop], .easy)
        XCTAssertEqual(PlanStore.cachedPlan(defaults: defaults), plan)
        XCTAssertEqual(PlanStore.storedDifficulty(defaults: defaults)[.stroop], .easy)
        XCTAssertEqual(PlanStore.lastDifficultyChange(defaults: defaults)[.stroop], plan.dayStamp)
        XCTAssertNil(PlanStore.lastDifficultyChange(defaults: defaults)[.memoryMatch])
    }

    func testGivenPlanSavedTodayWhenTodaysPlanAgainThenSamePlanEvenIfStateChanged() {
        let defaults = UserDefaults(suiteName: "DailyPolicyTests.todaysPlanCached")!
        defaults.removePersistentDomain(forName: "DailyPolicyTests.todaysPlanCached")
        let now = Date(timeIntervalSince1970: 1_790_000_000)
        let first = PlanStore.todaysPlan(state: PlayerStateSummary(games: [:]), now: now, defaults: defaults)
        let struggling = Stats(
            sessionsLast14Days: 2, meanAccuracy: 0.4,
            meanRoundsCompleted: 10, daysSinceLastPlayed: 1, currentDifficulty: .medium)
        let changed = PlayerStateSummary(games: [GameID.stroop.rawValue: struggling])

        XCTAssertEqual(PlanStore.todaysPlan(state: changed, now: now, defaults: defaults), first)
    }
}
