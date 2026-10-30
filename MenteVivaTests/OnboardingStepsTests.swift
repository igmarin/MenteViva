import XCTest

@testable import MenteViva

/// The first-run questions (#212): five steps, four answers, every one of them skippable, and
/// the gentlest pace offered first when the answers are being given for someone else.
final class OnboardingStepsTests: XCTestCase {
    private var defaults: UserDefaults!

    override func setUp() {
        defaults = UserDefaults(suiteName: "OnboardingStepsTests")
        defaults.removePersistentDomain(forName: "OnboardingStepsTests")
    }

    private func keys(_ question: OnboardingQuestion, _ profile: PlayerProfile = PlayerProfile()) -> [String] {
        OnboardingSteps.answers(for: question, profile: profile).map(\.labelKey)
    }

    private func profile(after answers: [ProfileAnswer]) -> PlayerProfile {
        answers.reduce(PlayerProfile()) { OnboardingSteps.choosing($1, in: $0) }
    }

    /// The issue's own example: a family member, memory + words, 5 minutes, pace skipped.
    private var answersOfTheIssue: [ProfileAnswer] {
        [.forWhom(.familyMember), .focus(.memory), .focus(.words), .minutes(5)]
    }

    private func state() -> PlayerStateSummary { PlayerStateSummary(games: [:]) }

    /// Noon, local time, `offset` days after a fixed day: day stamps and "days ago" stay the
    /// same wherever the tests run.
    private func noon(_ offset: Int) -> Date {
        let start = Calendar.current.date(from: DateComponents(year: 2026, month: 11, day: 2, hour: 12))!
        return Calendar.current.date(byAdding: .day, value: offset, to: start)!
    }

    // MARK: The flow

    func testGivenTheFirstRunWhenCountedThenFiveStepsAndFourQuestions() {
        XCTAssertEqual(OnboardingSteps.stepCount, 5)
        XCTAssertEqual(OnboardingSteps.questions, [.whoPlays, .focus, .minutes, .pace])
        XCTAssertEqual(OnboardingSteps.questions.filter(\.allowsMultiple), [.focus])
    }

    func testGivenEveryQuestionWhenShownThenItOffersAnswersAndPreselectsNone() {
        for question in OnboardingSteps.questions {
            let offered = OnboardingSteps.answers(for: question, profile: PlayerProfile())
            XCTAssertFalse(offered.isEmpty, "\(question) offers nothing")
            XCTAssertTrue(
                offered.filter { OnboardingSteps.isChosen($0, in: PlayerProfile()) }.isEmpty,
                "\(question) preselects an answer")
        }
    }

    // MARK: After the questions (#374: the photo offer, then the warm-up)

    func testGivenEmptyAlbumWhenOnboardingEndsThenPhotosStepIsOffered() {
        XCTAssertTrue(OnboardingSteps.offersPhotos(albumCount: 0))
        XCTAssertEqual(OnboardingSteps.afterQuestions(albumCount: 0, profile: PlayerProfile()), [.photos, .warmUp])
        XCTAssertEqual(
            OnboardingSteps.afterQuestions(albumCount: 0, profile: PlayerProfile(forWhom: .familyMember)), [.photos])
    }

    func testGivenAlbumWithPhotosWhenOnboardingEndsThenPhotosStepIsSkipped() {
        XCTAssertFalse(OnboardingSteps.offersPhotos(albumCount: 3))
        XCTAssertEqual(OnboardingSteps.afterQuestions(albumCount: 3, profile: PlayerProfile()), [.warmUp])
        XCTAssertEqual(
            OnboardingSteps.afterQuestions(albumCount: 3, profile: PlayerProfile(forWhom: .familyMember)), [])
    }

    // MARK: Which pace comes first (#212: Calm first for a family member)

    func testGivenAFamilyMemberWhenPaceAnswersThenCalmComesFirst() {
        XCTAssertEqual(
            keys(.pace, PlayerProfile(forWhom: .familyMember)),
            ["onboarding.pace.calm", "onboarding.pace.normal", "onboarding.pace.challenge"])
    }

    func testGivenNoAnswerYetOrMeWhenPaceAnswersThenNormalComesFirst() {
        XCTAssertEqual(keys(.pace).first, "onboarding.pace.normal")
        XCTAssertEqual(keys(.pace, PlayerProfile(forWhom: .me)).first, "onboarding.pace.normal")
    }

    // MARK: Giving and taking back answers

    func testGivenAFocusChosenWhenAnotherIsChosenThenBothStay() {
        let profile = profile(after: [.focus(.memory), .focus(.words)])
        XCTAssertEqual(profile.focus, [.memory, .words])
        XCTAssertTrue(OnboardingSteps.isChosen(.focus(.memory), in: profile))
        XCTAssertTrue(OnboardingSteps.isChosen(.focus(.words), in: profile))
        XCTAssertFalse(OnboardingSteps.isChosen(.focus(.numbers), in: profile))
    }

    func testGivenAChosenAnswerWhenChosenAgainThenItIsTakenBack() {
        for answer in [ProfileAnswer.forWhom(.me), .focus(.words), .minutes(10), .pace(.calm)] {
            XCTAssertEqual(profile(after: [answer, answer]), PlayerProfile(), "\(answer)")
        }
    }

    func testGivenTheIssuesAnswersWhenChosenThenTheProfileMatchesAndThePaceStaysUnanswered() {
        let profile = profile(after: answersOfTheIssue)
        XCTAssertEqual(profile, PlayerProfile(forWhom: .familyMember, focus: [.memory, .words], minutesPerDay: 5))
        XCTAssertNil(profile.startPace, "the pace step was skipped")
        for answer in answersOfTheIssue {
            XCTAssertTrue(OnboardingSteps.isChosen(answer, in: profile), "\(answer)")
        }
    }

    // MARK: What the answers do to the plan (the issue's last two acceptance lines)

    func testGivenTheIssuesAnswersWhenSavedThenTheProfileIsReadBackAndHomeDealsTwoGames() {
        ProfileStore.save(profile(after: answersOfTheIssue), defaults: defaults)
        let saved = ProfileStore.load(defaults: defaults)
        XCTAssertEqual(saved, PlayerProfile(forWhom: .familyMember, focus: [.memory, .words], minutesPerDay: 5))
        XCTAssertEqual(DailyPolicy.plan(state: state(), dayStamp: "2026-11-02", profile: saved).games.count, 2)
    }

    func testGivenFiveMinutesWhenMyPlanSaysFifteenThenTodayStandsAndTomorrowDealsFive() {
        ProfileStore.save(PlayerProfile(minutesPerDay: 5), defaults: defaults)
        XCTAssertEqual(PlanStore.todaysPlan(state: state(), now: noon(0), defaults: defaults).games.count, 2)

        // Changed today in My plan: today's plan was already dealt, so it stays as it is.
        ProfileStore.save(profile(after: [.minutes(15)]), defaults: defaults)
        XCTAssertEqual(PlanStore.todaysPlan(state: state(), now: noon(0), defaults: defaults).games.count, 2)

        // Tomorrow is dealt from the new answer.
        XCTAssertEqual(PlanStore.todaysPlan(state: state(), now: noon(1), defaults: defaults).games.count, 5)
    }
}
