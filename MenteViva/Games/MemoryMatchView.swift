import SwiftData
import SwiftUI

/// Memory Lane: classic pair-matching on large cards.
/// Level = board size (3 to 12 pairs, #199). Fully offline, fully deterministic.
/// #43: themed boards rotate each game so visits stop feeling identical.
/// #109: "a game, but he's not a child" — grown-up themes, paper-like cards, a
/// calm card back, and a board sized to the screen (iPad and iPhone) so every
/// card is visible without scrolling. Found pairs keep a checkmark, not just a tint.
/// #110: family photos added in Set up become cards first; the theme's
/// emoji fill whatever pairs the photos don't cover.
/// #142: the `.captions` variant (Names and Faces) is the same board with each photo paired to
/// its caption instead of to a twin.
struct MemoryMatchView: View {
    /// Which game this board plays: Memory Lane, or Names and Faces.
    enum Variant {
        case classic, captions

        var game: GameID { self == .classic ? .memoryMatch : .photoCaptions }
        var instructionKey: String { self == .classic ? "game.memory.instruction" : "game.photocaptions.instruction" }
    }

    let variant: Variant

    init(variant: Variant = .classic) {
        self.variant = variant
        _difficulty = State(initialValue: Difficulty.stored(variant.game))
    }

    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private static let spacing: CGFloat = 12
    /// The app icon's jade card and cream frame (#384): the same in light and dark.
    private static let cardBack = Color(UIColor(rgb: 0x246456))
    private static let cardFrame = Color(UIColor(rgb: 0xFFF1D0))
    private static let cardInk = Color(UIColor(rgb: 0x2B2118))

    @State private var difficulty: Difficulty
    /// Names and Faces: the captioned photos a board can use, read again for each deal.
    @State private var captioned: [(photo: URL, caption: String)] = []
    @State private var faces: [MemoryFace] = []
    /// Decoded once per deal so flipping never re-reads the disk.
    @State private var photoImages: [URL: UIImage] = [:]

    @State private var cards: [Card] = []
    /// The board's size on screen; deals are capped to it so cards keep minimum size.
    @State private var boardSize = CGSize.zero
    /// Which cards are face up after each tap (#237); the view animates it.
    @State private var board = MemoryBoard(pairs: [])
    @State private var moves = 0
    @State private var startedAt = Date.now
    @State private var showCelebration = false
    @State private var finalDetail = ""
    @State private var cardPositions: [Int: Int] = [:]
    @State private var flipBackTask: Task<Void, Never>?

    struct Card: Identifiable {
        /// The card's index into the board; `MemoryBoard` taps by this id.
        let id: Int
        let face: MemoryFace
    }

    /// Pairs per level 1...10 (#199). Levels 2/4/6 keep the old easy/medium/hard
    /// boards (4/6/8 pairs) so migrated players notice nothing; every other
    /// step adds at most one pair, so a higher level never shows fewer cards.
    static let pairsPerLevel = [3, 4, 5, 6, 7, 8, 9, 10, 11, 12]

    /// Narrowest card the player taps (conventions §4); the cap below never
    /// lets a card under it.
    static let minCard = 60.0

    static func pairCount(for difficulty: Difficulty) -> Int {
        difficulty.values(pairsPerLevel)
    }

    /// Pairs actually dealt at `difficulty` in a board of `size`: the table
    /// value, capped down until `gridFit` keeps every card at its minimum.
    /// Never below level 1's board: on a space too small even for that (a
    /// first layout pass, an extreme split screen) a small real game beats a
    /// one-pair board, and the cards still shrink to fit.
    static func cappedPairs(for difficulty: Difficulty, in size: CGSize) -> Int {
        fittedPairs(wanted: pairCount(for: difficulty), floor: pairsPerLevel[0], in: size)
    }

    /// `wanted` pairs, taken down one at a time to no fewer than `floor` until every card fits.
    static func fittedPairs(wanted: Int, floor: Int, in size: CGSize) -> Int {
        var pairs = wanted
        while pairs > floor && !cardsFit(pairs: pairs, in: size) { pairs -= 1 }
        return pairs
    }

    /// The pairs this board deals in `size`; Names and Faces never asks for more than its photos give.
    private func pairs(in size: CGSize) -> Int {
        pairs(in: size, captioned: captioned)
    }

    private func pairs(in size: CGSize, captioned: [(photo: URL, caption: String)]) -> Int {
        switch variant {
        case .classic:
            return Self.cappedPairs(for: difficulty, in: size)
        case .captions:
            let available = PhotoCaptionDeal.eligible(captioned).count
            return Self.fittedPairs(
                wanted: min(PhotoCaptionDeal.pairCount(for: difficulty), available),
                floor: min(PhotoCaptionDeal.minPairs, available), in: size)
        }
    }

    /// Whether `pairs` pairs fit in `size` with every card at its minimum.
    static func cardsFit(pairs: Int, in size: CGSize) -> Bool {
        let fit = gridFit(count: pairs * 2, in: size, spacing: spacing)
        return min(fit.card.width, fit.card.height) >= minCard
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
            LevelExplainBanner(
                change: PlanStore.cachedPlan()?.changes[variant.game], game: variant.game, hasStarted: moves > 0)
            Text(AppLanguage.localized(variant.instructionKey))
                .font(.title2)
                .multilineTextAlignment(.center)

            GeometryReader { geometry in
                let fit = Self.gridFit(count: cards.count, in: geometry.size, spacing: Self.spacing)
                LazyVGrid(
                    columns: Array(
                        repeating: GridItem(.fixed(fit.card.width), spacing: Self.spacing),
                        count: fit.columns),
                    spacing: Self.spacing
                ) {
                    ForEach(cards) { card in
                        Button {
                            flip(card.id)
                        } label: {
                            face(card, size: fit.card)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(
                            isShown(card)
                                ? label(card.face)
                                : AppLanguage.localized("game.memory.card.hidden")
                        )
                        .accessibilityHint(
                            board.matched.contains(card.id)
                                ? AppLanguage.localized("game.memory.a11y.matched")
                                : String(
                                    format: AppLanguage.localized("game.memory.a11y.position %lld %lld"),
                                    cardPositions[card.id] ?? 0, cards.count))
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onAppear {
                    boardSize = geometry.size
                    if cards.isEmpty { deal(size: geometry.size) }
                }
                .onGeometryChange(for: CGSize.self) {
                    $0.size
                } action: { size in
                    guard size.width > 0, size.height > 0 else { return }
                    boardSize = size
                    // Re-deal for the real size only before the first move. After it the
                    // board can still grow (the level note above goes away) or turn with
                    // the phone; the cards already dealt just resize, so a game in
                    // progress is never thrown away.
                    if moves == 0, cards.count != pairs(in: size) * 2 {
                        deal(size: size)
                    }
                }
            }
        }
        .padding()
        .gameHeader(variant.game, instruction: AppLanguage.localized(variant.instructionKey))
        .onDisappear {
            flipBackTask?.cancel()
            flipBackTask = nil
        }
        .celebration(
            isPresented: $showCelebration, game: variant.game, detail: finalDetail,
            onPlayAgain: { deal(size: boardSize) })
    }

    /// A card turns over in 0.25 s, eased in and out, the face swapping at the
    /// halfway point; with Reduce Motion it cross-fades in 0.2 s instead.
    /// Face up: a paper card with the picture. Face down: the icon's jade back
    /// with its cream frame and amber disc. Matched pairs get a soft wash of the game's ink and the checkmark.
    private func face(_ card: Card, size: CGSize) -> some View {
        let shown = isShown(card)
        let found = board.matched.contains(card.id)
        // Both layers swap at the halfway point of the turn, when the card is
        // edge-on and invisible; Reduce Motion fades without turning.
        let swap: Animation =
            reduceMotion
            ? .easeInOut(duration: 0.2) : .easeInOut(duration: 0.12).delay(0.13)
        return ZStack {
            cardBack(size: size)
                .opacity(shown ? 0 : 1)
                .animation(swap, value: shown)
            cardFront(card: card, size: size, found: found)
                .opacity(shown ? 1 : 0)
                .animation(swap, value: shown)
        }
        .frame(width: size.width, height: size.height)
        .shadow(color: .black.opacity(0.25), radius: 0, x: 3, y: 3)
        .rotation3DEffect(
            .degrees(shown && !reduceMotion ? 180 : 0), axis: (x: 0, y: 1, z: 0)
        )
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: shown)
        // Non-color cue: matched pairs keep a checkmark (WCAG 1.4.1).
        .overlay(alignment: .topTrailing) {
            if found { CheckBadge() }
        }
        // Gentle bloom on the moment a pair is found.
        .scaleEffect(found && !reduceMotion ? 1.03 : 1)
        .animation(.spring(duration: 0.35), value: found)
    }

    private func isShown(_ card: Card) -> Bool {
        // A missed pair stays face up in `pendingMiss` until the timer or the
        // next tap turns it back; the board clears `faceUp` on a miss.
        board.faceUp.contains(card.id) || board.pendingMiss.contains(card.id)
            || board.matched.contains(card.id)
    }

    /// The app icon as a card back: jade, an inset cream frame, an amber disc
    /// ringed in espresso. Drawn in shapes, the same in light and dark.
    private func cardBack(size: CGSize) -> some View {
        let disc = min(size.width, size.height) * 0.34
        return ZStack {
            RoundedRectangle(cornerRadius: 18)
                .fill(Self.cardBack)
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Self.cardFrame, lineWidth: 3)
                .padding(8)
            Circle()
                .fill(Color.amber)
                .overlay(Circle().strokeBorder(Self.cardInk, lineWidth: 3))
                .frame(width: disc, height: disc)
        }
    }

    /// The paper front with the picture; pre-turned so it reads upright when
    /// the card has turned over, while it is still hidden mid-turn.
    private func cardFront(card: Card, size: CGSize, found: Bool) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18)
                .fill(
                    found
                        ? AnyShapeStyle(.tint.opacity(0.16)) : AnyShapeStyle(Color.paper))
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(Color.espresso, lineWidth: 2)
            if case .photo(let url) = card.face, let image = photoImages[url] {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size.width - 10, height: size.height - 10)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            } else if case .picture(let picture) = card.face {
                PictureView(picture: picture, size: min(size.width, size.height) * 0.5)
            } else if case .caption(let text) = card.face {
                Text(text)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.espresso)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.5)
                    .padding(8)
            }
        }
        .rotation3DEffect(
            .degrees(reduceMotion ? 0 : 180), axis: (x: 0, y: 1, z: 0))
    }

    private func deal(size: CGSize) {
        HotPath.measure("memory.deal") { dealCards(size: size) }
    }

    private func dealCards(size: CGSize) {
        difficulty = Difficulty.stored(variant.game)
        flipBackTask?.cancel()
        flipBackTask = nil
        var generator = SystemRandomNumberGenerator()
        // `cards` lie in order; `pairIDs` says which cards belong together (index-aligned).
        let layout: (faces: [MemoryFace], cards: [MemoryFace], pairIDs: [Int])
        switch variant {
        case .classic:
            let deal = MemoryDeal.make(
                photos: MemoryPhotos.all(), pairs: Self.cappedPairs(for: difficulty, in: size), using: &generator)
            // Each face occurs exactly twice, so its index in the deal's pairs is the identity both copies share.
            layout = (deal.faces, deal.order.map { deal.faces[$0] }, deal.order)
        case .captions:
            let list = MemoryPhotos.captioned()
            captioned = list
            let dealt = PhotoCaptionDeal.make(
                captioned: list, pairs: pairs(in: size, captioned: list), using: &generator)
            layout = (dealt.cards.filter { if case .photo = $0 { true } else { false } }, dealt.cards, dealt.pairIDs)
        }
        faces = layout.faces
        photoImages = Dictionary(
            uniqueKeysWithValues: faces.compactMap { face in
                guard case .photo(let url) = face, let image = UIImage(contentsOfFile: url.path) else { return nil }
                return (url, image)
            })
        // The board taps by card id.
        cards = layout.cards.enumerated().map { Card(id: $0, face: $1) }
        board.deal(pairs: layout.pairIDs)
        cardPositions = Dictionary(uniqueKeysWithValues: cards.indices.map { (cards[$0].id, $0 + 1) })
        moves = 0
        startedAt = .now
    }

    /// Pictures say their name in the app's language (#324); photos are
    /// numbered so a pair can still be matched by ear.
    private func label(_ face: MemoryFace) -> String {
        switch face {
        case .picture(let picture): AppLanguage.localized(picture.nameKey)
        case .photo:
            String(
                format: AppLanguage.localized("game.memory.photo %lld"),
                (faces.firstIndex(of: face) ?? 0) + 1)
        case .caption(let text): text
        }
    }

    private func flip(_ cardID: Int) {
        // Face-up and found cards ignore taps here rather than via .disabled,
        // so the system never greys out the pictures he needs to read.
        guard let index = cards.firstIndex(where: { $0.id == cardID }) else { return }
        switch board.tap(index) {
        case .ignored, .turnedUp:
            break
        case .matched:
            moves += 1
            Feedback.play(.success)
            if board.isComplete { finish() }
        case .missed:
            moves += 1
            Feedback.play(.miss)
            scheduleTurnBack()
        case .missedBackThenUp:
            // The missed pair turns back at once and only the new card turns
            // up; no timer is left behind.
            flipBackTask?.cancel()
            flipBackTask = nil
        }
    }

    /// One pending turn-back at a time: scheduling a new one cancels the old,
    /// and a stale timer can never touch a newer board (#237).
    private func scheduleTurnBack() {
        flipBackTask?.cancel()
        let generation = board.generation
        flipBackTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.2))
            guard !Task.isCancelled else { return }
            _ = board.resolveMiss(generation: generation)
        }
    }

    private func finish() {
        let elapsed = Int(Date.now.timeIntervalSince(startedAt))
        let score = Self.score(pairCount: faces.count, moves: moves)
        // Score stays in the model as a record of how the round went (#45); the
        // player sees progress, not points.
        modelContext.record(
            GameSession(
                gameID: variant.game, score: score,
                rounds: faces.count, durationSeconds: elapsed,
                correct: faces.count, attempts: moves,
                difficulty: difficulty))
        finalDetail = String(format: AppLanguage.localized("game.celebration.pairs %lld"), faces.count)
        showCelebration = true
    }
}

#Preview {
    MemoryMatchView()
}
