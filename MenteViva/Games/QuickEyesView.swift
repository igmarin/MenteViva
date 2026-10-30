import SwiftData
import SwiftUI

/// Quick Eyes: a picture, then the player taps the matching picture among big
/// buttons. Generic visual-discrimination task — deliberately NOT a UFOV®/BrainHQ
/// clone (licensed, see docs/research-2026-09.md §3).
/// Levels 1–5 are player-paced (#46): the picture stays until "Got it", and a miss
/// keeps the round open. Levels 6–10 (or a "faster one" the player accepts) flash
/// the picture for a shrinking time. No visible countdown timer either way.
struct QuickEyesView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dynamicTypeSize) private var typeSize

    private static let totalRounds = 12
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
    /// Whether the picture waits for "Got it" instead of flashing (#46).
    private var isPaced: Bool { QuickEyesDeal.isPaced(difficulty) && !wantsFaster }
    private var startDisplayTime: Double { Self.displayTimes(for: difficulty).start }
    private var minDisplayTime: Double { Self.displayTimes(for: difficulty).floor }
    private static let voiceOverHold = 2.5
    private let shrinkFactor = 0.92
    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    enum Phase {
        case showing, choosing, invite
    }

    @State private var difficulty = Difficulty.stored(.quickEyes)
    @State private var phase: Phase = .showing
    @State private var progress = RoundProgress(totalRounds: Self.totalRounds)
    @State private var target = GamePictures.named("sunflower")
    @State private var options: [GamePicture] = []
    @State private var displayTime = QuickEyesView.displayTimes(for: Difficulty.stored(.quickEyes)).start
    @State private var correct = 0
    @State private var speedBonus = 0
    @State private var missedLastRound = false
    /// Player-paced rounds (#46): when the picture appeared, the wrong picks faded this round,
    /// whether the player took the faster-round invite, and the invite's streak.
    @State private var revealedAt = Date.now
    @State private var lookTime = 0.0
    @State private var fadedPictures: Set<GamePicture> = []
    @State private var wantsFaster = false
    @State private var invite = FasterInvite()
    @State private var optionsShownAt = Date.now
    @State private var startedAt = Date.now
    @State private var revealTask: Task<Void, Never>?
    /// The answer beat (#235): set by a tap, cleared when the next picture flashes.
    @State private var beat: AnswerBeat<GamePicture>?
    @State private var showCelebration = false
    @State private var finalDetail = ""

    static func score(correct: Int, speedBonus: Int) -> Int {
        correct * 10 + speedBonus
    }

    var body: some View {
        VStack(spacing: 24) {
            LevelExplainBanner(
                change: PlanStore.cachedPlan()?.changes[GameID.quickEyes], game: GameID.quickEyes,
                hasStarted: progress.completedRounds > 0)
            // At accessibility text sizes the long instruction would push the
            // choices off screen; while choosing, the short prompt is enough (#117).
            if phase == .showing || !typeSize.isAccessibilitySize, phase != .invite {
                Text(AppLanguage.localized(isPaced ? "game.quickeyes.instruction.paced" : "game.quickeyes.instruction"))
                    .font(.title2)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            switch phase {
            case .showing:
                VStack(spacing: 24) {
                    PictureView(picture: target, size: 120)
                        .accessibilityLabel(
                            String(format: AppLanguage.localized("game.quickeyes.a11y.flash %@"), name(of: target)))
                    if isPaced {
                        Button(action: gotIt) {
                            Text(AppLanguage.localized("game.quickeyes.gotit"))
                                .font(.title2.weight(.semibold))
                        }
                        .buttonStyle(AnswerTileStyle(minHeight: 100))
                    }
                }
            case .invite:
                VStack(spacing: 16) {
                    Text(AppLanguage.localized("game.quickeyes.invite.title"))
                        .font(.title2.weight(.semibold))
                    Button {
                        wantsFaster = true
                        displayTime = startDisplayTime
                        startRound()
                    } label: {
                        Text(AppLanguage.localized("game.quickeyes.invite.yes")).font(.title2)
                    }
                    .buttonStyle(AnswerTileStyle(minHeight: 100))
                    Button(action: startRound) {
                        Text(AppLanguage.localized("game.quickeyes.invite.no")).font(.title2)
                    }
                    .buttonStyle(AnswerTileStyle(strength: 0.08, minHeight: 100))
                }
            case .choosing:
                VStack(spacing: 16) {
                    if !fadedPictures.isEmpty {
                        // A miss keeps the round open: the picture comes back, the wrong pick fades (#46).
                        PictureView(picture: target, size: 72)
                            .accessibilityLabel(
                                String(format: AppLanguage.localized("game.quickeyes.a11y.flash %@"), name(of: target)))
                        Text(AppLanguage.localized("game.quickeyes.lookagain"))
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(Color.todaysPick)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(Color.amber.opacity(0.24), in: .rect(cornerRadius: 14))
                    } else if missedLastRound {
                        // A soft amber note, not secondary grey: the kindest
                        // line on screen should also be easy to read.
                        Text(AppLanguage.localized("game.quickeyes.almost"))
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(Color.todaysPick)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(Color.amber.opacity(0.24), in: .rect(cornerRadius: 14))
                    }
                    Text(AppLanguage.localized("game.quickeyes.prompt"))
                        .font(.title2)
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(options, id: \.self) { picture in
                            Button {
                                choose(picture)
                            } label: {
                                PictureView(picture: picture, size: 56)
                            }
                            .buttonStyle(AnswerTileStyle())
                            .disabled(fadedPictures.contains(picture))
                            .opacity(fadedPictures.contains(picture) ? 0.35 : 1)
                            .answerMark(beat?.mark(for: picture) ?? .plain)
                            .accessibilityLabel(name(of: picture))
                        }
                    }
                }
            }

            Spacer()

            RoundCounter(progress: progress)
        }
        .padding()
        .fitOrScroll()
        .gameHeader(
            .quickEyes,
            instruction: AppLanguage.localized(
                phase == .showing
                    ? (isPaced ? "game.quickeyes.instruction.paced" : "game.quickeyes.instruction")
                    : phase == .invite ? "game.quickeyes.invite.title" : "game.quickeyes.prompt")
        )
        .onAppear(perform: startRound)
        .onDisappear {
            // A beat cut short must not leave taps locked if this state comes back.
            revealTask?.cancel()
            beat = nil
        }
        // Same celebration as every other game (#45): progress, not points.
        .celebration(isPresented: $showCelebration, game: .quickEyes, detail: finalDetail, onPlayAgain: restart)
    }

    private func restart() {
        revealTask?.cancel()
        beat = nil
        progress.reset()
        correct = 0
        speedBonus = 0
        difficulty = Difficulty.stored(.quickEyes)
        displayTime = startDisplayTime
        missedLastRound = false
        wantsFaster = false
        invite = FasterInvite()
        startedAt = .now
        startRound()
    }

    private func startRound() {
        revealTask?.cancel()
        var generator = SystemRandomNumberGenerator()
        let round = QuickEyesDeal.make(optionCount: QuickEyesDeal.optionCount(for: difficulty), using: &generator)
        target = round.target
        options = round.options
        fadedPictures = []
        phase = .showing
        AccessibilityNotification.Announcement(
            String(format: AppLanguage.localized("game.quickeyes.a11y.flash %@"), name(of: target))
        ).post()
        revealedAt = .now
        // Paced rounds wait for "Got it"; nothing hides the picture on a timer.
        guard !isPaced else { return }
        // VoiceOver needs time to speak the picture; hold it longer (#64).
        let hold = UIAccessibility.isVoiceOverRunning ? max(displayTime, Self.voiceOverHold) : displayTime
        revealTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(hold))
            guard !Task.isCancelled, phase == .showing else { return }
            optionsShownAt = .now
            phase = .choosing
        }
    }

    /// "Got it" (#46): hide the picture, keep how long the player looked, show the choices.
    private func gotIt() {
        guard phase == .showing else { return }
        lookTime = Date.now.timeIntervalSince(revealedAt)
        optionsShownAt = .now
        phase = .choosing
    }

    /// A picture's name in the app's language (#324), for VoiceOver.
    private func name(of picture: GamePicture) -> String {
        AppLanguage.localized(picture.nameKey)
    }

    private func choose(_ picture: GamePicture) {
        guard phase == .choosing, beat == nil, !progress.isFinished else { return }
        // Paced levels never lose a round to a miss: fade the pick and let the player look again (#46).
        if isPaced, picture != target {
            fadedPictures.insert(picture)
            Feedback.play(.miss)
            AccessibilityNotification.Announcement(AppLanguage.localized("game.quickeyes.lookagain")).post()
            return
        }
        let firstTry = fadedPictures.isEmpty
        let answer = AnswerBeat(tapped: picture, right: target)
        beat = answer
        if answer.isRight {
            if firstTry { correct += 1 }
            missedLastRound = false
            Feedback.play(.success)
            AccessibilityNotification.Announcement(AppLanguage.localized("game.answer.right")).post()
            // Speed bonus: up to 5 points, one less per half-second of reaction time.
            let reaction = Date.now.timeIntervalSince(optionsShownAt)
            if firstTry { speedBonus += max(0, 5 - Int(reaction / 0.5)) }
            if !isPaced { displayTime = max(minDisplayTime, displayTime * shrinkFactor) }
        } else {
            missedLastRound = true
            Feedback.play(.miss)
            AccessibilityNotification.Announcement(
                String(format: AppLanguage.localized("game.answer.was %@"), name(of: target))
            ).post()
            // Relax one step after a miss so the next round feels kinder.
            displayTime = min(startDisplayTime, displayTime / shrinkFactor)
        }
        // The beat shares revealTask, so leaving the game or restarting cancels it too.
        revealTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(answer.duration(voiceOver: UIAccessibility.isVoiceOverRunning)))
            guard !Task.isCancelled else { return }
            beat = nil
            let offerFaster =
                isPaced && answer.isRight
                && invite.record(rightFirstTry: firstTry, look: lookTime)
            if progress.completeRound() {
                finish()
            } else if offerFaster {
                phase = .invite
            } else {
                startRound()
            }
        }
    }

    private func finish() {
        revealTask?.cancel()
        revealTask = nil
        let elapsed = Int(Date.now.timeIntervalSince(startedAt))
        let score = Self.score(correct: correct, speedBonus: speedBonus)
        modelContext.record(
            GameSession(
                gameID: .quickEyes, score: score,
                rounds: Self.totalRounds, durationSeconds: elapsed,
                correct: correct, attempts: Self.totalRounds,
                difficulty: difficulty))
        // Completion, never a hit count: a first-try tally can be small (#394).
        finalDetail = String(format: AppLanguage.localized("game.celebration.rounds %lld"), Self.totalRounds)
        showCelebration = true
    }
}

#Preview {
    QuickEyesView()
}
