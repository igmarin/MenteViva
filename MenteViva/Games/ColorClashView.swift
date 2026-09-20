import SwiftUI
import SwiftData

/// Color Clash: Stroop — the word names a color, the ink may be another.
/// Tap the INK color. 10 gentle rounds, no timer.
struct ColorClashView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    private enum Ink: String, CaseIterable {
        case red, blue, green, orange

        var color: Color {
            switch self {
            case .red: .red
            case .blue: .blue
            case .green: .green
            case .orange: .orange
            }
        }

        var word: String {
            switch self {
            case .red: AppLanguage.localized( "game.colorclash.word.red")
            case .blue: AppLanguage.localized( "game.colorclash.word.blue")
            case .green: AppLanguage.localized( "game.colorclash.word.green")
            case .orange: AppLanguage.localized( "game.colorclash.word.orange")
            }
        }

        var label: String {
            switch self {
            case .red: AppLanguage.localized( "game.colorclash.color.red")
            case .blue: AppLanguage.localized( "game.colorclash.color.blue")
            case .green: AppLanguage.localized( "game.colorclash.color.green")
            case .orange: AppLanguage.localized( "game.colorclash.color.orange")
            }
        }

        /// Non-color cue: each ink has a distinct shape so color alone never
        /// carries the answer (WCAG 1.4.1, conventions.md §4).
        var shape: String {
            switch self {
            case .red: "circle.fill"
            case .blue: "triangle.fill"
            case .green: "square.fill"
            case .orange: "diamond.fill"
            }
        }

        var shapeName: String {
            switch self {
            case .red: AppLanguage.localized( "game.colorclash.shape.circle")
            case .blue: AppLanguage.localized( "game.colorclash.shape.triangle")
            case .green: AppLanguage.localized( "game.colorclash.shape.square")
            case .orange: AppLanguage.localized( "game.colorclash.shape.diamond")
            }
        }
    }

    private static let totalRounds = 10

    @State private var word: Ink = .red
    @State private var ink: Ink = .blue
    @State private var progress = RoundProgress(totalRounds: Self.totalRounds)
    @State private var correct = 0
    @State private var startedAt = Date.now
    @State private var showCelebration = false
    @State private var finalScore = 0

    static func score(correct: Int) -> Int {
        correct * 10
    }

    var body: some View {
        VStack(spacing: 32) {
            Text(AppLanguage.localized( "game.colorclash.instruction"))
                .font(.title2)
                .multilineTextAlignment(.center)

            Text(word.word)
                .font(.system(size: 64, weight: .bold))
                .foregroundStyle(ink.color)
                .accessibilityHidden(true) // word is a decoy; don't read it

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(Ink.allCases, id: \.self) { candidate in
                    Button { tap(candidate) } label: {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(candidate.color)
                            .frame(maxWidth: .infinity, minHeight: 110)
                            .overlay {
                                Image(systemName: candidate.shape)
                                    .font(.system(size: 40, weight: .bold))
                                    .foregroundStyle(.white)
                                    .shadow(color: .black.opacity(0.35), radius: 2, y: 1)
                                    .accessibilityHidden(true)
                            }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(candidate.label)
                    .accessibilityHint(candidate.shapeName)
                }
            }

            Text("\(progress.displayRound) / \(Self.totalRounds)")
                .font(.title3)
                .foregroundStyle(.secondary)
        }
        .padding()
        .navigationTitle(AppLanguage.localized( "game.colorclash.title"))
        .onAppear(perform: deal)
        .fullScreenCover(isPresented: $showCelebration) {
            CelebrationView(score: finalScore,
                            onPlayAgain: { showCelebration = false; restart() },
                            onHome: { showCelebration = false; dismiss() })
        }
    }

    private func restart() {
        progress.reset()
        correct = 0
        deal()
    }

    private func deal() {
        word = Ink.allCases.randomElement() ?? .red
        ink = Ink.allCases.randomElement() ?? .blue
        startedAt = .now
    }

    private func tap(_ candidate: Ink) {
        if candidate == ink {
            correct += 1
            Feedback.play(.success)
        } else {
            Feedback.play(.miss)
        }
        if progress.completeRound() {
            finish()
        } else {
            deal()
        }
    }

    private func finish() {
        let elapsed = Int(Date.now.timeIntervalSince(startedAt))
        let score = Self.score(correct: correct)
        modelContext.insert(GameSession(gameID: .stroop, score: score,
                                        rounds: Self.totalRounds, durationSeconds: elapsed))
        finalScore = score
        showCelebration = true
    }
}

#Preview {
    ColorClashView()
}
