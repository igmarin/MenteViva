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

    struct Card: Identifiable {
        let id: Int
        let emoji: String
        var isFaceUp = false
        var isMatched = false
    }

    var body: some View {
        VStack(spacing: 24) {
            Text(String(localized: "game.memory.instruction"))
                .font(.title2)
                .multilineTextAlignment(.center)

            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(cards.indices, id: \.self) { i in
                    Button { flip(i) } label: {
                        Text(cards[i].isFaceUp || cards[i].isMatched ? cards[i].emoji : "❓")
                            .font(.system(size: 56))
                            .frame(maxWidth: .infinity, minHeight: 110)
                            .background(cards[i].isMatched ? .green.opacity(0.2) : .blue.opacity(0.15),
                                        in: .rect(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)
                    .disabled(cards[i].isFaceUp || cards[i].isMatched)
                    .accessibilityLabel(cards[i].isFaceUp || cards[i].isMatched
                                        ? cards[i].emoji
                                        : String(localized: "game.memory.card.hidden"))
                }
            }
            .padding()
        }
        .padding()
        .navigationTitle(String(localized: "game.memory.title"))
        .onAppear(perform: deal)
    }

    private func deal() {
        cards = (emojis + emojis).shuffled().enumerated().map { Card(id: $0, emoji: $1) }
        startedAt = .now
    }

    private func flip(_ i: Int) {
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
            if matched == emojis.count { finish() }
        } else {
            let pair = flipped
            flipped = []
            Task {
                try? await Task.sleep(for: .seconds(1.2))
                cards[pair[0]].isFaceUp = false
                cards[pair[1]].isFaceUp = false
            }
        }
    }

    private func finish() {
        let elapsed = Int(Date.now.timeIntervalSince(startedAt))
        let score = max(10, emojis.count * 20 - moves * 2)
        modelContext.insert(GameSession(gameID: "memory", score: score,
                                        rounds: moves, durationSeconds: elapsed))
    }
}

#Preview {
    MemoryMatchView()
}
