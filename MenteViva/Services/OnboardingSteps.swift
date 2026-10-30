import Foundation

/// The four first-run questions (#212), as data instead of as screens. The same four answers
/// are asked once on first run and can be changed any time in Settings → My plan, so the
/// questions, the options and the way an answer lands in the `PlayerProfile` live in one pure
/// place that tests can drive without a screen.
nonisolated enum OnboardingQuestion: String, CaseIterable {
    /// Who will play: it decides which pace is offered first.
    case whoPlays
    /// What to exercise. Any number of answers, or none at all.
    case focus
    /// Minutes a day, which decides how many games the daily plan deals.
    case minutes
    /// How to start, which quietly sets the level a game begins at.
    case pace

    /// The question itself, in the player's language.
    var titleKey: String {
        switch self {
        case .whoPlays: "onboarding.who.title"
        case .focus: "onboarding.focus.title"
        case .minutes: "onboarding.minutes.title"
        case .pace: "onboarding.pace.title"
        }
    }

    /// Only the focus question takes more than one answer, so it is the only one that waits
    /// for "Next" instead of moving on at the first tap.
    var allowsMultiple: Bool { self == .focus }
}

/// One answer the player can give. Each case carries the profile's own value, so a screen
/// never maps a label back to a meaning, and `PlayerProfile` stays the only place that
/// knows what an answer means.
nonisolated enum ProfileAnswer: Equatable {
    case forWhom(PlayerProfile.ForWhom)
    case focus(PlayerProfile.Focus)
    case minutes(Int)
    case pace(PlayerProfile.StartPace)

    /// The answer's own words. The minutes are keyed one by one so every offered answer is
    /// a string that exists in the catalog, in both languages.
    var labelKey: String {
        switch self {
        case .forWhom(.me): "onboarding.who.me"
        case .forWhom(.familyMember): "onboarding.who.family"
        case .focus(.memory): "onboarding.focus.memory"
        case .focus(.attention): "onboarding.focus.attention"
        case .focus(.numbers): "onboarding.focus.numbers"
        case .focus(.words): "onboarding.focus.words"
        case .focus(.justFun): "onboarding.focus.fun"
        case .minutes(let minutes): "onboarding.minutes.\(minutes)"
        case .pace(.calm): "onboarding.pace.calm"
        case .pace(.normal): "onboarding.pace.normal"
        case .pace(.challenge): "onboarding.pace.challenge"
        }
    }
}

/// A screen the first run may show after the last question, outside the "N of 5" count:
/// both are offers, so neither is a step the player has to take.
nonisolated enum OnboardingOffer: Equatable {
    /// "Add a few photos of people you love?" (#374).
    case photos
    /// "Shall we play three games to find your pace?" (#213).
    case warmUp
}

/// The questions in order and what each one offers (#212). Pure: no view, no store, so the
/// order rule below is a thing tests can hold on to.
nonisolated enum OnboardingSteps {
    /// The four questions, in the order they are asked. On screen the first run is five
    /// steps, because the welcome screen counts as the first one.
    static let questions: [OnboardingQuestion] = [.whoPlays, .focus, .minutes, .pace]

    /// How many steps the first run shows, counting the welcome screen ("2 of 5", #212).
    static let stepCount = questions.count + 1

    /// The family photos are offered only while the album is empty (#374): three games are
    /// better with them, and someone who already added photos has found Set up on their own.
    static func offersPhotos(albumCount: Int) -> Bool {
        albumCount == 0
    }

    /// The offers after the last question, in order: photos first, so the warm-up that follows
    /// can already deal from them, then the warm-up when it applies (#213). Empty means Home.
    static func afterQuestions(albumCount: Int, profile: PlayerProfile) -> [OnboardingOffer] {
        (offersPhotos(albumCount: albumCount) ? [.photos] : []) + (WarmUp.isOffered(to: profile) ? [.warmUp] : [])
    }

    /// The answers to offer, in the order to show them. With "a family member" the gentlest
    /// pace is the nearest one to the thumb, because whoever answers is choosing for someone
    /// else; for yourself the everyday pace leads. Nothing is preselected either way, so the
    /// order is a nudge, never an answer (#212).
    static func answers(for question: OnboardingQuestion, profile: PlayerProfile) -> [ProfileAnswer] {
        switch question {
        case .whoPlays: [.forWhom(.me), .forWhom(.familyMember)]
        case .focus: PlayerProfile.Focus.allCases.map(ProfileAnswer.focus)
        case .minutes: [.minutes(5), .minutes(10), .minutes(15)]
        case .pace:
            profile.forWhom == .familyMember
                ? [.pace(.calm), .pace(.normal), .pace(.challenge)]
                : [.pace(.normal), .pace(.calm), .pace(.challenge)]
        }
    }

    /// Whether the profile already holds this answer: the tick and the filled tile.
    static func isChosen(_ answer: ProfileAnswer, in profile: PlayerProfile) -> Bool {
        switch answer {
        case .forWhom(let whom): profile.forWhom == whom
        case .focus(let focus): profile.focus.contains(focus)
        case .minutes(let minutes): profile.minutesPerDay == minutes
        case .pace(let pace): profile.startPace == pace
        }
    }

    /// The profile with this answer given. Giving the same answer again takes it back, so
    /// every question can be left unanswered again: that is how a first-run answer is undone
    /// in My plan, without a "none" button to explain.
    static func choosing(_ answer: ProfileAnswer, in profile: PlayerProfile) -> PlayerProfile {
        var profile = profile
        switch answer {
        case .forWhom(let whom):
            profile.forWhom = profile.forWhom == whom ? nil : whom
        case .focus(let focus):
            if profile.focus.contains(focus) {
                profile.focus.remove(focus)
            } else {
                profile.focus.insert(focus)
            }
        case .minutes(let minutes):
            profile.minutesPerDay = profile.minutesPerDay == minutes ? nil : minutes
        case .pace(let pace):
            profile.startPace = profile.startPace == pace ? nil : pace
        }
        return profile
    }
}
