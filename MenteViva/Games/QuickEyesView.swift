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
    @Environment(\.scenePhase) private var scenePhase

    private static let totalRounds = 12
    /// Whether the picture waits for "Got it" instead of flashing (#46).
    private var isPaced: Bool { run.isPaced }
    private static let voiceOverHold = 2.5
    /// The choice grid's gap and the screen's edge padding, named so the tile-width fit below
    /// does not lean on SwiftUI defaults (#413).
    private let gridGap: CGFloat = 8
    private let edgePadding: CGFloat = 16
    private var columns: [GridItem] {
        [GridItem(.flexible(), spacing: gridGap), GridItem(.flexible(), spacing: gridGap)]
    }
    /// Picture sizes and the choice tile's margin (#413), scaled with Dynamic Type
    /// (title2, like the tick). Choices are 84 in a 110pt tile, the flash target up to 240, the look-again
    /// thumbnail 96.
    @ScaledMetric(relativeTo: .title2) private var choiceSize: CGFloat = 84
    @ScaledMetric(relativeTo: .title2) private var choiceMargin: CGFloat = 13
    @ScaledMetric(relativeTo: .title2) private var flashCeiling: CGFloat = 240
    @ScaledMetric(relativeTo: .title2) private var thumbnailSize: CGFloat = 96
    /// The screen's width, which caps the flash target and the choices (#413).
    @State private var viewWidth = UIScreen.main.bounds.width

    enum Phase {
        case showing, choosing, invite
    }

    /// The run's rules (#416): picks, fade, flash speed and the faster-round invite.
    @State private var run = QuickEyesRun(difficulty: Difficulty.stored(.quickEyes))
    @State private var phase: Phase = .showing
    @State private var progress = RoundProgress(totalRounds: Self.totalRounds)
    @State private var target = GamePictures.named("sunflower")
    @State private var options: [GamePicture] = []
    /// Player-paced rounds (#46): when the picture appeared and how long the player looked.
    @State private var revealedAt = Date.now
    @State private var lookTime = 0.0
    @State private var optionsShownAt = Date.now
    @State private var startedAt = Date.now
    @State private var revealTask: Task<Void, Never>?
    /// A call or the app switcher cut the flash short (#415): deal the round again on return, uncounted.
    @State private var flashInterrupted = false
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
                    PictureView(
                        picture: target,
                        size: PictureView.flashTarget(
                            ceiling: flashCeiling, width: viewWidth, isAccessibilitySize: typeSize.isAccessibilitySize)
                    )
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
                        run.acceptFaster()
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
                    if !run.fadedPictures.isEmpty {
                        // A miss keeps the round open: the picture comes back, the wrong pick fades (#46).
                        PictureView(picture: target, size: thumbnailSize)
                            .accessibilityLabel(
                                String(format: AppLanguage.localized("game.quickeyes.a11y.flash %@"), name(of: target)))
                        Text(AppLanguage.localized("game.quickeyes.lookagain"))
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(Color.todaysPick)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(Color.amber.opacity(0.24), in: .rect(cornerRadius: 14))
                    } else if run.missedLastRound {
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
                                PictureView(picture: picture, size: fittedChoiceSize)
                                    .padding(choiceMargin)
                            }
                            .buttonStyle(AnswerTileStyle())
                            .disabled(run.fadedPictures.contains(picture))
                            .opacity(run.fadedPictures.contains(picture) ? 0.35 : 1)
                            .answerMark(beat?.mark(for: picture) ?? .plain)
                            .accessibilityLabel(name(of: picture))
                        }
                    }
                }
            }

            Spacer()

            RoundCounter(progress: progress)
        }
        .padding(edgePadding)
        // `gameColumn()` in two halves: the width is measured inside the column, so the
        // pictures are fitted to the column and not to a wide iPad screen (#400).
        .frame(maxWidth: GameColumn.maxWidth)
        .onGeometryChange(for: CGFloat.self) {
            $0.size.width
        } action: { width in
            if width > 0 { viewWidth = width }
        }
        .frame(maxWidth: .infinity)
        .fitOrScroll()
        .gameHeader(
            .quickEyes,
            instruction: AppLanguage.localized(
                phase == .showing
                    ? (isPaced ? "game.quickeyes.instruction.paced" : "game.quickeyes.instruction")
                    : phase == .invite ? "game.quickeyes.invite.title" : "game.quickeyes.prompt")
        )
        .onAppear(perform: startRound)
        .onChange(of: scenePhase) { _, newPhase in pauseOrResume(for: newPhase) }
        .onDisappear {
            // A beat cut short must not leave taps locked if this state comes back.
            revealTask?.cancel()
            beat = nil
        }
        // Same celebration as every other game (#45): progress, not points.
        .celebration(isPresented: $showCelebration, game: .quickEyes, detail: finalDetail, onPlayAgain: restart)
    }

    /// The choice picture at its scaled size, held to what a two-column tile can carry (#413):
    /// the screen less its edge padding and the gap, halved.
    private var fittedChoiceSize: CGFloat {
        PictureView.fitted(
            choiceSize, columnWidth: (viewWidth - 2 * edgePadding - gridGap) / 2, margin: choiceMargin)
    }

    private func restart() {
        revealTask?.cancel()
        beat = nil
        progress.reset()
        run = QuickEyesRun(difficulty: Difficulty.stored(.quickEyes))
        startedAt = .now
        startRound()
    }

    private func startRound() {
        revealTask?.cancel()
        var generator = SystemRandomNumberGenerator()
        let round = QuickEyesDeal.make(optionCount: QuickEyesDeal.optionCount(for: run.difficulty), using: &generator)
        target = round.target
        options = round.options
        run.startRound()
        phase = .showing
        AccessibilityNotification.Announcement(
            String(format: AppLanguage.localized("game.quickeyes.a11y.flash %@"), name(of: target))
        ).post()
        revealedAt = .now
        // Paced rounds wait for "Got it"; nothing hides the picture on a timer.
        guard !isPaced else { return }
        // VoiceOver needs time to speak the picture; hold it longer (#64).
        let hold = UIAccessibility.isVoiceOverRunning ? max(run.displayTime, Self.voiceOverHold) : run.displayTime
        revealTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(hold))
            guard !Task.isCancelled, phase == .showing else { return }
            optionsShownAt = .now
            phase = .choosing
        }
    }

    /// A flash cut short by a call or the app switcher must not cost a round (#415): stop its timer,
    /// and when the app is active again show the round again. Only the flash timer is stopped; the
    /// answer beat finishes by itself, and cancelling it would leave taps locked.
    private func pauseOrResume(for newPhase: ScenePhase) {
        if newPhase != .active {
            guard phase == .showing, !isPaced, !flashInterrupted else { return }
            revealTask?.cancel()
            flashInterrupted = true
        } else if flashInterrupted {
            flashInterrupted = false
            if phase == .showing { startRound() }
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
        // Paced levels never lose a round to a miss: the run fades the pick and the player looks again (#46).
        let reaction = Date.now.timeIntervalSince(optionsShownAt)
        let outcome = run.pick(picture, target: target, reactionSeconds: reaction)
        if outcome == .faded {
            Feedback.play(.miss)
            AccessibilityNotification.Announcement(AppLanguage.localized("game.quickeyes.lookagain")).post()
            return
        }
        let answer = AnswerBeat(tapped: picture, right: target)
        beat = answer
        answer.play(rightName: name(of: target))
        // The beat shares revealTask, so leaving the game or restarting cancels it too.
        revealTask = answer.after {
            beat = nil
            let offerFaster = run.roundEnded(lookSeconds: lookTime)
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
        let score = Self.score(correct: run.correct, speedBonus: run.speedBonus)
        modelContext.record(
            GameSession(
                gameID: .quickEyes, score: score,
                rounds: Self.totalRounds, durationSeconds: elapsed,
                correct: run.correct, attempts: Self.totalRounds,
                difficulty: run.difficulty))
        // Completion, never a hit count: a first-try tally can be small (#394).
        finalDetail = String(format: AppLanguage.localized("game.celebration.rounds %lld"), Self.totalRounds)
        showCelebration = true
    }
}

#Preview {
    QuickEyesView()
}
