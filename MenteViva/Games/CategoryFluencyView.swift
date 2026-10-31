import SwiftData
import SwiftUI

/// Name the Herd: pick the 7 items that belong to the shown category
/// from a grid of big picture tiles (2 to 11 decoys by level). 3 of 7 categories per session.
struct CategoryFluencyView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// The next step after a correct pick, kept pure so the completion beat is testable.
    nonisolated enum Completion: Equatable {
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
        /// A decoy already tapped: it fades and stays quiet, so it is never counted twice (#415).
        var isTried = false
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
    /// What the board has to work with (#415): the play area's height, measured outside the padding,
    /// and the width and height of the header block above the grid. The grid's own room is what is left.
    @State private var areaHeight: CGFloat = 0
    @State private var headerSize: CGSize = .zero
    /// Decoys the session was dealt with, nil until the board has been measured.
    @State private var dealtDecoys: Int?

    static func score(totalCorrect: Int) -> Int {
        totalCorrect * 10
    }

    /// A finished category always gets a beat; its result decides where to go afterwards.
    static func completion(found: Int, total: Int, hasNextRound: Bool) -> Completion {
        guard found == total else { return .keepPlaying }
        return hasNextRound ? .showBeatThenNextCategory : .showBeatThenFinish
    }

    /// The screen's edge padding, named so the height measured outside it can take it off (#415).
    private static let edgePadding: CGFloat = 16

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

    /// The column minimum the grid uses, as a plain number for the fit.
    private var tileSide: Double {
        Double(PictureView.columnMinimum(picture: pictureSize, margin: pictureMargin))
    }

    /// The space the grid has (#415): the measured column's width, and the height left under the
    /// banner and the header. The header's height never depends on the deal (see `header`), so the
    /// first measure is the final one. Zero until both are measured.
    private var boardSize: CGSize {
        guard areaHeight > 0, headerSize.width > 0 else { return .zero }
        return CGSize(width: headerSize.width, height: max(0, areaHeight - headerSize.height - 24))
    }

    /// The round being played, or nil once the session ends. Body reads this
    /// instead of indexing the deal: a counter that runs one past the end used
    /// to crash here with "Index out of range" (#30).
    private var currentRound: CategoryDeal.Round? {
        session.indices.contains(progress.completedRounds) ? session[progress.completedRounds] : nil
    }

    var body: some View {
        VStack(spacing: 24) {
            // Everything above the grid, measured as one block so the grid knows how much room is left.
            VStack(spacing: 24) {
                LevelExplainBanner(
                    game: GameID.categoryFluency, hasStarted: totalPicks > 0 || progress.completedRounds > 0)
                header(currentRound)
            }
            .frame(maxWidth: .infinity)
            .onGeometryChange(for: CGSize.self) {
                $0.size
            } action: { size in
                headerSize = size
                dealForBoard()
            }

            if let round = currentRound {
                board(round)
                    .id(round.category)
                    .transition(reduceMotion ? .identity : .opacity)
            }
        }
        .gameColumn(maxWidth: 720)
        .padding(Self.edgePadding)
        .fitOrScroll()
        // Measured outside the padding and the fit-or-scroll, so it is the room the screen offers
        // and not the height of what is in it (as Sudoku does).
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onGeometryChange(for: CGFloat.self) {
            $0.size.height - 2 * Self.edgePadding
        } action: { height in
            areaHeight = height
            dealForBoard()
        }
        .gameHeader(
            .categoryFluency,
            instruction: AppLanguage.localized("game.category.instruction") + " " + (currentRound.map(name(of:)) ?? "")
        )
        .onAppear(perform: dealForBoard)
        .onDisappear { completionTask?.cancel() }
        .celebration(isPresented: $showCelebration, game: .categoryFluency, detail: finalDetail, onPlayAgain: restart)
    }

    /// The instruction, the category and the progress. It is drawn before a round exists, hidden, and
    /// its height never depends on which category is asked or on the completion beat, because the
    /// board is fitted to what is left under it: a header that grew after the deal would push the last
    /// row below the fold or deal the board a second time (#415).
    private func header(_ round: CategoryDeal.Round?) -> some View {
        let total = CategoryDeal.itemsPerCategory
        return VStack(spacing: 24) {
            Text(AppLanguage.localized("game.category.instruction"))
                .font(.title2)
                .multilineTextAlignment(.center)

            // Every name sits in the same slot, so the slot is as tall as the longest one wraps
            // in this language and at this text size; only the asked one is seen or heard.
            ZStack {
                ForEach(CategoryDeal.Category.allCases, id: \.self) { category in
                    let asked = category == round?.category
                    Text(AppLanguage.localized(category.nameKey))
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .opacity(asked ? 1 : 0)
                        .accessibilityHidden(!asked)
                        .accessibilityAddTraits(.isHeader)
                }
            }

            // The completion beat takes the place of the count for a second, so nothing moves.
            ProgressCards(
                done: round == nil ? 0 : found, total: total,
                words: round.flatMap { isShowingCompletionBeat ? complete(name(of: $0)) : nil }
                    ?? String(format: AppLanguage.localized("game.category.found %lld %lld"), found, total))
        }
        .opacity(round == nil ? 0 : 1)
        .accessibilityHidden(round == nil)
        .id(round?.category)
        .transition(reduceMotion ? .identity : .opacity)
        .onAppear { if let round { AccessibilityNotification.Announcement(name(of: round)).post() } }
    }

    private func complete(_ name: String) -> String {
        String(format: AppLanguage.localized("game.category.complete %@"), name)
    }

    /// The picture tiles of the round in play.
    private func board(_ round: CategoryDeal.Round) -> some View {
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
                // A decoy he has tried fades and cannot be tapped again, as in Quick Eyes (#415).
                .disabled(tile.isTried)
                .opacity(tile.isTried ? 0.35 : 1)
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
                .accessibilityHint(hint(for: tile))
            }
        }
    }

    /// What VoiceOver adds after a tile's name: found, tried, or where it sits.
    private func hint(for tile: Tile) -> String {
        if tile.isPicked { return AppLanguage.localized("game.category.a11y.picked") }
        if tile.isTried { return AppLanguage.localized("game.category.a11y.tried") }
        return String(
            format: AppLanguage.localized("game.category.a11y.position %lld %lld"),
            tilePositions[tile.id] ?? 0, tiles.count)
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

    /// Deals for the measured board (#415): on the first non-zero size, and again while nothing has been
    /// picked if the size changes how many decoys fit (the level note goes away, the phone turns). After
    /// a pick the board stays as dealt, so a game in progress is never thrown away.
    private func dealForBoard() {
        guard boardSize != .zero else { return }
        let decoys = CategoryDeal.fittedDecoyCount(for: difficulty, size: boardSize, tile: tileSide)
        guard
            CategoryDeal.shouldDeal(
                hasSession: !session.isEmpty, picks: totalPicks, dealt: dealtDecoys, fitted: decoys)
        else { return }
        // A new fit keeps the categories: the name stays and nothing is announced twice.
        setup(keeping: session.isEmpty ? nil : session.map(\.category))
    }

    private func setup(keeping categories: [CategoryDeal.Category]? = nil) {
        guard boardSize != .zero else { return }
        completionTask?.cancel()
        completionTask = nil
        isShowingCompletionBeat = false
        dealtDecoys = CategoryDeal.fittedDecoyCount(for: difficulty, size: boardSize, tile: tileSide)
        var generator = SystemRandomNumberGenerator()
        session = CategoryDeal.deal(
            difficulty: difficulty, size: boardSize, tile: tileSide, categories: categories, using: &generator)
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
        guard !isShowingCompletionBeat, let i = tiles.firstIndex(where: { $0.id == tileID }) else { return }
        let outcome = CategoryDeal.tapOutcome(
            belongs: tiles[i].belongs, isPicked: tiles[i].isPicked, isTried: tiles[i].isTried)
        guard outcome != .ignored else { return }
        totalPicks += 1
        guard outcome == .found else {
            tiles[i].isTried = true
            Feedback.play(.miss)
            missedTile = tileID
            // The tile fades (decoy: kind, quiet), and VoiceOver hears the tap registered.
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
