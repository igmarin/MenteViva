import SwiftUI
import SwiftData

/// Memory Lane: classic pair-matching on large cards.
/// Difficulty = board size (4 / 6 / 8 pairs). Fully offline, fully deterministic.
/// #43: themed boards rotate each game so visits stop feeling identical.
/// #109: "a game, but he's not a child" — grown-up themes, paper-like cards, a
/// calm card back, and a board sized to the screen (iPad and iPhone) so every
/// card is visible without scrolling. Found pairs keep a checkmark, not just a tint.
struct MemoryMatchView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Four grown-up sets of 8 pairs. One is drawn per game; emoji carry their
    /// own VoiceOver names, so themes need no extra strings.
    private static let themes: [[String]] = [
        ["☕️", "🫖", "🍞", "🧀", "🍷", "🥐", "🍋", "🫒"],   // kitchen table
        ["🌹", "🌻", "🌷", "🪴", "🍐", "🌳", "🦋", "🐝"],   // the garden
        ["⛵️", "🚂", "✈️", "🗺️", "🧳", "⛰️", "🏖️", "🚲"],   // travels
        ["🎻", "🎺", "🎹", "📻", "🕰️", "📚", "🧶", "🪑"],   // music and home
    ]
    private static let spacing: CGFloat = 12
    /// Deep slate card back: calm, not childish, readable in light and dark.
    private static let cardBack = Color(red: 0.20, green: 0.34, blue: 0.42)

    @State private var difficulty = Difficulty.stored(.memoryMatch)
    @State private var emojis: [String] = Array(Self.themes[0].prefix(6))

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
        difficulty.pick(4, 6, 8)
    }

    /// Columns and card size that show `count` cards in `size` with nothing
    /// scrolled away, making the smaller card side as large as possible. Full
    /// rows win unless a ragged board gives cards over 10% larger — a lone card
    /// on the last row reads as a mistake. Cards fill their cell, but never get
    /// taller than 1.3x their width.
    static func gridFit(count: Int, in size: CGSize, spacing: CGFloat) -> (columns: Int, card: CGSize) {
        guard count > 0 else { return (1, .zero) }
        var best = (columns: 1, card: CGSize.zero, side: -CGFloat.infinity)
        for columns in 1...count {
            let rows = (count + columns - 1) / columns
            let width = (size.width - spacing * CGFloat(columns - 1)) / CGFloat(columns)
            let height = (size.height - spacing * CGFloat(rows - 1)) / CGFloat(rows)
            let side = min(width, height) * (count % columns == 0 ? 1 : 0.9)
            if side > best.side {
                best = (columns, CGSize(width: width, height: min(height, width * 1.3)), side)
            }
        }
        return (best.columns, best.card)
    }

    static func score(pairCount: Int, moves: Int) -> Int {
        max(10, pairCount * 20 - moves * 2)
    }

    var body: some View {
        VStack(spacing: 24) {
            Text(AppLanguage.localized("game.memory.instruction"))
                .font(.title2)
                .multilineTextAlignment(.center)

            GeometryReader { geometry in
                let fit = Self.gridFit(count: cards.count, in: geometry.size, spacing: Self.spacing)
                LazyVGrid(columns: Array(repeating: GridItem(.fixed(fit.card.width), spacing: Self.spacing),
                                         count: fit.columns),
                          spacing: Self.spacing) {
                    ForEach(cards) { card in
                        Button { flip(card.id) } label: { face(card, size: fit.card) }
                            .buttonStyle(.plain)
                            .accessibilityLabel(card.isFaceUp || card.isMatched
                                                ? card.emoji
                                                : AppLanguage.localized("game.memory.card.hidden"))
                            .accessibilityHint(card.isMatched
                                               ? AppLanguage.localized("game.memory.a11y.matched")
                                               : String(format: AppLanguage.localized("game.memory.a11y.position %lld %lld"), cardPositions[card.id] ?? 0, cards.count))
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding()
        .navigationTitle(AppLanguage.localized("game.memory.title"))
        .onAppear(perform: deal)
        .onDisappear { flipBackTask?.cancel() }
        .celebration(isPresented: $showCelebration, detail: finalDetail, onPlayAgain: deal)
    }

    /// Face up: a paper card with the picture. Face down: the slate back with a
    /// small leaf. Matched pairs get a soft green paper and the checkmark.
    private func face(_ card: Card, size: CGSize) -> some View {
        let shown = card.isFaceUp || card.isMatched
        return ZStack {
            RoundedRectangle(cornerRadius: 18)
                .fill(shown ? AnyShapeStyle(card.isMatched ? Color.green.opacity(0.14) : Color(.systemBackground))
                            : AnyShapeStyle(Self.cardBack.gradient))
                .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(.black.opacity(shown ? 0.12 : 0), lineWidth: 1)
            if shown {
                Text(card.emoji)
                    .font(.system(size: min(size.width, size.height) * 0.5))
            } else {
                Image(systemName: "leaf.fill")
                    .font(.system(size: min(size.width, size.height) * 0.22))
                    .foregroundStyle(.white.opacity(0.35))
            }
        }
        .frame(width: size.width, height: size.height)
        // Non-color cue: matched pairs keep a checkmark (WCAG 1.4.1).
        .overlay(alignment: .topTrailing) {
            if card.isMatched { CheckBadge() }
        }
        // Gentle bloom on the moment a pair is found.
        .scaleEffect(card.isMatched && !reduceMotion ? 1.03 : 1)
        .animation(.spring(duration: 0.35), value: card.isMatched)
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
        // Face-up and found cards ignore taps here rather than via .disabled,
        // so the system never greys out the pictures he needs to read.
        guard let i = cards.firstIndex(where: { $0.id == cardID }),
              !cards[i].isFaceUp, !cards[i].isMatched else { return }
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
        modelContext.record(GameSession(gameID: .memoryMatch, score: score,
                                        rounds: emojis.count, durationSeconds: elapsed,
                                        correct: emojis.count, attempts: moves,
                                        difficulty: difficulty))
        finalDetail = String(format: AppLanguage.localized("game.celebration.pairs %lld"), emojis.count)
        showCelebration = true
    }
}

#Preview {
    MemoryMatchView()
}
