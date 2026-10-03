import SwiftData
import SwiftUI

/// Color Clash: Stroop — the word names a color, the ink may be another.
/// Tap the INK color. 10 gentle rounds, no timer.
struct ColorClashView: View {
    @Environment(\.modelContext) private var modelContext

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
            case .red: AppLanguage.localized("game.colorclash.word.red")
            case .blue: AppLanguage.localized("game.colorclash.word.blue")
            case .green: AppLanguage.localized("game.colorclash.word.green")
            case .orange: AppLanguage.localized("game.colorclash.word.orange")
            }
        }

        var label: String {
            switch self {
            case .red: AppLanguage.localized("game.colorclash.color.red")
            case .blue: AppLanguage.localized("game.colorclash.color.blue")
            case .green: AppLanguage.localized("game.colorclash.color.green")
            case .orange: AppLanguage.localized("game.colorclash.color.orange")
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
            case .red: AppLanguage.localized("game.colorclash.shape.circle")
            case .blue: AppLanguage.localized("game.colorclash.shape.triangle")
            case .green: AppLanguage.localized("game.colorclash.shape.square")
            case .orange: AppLanguage.localized("game.colorclash.shape.diamond")
            }
        }
    }

    private static let totalRounds = 10

    /// Chance the word already matches its ink: easy is mostly matching, hard never.
    static func matchingChance(for difficulty: Difficulty) -> Double {
        difficulty.pick(0.7, 0.25, 0)
    }

    // The word and its shape follow the device text size (#117).
    @ScaledMetric(relativeTo: .largeTitle) private var wordSize: CGFloat = 64
    @ScaledMetric(relativeTo: .largeTitle) private var shapeSize: CGFloat = 40

    @State private var difficulty = Difficulty.stored(.stroop)
    @State private var word: Ink = .red
    @State private var ink: Ink = .blue
    @State private var progress = RoundProgress(totalRounds: Self.totalRounds)
    @State private var correct = 0
    @State private var startedAt = Date.now
    @State private var showCelebration = false
    @State private var finalDetail = ""
    @State private var missed = false

    private var stimulusLabel: String {
        String(format: AppLanguage.localized("game.colorclash.a11y.stimulus %@ %@"), ink.label, ink.shapeName)
    }

    static func score(correct: Int) -> Int {
        correct * 10
    }

    var body: some View {
        VStack(spacing: 32) {
            Text(AppLanguage.localized("game.colorclash.instruction"))
                .font(.title2)
                .multilineTextAlignment(.center)

            // Word is a decoy. VoiceOver hears the INK colour and its shape;
            // the shape is also drawn so colour-blind players can match it (#64).
            HStack(spacing: 16) {
                Text(word.word)
                    .font(.system(size: wordSize, weight: .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .foregroundStyle(ink.color)
                Image(systemName: ink.shape)
                    .font(.system(size: shapeSize, weight: .bold))
                    .foregroundStyle(ink.color)
            }
            .modifier(MissCue(active: $missed))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(stimulusLabel)
            .accessibilityHint(AppLanguage.localized("game.colorclash.a11y.stimulus.hint"))

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(Ink.allCases, id: \.self) { candidate in
                    Button {
                        tap(candidate)
                    } label: {
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

            RoundCounter(progress: progress)
        }
        .padding()
        .fitOrScroll()
        .navigationTitle(AppLanguage.localized("game.colorclash.title"))
        .onAppear {
            startedAt = .now
            deal()
        }
        .celebration(isPresented: $showCelebration, detail: finalDetail, onPlayAgain: restart)
    }

    private func restart() {
        progress.reset()
        correct = 0
        startedAt = .now
        deal()
    }

    private func deal() {
        ink = Ink.allCases.randomElement() ?? .blue
        let matches = Double.random(in: 0..<1) < Self.matchingChance(for: difficulty)
        word = matches ? ink : (Ink.allCases.filter { $0 != ink }.randomElement() ?? .red)
        AccessibilityNotification.Announcement(stimulusLabel).post()
    }

    private func tap(_ candidate: Ink) {
        guard !progress.isFinished else { return }
        if candidate == ink {
            correct += 1
            Feedback.play(.success)
        } else {
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
        let score = Self.score(correct: correct)
        // Completion, never a hit count: Color Clash is error-inducing by
        // design (Stroop), so the warm message celebrates finishing (#45).
        modelContext.record(
            GameSession(
                gameID: .stroop, score: score,
                rounds: Self.totalRounds, durationSeconds: elapsed,
                correct: correct, attempts: Self.totalRounds,
                difficulty: difficulty))
        finalDetail = String(format: AppLanguage.localized("game.celebration.rounds %lld"), Self.totalRounds)
        showCelebration = true
    }
}

#Preview {
    ColorClashView()
}
