import SwiftUI
import SwiftData

/// Number Trail: one gentle addition at a time. Sums start at ≤10 and grow
/// with the streak. 4 big answer buttons, 10 questions, no timer.
struct MathStreakView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    private let totalQuestions = 10

    @State private var a = 0
    @State private var b = 0
    @State private var options: [Int] = []
    @State private var question = 0
    @State private var streak = 0
    @State private var bestStreak = 0
    @State private var correct = 0
    @State private var startedAt = Date.now
    @State private var showCelebration = false
    @State private var finalScore = 0

    private var answer: Int { a + b }

    var body: some View {
        VStack(spacing: 32) {
            Text(String(localized: "game.math.instruction"))
                .font(.title2)
                .multilineTextAlignment(.center)

            Text("\(a) + \(b)")
                .font(.system(size: 72, weight: .bold))
                .accessibilityLabel("\(a) + \(b)")

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(options, id: \.self) { option in
                    Button { tap(option) } label: {
                        Text("\(option)")
                            .font(.system(size: 44, weight: .semibold))
                            .frame(maxWidth: .infinity, minHeight: 110)
                            .background(.blue.opacity(0.15), in: .rect(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(option)")
                }
            }

            Text("\(question + 1) / \(totalQuestions)")
                .font(.title3)
                .foregroundStyle(.secondary)
        }
        .padding()
        .navigationTitle(String(localized: "game.math.title"))
        .onAppear(perform: deal)
        .fullScreenCover(isPresented: $showCelebration) {
            CelebrationView(score: finalScore,
                            onPlayAgain: { showCelebration = false; restart() },
                            onHome: { showCelebration = false; dismiss() })
        }
    }

    private func restart() {
        question = 0
        streak = 0
        bestStreak = 0
        correct = 0
        startedAt = .now
        deal()
    }

    private func deal() {
        let maxSum = min(10 + streak * 5, 50) // grow gently with the streak
        a = Int.random(in: 1...(maxSum - 1))
        b = Int.random(in: 1...(maxSum - a))
        var pool = Set([answer])
        while pool.count < 4 {
            let offset = Int.random(in: 1...3) * (Bool.random() ? 1 : -1)
            let candidate = answer + offset
            if candidate > 0 { pool.insert(candidate) }
        }
        options = pool.shuffled()
    }

    private func tap(_ option: Int) {
        if option == answer {
            streak += 1
            bestStreak = max(bestStreak, streak)
            correct += 1
        } else {
            streak = 0
        }
        question += 1
        if question == totalQuestions {
            finish()
        } else {
            deal()
        }
    }

    private func finish() {
        let elapsed = Int(Date.now.timeIntervalSince(startedAt))
        let score = correct * 10 + bestStreak * 2
        modelContext.insert(GameSession(gameID: "math_streaks", score: score,
                                        rounds: totalQuestions, durationSeconds: elapsed))
        finalScore = score
        showCelebration = true
    }
}

#Preview {
    MathStreakView()
}
