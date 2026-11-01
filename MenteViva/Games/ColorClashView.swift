import SwiftData
import SwiftUI

/// Color Clash: Stroop — the word names a color, the ink may be another.
/// Tap the INK color. 10 gentle rounds, no timer.
struct ColorClashView: View {
    @Environment(\.modelContext) private var modelContext

    private static let totalRounds = 10

    // The word and its shape follow the device text size (#117).
    @ScaledMetric(relativeTo: .largeTitle) private var wordSize: CGFloat = 64
    @Environment(\.horizontalSizeClass) private var sizeClass
    @ScaledMetric(relativeTo: .largeTitle) private var shapeSize: CGFloat = 40

    @State private var difficulty = Difficulty.stored(.stroop)
    @State private var word: Ink = .red
    @State private var ink: Ink = .blue
    @State private var progress = RoundProgress(totalRounds: Self.totalRounds)
    @State private var correct = 0
    /// True once a word is dealt: `.onAppear` runs again when the celebration closes (#415).
    @State private var hasDealt = false
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

    var body: some View {
        VStack(spacing: 32) {
            LevelExplainBanner(
                game: GameID.stroop, hasStarted: progress.completedRounds > 0)
            Text(AppLanguage.localized("game.colorclash.instruction"))
                .font(.title2)
                .multilineTextAlignment(.center)

            // Word is a decoy. VoiceOver hears the INK colour and its shape;
            // the shape is also drawn so colour-blind players can match it (#64).
            HStack(spacing: 16) {
                Text(word.word)
                    .font(
                        .system(
                            size: wordSize * GameColumn.textScale(isRegularWidth: GameColumn.usesPadLayout(sizeClass)),
                            weight: .bold)
                    )
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .foregroundStyle(ink.color)
                Image(systemName: ink.shape)
                    .font(.system(size: shapeSize, weight: .bold))
                    .foregroundStyle(ink.color)
            }
            // The ink is the answer, so it sits on the system background it was
            // checked against, not on cream (#336).
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .background(Color(.systemBackground), in: .rect(cornerRadius: 16))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(stimulusLabel)
            .accessibilityHint(AppLanguage.localized("game.colorclash.a11y.stimulus.hint"))

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(ColorClashDeal.availableInks(for: difficulty), id: \.self) { candidate in
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
        .gameColumn()
        .padding()
        .fitOrScroll()
        .gameHeader(
            .stroop, instruction: AppLanguage.localized("game.colorclash.instruction"),
            inProgress: progress.completedRounds > 0
        )
        .firstPlayGuide(.stroop, line: AppLanguage.localized("game.colorclash.instruction"), example: guideExample)
        .onAppear {
            // Fires again when the celebration closes; Play again has already dealt, so deal only once.
            guard !hasDealt else { return }
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
        difficulty = Difficulty.stored(.stroop)
        beatTask?.cancel()
        beat = nil
        progress.reset()
        correct = 0
        startedAt = .now
        deal()
    }

    private func deal() {
        var generator = SystemRandomNumberGenerator()
        let stimulus = ColorClashDeal.make(difficulty: difficulty, using: &generator)
        ink = stimulus.ink
        word = stimulus.word
        hasDealt = true
        AccessibilityNotification.Announcement(stimulusLabel).post()
    }

    /// Shows the answer for a beat (#235), ignoring taps meanwhile, then deals the next word.
    private func tap(_ candidate: Ink) {
        guard beat == nil, !progress.isFinished else { return }
        let answer = AnswerBeat(tapped: candidate, right: ink)
        beat = answer
        if answer.isRight {
            correct += 1
        }
        answer.play(rightName: ink.label)
        beatTask = answer.after {
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
        // Completion, never a hit count: Color Clash is error-inducing by
        // design (Stroop), so the warm message celebrates finishing (#45).
        modelContext.record(
            GameSession(
                gameID: .stroop,
                rounds: Self.totalRounds, durationSeconds: elapsed,
                correct: correct, attempts: Self.totalRounds,
                difficulty: difficulty))
        finalDetail = String(format: AppLanguage.localized("game.celebration.rounds %lld"), Self.totalRounds)
        showCelebration = true
    }
}

/// The bits of `Ink` that are UI: the words it shows, the names VoiceOver
/// reads, and the colour it paints with. `Ink` itself is pure logic
/// (`ColorClashDeal.swift`), so it carries keys and the view turns them into
/// text — the same shape as `PlayingCard.nameKey`.
extension Ink {
    /// The word this ink can show.
    var word: String { AppLanguage.localized(wordKey) }

    /// The colour's name: VoiceOver reads it, and it names the right answer.
    var label: String { AppLanguage.localized(labelKey) }

    /// The shape's name, read after the colour by VoiceOver.
    var shapeName: String { AppLanguage.localized(shapeNameKey) }

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
}

#Preview {
    ColorClashView()
}
