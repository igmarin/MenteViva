import SwiftUI
import SwiftData

/// Name the Herd: pick the 7 items that belong to the shown category
/// from a grid of big emoji tiles (3 / 5 / 7 decoys by difficulty). 3 categories per session.
struct CategoryFluencyView: View {
    @Environment(\.modelContext) private var modelContext

    private enum Category: CaseIterable {
        case animals, fruits, colors, vehicles

        var name: String {
            switch self {
            case .animals: AppLanguage.localized("game.category.animals")
            case .fruits: AppLanguage.localized("game.category.fruits")
            case .colors: AppLanguage.localized("game.category.colors")
            case .vehicles: AppLanguage.localized("game.category.vehicles")
            }
        }

        var items: [String] {
            switch self {
            case .animals: ["🐶", "🐱", "🦁", "🐸", "🐢", "🦋", "🐘"]
            case .fruits: ["🍎", "🍌", "🍇", "🍊", "🍓", "🍉", "🍑"]
            case .colors: ["🔴", "🔵", "🟢", "🟡", "🟠", "🟣", "🟤"]
            case .vehicles: ["🚗", "🚌", "✈️", "🚀", "🚲", "🚂", "⛵️"]
            }
        }
    }

    private let roundsPerSession = 3
    static func decoyCount(for difficulty: Difficulty) -> Int {
        difficulty.pick(3, 5, 7)
    }
    @State private var difficulty = Difficulty.stored(.categoryFluency)

    struct Tile: Identifiable {
        let id: Int
        let emoji: String
        let belongs: Bool
        var isPicked = false
    }

    @State private var rounds: [Category] = []
    @State private var tiles: [Tile] = []
    @State private var progress = RoundProgress(totalRounds: 3)
    @State private var found = 0
    @State private var totalCorrect = 0
    @State private var totalPicks = 0
    @State private var startedAt = Date.now
    @State private var showCelebration = false
    @State private var finalDetail = ""
    @State private var tilePositions: [Int: Int] = [:]
    @State private var missedTile: Int?

    static func score(totalCorrect: Int) -> Int {
        totalCorrect * 10
    }

    private let columns = [GridItem(.adaptive(minimum: 100), spacing: 16)]

    /// The round being played, or nil once the session ends. Body reads this
    /// instead of indexing `rounds`: a counter that runs one past the end used
    /// to crash here with "Index out of range" (#30).
    private var currentRound: Category? {
        rounds.indices.contains(progress.completedRounds) ? rounds[progress.completedRounds] : nil
    }

    var body: some View {
        VStack(spacing: 24) {
            if let round = currentRound {
                Text(AppLanguage.localized("game.category.instruction"))
                    .font(.title2)
                    .multilineTextAlignment(.center)

                Text(round.name)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .accessibilityAddTraits(.isHeader)

                Text("\(found) / \(round.items.count)")
                    .font(.title3)
                    .foregroundStyle(.secondary)

                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(tiles) { tile in
                        Button { tap(tile.id) } label: {
                            Text(tile.emoji)
                                .font(.system(size: 52))
                                .frame(maxWidth: .infinity, minHeight: 100)
                                .background(tile.isPicked ? .green.opacity(0.25) : .blue.opacity(0.15),
                                            in: .rect(cornerRadius: 16))
                                // Non-color cue: picked tiles get a visible checkmark,
                                // not just a green tint (WCAG 1.4.1, conventions.md §4).
                                .overlay(alignment: .topTrailing) {
                                    if tile.isPicked { CheckBadge() }
                                }
                        }
                        .buttonStyle(.plain)
                        .modifier(MissCue(active: Binding(get: { missedTile == tile.id },
                                                          set: { if !$0 { missedTile = nil } })))
                        .disabled(tile.isPicked)
                        .accessibilityLabel(tile.emoji)
                        .accessibilityHint(tile.isPicked
                                           ? AppLanguage.localized("game.category.a11y.picked")
                                           : String(format: AppLanguage.localized("game.category.a11y.position %lld %lld"), tilePositions[tile.id] ?? 0, tiles.count))
                    }
                }
            }
        }
        .padding()
        .navigationTitle(AppLanguage.localized("game.category.title"))
        .onAppear(perform: setup)
        .celebration(isPresented: $showCelebration, detail: finalDetail, onPlayAgain: restart)
    }

    private func restart() {
        progress.reset()
        totalCorrect = 0
        totalPicks = 0
        setup()
    }

    private func setup() {
        rounds = Category.allCases.shuffled().prefix(roundsPerSession).map { $0 }
        progress = RoundProgress(totalRounds: rounds.count)
        startedAt = .now
        dealRound()
    }

    private func dealRound() {
        guard let category = currentRound else { return }
        let decoys = Category.allCases.filter { $0 != category }
            .flatMap(\.items).shuffled().prefix(Self.decoyCount(for: difficulty))
        let mixed = category.items.map { (emoji: $0, belongs: true) }
            + decoys.map { (emoji: $0, belongs: false) }
        tiles = mixed.shuffled().enumerated().map { Tile(id: $0, emoji: $1.emoji, belongs: $1.belongs) }
        tilePositions = Dictionary(uniqueKeysWithValues: tiles.indices.map { (tiles[$0].id, $0 + 1) })
        found = 0
    }

    private func tap(_ tileID: Int) {
        guard let i = tiles.firstIndex(where: { $0.id == tileID }),
              !tiles[i].isPicked else { return }
        totalPicks += 1
        guard tiles[i].belongs else { Feedback.play(.miss); missedTile = tileID; return } // decoy: kind, quiet
        tiles[i].isPicked = true
        found += 1
        totalCorrect += 1
        Feedback.play(.success)
        guard found == currentRound?.items.count ?? 0 else { return }
        if progress.completeRound() {
            finish()
        } else {
            dealRound()
        }
    }

    private func finish() {
        let elapsed = Int(Date.now.timeIntervalSince(startedAt))
        let score = Self.score(totalCorrect: totalCorrect)
        modelContext.insert(GameSession(gameID: .categoryFluency, score: score,
                                        rounds: roundsPerSession, durationSeconds: elapsed,
                                        correct: totalCorrect, attempts: totalPicks))
        finalDetail = String(format: AppLanguage.localized("game.celebration.items %lld"), totalCorrect)
        showCelebration = true
    }
}

#Preview {
    CategoryFluencyView()
}
