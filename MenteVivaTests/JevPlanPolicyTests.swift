import XCTest
@testable import MenteViva

/// Policy: JevService.makePlan turns a hand-built answers dictionary into a
/// DailyPlan. No network — the mapping rules are what we own and must hold.
final class JevPlanPolicyTests: XCTestCase {

    private let stamp = "2026-03-07"
    private let current: [GameID: Difficulty] = [
        .memoryMatch: .medium, .stroop: .medium, .categoryFluency: .medium,
        .mathStreaks: .medium, .quickEyes: .medium,
    ]

    private func makePlan(_ answers: [String: JevAnswer],
                          gamesPerDay: Int = 3,
                          floor: Double = 0.6) -> DailyPlan {
        JevService.makePlan(from: answers, current: current, dayStamp: stamp,
                            gamesPerDay: gamesPerDay, confidenceFloor: floor)
    }

    // MARK: Mix ranking

    func testGivenIncludeProbabilitiesWhenPlanThenGamesRankedBestFirst() {
        let answers: [String: JevAnswer] = [
            "include_stroop": .noul(probability: 0.9),
            "include_math_streaks": .noul(probability: 0.7),
            "include_memory_match": .noul(probability: 0.4),
            "include_quick_eyes": .noul(probability: 0.2),
            "include_category_fluency": .noul(probability: 0.1),
        ]
        let plan = makePlan(answers)
        XCTAssertEqual(plan.games, [.stroop, .mathStreaks, .memoryMatch])
    }

    func testGivenMissingIncludeAnswersWhenPlanThenThoseGamesSortLast() {
        let answers: [String: JevAnswer] = [
            "include_quick_eyes": .noul(probability: 0.5),
        ]
        let plan = makePlan(answers)
        XCTAssertEqual(plan.games.first, .quickEyes)
        XCTAssertEqual(plan.games.count, 3)
    }

    func testGivenAllProbabilitiesLowWhenPlanThenMixStillHasGamesPerDay() {
        // prefix() keeps the mix non-empty even when Jev hates everything.
        let answers = Dictionary(uniqueKeysWithValues:
            GameID.allCases.map { ("include_\($0.rawValue)", JevAnswer.noul(probability: 0.01)) })
        let plan = makePlan(answers)
        XCTAssertEqual(plan.games.count, 3)
        XCTAssertEqual(Set(plan.games).count, 3)
    }

    func testGivenCustomGamesPerDayWhenPlanThenPrefixRespectsIt() {
        let answers: [String: JevAnswer] = [
            "include_stroop": .noul(probability: 0.9),
            "include_math_streaks": .noul(probability: 0.7),
        ]
        let plan = makePlan(answers, gamesPerDay: 2)
        XCTAssertEqual(plan.games, [.stroop, .mathStreaks])
    }

    // MARK: Difficulty confidence gate

    func testGivenConfidentScoreWhenPlanThenDifficultyIsApplied() {
        let answers: [String: JevAnswer] = [
            "difficulty_stroop": .score(score: 1.8, confidence: 0.9),
        ]
        let plan = makePlan(answers)
        XCTAssertEqual(plan.difficulty[.stroop], .hard)
    }

    func testGivenLowConfidenceScoreWhenPlanThenCurrentDifficultyKept() {
        // Wrong difficulty is the high-stakes error; below the floor we keep yesterday's.
        let answers: [String: JevAnswer] = [
            "difficulty_stroop": .score(score: 2.0, confidence: 0.59),
        ]
        let plan = makePlan(answers)
        XCTAssertEqual(plan.difficulty[.stroop], .medium)
    }

    func testGivenScoreAtConfidenceFloorWhenPlanThenItIsApplied() {
        let answers: [String: JevAnswer] = [
            "difficulty_stroop": .score(score: 0.2, confidence: 0.6),
        ]
        let plan = makePlan(answers)
        XCTAssertEqual(plan.difficulty[.stroop], .easy)
    }

    func testGivenNoDifficultyAnswersWhenPlanThenCurrentDifficultyPreserved() {
        let plan = makePlan([:])
        XCTAssertEqual(plan.difficulty, current)
    }

    func testGivenAnyAnswersWhenPlanThenDayStampIsCarriedThrough() {
        XCTAssertEqual(makePlan([:]).dayStamp, stamp)
    }
}
