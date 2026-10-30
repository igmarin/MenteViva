import SwiftData
import SwiftUI

/// Finish the Saying (#181): the start of a familiar saying, and he picks the ending
/// from big buttons. A near miss dims that button and he keeps choosing; once right,
/// the whole saying shows and the speaker button reads it aloud. 8 sayings, no timer.
struct SayingsView: View {
    @Environment(\.modelContext) private var modelContext

    @ScaledMetric(relativeTo: .largeTitle) private var sayingSize: CGFloat = 34

    @State private var difficulty = Difficulty.stored(.sayings)
    @State private var rounds: [SayingRound] = []
    @State private var progress = RoundProgress(totalRounds: SayingsDeck.roundsPerGame)
    @State private var dimmed: Set<Saying> = []
    @State private var solved = false
    @State private var correct = 0
    @State private var taps = 0
    @State private var startedAt = Date.now
    @State private var missed = false
    @State private var missedChoice: Saying?
    @State private var showAlmost = false
    @State private var showCelebration = false
    @State private var finalDetail = ""

    private var round: SayingRound? {
        rounds.indices.contains(progress.completedRounds) ? rounds[progress.completedRounds] : nil
    }

    var body: some View {
        VStack(spacing: 24) {
            LevelExplainBanner(
                change: PlanStore.cachedPlan()?.changes[GameID.sayings], game: GameID.sayings,
                hasStarted: taps > 0 || progress.completedRounds > 0)
            Text(AppLanguage.localized("game.sayings.instruction"))
                .font(.title2)
                .multilineTextAlignment(.center)

            if let round {
                Text(solved ? whole(round.saying) : AppLanguage.localized(round.saying.startKey) + "…")
                    .font(.system(size: sayingSize, weight: .semibold, design: .serif))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                if showAlmost {
                    // The same soft amber note as Quick Eyes: kind and easy to read.
                    Text(AppLanguage.localized("game.sayings.miss"))
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(Color.todaysPick)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color.amber.opacity(0.24), in: .rect(cornerRadius: 14))
                }

                if solved {
                    HStack(spacing: 12) {
                        Button {
                            CaptionSpeaker.speak(whole(round.saying))
                        } label: {
                            Image(systemName: "speaker.wave.2.fill")
                                .font(.title)
                                .frame(minWidth: 100, minHeight: 100)
                        }
                        .buttonStyle(AnswerTileStyle(minHeight: 100))
                        .fixedSize(horizontal: true, vertical: false)
                        .accessibilityLabel(AppLanguage.localized("game.sayings.a11y.listen"))

                        Button(action: next) {
                            Text(AppLanguage.localized("game.sayings.next")).font(.title2.weight(.semibold))
                        }
                        .buttonStyle(AnswerTileStyle(minHeight: 100))
                    }
                } else {
                    VStack(spacing: 12) {
                        ForEach(round.choices, id: \.self) { choice in
                            Button {
                                choose(choice, in: round)
                            } label: {
                                Text(AppLanguage.localized(choice.endKey))
                                    .font(.title2)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 12)
                            }
                            .buttonStyle(AnswerTileStyle(minHeight: 100))
                            .disabled(dimmed.contains(choice))
                            .opacity(dimmed.contains(choice) ? 0.4 : 1)
                            .modifier(MissCue(active: missedChoice == choice ? $missed : .constant(false)))
                        }
                    }
                }

                RoundCounter(progress: progress)
            }
        }
        .padding()
        .fitOrScroll()
        .gameHeader(.sayings, instruction: AppLanguage.localized("game.sayings.instruction"))
        .onAppear { if rounds.isEmpty { deal() } }
        .onDisappear { CaptionSpeaker.stop() }
        .celebration(isPresented: $showCelebration, game: .sayings, detail: finalDetail, onPlayAgain: restart)
    }

    private func whole(_ saying: Saying) -> String {
        AppLanguage.localized(saying.startKey) + " " + AppLanguage.localized(saying.endKey)
    }

    private func deal() {
        var generator = SystemRandomNumberGenerator()
        rounds = SayingsDeck.deal(difficulty: difficulty, defaults: .standard, using: &generator)
    }

    private func restart() {
        difficulty = Difficulty.stored(.sayings)
        progress.reset()
        correct = 0
        taps = 0
        startedAt = .now
        resetRound()
        deal()
    }

    private func resetRound() {
        dimmed = []
        solved = false
        showAlmost = false
        missed = false
        missedChoice = nil
    }

    private func choose(_ choice: Saying, in round: SayingRound) {
        taps += 1
        if choice == round.saying {
            if dimmed.isEmpty { correct += 1 }  // right on the first tap
            solved = true
            showAlmost = false
            Feedback.play(.success)
            if CaptionSpeaker.autoSpeaks() {
                CaptionSpeaker.speak(whole(round.saying))
            } else if UIAccessibility.isVoiceOverRunning {
                AccessibilityNotification.Announcement(whole(round.saying)).post()
            }
        } else {
            dimmed.insert(choice)
            missedChoice = choice
            missed = true
            showAlmost = true
            Feedback.play(.miss)
            AccessibilityNotification.Announcement(AppLanguage.localized("game.sayings.miss")).post()
        }
    }

    private func next() {
        CaptionSpeaker.stop()
        if let round { SayingsDeck.markSeen(round.saying, defaults: .standard) }
        resetRound()
        if progress.completeRound() { finish() }
    }

    private func finish() {
        modelContext.record(
            GameSession(
                gameID: .sayings, score: correct * 10,
                rounds: SayingsDeck.roundsPerGame, durationSeconds: Int(Date.now.timeIntervalSince(startedAt)),
                correct: correct, attempts: taps,
                difficulty: difficulty))
        finalDetail = String(
            format: AppLanguage.localized("game.celebration.sayings %lld"), SayingsDeck.roundsPerGame)
        showCelebration = true
    }
}

#Preview {
    SayingsView()
}
