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
    private let totalRounds = 12
    private let startDisplayTime = 1.2
    private let minDisplayTime = 0.35
    private let shrinkFactor = 0.92
    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    enum Phase {
        case showing, choosing, done
    }

    @State private var phase: Phase = .showing
    @State private var round = 1
    @State private var target = "🌻"
    @State private var options: [String] = []
    @State private var displayTime = 1.2
    @State private var correct = 0
    @State private var speedBonus = 0
    @State private var missedLastRound = false
    @State private var optionsShownAt = Date.now
    @State private var startedAt = Date.now

    var body: some View {
        VStack(spacing: 24) {
            Text(String(localized: "game.quickeyes.instruction"))
                .font(.title2)
                .multilineTextAlignment(.center)

            Spacer()

            switch phase {
            case .showing:
                Text(target)
                    .font(.system(size: 120))
                    .accessibilityLabel(String(localized: "game.quickeyes.a11y.showing"))
            case .choosing:
                VStack(spacing: 16) {
                    if missedLastRound {
                        Text(String(localized: "game.quickeyes.almost"))
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
                    Text(String(localized: "game.quickeyes.prompt"))
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
            case .done:
                VStack(spacing: 16) {
                    Text(String(localized: "game.common.welldone"))
                        .font(.title)
                    Text("\(correct) / \(totalRounds)")
                        .font(.title2)
                }
            }

            Spacer()
        }
        .padding()
        .navigationTitle(String(localized: "game.quickeyes.title"))
        .onAppear(perform: startRound)
    }

    private func startRound() {
        target = emojis.randomElement() ?? "🌻"
        let distractors = emojis.filter { $0 != target }.shuffled().prefix(3)
        options = (distractors + [target]).shuffled()
        phase = .showing
        Task {
            try? await Task.sleep(for: .seconds(displayTime))
            guard phase == .showing else { return }
            optionsShownAt = .now
            phase = .choosing
        }
    }

    private func choose(_ emoji: String) {
        guard phase == .choosing else { return }
        if emoji == target {
            correct += 1
            missedLastRound = false
            // Speed bonus: up to 5 points, one less per half-second of reaction time.
            let reaction = Date.now.timeIntervalSince(optionsShownAt)
            speedBonus += max(0, 5 - Int(reaction / 0.5))
            displayTime = max(minDisplayTime, displayTime * shrinkFactor)
        } else {
            missedLastRound = true
            // Relax one step after a miss so the next round feels kinder.
            displayTime = min(startDisplayTime, displayTime / shrinkFactor)
        }
        if round == totalRounds {
            finish()
        } else {
            round += 1
            startRound()
        }
    }

    private func finish() {
        phase = .done
        let elapsed = Int(Date.now.timeIntervalSince(startedAt))
        let score = correct * 10 + speedBonus
        modelContext.insert(GameSession(gameID: "quick_eyes", score: score,
                                        rounds: totalRounds, durationSeconds: elapsed))
    }
}

#Preview {
    QuickEyesView()
}
