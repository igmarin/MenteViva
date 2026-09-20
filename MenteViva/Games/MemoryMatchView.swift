import SwiftUI
import SwiftData

/// Memory Lane: classic pair-matching with big emoji cards.
/// Difficulty = grid size. Fully offline, fully deterministic.
struct MemoryMatchView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    private let emojis = ["🌻", "🐢", "🍎", "🎸", "🌙", "☕️", "🦋", "🍊"]
    private let columns = [GridItem(.adaptive(minimum: 100), spacing: 16)]

    @State private var cards: [Card] = []
    @State private var flipped: [Int] = []
    @State private var matched = 0
    @State private var moves = 0
    @State private var startedAt = Date.now
    @State private var showCelebration = false
    @State private var finalScore = 0
    @State private var cardPositions: [Int: Int] = [:]
    @State private var flipBackTask: Task<Void, Never>?

    struct Card: Identifiable {
        let id: Int
        let emoji: String
        var isFaceUp = false
        var isMatched = false
    }

    static func score(pairCount: Int, moves: Int) -> Int {
        max(10, pairCount * 20 - moves * 2)
    }

    var body: some View {
        VStack(spacing: 24) {
            Text(AppLanguage.localized( "game.memory.instruction"))
                .font(.title2)
                .multilineTextAlignment(.center)

            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(cards) { card in
                    Button { flip(card.id) } label: {
                        Text(card.isFaceUp || card.isMatched ? card.emoji : "❓")
                            .font(.system(size: 56))
                            .frame(maxWidth: .infinity, minHeight: 110)
                            .background(card.isMatched ? .green.opacity(0.2) : .blue.opacity(0.15),
                                        in: .rect(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)
                    .disabled(card.isFaceUp || card.isMatched)
                    .accessibilityLabel(card.isFaceUp || card.isMatched
                                        ? card.emoji
                                        : AppLanguage.localized( "game.memory.card.hidden"))
                    .accessibilityHint(card.isMatched
                                       ? AppLanguage.localized( "game.memory.a11y.matched")
                                       : AppLanguage.localized( "game.memory.a11y.position \(cardPositions[card.id] ?? 0) \(cards.count)"))
                }
            }
            .padding()
        }
        .padding()
        .navigationTitle(AppLanguage.localized( "game.memory.title"))
        .onAppear(perform: deal)
        .onDisappear { flipBackTask?.cancel() }
        .fullScreenCover(isPresented: $showCelebration) {
            CelebrationView(score: finalScore,
                            onPlayAgain: { showCelebration = false; deal() },
                            onHome: { showCelebration = false; dismiss() })
        }
    }

    private func deal() {
        flipBackTask?.cancel()
        cards = (emojis + emojis).shuffled().enumerated().map { Card(id: $0, emoji: $1) }
        cardPositions = Dictionary(uniqueKeysWithValues: cards.indices.map { (cards[$0].id, $0 + 1) })
        flipped = []
        matched = 0
        moves = 0
        startedAt = .now
    }

    private func flip(_ cardID: Int) {
        guard let i = cards.firstIndex(where: { $0.id == cardID }) else { return }
        cards[i].isFaceUp = true
        flipped.append(i)
        guard flipped.count == 2 else { return }
        moves += 1
        let (a, b) = (flipped[0], flipped[1])
        if cards[a].emoji == cards[b].emoji {
            cards[a].isMatched = true
            cards[b].isMatched = true
            matched += 1
            flipped = []
            Feedback.play(.success)
            if matched == emojis.count { finish() }
        } else {
            Feedback.play(.miss)
            let pair = flipped
            flipped = []
            flipBackTask = Task { @MainActor in
                try? await Task.sleep(for: .seconds(1.2))
                guard !Task.isCancelled,
                      pair.allSatisfy({ cards.indices.contains($0) }) else { return }
                cards[pair[0]].isFaceUp = false
                cards[pair[1]].isFaceUp = false
            }
        }
    }

    private func finish() {
        let elapsed = Int(Date.now.timeIntervalSince(startedAt))
        let score = Self.score(pairCount: emojis.count, moves: moves)
        modelContext.insert(GameSession(gameID: .memoryMatch, score: score,
                                        rounds: moves, durationSeconds: elapsed))
        finalScore = score
        showCelebration = true
    }
}

#Preview {
    MemoryMatchView()
}
