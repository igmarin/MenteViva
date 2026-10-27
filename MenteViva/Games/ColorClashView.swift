import SwiftData
import SwiftUI

/// Color Clash: Stroop — the word names a color, the ink may be another.
/// Tap the INK color. 10 gentle rounds, no timer.
struct ColorClashView: View {
    @Environment(\.modelContext) private var modelContext

    enum Ink: String, CaseIterable {
        case red, blue, green, orange, purple, yellow

        var color: Color {
            switch self {
            case .red: .red
            case .blue: .blue
            case .green: .green
            case .orange: .orange
            case .purple: .purple
            case .yellow: Color(red: 0.7, green: 0.6, blue: 0.0)
            }
        }

        var word: String {
            switch self {
            case .red: AppLanguage.localized("game.colorclash.word.red")
            case .blue: AppLanguage.localized("game.colorclash.word.blue")
            case .green: AppLanguage.localized("game.colorclash.word.green")
            case .orange: AppLanguage.localized("game.colorclash.word.orange")
            case .purple: AppLanguage.localized("game.colorclash.word.purple")
            case .yellow: AppLanguage.localized("game.colorclash.word.yellow")
            }
        }

        var label: String {
            switch self {
            case .red: AppLanguage.localized("game.colorclash.color.red")
            case .blue: AppLanguage.localized("game.colorclash.color.blue")
            case .green: AppLanguage.localized("game.colorclash.color.green")
            case .orange: AppLanguage.localized("game.colorclash.color.orange")
            case .purple: AppLanguage.localized("game.colorclash.color.purple")
            case .yellow: AppLanguage.localized("game.colorclash.color.yellow")
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
            case .purple: "hexagon.fill"
            case .yellow: "star.fill"
            }
        }

        var shapeName: String {
            switch self {
            case .red: AppLanguage.localized("game.colorclash.shape.circle")
            case .blue: AppLanguage.localized("game.colorclash.shape.triangle")
            case .green: AppLanguage.localized("game.colorclash.shape.square")
            case .orange: AppLanguage.localized("game.colorclash.shape.diamond")
            case .purple: AppLanguage.localized("game.colorclash.shape.hexagon")
            case .yellow: AppLanguage.localized("game.colorclash.shape.star")
            }
        }
    }

    private static let totalRounds = 10

    /// Matching chance per level: high at 1, 0 from 6 onward. Levels 2/4/6
    /// are 0.7/0.25/0 to match old easy/medium/hard.
    static let matchingChanceByLevel: [Double] = [0.85, 0.7, 0.45, 0.25, 0.1, 0, 0, 0, 0, 0]

    /// Chance the word already matches its ink.
    static func matchingChance(for difficulty: Difficulty) -> Double {
        difficulty.values(matchingChanceByLevel)
    }

    /// Available inks per level. More distinct colour+shape choices increase
    /// Stroop interference without shrinking targets or using colour alone,
    /// and reuses the existing shape cue infrastructure.
    static func availableInks(for difficulty: Difficulty) -> [Ink] {
        // Levels 1-8 show 4 options, 9-10 show 6 so difficulty rises via larger choice set.
        let count = difficulty.values([4, 4, 4, 4, 4, 4, 4, 4, 6, 6])
        return Array(Ink.allCases.prefix(count))
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
    /// The answer beat (#235): set by a tap, cleared when the next word is dealt.
    @State private var beat: AnswerBeat<Ink>?
    @State private var beatTask: Task<Void, Never>?

    private var stimulusLabel: String {
        String(format: AppLanguage.localized("game.colorclash.a11y.stimulus %@ %@"), ink.label, ink.shapeName)
    }

    /// The guide's example move in words (#243): the ink of the word on screen, the tile to tap.
    private var guideExample: String {
        String(format: AppLanguage.localized("guide.colorclash.example %@"), ink.label.lowercased())
    }

    static func score(correct: Int) -> Int {
        correct * 10
    }

    var body: some View {
        VStack(spacing: 32) {
            LevelExplainBanner(
                change: PlanStore.cachedPlan()?.changes[GameID.stroop], game: GameID.stroop,
                hasStarted: progress.completedRounds > 0)
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
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(stimulusLabel)
            .accessibilityHint(AppLanguage.localized("game.colorclash.a11y.stimulus.hint"))

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(Self.availableInks(for: difficulty), id: \.self) { candidate in
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
                    .answerMark(beat?.mark(for: candidate) ?? .plain)
                    .guideTarget(candidate == ink)
                    .accessibilityLabel(candidate.label)
                    .accessibilityHint(candidate.shapeName)
                }
            }

            RoundCounter(progress: progress)
        }
        .padding()
        .fitOrScroll()
        .gameHeader(.stroop, instruction: AppLanguage.localized("game.colorclash.instruction"))
        .firstPlayGuide(.stroop, line: AppLanguage.localized("game.colorclash.instruction"), example: guideExample)
        .onAppear {
            startedAt = .now
            deal()
        }
        .onDisappear {
            // A beat cut short must not leave taps locked if this state comes back.
            beatTask?.cancel()
            beat = nil
        }
        .celebration(isPresented: $showCelebration, game: .stroop, detail: finalDetail, onPlayAgain: restart)
    }

    private func restart() {
        beatTask?.cancel()
        beat = nil
        progress.reset()
        correct = 0
        startedAt = .now
        deal()
    }

    private func deal() {
        let pool = Self.availableInks(for: difficulty)
        ink = pool.randomElement() ?? .blue
        let matches = Double.random(in: 0..<1) < Self.matchingChance(for: difficulty)
        word = matches ? ink : (pool.filter { $0 != ink }.randomElement() ?? .red)
        AccessibilityNotification.Announcement(stimulusLabel).post()
    }

    /// Shows the answer for a beat (#235), ignoring taps meanwhile, then deals the next word.
    private func tap(_ candidate: Ink) {
        guard beat == nil, !progress.isFinished else { return }
        let answer = AnswerBeat(tapped: candidate, right: ink)
        beat = answer
        if answer.isRight {
            correct += 1
            Feedback.play(.success)
            AccessibilityNotification.Announcement(AppLanguage.localized("game.answer.right")).post()
        } else {
            Feedback.play(.miss)
            AccessibilityNotification.Announcement(
                String(format: AppLanguage.localized("game.answer.was %@"), ink.label)
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
