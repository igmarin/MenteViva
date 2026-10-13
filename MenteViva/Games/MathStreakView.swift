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
    @State private var missed = false

    static func score(correct: Int, bestStreak: Int) -> Int {
        correct * 10 + bestStreak * 2
    }

    var body: some View {
        VStack(spacing: 32) {
            Text(AppLanguage.localized("game.math.instruction"))
                .font(.title2)
                .multilineTextAlignment(.center)

            Text(verbatim: question.text)
                .font(.system(size: sumSize, weight: .bold))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .accessibilityLabel(question.spoken())
                .modifier(MissCue(active: $missed))

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
                    .accessibilityLabel("\(option)")
                }
            }

            RoundCounter(progress: progress)
        }
        .padding()
        .fitOrScroll()
        .gameHeader(.mathStreaks, instruction: AppLanguage.localized("game.math.instruction") + " " + question.spoken())
        .onAppear(perform: deal)
        .celebration(isPresented: $showCelebration, game: .mathStreaks, detail: finalDetail, onPlayAgain: restart)
    }

    private func restart() {
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
    }

    private func tap(_ option: Int) {
        guard !progress.isFinished else { return }
        if option == question.answer {
            streak += 1
            bestStreak = max(bestStreak, streak)
            correct += 1
            Feedback.play(.success)
        } else {
            streak = 0
            Feedback.play(.miss)
            missed = true
        }
        if progress.completeRound() {
            finish()
        } else {
            deal()
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
        // A streak of 2+ is worth naming; below that, celebrate finishing (#45).
        finalDetail =
            bestStreak >= 2
            ? String(format: AppLanguage.localized("game.celebration.streak %lld"), bestStreak)
            : String(format: AppLanguage.localized("game.celebration.questions %lld"), totalQuestions)
        showCelebration = true
    }
}

#Preview {
    MathStreakView()
}
