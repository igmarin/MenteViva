import Foundation

/// Quick Eyes' rules for one run (#416): which picks count, the paced fade, how fast the flash is
/// and when to offer a faster round. `correct` and the round count feed the level staircase, so
/// they live here where a test can reach them; the view keeps the phase, its tasks and what
/// VoiceOver hears.
nonisolated struct QuickEyesRun {
    /// Flash length in seconds for levels 1...10: where it starts and the floor it shrinks to (#200).
    /// Levels 2, 4 and 6 keep the old easy, medium and hard pairs, so migrated players notice nothing.
    /// Level 1 gives the slowest start yet, and 7–10 tighten in small steps; no time grows with the level.
    static let displayTimeTable: [(start: Double, floor: Double)] = [
        (2.0, 1.0), (1.6, 0.8), (1.4, 0.5), (1.2, 0.35), (1.1, 0.3),
        (1.0, 0.25), (0.9, 0.22), (0.8, 0.2), (0.75, 0.18), (0.7, 0.16),
    ]

    static func displayTimes(for difficulty: Difficulty) -> (start: Double, floor: Double) {
        difficulty.values(displayTimeTable)
    }

    /// Each right pick shortens the flash by this much, each miss lengthens it by the same step.
    private static let shrinkFactor = 0.92

    /// What a pick did, so the view knows whether the round is over.
    enum Pick: Equatable {
        /// Paced level, wrong picture: it fades and the round stays open (#46).
        case faded
        /// The right picture; `firstTry` is false when a wrong one faded earlier this round.
        case right(firstTry: Bool)
        /// Flashing level, wrong picture: the round ends with a warm "almost".
        case missed
    }

    let difficulty: Difficulty
    /// Right first try only, as the level staircase reads it.
    private(set) var correct = 0
    private(set) var missedLastRound = false
    /// Wrong pictures faded this round (paced levels).
    private(set) var fadedPictures: Set<GamePicture> = []
    private(set) var displayTime: Double
    private var wantsFaster = false
    private var invite = FasterInvite()
    private var lastPick: Pick?

    init(difficulty: Difficulty) {
        self.difficulty = difficulty
        displayTime = Self.displayTimes(for: difficulty).start
    }

    /// Whether the picture waits for "Got it" instead of flashing (#46), until the player takes the faster round.
    var isPaced: Bool { QuickEyesDeal.isPaced(difficulty) && !wantsFaster }

    /// A new picture is dealt: last round's faded picks and pick are forgotten.
    mutating func startRound() {
        fadedPictures = []
        lastPick = nil
    }

    /// Applies one pick. Paced levels never lose a round to a miss: the wrong picture fades and the
    /// player looks again (#46). Flash levels shrink the flash on a right pick and relax one step on a miss
    /// so the next round feels kinder.
    mutating func pick(_ picture: GamePicture, target: GamePicture) -> Pick {
        let result: Pick
        if isPaced, picture != target {
            fadedPictures.insert(picture)
            result = .faded
        } else if picture == target {
            let firstTry = fadedPictures.isEmpty
            if firstTry {
                correct += 1
            }
            missedLastRound = false
            if !isPaced { displayTime = max(Self.displayTimes(for: difficulty).floor, displayTime * Self.shrinkFactor) }
            result = .right(firstTry: firstTry)
        } else {
            missedLastRound = true
            displayTime = min(Self.displayTimes(for: difficulty).start, displayTime / Self.shrinkFactor)
            result = .missed
        }
        lastPick = result
        return result
    }

    /// The player said yes to a faster round: flash from the level's start time from now on.
    mutating func acceptFaster() {
        wantsFaster = true
        displayTime = Self.displayTimes(for: difficulty).start
    }

    /// The answer beat is over: true when the faster-round invite should show now. Only a right
    /// pick on a paced level counts towards the invite's streak.
    mutating func roundEnded(lookSeconds: Double) -> Bool {
        guard isPaced, case .right(let firstTry)? = lastPick else { return false }
        return invite.record(rightFirstTry: firstTry, look: lookSeconds)
    }
}
