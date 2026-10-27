import SwiftData
import SwiftUI

/// Name the Herd: pick the 7 items that belong to the shown category
/// from a grid of big emoji tiles (3 / 5 / 7 decoys by difficulty). 3 categories per session.
struct CategoryFluencyView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// The next step after a correct pick, kept pure so the completion beat is testable.
    enum Completion: Equatable {
        case keepPlaying
        case showBeatThenNextCategory
        case showBeatThenFinish
    }

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

    /// Decoys per level: one more each step so progress is felt, but never
    /// mid-game. Levels 2/4/6 are 3/5/7 to match the old easy/medium/hard so
    /// migrated players see no change; the fit cap keeps 100pt targets on SE.
    static let decoysByLevel: [Int] = [2, 3, 4, 5, 6, 7, 8, 9, 10, 11]
    /// Smallest tile that stays tappable (conventions §4).
    static let tileMin: Double = 100
    static let tileGap: Double = 16
    static let horizontalPadding: Double = 32

    /// Decoys for a level, capped to the available pool.
    static func decoyCount(for difficulty: Difficulty) -> Int {
        min(difficulty.values(decoysByLevel), 21)
    }

    /// Test helper with injectable pool size.
    static func decoyCount(for difficulty: Difficulty, poolSize: Int) -> Int {
        min(difficulty.values(decoysByLevel), poolSize)
    }

    /// Decoys capped to both the pool and the width so every tile keeps
    /// 100pt. Width is the full screen width; padding and gaps are removed
    /// before measuring.
    static func fittedDecoyCount(for difficulty: Difficulty, width: Double) -> Int {
        fittedDecoyCount(for: difficulty, width: width, poolSize: 21)
    }

    /// Test helper with injectable pool size.
    static func fittedDecoyCount(for difficulty: Difficulty, width: Double, poolSize: Int) -> Int {
        let poolCapped = decoyCount(for: difficulty, poolSize: poolSize)
        let gridWidth = max(0, width - horizontalPadding)
        // Columns that keep a tile >= 100pt.
        let maxColumns = max(1, Int((gridWidth + tileGap) / (tileMin + tileGap)))
        // If even a single column doesn't fit, no decoy can rescue it.
        guard gridWidth >= tileMin else { return 0 }
        // When the board needs more columns than fit, the tile would shrink
        // below 100pt. Cap decoys so total tiles don't force that.
        // Approximation: total tiles displayed in maxColumns columns.
        let maxTotalTiles = maxColumns * 6  // enough rows before scrolling, keeps 100pt
        let maxDecoysForWidth = max(0, maxTotalTiles - 7)
        return min(poolCapped, maxDecoysForWidth)
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
    @State private var isShowingCompletionBeat = false
    @State private var completionTask: Task<Void, Never>?

    static func score(totalCorrect: Int) -> Int {
        totalCorrect * 10
    }

    /// A finished category always gets a beat; its result decides where to go afterwards.
    static func completion(found: Int, total: Int, hasNextRound: Bool) -> Completion {
        guard found == total else { return .keepPlaying }
        return hasNextRound ? .showBeatThenNextCategory : .showBeatThenFinish
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
            LevelExplainBanner(
                change: PlanStore.cachedPlan()?.changes[GameID.categoryFluency], game: GameID.categoryFluency,
                hasStarted: totalPicks > 0 || progress.completedRounds > 0)
            if let round = currentRound {
                Group {
                    Text(AppLanguage.localized("game.category.instruction"))
                        .font(.title2)
                        .multilineTextAlignment(.center)

                    Text(round.name)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .accessibilityAddTraits(.isHeader)

                    ProgressCards(
                        done: found, total: round.items.count,
                        words: String(
                            format: AppLanguage.localized("game.category.found %lld %lld"), found, round.items.count))

                    if isShowingCompletionBeat {
                        Text(String(format: AppLanguage.localized("game.category.complete %@"), round.name))
                            .font(.title2)
                            .multilineTextAlignment(.center)
                    }

                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(tiles) { tile in
                            Button {
                                tap(tile.id)
                            } label: {
                                Text(tile.emoji)
                                    .font(.system(size: 52))
                            }
                            .buttonStyle(
                                AnswerTileStyle(strength: tile.isPicked ? 0.32 : 0.12, minHeight: 100)
                            )
                            // Non-color cue: picked tiles get a visible checkmark,
                            // not just a stronger tint (WCAG 1.4.1, conventions.md §4).
                            .overlay(alignment: .topTrailing) {
                                if tile.isPicked { CheckBadge() }
                            }
                            .modifier(
                                MissCue(
                                    active: Binding(
                                        get: { missedTile == tile.id },
                                        set: { if !$0 { missedTile = nil } }))
                            )
                            .accessibilityLabel(tile.emoji)
                            .accessibilityHint(
                                tile.isPicked
                                    ? AppLanguage.localized("game.category.a11y.picked")
                                    : String(
                                        format: AppLanguage.localized("game.category.a11y.position %lld %lld"),
                                        tilePositions[tile.id] ?? 0, tiles.count))
                        }
                    }
                }
                .id(round)
                .transition(reduceMotion ? .identity : .opacity)
                .onAppear { AccessibilityNotification.Announcement(round.name).post() }
            }
        }
        .padding()
        .fitOrScroll()
        .gameHeader(
            .categoryFluency,
            instruction: AppLanguage.localized("game.category.instruction") + " " + (currentRound?.name ?? "")
        )
        .onAppear(perform: setup)
        .onDisappear { completionTask?.cancel() }
        .celebration(isPresented: $showCelebration, game: .categoryFluency, detail: finalDetail, onPlayAgain: restart)
    }

    private func restart() {
        progress.reset()
        totalCorrect = 0
        totalPicks = 0
        setup()
    }

    private func setup() {
        completionTask?.cancel()
        completionTask = nil
        isShowingCompletionBeat = false
        rounds = Category.allCases.shuffled().prefix(roundsPerSession).map { $0 }
        progress = RoundProgress(totalRounds: rounds.count)
        startedAt = .now
        dealRound()
    }

    private func dealRound() {
        guard let category = currentRound else { return }
        let width = Double(UIScreen.main.bounds.width)
        let count = Self.fittedDecoyCount(for: difficulty, width: width)
        let decoys = Category.allCases.filter { $0 != category }
            .flatMap(\.items).shuffled().prefix(count)
        let mixed =
            category.items.map { (emoji: $0, belongs: true) }
            + decoys.map { (emoji: $0, belongs: false) }
        tiles = mixed.shuffled().enumerated().map { Tile(id: $0, emoji: $1.emoji, belongs: $1.belongs) }
        tilePositions = Dictionary(uniqueKeysWithValues: tiles.indices.map { (tiles[$0].id, $0 + 1) })
        found = 0
    }

    private func tap(_ tileID: Int) {
        guard !isShowingCompletionBeat,
            let i = tiles.firstIndex(where: { $0.id == tileID }),
            !tiles[i].isPicked
        else { return }
        totalPicks += 1
        guard tiles[i].belongs else {
            Feedback.play(.miss)
            missedTile = tileID
            return
        }  // decoy: kind, quiet
        tiles[i].isPicked = true
        found += 1
        totalCorrect += 1
        Feedback.play(.success)
        let completion = Self.completion(
            found: found, total: currentRound?.items.count ?? 0,
            hasNextRound: progress.completedRounds + 1 < rounds.count)
        guard completion != .keepPlaying else { return }
        isShowingCompletionBeat = true
        completionTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(1))
            guard !Task.isCancelled else { return }
            isShowingCompletionBeat = false
            switch completion {
            case .keepPlaying:
                break
            case .showBeatThenNextCategory:
                withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.25)) {
                    _ = progress.completeRound()
                    dealRound()
                }
            case .showBeatThenFinish:
                _ = progress.completeRound()
                finish()
            }
        }
    }

    private func finish() {
        let elapsed = Int(Date.now.timeIntervalSince(startedAt))
        let score = Self.score(totalCorrect: totalCorrect)
        modelContext.record(
            GameSession(
                gameID: .categoryFluency, score: score,
                rounds: roundsPerSession, durationSeconds: elapsed,
                correct: totalCorrect, attempts: totalPicks,
                difficulty: difficulty))
        finalDetail = String(format: AppLanguage.localized("game.celebration.items %lld"), totalCorrect)
        showCelebration = true
    }
}

#Preview {
    CategoryFluencyView()
}
