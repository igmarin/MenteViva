import SwiftUI
import SwiftData

/// Memory Lane: classic pair-matching with big emoji cards.
/// Difficulty = grid size (6 / 8 / 10 pairs). Fully offline, fully deterministic.
/// #43: themed boards rotate each game so visits stop feeling identical;
/// warmer palette and a checkmark (not just a tint) mark found pairs.
struct MemoryMatchView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Four themed sets of 8 pairs. One is drawn per game; emoji carry their
    /// own VoiceOver names, so themes need no extra strings.
    private static let themes: [[String]] = [
        ["🌻", "🐢", "🍎", "🎸", "🌙", "☕️", "🦋", "🍊", "🌷", "🐞"],   // garden afternoon
        ["🐶", "🐱", "🦁", "🐸", "🐘", "🐝", "🦆", "🐢", "🐰", "🐧"],   // animal friends
        ["🍎", "🍌", "🍇", "🍊", "🍓", "🍉", "🍑", "🥝", "🍍", "🍒"],   // fruit bowl
        ["🚗", "🚌", "✈️", "🚀", "🚲", "🚂", "⛵️", "🛵", "🚁", "🚜"],   // ways to go
    ]

    @State private var difficulty = Difficulty.stored(.memoryMatch)
    @State private var emojis: [String] = Array(Self.themes[0].prefix(8))
    private let columns = [GridItem(.adaptive(minimum: 110), spacing: 16)]

    @State private var cards: [Card] = []
    @State private var flipped: [Int] = []
    @State private var matched = 0
    @State private var moves = 0
    @State private var startedAt = Date.now
    @State private var showCelebration = false
    @State private var finalDetail = ""
    @State private var cardPositions: [Int: Int] = [:]
    @State private var flipBackTask: Task<Void, Never>?

    struct Card: Identifiable {
        let id: Int
        let emoji: String
        var isFaceUp = false
        var isMatched = false
    }

    static func pairCount(for difficulty: Difficulty) -> Int {
        difficulty.pick(6, 8, 10)
    }

    static func score(pairCount: Int, moves: Int) -> Int {
        max(10, pairCount * 20 - moves * 2)
    }

    var body: some View {
        VStack(spacing: 24) {
            Text(AppLanguage.localized("game.memory.instruction"))
                .font(.title2)
                .multilineTextAlignment(.center)

            ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(cards) { card in
                    Button { flip(card.id) } label: {
                        Text(card.isFaceUp || card.isMatched ? card.emoji : "🌼")
                            .font(.system(size: 64))
                            .frame(maxWidth: .infinity, minHeight: 120)
                            .background(card.isMatched ? .green.opacity(0.2) : .orange.opacity(0.14),
                                        in: .rect(cornerRadius: 16))
                            // Non-color cue: matched pairs keep a checkmark,
                            // not just a green tint (WCAG 1.4.1).
                            .overlay(alignment: .topTrailing) {
                                if card.isMatched { CheckBadge() }
                            }
                            // Gentle bloom on the moment a pair is found.
                            .scaleEffect(card.isMatched && !reduceMotion ? 1.04 : 1)
                            .animation(.spring(duration: 0.35), value: card.isMatched)
                    }
                    .buttonStyle(.plain)
                    .disabled(card.isFaceUp || card.isMatched)
                    .accessibilityLabel(card.isFaceUp || card.isMatched
                                        ? card.emoji
                                        : AppLanguage.localized("game.memory.card.hidden"))
                    .accessibilityHint(card.isMatched
                                       ? AppLanguage.localized("game.memory.a11y.matched")
                                       : String(format: AppLanguage.localized("game.memory.a11y.position %lld %lld"), cardPositions[card.id] ?? 0, cards.count))
                }
            }
            .padding()
            }
        }
        .padding()
        .navigationTitle(AppLanguage.localized("game.memory.title"))
        .onAppear(perform: deal)
        .onDisappear { flipBackTask?.cancel() }
        .celebration(isPresented: $showCelebration, detail: finalDetail, onPlayAgain: deal)
    }

    private func deal() {
        flipBackTask?.cancel()
        emojis = Array((Self.themes.randomElement() ?? Self.themes[0])
            .prefix(Self.pairCount(for: difficulty)))
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
        // Score stays in the model as anonymous telemetry for Jev (#45); the
        // player sees progress, not points.
        modelContext.insert(GameSession(gameID: .memoryMatch, score: score,
                                        rounds: emojis.count, durationSeconds: elapsed,
                                        correct: emojis.count, attempts: moves))
        finalDetail = String(format: AppLanguage.localized("game.celebration.pairs %lld"), emojis.count)
        showCelebration = true
    }
}

#Preview {
    MemoryMatchView()
}
