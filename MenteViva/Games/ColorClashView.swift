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
            case .red: String(localized: "game.colorclash.word.red")
            case .blue: String(localized: "game.colorclash.word.blue")
            case .green: String(localized: "game.colorclash.word.green")
            case .orange: String(localized: "game.colorclash.word.orange")
            }
        }

        var label: String {
            switch self {
            case .red: String(localized: "game.colorclash.color.red")
            case .blue: String(localized: "game.colorclash.color.blue")
            case .green: String(localized: "game.colorclash.color.green")
            case .orange: String(localized: "game.colorclash.color.orange")
            }
        }
    }

    private let totalRounds = 10

    @State private var word: Ink = .red
    @State private var ink: Ink = .blue
    @State private var round = 0
    @State private var correct = 0
    @State private var startedAt = Date.now
    @State private var showCelebration = false
    @State private var finalScore = 0

    var body: some View {
        VStack(spacing: 32) {
            Text(String(localized: "game.colorclash.instruction"))
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
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(candidate.label)
                }
            }

            Text("\(round + 1) / \(totalRounds)")
                .font(.title3)
                .foregroundStyle(.secondary)
        }
        .padding()
        .navigationTitle(String(localized: "game.colorclash.title"))
        .onAppear(perform: deal)
        .fullScreenCover(isPresented: $showCelebration) {
            CelebrationView(score: finalScore,
                            onPlayAgain: { showCelebration = false; restart() },
                            onHome: { showCelebration = false; dismiss() })
        }
    }

    private func restart() {
        round = 0
        correct = 0
        deal()
    }

    private func deal() {
        word = Ink.allCases.randomElement()!
        ink = Ink.allCases.randomElement()!
        startedAt = .now
    }

    private func tap(_ candidate: Ink) {
        if candidate == ink { correct += 1 }
        round += 1
        if round == totalRounds {
            finish()
        } else {
            deal()
        }
    }

    private func finish() {
        let elapsed = Int(Date.now.timeIntervalSince(startedAt))
        let score = correct * 10
        modelContext.insert(GameSession(gameID: "stroop", score: score,
                                        rounds: totalRounds, durationSeconds: elapsed))
        finalScore = score
        showCelebration = true
    }
}

#Preview {
    ColorClashView()
}
