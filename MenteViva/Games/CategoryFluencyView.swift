import SwiftData
import SwiftUI

/// Name the Herd: pick the 7 items that belong to the shown category
/// from a grid of big picture tiles (2 to 11 decoys by level). 3 of 7 categories per session.
struct CategoryFluencyView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// The next step after a correct pick, kept pure so the completion beat is testable.
    enum Completion: Equatable {
        case keepPlaying
        case showBeatThenNextCategory
        case showBeatThenFinish
    }

    @State private var difficulty = Difficulty.stored(.categoryFluency)

    struct Tile: Identifiable {
        let id: Int
        let picture: GamePicture
        let belongs: Bool
        var isPicked = false
    }

    @State private var session: [CategoryDeal.Round] = []
    @State private var tiles: [Tile] = []
    @State private var progress = RoundProgress(totalRounds: CategoryDeal.roundsPerSession)
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

    /// Picture and its margin inside the tile (#413). Both grow with the text; the tick below stops
    /// growing at xxxLarge, so the margin outpaces it and the tick keeps off the picture.
    @ScaledMetric(relativeTo: .title2) private var pictureSize: CGFloat = 72
    @ScaledMetric(relativeTo: .title2) private var pictureMargin: CGFloat = 14

    /// Columns are as narrow as the picture and its margin allow (100pt at the default size).
    private var columns: [GridItem] {
        [
            GridItem(
                .adaptive(minimum: PictureView.columnMinimum(picture: pictureSize, margin: pictureMargin)),
                spacing: 16)
        ]
    }

    /// The round being played, or nil once the session ends. Body reads this
    /// instead of indexing the deal: a counter that runs one past the end used
    /// to crash here with "Index out of range" (#30).
    private var currentRound: CategoryDeal.Round? {
        session.indices.contains(progress.completedRounds) ? session[progress.completedRounds] : nil
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

                    Text(name(of: round))
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .accessibilityAddTraits(.isHeader)

                    ProgressCards(
                        done: found, total: round.category.items.count,
                        words: String(
                            format: AppLanguage.localized("game.category.found %lld %lld"), found, round.category.items.count))

                    if isShowingCompletionBeat {
                        Text(String(format: AppLanguage.localized("game.category.complete %@"), name(of: round)))
                            .font(.title2)
                            .multilineTextAlignment(.center)
                    }

                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(tiles) { tile in
                            Button {
                                tap(tile.id)
                            } label: {
                                PictureView(picture: tile.picture, size: pictureSize)
                                    .padding(pictureMargin)
                            }
                            .buttonStyle(
                                AnswerTileStyle(strength: tile.isPicked ? 0.32 : 0.12, minHeight: 100)
                            )
                            // Non-color cue: picked tiles get a visible checkmark,
                            // not just a stronger tint (WCAG 1.4.1, conventions.md §4).
                            .overlay(alignment: .topTrailing) {
                                // Hangs 12pt over the tile's corner so the tick never covers the picture, and
                                // stops growing at xxxLarge so it stays inside the screen's 16pt edge (#413).
                                if tile.isPicked {
                                    CheckBadge().dynamicTypeSize(...DynamicTypeSize.xxxLarge).offset(x: 12, y: -12)
                                }
                            }
                            .modifier(
                                MissCue(
                                    active: Binding(
                                        get: { missedTile == tile.id },
                                        set: { if !$0 { missedTile = nil } }))
                            )
                            .accessibilityLabel(AppLanguage.localized(tile.picture.nameKey))
                            .accessibilityHint(
                                tile.isPicked
                                    ? AppLanguage.localized("game.category.a11y.picked")
                                    : String(
                                        format: AppLanguage.localized("game.category.a11y.position %lld %lld"),
                                        tilePositions[tile.id] ?? 0, tiles.count))
                        }
                    }
                }
                .id(round.category)
                .transition(reduceMotion ? .identity : .opacity)
                .onAppear { AccessibilityNotification.Announcement(name(of: round)).post() }
            }
        }
        .padding()
        .fitOrScroll()
        .gameHeader(
            .categoryFluency,
            instruction: AppLanguage.localized("game.category.instruction") + " " + (currentRound.map(name(of:)) ?? "")
        )
        .onAppear(perform: setup)
        .onDisappear { completionTask?.cancel() }
        .celebration(isPresented: $showCelebration, game: .categoryFluency, detail: finalDetail, onPlayAgain: restart)
    }

    /// The category in play, as shown and announced.
    private func name(of round: CategoryDeal.Round) -> String {
        AppLanguage.localized(round.category.nameKey)
    }

    private func restart() {
        progress.reset()
        totalCorrect = 0
        totalPicks = 0
        difficulty = Difficulty.stored(.categoryFluency)
        setup()
    }

    private func setup() {
        completionTask?.cancel()
        completionTask = nil
        isShowingCompletionBeat = false
        var generator = SystemRandomNumberGenerator()
        session = CategoryDeal.deal(
            difficulty: difficulty, width: Double(UIScreen.main.bounds.width), using: &generator)
        progress = RoundProgress(totalRounds: session.count)
        startedAt = .now
        dealRound()
    }

    /// Lays out the tiles of the round in play; the deal already shuffled them.
    private func dealRound() {
        guard let round = currentRound else { return }
        tiles = round.tiles.enumerated().map { Tile(id: $0, picture: $1.picture, belongs: $1.belongs) }
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
            // Nothing new on screen (decoy: kind, quiet), but VoiceOver hears the tap registered.
            AccessibilityNotification.Announcement(AppLanguage.localized("game.category.miss")).post()
            return
        }
        tiles[i].isPicked = true
        found += 1
        totalCorrect += 1
        Feedback.play(.success)
        let completion = Self.completion(
            found: found, total: currentRound?.category.items.count ?? 0,
            hasNextRound: progress.completedRounds + 1 < session.count)
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
                rounds: CategoryDeal.roundsPerSession, durationSeconds: elapsed,
                correct: totalCorrect, attempts: totalPicks,
                difficulty: difficulty))
        finalDetail = String(format: AppLanguage.localized("game.celebration.items %lld"), totalCorrect)
        showCelebration = true
    }
}

#Preview {
    CategoryFluencyView()
}
