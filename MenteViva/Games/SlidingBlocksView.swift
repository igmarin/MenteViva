import SwiftData
import SwiftUI

/// Sliding Blocks: slide the blocks to free the big one through the gap at the
/// bottom (#223). Tap a block and only the arrows it can follow appear; a block
/// can also be dragged, and VoiceOver moves blocks through custom actions that
/// name the legal directions only. The rules live in `SlidingBlocksPuzzle`
/// (#222); this view owns taps, drags and drawing. No illegal move is ever
/// shown, so there is no failure copy, only movement. Fully offline.
struct SlidingBlocksView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var difficulty = Difficulty.stored(.slidingBlocks)
    /// The dealt puzzle's data (its `minMoves` is recorded as `correct`).
    @State private var data: SlidingBlocksLevels.PuzzleData?
    @State private var puzzle: SlidingBlocksPuzzle?
    /// The dealt layout, kept so "Start over" can restore it.
    @State private var initialBlocks: [SlidingBlock] = []
    @State private var selected: Int?
    @State private var dragged: Int?
    @State private var dragOffset = CGSize.zero
    /// Fewest-moves table for "Show me a move"; built off the main thread after
    /// each deal (about 0.3 s on a Mac for a 4×5 board).
    @State private var hintMap: SlidingBlocksMap?
    /// The running hint-table build: a new deal (or leaving the screen) cancels
    /// it, and the search itself stops early on cancellation.
    @State private var hintBuild: Task<SlidingBlocksMap, Never>?
    /// Guards the async hint-table build: a table is kept only for the deal that asked for it.
    @State private var dealID = 0
    @State private var startedAt = Date.now
    @State private var showCelebration = false
    @State private var finalDetail = ""

    private var instruction: String { AppLanguage.localized("game.sliding.instruction") }

    var body: some View {
        VStack(spacing: 16) {
            LevelExplainBanner(
                change: PlanStore.cachedPlan()?.changes[GameID.slidingBlocks], game: GameID.slidingBlocks,
                hasStarted: (puzzle?.movesMade ?? 0) > 0)
            Text(instruction)
                .font(.title2)
                .multilineTextAlignment(.center)

            board
                .frame(minHeight: 340)

            moveArrows

            controls
        }
        .padding()
        .fitOrScroll()
        .gameHeader(.slidingBlocks, instruction: instruction)
        .onAppear(perform: dealIfNeeded)
        .onDisappear { hintBuild?.cancel() }
        .celebration(isPresented: $showCelebration, game: .slidingBlocks, detail: finalDetail, onPlayAgain: deal)
    }

    // MARK: - Board

    private var board: some View {
        GeometryReader { proxy in
            if let puzzle {
                let cell = cellSize(for: puzzle, in: proxy.size)
                let boardWidth = cell * CGFloat(puzzle.width)
                let boardHeight = cell * CGFloat(puzzle.height)
                ZStack(alignment: .topLeading) {
                    boardFrame(puzzle: puzzle, cell: cell)
                        .frame(width: boardWidth, height: boardHeight)
                    ForEach(puzzle.blocks.indices, id: \.self) { index in
                        blockView(index, puzzle: puzzle, cell: cell)
                    }
                }
                .frame(width: boardWidth, height: boardHeight)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .accessibilityElement(children: .contain)
    }

    /// Biggest cell that keeps the whole board inside `size`. Every shipped
    /// board (≤4 wide, ≤5 tall) lands at 68pt or more on an iPhone, above the
    /// 60pt floor (conventions §4).
    private func cellSize(for puzzle: SlidingBlocksPuzzle, in size: CGSize) -> CGFloat {
        min(size.width / CGFloat(puzzle.width), size.height / CGFloat(puzzle.height))
    }

    /// The board's edge with a gap where the big block leaves: bottom centre,
    /// marked with a chevron so the exit never relies on position alone.
    private func boardFrame(puzzle: SlidingBlocksPuzzle, cell: CGFloat) -> some View {
        let gapX = CGFloat(puzzle.exitX) * cell
        let gapWidth = CGFloat(puzzle.bigBlock.w) * cell
        return Canvas { context, size in
            var frame = Path()
            frame.move(to: CGPoint(x: gapX, y: size.height))
            frame.addLine(to: CGPoint(x: 0, y: size.height))
            frame.addLine(to: CGPoint(x: 0, y: 0))
            frame.addLine(to: CGPoint(x: size.width, y: 0))
            frame.addLine(to: CGPoint(x: size.width, y: size.height))
            frame.addLine(to: CGPoint(x: gapX + gapWidth, y: size.height))
            context.stroke(frame, with: .color(Color.espresso), lineWidth: 4)
            var chevron = Path()
            let middle = gapX + gapWidth / 2
            chevron.move(to: CGPoint(x: middle - 14, y: size.height - 26))
            chevron.addLine(to: CGPoint(x: middle, y: size.height - 12))
            chevron.addLine(to: CGPoint(x: middle + 14, y: size.height - 26))
            context.stroke(
                chevron, with: .color(Color.amber), style: StrokeStyle(lineWidth: 4.5, lineCap: .round, lineJoin: .round))
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    // MARK: - Blocks

    private func blockView(_ index: Int, puzzle: SlidingBlocksPuzzle, cell: CGFloat) -> some View {
        let block = puzzle.blocks[index]
        let isBig = index == puzzle.bigIndex
        let isSelected = selected == index
        return Button {
            tap(index)
        } label: {
            RoundedRectangle(cornerRadius: 12)
                .fill(isBig ? Color.amber : GameID.slidingBlocks.ink)
                .overlay {
                    // Stripes on the big block: it is the goal by shape, not by colour alone (WCAG 1.4.1).
                    if isBig {
                        StripeOverlay()
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(
                            isSelected ? Color.espresso : Color.paper.opacity(0.9),
                            lineWidth: isSelected ? 6 : 2)
                }
                .shadow(color: .black.opacity(isSelected ? 0.35 : 0.18), radius: isSelected ? 8 : 3, y: 3)
                .padding(3)
        }
        .buttonStyle(.plain)
        .frame(width: CGFloat(block.w) * cell, height: CGFloat(block.h) * cell)
        .offset(
            x: CGFloat(block.x) * cell + (dragged == index ? dragOffset.width : 0),
            y: CGFloat(block.y) * cell + (dragged == index ? dragOffset.height : 0)
        )
        .zIndex(dragged == index ? 2 : (isSelected ? 1 : 0))
        // Reduce Motion: moves land at once, with no slide (issue spec).
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: puzzle)
        .simultaneousGesture(drag(for: index, cell: cell, puzzle: puzzle))
        .accessibilityLabel(blockLabel(index, puzzle: puzzle))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        // VoiceOver moves the block straight, one cell at a time, and hears only
        // the directions that are legal right now (issue spec).
        .accessibilityActions {
            ForEach(directions(for: index, in: puzzle), id: \.self) { direction in
                Button(AppLanguage.localized("game.sliding.move.\(direction.rawValue)")) {
                    apply(SlidingMove(block: index, direction: direction, steps: 1))
                }
            }
        }
    }

    /// One 100pt arrow tile per direction the selected block can slide; nothing
    /// for the directions it can't (issue spec). They sit in their own row
    /// under the board, never over another block (PR #348 review). Before
    /// anything is picked, the row says what to do, so its height never jumps.
    private var moveArrows: some View {
        Group {
            if let selected, let puzzle, selected < puzzle.blocks.count {
                HStack(spacing: 12) {
                    ForEach(directions(for: selected, in: puzzle), id: \.self) { direction in
                        Button {
                            apply(SlidingMove(block: selected, direction: direction, steps: 1))
                        } label: {
                            Image(systemName: direction.arrowSymbol)
                                .font(.title.weight(.bold))
                        }
                        .buttonStyle(AnswerTileStyle(minHeight: 100))
                        .accessibilityLabel(AppLanguage.localized("game.sliding.move.\(direction.rawValue)"))
                    }
                }
            } else {
                Text(AppLanguage.localized("game.sliding.tapblock"))
                    .font(.title2)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 100)
            }
        }
    }

    /// The directions `index` can slide in right now, in a stable order.
    private func directions(for index: Int, in puzzle: SlidingBlocksPuzzle) -> [SlidingDirection] {
        let legal = Set(puzzle.moves().filter { $0.block == index }.map(\.direction))
        return SlidingDirection.allCases.filter(legal.contains)
    }

    /// How far `index` can slide toward `direction`, in cells (0 = it can't).
    private func maxSteps(_ index: Int, _ direction: SlidingDirection, in puzzle: SlidingBlocksPuzzle) -> Int {
        puzzle.moves().filter { $0.block == index && $0.direction == direction }.map(\.steps).max() ?? 0
    }

    // MARK: - Controls

    private var controls: some View {
        HStack(spacing: 12) {
            controlButton("game.sliding.undo", enabled: !(puzzle?.history.isEmpty ?? true), action: undo)
            controlButton("game.sliding.restart", enabled: (puzzle?.movesMade ?? 0) > 0, action: startOver)
            controlButton(
                "game.sliding.hint", enabled: hintMap != nil && !(puzzle?.isSolved ?? true), action: showMove)
        }
    }

    private func controlButton(_ key: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(AppLanguage.localized(key))
                .font(.title2.weight(.semibold))
        }
        .buttonStyle(AnswerTileStyle(minHeight: 100))
        .disabled(!enabled)
    }

    // MARK: - Play

    private func tap(_ index: Int) {
        selected = selected == index ? nil : index
        Feedback.play(.tap)
    }

    /// A drag moves the block along its freer axis, clamped to the cells that
    /// are actually clear; letting go snaps it to the nearest cell.
    private func drag(for index: Int, cell: CGFloat, puzzle: SlidingBlocksPuzzle) -> some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { value in
                dragged = index
                dragOffset = clamped(value.translation, block: index, cell: cell, puzzle: puzzle)
            }
            .onEnded { value in
                let offset = clamped(value.translation, block: index, cell: cell, puzzle: puzzle)
                dragged = nil
                dragOffset = .zero
                if offset.width != 0 {
                    let steps = Int((abs(offset.width) / cell).rounded())
                    if steps > 0 {
                        apply(SlidingMove(block: index, direction: offset.width > 0 ? .right : .left, steps: steps))
                    }
                } else if offset.height != 0 {
                    let steps = Int((abs(offset.height) / cell).rounded())
                    if steps > 0 {
                        apply(SlidingMove(block: index, direction: offset.height > 0 ? .down : .up, steps: steps))
                    }
                }
            }
    }

    /// The translation limited to the dominant axis and to the cells the block
    /// can legally reach, so a drag never crosses a neighbour.
    private func clamped(
        _ translation: CGSize, block index: Int, cell: CGFloat, puzzle: SlidingBlocksPuzzle
    ) -> CGSize {
        if abs(translation.width) >= abs(translation.height) {
            let low = -CGFloat(maxSteps(index, .left, in: puzzle)) * cell
            let high = CGFloat(maxSteps(index, .right, in: puzzle)) * cell
            return CGSize(width: min(max(translation.width, low), high), height: 0)
        }
        let low = -CGFloat(maxSteps(index, .up, in: puzzle)) * cell
        let high = CGFloat(maxSteps(index, .down, in: puzzle)) * cell
        return CGSize(width: 0, height: min(max(translation.height, low), high))
    }

    private func apply(_ move: SlidingMove) {
        guard var current = puzzle, current.apply(move) else { return }
        if reduceMotion {
            puzzle = current
        } else {
            withAnimation(.easeInOut(duration: 0.25)) { puzzle = current }
        }
        Feedback.play(.tap)
        if current.isSolved { finish(solved: current) }
    }

    private func undo() {
        guard var current = puzzle, current.undo() else { return }
        if reduceMotion {
            puzzle = current
        } else {
            withAnimation(.easeInOut(duration: 0.25)) { puzzle = current }
        }
        selected = nil
        Feedback.play(.tap)
    }

    private func startOver() {
        guard var current = puzzle, current.movesMade > 0 else { return }
        current.reset(to: initialBlocks)
        if reduceMotion {
            puzzle = current
        } else {
            withAnimation(.easeInOut(duration: 0.25)) { puzzle = current }
        }
        selected = nil
        Feedback.play(.tap)
    }

    /// "Show me a move": the hint table's best next slide is played for the
    /// player, so it teaches by moving, not by pointing.
    private func showMove() {
        guard let current = puzzle, let map = hintMap, let move = map.hint(from: current) else { return }
        apply(move)
    }

    private func dealIfNeeded() {
        if puzzle == nil { deal() }
    }

    private func deal() {
        var generator = SystemRandomNumberGenerator()
        let next = SlidingBlocksLevels.puzzle(for: difficulty, using: &generator)
        data = next
        let fresh = next.puzzle
        puzzle = fresh
        initialBlocks = fresh.blocks
        selected = nil
        dragged = nil
        dragOffset = .zero
        startedAt = .now
        dealID += 1
        hintMap = nil
        hintBuild?.cancel()
        let deal = dealID
        // Detached so the board stays responsive; the search stops early when
        // this task is cancelled (re-deal or leaving the screen).
        let work = Task.detached(priority: .userInitiated) {
            SlidingBlocksMap(from: fresh) { Task.isCancelled }
        }
        hintBuild = work
        Task { @MainActor in
            let map = await work.value
            // A cancelled or superseded build holds a partial table: drop it.
            guard !work.isCancelled, dealID == deal else { return }
            hintMap = map
        }
    }

    /// The big block is out: record the session with its level (issue spec),
    /// then the shared celebration says it warmly.
    private func finish(solved: SlidingBlocksPuzzle) {
        let elapsed = Int(Date.now.timeIntervalSince(startedAt))
        let best = data?.minMoves ?? solved.movesMade
        modelContext.record(
            GameSession(
                gameID: .slidingBlocks, score: Self.score(minMoves: best, moves: solved.movesMade),
                rounds: 1, durationSeconds: elapsed,
                correct: best, attempts: solved.movesMade, difficulty: difficulty))
        finalDetail = AppLanguage.localized("game.sliding.out")
        if CaptionSpeaker.autoSpeaks() { CaptionSpeaker.speak(finalDetail) }
        AccessibilityNotification.Announcement(finalDetail).post()
        showCelebration = true
    }

    /// Progress, never points (#45): a clean run is 100, each slide beyond the
    /// puzzle's fewest costs 5, floored at 10. Stored, never shown.
    static func score(minMoves: Int, moves: Int) -> Int {
        max(10, 100 - max(0, moves - minMoves) * 5)
    }

    // MARK: - VoiceOver names

    /// "big block, top middle": size and place, so the board can be read by ear.
    private func blockLabel(_ index: Int, puzzle: SlidingBlocksPuzzle) -> String {
        let block = puzzle.blocks[index]
        let sizeKey: String
        if index == puzzle.bigIndex {
            sizeKey = "game.sliding.block.big"
        } else if block.w == 2 {
            sizeKey = "game.sliding.block.wide"
        } else if block.h == 2 {
            sizeKey = "game.sliding.block.tall"
        } else {
            sizeKey = "game.sliding.block.small"
        }
        return AppLanguage.localized(sizeKey) + ", " + placeLabel(for: block, in: puzzle)
    }

    /// The board as a 3×3 grid of places ("top middle"); a block is placed by
    /// its top-left cell, which is where its slide starts.
    private func placeLabel(for block: SlidingBlock, in puzzle: SlidingBlocksPuzzle) -> String {
        let column = min(2, block.x * 3 / puzzle.width)
        let row = min(2, block.y * 3 / puzzle.height)
        let key: String
        switch (row, column) {
        case (0, 0): key = "game.sliding.place.topleft"
        case (0, 1): key = "game.sliding.place.topmiddle"
        case (0, 2): key = "game.sliding.place.topright"
        case (1, 0): key = "game.sliding.place.middleleft"
        case (1, 1): key = "game.sliding.place.middle"
        case (1, 2): key = "game.sliding.place.middleright"
        case (2, 0): key = "game.sliding.place.bottomleft"
        case (2, 1): key = "game.sliding.place.bottommiddle"
        default: key = "game.sliding.place.bottomright"
        }
        return AppLanguage.localized(key)
    }
}

extension SlidingDirection {
    /// The SF Symbol for this direction's arrow button.
    fileprivate var arrowSymbol: String {
        switch self {
        case .left: "arrow.left"
        case .right: "arrow.right"
        case .up: "arrow.up"
        case .down: "arrow.down"
        }
    }
}

/// Diagonal stripes for the big block, so "the goal block" never rests on colour alone.
private struct StripeOverlay: View {
    var body: some View {
        Canvas { context, size in
            let step: CGFloat = 12
            var path = Path()
            for x in stride(from: -size.height, through: size.width + size.height, by: step) {
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x + size.height, y: size.height))
            }
            context.stroke(path, with: .color(Color.espresso.opacity(0.25)), lineWidth: 2.5)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

#Preview {
    SlidingBlocksView()
}
