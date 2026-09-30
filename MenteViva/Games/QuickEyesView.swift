import SwiftUI
import SwiftData

/// Quick Eyes: processing-speed game. A picture flashes on screen for a
/// shrinking display time, then the player taps the matching picture among
/// four big buttons. Generic visual-discrimination task — deliberately NOT
/// a UFOV®/BrainHQ clone (licensed, see docs/research-2026-09.md §3).
/// No visible countdown timer; the shrinking display time is the challenge.
struct QuickEyesView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    private let emojis = ["🌻", "🐢", "🍎", "🎸", "🌙", "☕️", "🦋", "🍊", "🚗", "⭐", "🐝", "🌵"]
    private static let totalRounds = 12
    private let startDisplayTime = 1.2
    private let minDisplayTime = 0.35
    private static let voiceOverHold = 2.5
    private let shrinkFactor = 0.92
    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    enum Phase {
        case showing, choosing
    }

    @State private var phase: Phase = .showing
    @State private var progress = RoundProgress(totalRounds: Self.totalRounds)
    @State private var target = "🌻"
    @State private var options: [String] = []
    @State private var displayTime = 1.2
    @State private var correct = 0
    @State private var speedBonus = 0
    @State private var missedLastRound = false
    @State private var optionsShownAt = Date.now
    @State private var startedAt = Date.now
    @State private var revealTask: Task<Void, Never>?
    @State private var showCelebration = false
    @State private var finalDetail = ""

    static func score(correct: Int, speedBonus: Int) -> Int {
        correct * 10 + speedBonus
    }

    var body: some View {
        VStack(spacing: 24) {
            Text(AppLanguage.localized("game.quickeyes.instruction"))
                .font(.title2)
                .multilineTextAlignment(.center)

            Spacer()

            switch phase {
            case .showing:
                Text(target)
                    .font(.system(size: 120))
                    .accessibilityLabel(String(format: AppLanguage.localized("game.quickeyes.a11y.flash %@"), target))
            case .choosing:
                VStack(spacing: 16) {
                    if missedLastRound {
                        Text(AppLanguage.localized("game.quickeyes.almost"))
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
                    Text(AppLanguage.localized("game.quickeyes.prompt"))
                        .font(.title2)
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(options, id: \.self) { emoji in
                            Button { choose(emoji) } label: {
                                Text(emoji)
                                    .font(.system(size: 56))
                                    .frame(maxWidth: .infinity, minHeight: 110)
                                    .background(.blue.opacity(0.15), in: .rect(cornerRadius: 16))
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(emoji)
                        }
                    }
                }
            }

            Spacer()
        }
        .padding()
        .navigationTitle(AppLanguage.localized("game.quickeyes.title"))
        .onAppear(perform: startRound)
        .onDisappear { revealTask?.cancel() }
        // Same celebration as every other game (#45): progress, not points.
        .fullScreenCover(isPresented: $showCelebration) {
            CelebrationView(detail: finalDetail,
                            onPlayAgain: { showCelebration = false; restart() },
                            onHome: { showCelebration = false; dismiss() })
        }
    }

    private func restart() {
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
            String(format: AppLanguage.localized("game.quickeyes.a11y.flash %@"), target)).post()
        revealTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(hold))
            guard !Task.isCancelled, phase == .showing else { return }
            optionsShownAt = .now
            phase = .choosing
        }
    }

    private func choose(_ emoji: String) {
        guard phase == .choosing, !progress.isFinished else { return }
        if emoji == target {
            correct += 1
            missedLastRound = false
            Feedback.play(.success)
            // Speed bonus: up to 5 points, one less per half-second of reaction time.
            let reaction = Date.now.timeIntervalSince(optionsShownAt)
            speedBonus += max(0, 5 - Int(reaction / 0.5))
            displayTime = max(minDisplayTime, displayTime * shrinkFactor)
        } else {
            missedLastRound = true
            Feedback.play(.miss)
            // Relax one step after a miss so the next round feels kinder.
            displayTime = min(startDisplayTime, displayTime / shrinkFactor)
        }
        if progress.completeRound() {
            finish()
        } else {
            startRound()
        }
    }

    private func finish() {
        revealTask?.cancel()
        revealTask = nil
        let elapsed = Int(Date.now.timeIntervalSince(startedAt))
        let score = Self.score(correct: correct, speedBonus: speedBonus)
        modelContext.insert(GameSession(gameID: .quickEyes, score: score,
                                        rounds: Self.totalRounds, durationSeconds: elapsed,
                                        correct: correct, attempts: Self.totalRounds))
        finalDetail = String(format: AppLanguage.localized("game.celebration.spotted %lld %lld"),
                             correct, Self.totalRounds)
        showCelebration = true
    }
}

#Preview {
    QuickEyesView()
}
