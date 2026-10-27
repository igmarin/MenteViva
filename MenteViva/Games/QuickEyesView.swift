import SwiftData
import SwiftUI

/// Quick Eyes: processing-speed game. A picture flashes on screen for a
/// shrinking display time, then the player taps the matching picture among
/// four big buttons. Generic visual-discrimination task — deliberately NOT
/// a UFOV®/BrainHQ clone (licensed, see docs/research-2026-09.md §3).
/// No visible countdown timer; the shrinking display time is the challenge.
struct QuickEyesView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dynamicTypeSize) private var typeSize

    private let emojis = ["🌻", "🐢", "🍎", "🎸", "🌙", "☕️", "🦋", "🍊", "🚗", "⭐", "🐝", "🌵"]
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
    private var startDisplayTime: Double { Self.displayTimes(for: difficulty).start }
    private var minDisplayTime: Double { Self.displayTimes(for: difficulty).floor }
    private static let voiceOverHold = 2.5
    private let shrinkFactor = 0.92
    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    enum Phase {
        case showing, choosing
    }

    @State private var difficulty = Difficulty.stored(.quickEyes)
    @State private var phase: Phase = .showing
    @State private var progress = RoundProgress(totalRounds: Self.totalRounds)
    @State private var target = "🌻"
    @State private var options: [String] = []
    @State private var displayTime = QuickEyesView.displayTimes(for: Difficulty.stored(.quickEyes)).start
    @State private var correct = 0
    @State private var speedBonus = 0
    @State private var missedLastRound = false
    @State private var optionsShownAt = Date.now
    @State private var startedAt = Date.now
    @State private var revealTask: Task<Void, Never>?
    /// The answer beat (#235): set by a tap, cleared when the next picture flashes.
    @State private var beat: AnswerBeat<String>?
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
            if phase == .showing || !typeSize.isAccessibilitySize {
                Text(AppLanguage.localized("game.quickeyes.instruction"))
                    .font(.title2)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            switch phase {
            case .showing:
                Text(target)
                    .font(.system(size: 120))
                    .accessibilityLabel(String(format: AppLanguage.localized("game.quickeyes.a11y.flash %@"), target))
            case .choosing:
                VStack(spacing: 16) {
                    if missedLastRound {
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
                        ForEach(options, id: \.self) { emoji in
                            Button {
                                choose(emoji)
                            } label: {
                                Text(emoji)
                                    .font(.system(size: 56))
                            }
                            .buttonStyle(AnswerTileStyle())
                            .answerMark(beat?.mark(for: emoji) ?? .plain)
                            .accessibilityLabel(emoji)
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
            instruction: AppLanguage.localized(phase == .showing ? "game.quickeyes.instruction" : "game.quickeyes.prompt")
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
        displayTime = startDisplayTime
        missedLastRound = false
        startedAt = .now
        startRound()
    }

    private func startRound() {
        revealTask?.cancel()
        target = emojis.randomElement() ?? "🌻"
        let distractors = emojis.filter { $0 != target }.shuffled().prefix(3)
        options = (distractors + [target]).shuffled()
        phase = .showing
        // VoiceOver needs time to speak the picture; hold it longer (#64).
        let hold = UIAccessibility.isVoiceOverRunning ? max(displayTime, Self.voiceOverHold) : displayTime
        AccessibilityNotification.Announcement(
            String(format: AppLanguage.localized("game.quickeyes.a11y.flash %@"), target)
        ).post()
        revealTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(hold))
            guard !Task.isCancelled, phase == .showing else { return }
            optionsShownAt = .now
            phase = .choosing
        }
    }

    /// Shows the answer for a beat (#235), ignoring taps meanwhile, then flashes the next picture.
    private func choose(_ emoji: String) {
        guard phase == .choosing, beat == nil, !progress.isFinished else { return }
        let answer = AnswerBeat(tapped: emoji, right: target)
        beat = answer
        if answer.isRight {
            correct += 1
            missedLastRound = false
            Feedback.play(.success)
            AccessibilityNotification.Announcement(AppLanguage.localized("game.answer.right")).post()
            // Speed bonus: up to 5 points, one less per half-second of reaction time.
            let reaction = Date.now.timeIntervalSince(optionsShownAt)
            speedBonus += max(0, 5 - Int(reaction / 0.5))
            displayTime = max(minDisplayTime, displayTime * shrinkFactor)
        } else {
            missedLastRound = true
            Feedback.play(.miss)
            AccessibilityNotification.Announcement(
                String(format: AppLanguage.localized("game.answer.was %@"), target)
            ).post()
            // Relax one step after a miss so the next round feels kinder.
            displayTime = min(startDisplayTime, displayTime / shrinkFactor)
        }
        // The beat shares revealTask, so leaving the game or restarting cancels it too.
        revealTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(answer.duration(voiceOver: UIAccessibility.isVoiceOverRunning)))
            guard !Task.isCancelled else { return }
            beat = nil
            if progress.completeRound() {
                finish()
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
        finalDetail = String(
            format: AppLanguage.localized("game.celebration.spotted %lld %lld"),
            correct, Self.totalRounds)
        showCelebration = true
    }
}

#Preview {
    QuickEyesView()
}
