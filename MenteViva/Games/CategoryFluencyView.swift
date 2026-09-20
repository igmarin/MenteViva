import SwiftUI
import SwiftData

/// Name the Herd: pick the 7 items that belong to the shown category
/// from a grid of 12 big emoji tiles (5 decoys). 3 categories per session.
struct CategoryFluencyView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    private enum Category: CaseIterable {
        case animals, fruits, colors, vehicles

        var name: String {
            switch self {
            case .animals: String(localized: "game.category.animals")
            case .fruits: String(localized: "game.category.fruits")
            case .colors: String(localized: "game.category.colors")
            case .vehicles: String(localized: "game.category.vehicles")
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
    private let decoyCount = 5

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
    @State private var startedAt = Date.now
    @State private var showCelebration = false
    @State private var finalScore = 0
    @State private var tilePositions: [Int: Int] = [:]

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
                Text(String(localized: "game.category.instruction"))
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
                    ForEach(tiles.indices, id: \.self) { i in
                        Button { tap(i) } label: {
                            Text(tiles[i].emoji)
                                .font(.system(size: 52))
                                .frame(maxWidth: .infinity, minHeight: 100)
                                .background(tiles[i].isPicked ? .green.opacity(0.25) : .blue.opacity(0.15),
                                            in: .rect(cornerRadius: 16))
                                // Non-color cue: picked tiles get a visible checkmark,
                                // not just a green tint (WCAG 1.4.1, conventions.md §4).
                                .overlay(alignment: .topTrailing) {
                                    pickedBadge(isPicked: tiles[i].isPicked)
                                }
                        }
                        .buttonStyle(.plain)
                        .disabled(tiles[i].isPicked)
                        .accessibilityLabel(tiles[i].emoji)
                        .accessibilityHint(tiles[i].isPicked
                                           ? String(localized: "game.category.a11y.picked")
                                           : String(localized: "game.category.a11y.position \(tilePositions[i] ?? 0) \(tiles.count)"))
                    }
                }
            }
        }
        .padding()
        .navigationTitle(String(localized: "game.category.title"))
        .onAppear(perform: setup)
        .fullScreenCover(isPresented: $showCelebration) {
            CelebrationView(score: finalScore,
                            onPlayAgain: { showCelebration = false; restart() },
                            onHome: { showCelebration = false; dismiss() })
        }
    }

    @ViewBuilder
    private func pickedBadge(isPicked: Bool) -> some View {
        if isPicked {
            Image(systemName: "checkmark.circle.fill")
                .font(.title2)
                .foregroundStyle(.white, .green) // solid badge, readable on any tile tint
                .padding(6)
                .accessibilityHidden(true)
        }
    }

    private func restart() {
        progress.reset()
        totalCorrect = 0
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
            .flatMap(\.items).shuffled().prefix(decoyCount)
        let mixed = category.items.map { (emoji: $0, belongs: true) }
            + decoys.map { (emoji: $0, belongs: false) }
        tiles = mixed.shuffled().enumerated().map { Tile(id: $0, emoji: $1.emoji, belongs: $1.belongs) }
        tilePositions = Dictionary(uniqueKeysWithValues: tiles.indices.map { (tiles[$0].id, $0 + 1) })
        found = 0
    }

    private func tap(_ i: Int) {
        guard tiles[i].belongs else { Feedback.play(.miss); return } // decoy: kind, quiet
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
        let score = totalCorrect * 10
        modelContext.insert(GameSession(gameID: "category_fluency", score: score,
                                        rounds: roundsPerSession, durationSeconds: elapsed))
        finalScore = score
        showCelebration = true
    }
}

#Preview {
    CategoryFluencyView()
}
