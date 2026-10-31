import SwiftData
import SwiftUI

/// Number Trail: one gentle sum at a time. Numbers start small and grow with the
/// streak; the operators step up with difficulty (#143, `NumberTrailQuestion`).
/// 4 big answer buttons, 10 questions, no timer.
struct MathStreakView: View {
    @Environment(\.modelContext) private var modelContext

    private static let totalQuestions = 10
    private var totalQuestions: Int { Self.totalQuestions }

    // Numbers follow the device text size (#117); emoji elsewhere stay fixed.
    @ScaledMetric(relativeTo: .largeTitle) private var sumSize: CGFloat = 72
    @Environment(\.horizontalSizeClass) private var sizeClass
    @ScaledMetric(relativeTo: .title) private var answerSize: CGFloat = 44

    @State private var difficulty = Difficulty.stored(.mathStreaks)
    @State private var question = NumberTrailQuestion(left: 0, operation: .plus, right: 0, answer: 0)
    @State private var options: [Int] = []
    @State private var progress = RoundProgress(totalRounds: MathStreakView.totalQuestions)
    @State private var streak = 0
    @State private var bestStreak = 0
    @State private var correct = 0
    @State private var startedAt = Date.now
    @State private var showCelebration = false
    @State private var finalDetail = ""
    /// The answer beat (#235): set by a tap, cleared when the next sum is dealt.
    @State private var beat: AnswerBeat<Int>?
    @State private var beatTask: Task<Void, Never>?

    static func score(correct: Int, bestStreak: Int) -> Int {
        correct * 10 + bestStreak * 2
    }

    var body: some View {
        VStack(spacing: 32) {
            LevelExplainBanner(
                change: PlanStore.cachedPlan()?.changes[GameID.mathStreaks], game: GameID.mathStreaks,
                hasStarted: progress.completedRounds > 0)
            Text(AppLanguage.localized("game.math.instruction"))
                .font(.title2)
                .multilineTextAlignment(.center)

            Text(verbatim: question.text)
                .font(
                    .system(
                        size: sumSize * GameColumn.textScale(isRegularWidth: GameColumn.usesPadLayout(sizeClass)), weight: .bold)
                )
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .accessibilityLabel(question.spoken())

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(options, id: \.self) { option in
                    Button {
                        tap(option)
                    } label: {
                        Text(verbatim: "\(option)")
                            .font(.system(size: answerSize, weight: .semibold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                    }
                    .buttonStyle(AnswerTileStyle())
                    .answerMark(beat?.mark(for: option) ?? .plain)
                    .accessibilityLabel("\(option)")
                }
            }

            RoundCounter(progress: progress)
        }
        .gameColumn()
        .padding()
        .fitOrScroll()
        .gameHeader(.mathStreaks, instruction: AppLanguage.localized("game.math.instruction") + " " + question.spoken())
        .onAppear(perform: deal)
        .onDisappear {
            // A beat cut short must not leave taps locked if this state comes back.
            beatTask?.cancel()
            beat = nil
        }
        .celebration(isPresented: $showCelebration, game: .mathStreaks, detail: finalDetail, onPlayAgain: restart)
    }

    private func restart() {
        difficulty = Difficulty.stored(.mathStreaks)
        beatTask?.cancel()
        beat = nil
        progress.reset()
        streak = 0
        bestStreak = 0
        correct = 0
        startedAt = .now
        deal()
    }

    private func deal() {
        var generator = SystemRandomNumberGenerator()
        question = NumberTrailQuestion.make(difficulty: difficulty, streak: streak, using: &generator)
        options = NumberTrailQuestion.options(for: question.answer, using: &generator)
        // The first deal is read with the screen; later ones replace the answers and move focus (#391).
        if progress.completedRounds > 0 {
            AccessibilityNotification.Announcement(question.spoken()).post()
        }
    }

    /// Shows the answer for a beat (#235), ignoring taps meanwhile, then deals the next sum.
    private func tap(_ option: Int) {
        guard beat == nil, !progress.isFinished else { return }
        let answer = AnswerBeat(tapped: option, right: question.answer)
        beat = answer
        if answer.isRight {
            streak += 1
            bestStreak = max(bestStreak, streak)
            correct += 1
            Feedback.play(.success)
            AccessibilityNotification.Announcement(AppLanguage.localized("game.answer.right")).post()
        } else {
            streak = 0
            Feedback.play(.miss)
            AccessibilityNotification.Announcement(
                String(format: AppLanguage.localized("game.answer.was %@"), "\(question.answer)")
            ).post()
        }
        beatTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(answer.duration(voiceOver: UIAccessibility.isVoiceOverRunning)))
            guard !Task.isCancelled else { return }
            beat = nil
            if progress.completeRound() {
                finish()
            } else {
                deal()
            }
        }
    }

    private func finish() {
        let elapsed = Int(Date.now.timeIntervalSince(startedAt))
        let score = Self.score(correct: correct, bestStreak: bestStreak)
        modelContext.record(
            GameSession(
                gameID: .mathStreaks, score: score,
                rounds: totalQuestions, durationSeconds: elapsed,
                correct: correct, attempts: totalQuestions,
                difficulty: difficulty))
        // Completion, never a streak or a hit count (#45, #394).
        finalDetail = String(format: AppLanguage.localized("game.celebration.questions %lld"), totalQuestions)
        showCelebration = true
    }
}

#Preview {
    MathStreakView()
}
