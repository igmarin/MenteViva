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

    /// Re-read on every deal, so "Play again" follows a level change.
    @State private var difficulty = Difficulty.stored(.slidingBlocks)
    /// The dealt puzzle's data (its `minMoves` is recorded as `correct`).
    @State private var data: SlidingBlocksLevels.PuzzleData?
    @State private var puzzle: SlidingBlocksPuzzle?
    /// The dealt layout, kept so "Start over" can restore it.
    @State private var initialBlocks: [SlidingBlock] = []
    @State private var selected: Int?
    @State private var dragged: Int?
    @State private var dragOffset = CGSize.zero
    /// The running drag's axis and reach, fixed on its first tick so a curved
    /// drag never flips between a horizontal and a vertical preview.
    @State private var dragLimits: DragLimits?
    /// The last slide, so a repeated one-cell arrow in the same direction
    /// extends it: a straight slide is one move however it is entered, the way
    /// `minMoves` counts it. Cleared by anything else that changes the board.
    @State private var lastSlide: SlidingMove?
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
    /// Today's level-change note, decided once when the screen opens and dropped
    /// on a replay. Held here, not re-read from the store, so the note keeps its
    /// place in the layout for the whole deal (`SlidingBoardLayout.NoteSlot`).
    @State private var explainKey = Self.pendingExplainKey()

    private var instruction: String { AppLanguage.localized("game.sliding.instruction") }

    var body: some View {
        VStack(spacing: 16) {
            explainNote
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
        // A block drag never scrolls the page, even in the scrolling layout (#470).
        .scrollDisabled(dragged != nil)
        .gameHeader(.slidingBlocks, instruction: instruction)
        .onAppear(perform: dealIfNeeded)
        .onDisappear { hintBuild?.cancel() }
        .celebration(isPresented: $showCelebration, game: .slidingBlocks, detail: finalDetail, onPlayAgain: deal)
    }

    // MARK: - Level note

    /// The key of today's level-change note if it should show on this open, else nil.
    /// Same rule as `LevelExplainBanner`, read once instead of on every redraw.
    private static func pendingExplainKey() -> String? {
        let change = PlanStore.cachedPlan()?.changes[GameID.slidingBlocks]
        let seen = LevelOfferStore.hasSeenExplain(for: GameID.slidingBlocks, today: PlanStore.dayStamp())
        guard LevelExplainPolicy.shouldShow(change: change, alreadySeenToday: seen) else { return nil }
        return LevelExplainPolicy.key(for: change)
    }

    /// The note, which fades out on the first move but keeps its height, so the
    /// board does not grow under the player's finger (#470).
    @ViewBuilder
    private var explainNote: some View {
        let slot = SlidingBoardLayout.NoteSlot.slot(
            hasNote: explainKey != nil, hasStarted: (puzzle?.movesMade ?? 0) > 0)
        if let explainKey, slot.takesSpace {
            LevelExplainLine(key: explainKey)
                .opacity(slot == .showing ? 1 : 0)
                .accessibilityHidden(slot != .showing)
                .onAppear {
                    LevelOfferStore.markExplainSeen(for: GameID.slidingBlocks, today: PlanStore.dayStamp())
                }
        }
    }

    // MARK: - Board

    private var board: some View {
        GeometryReader { proxy in
            if let puzzle {
                let cell = SlidingBoardLayout.cellSize(in: proxy.size, columns: puzzle.width, rows: puzzle.height)
                let boardWidth = cell * CGFloat(puzzle.width)
                let boardHeight = cell * CGFloat(puzzle.height)
                let legal = Self.directions(in: puzzle)
                ZStack(alignment: .topLeading) {
                    boardFrame(puzzle: puzzle, cell: cell)
                        .frame(width: boardWidth, height: boardHeight)
                    ForEach(puzzle.blocks.indices, id: \.self) { index in
                        blockView(index, puzzle: puzzle, cell: cell, directions: legal[index] ?? [])
                    }
                }
                .frame(width: boardWidth, height: boardHeight)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .accessibilityElement(children: .contain)
    }

    /// The board's edge with a gap where the big block leaves: the bottom edge
    /// at `exitX` (centred on 4-wide boards, left on 3-wide ones), marked with
    /// a chevron so the exit never relies on position alone.
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

    private func blockView(
        _ index: Int, puzzle: SlidingBlocksPuzzle, cell: CGFloat, directions: [SlidingDirection]
    ) -> some View {
        let block = puzzle.blocks[index]
        let isBig = index == puzzle.bigIndex
        let isSelected = selected == index
        return
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
            .contentShape(Rectangle())
            .frame(width: CGFloat(block.w) * cell, height: CGFloat(block.h) * cell)
            .offset(
                x: CGFloat(block.x) * cell + (dragged == index ? dragOffset.width : 0),
                y: CGFloat(block.y) * cell + (dragged == index ? dragOffset.height : 0)
            )
            .zIndex(dragged == index ? 2 : (isSelected ? 1 : 0))
            // The one place moves animate. Reduce Motion: moves land at once, with no slide (issue spec).
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: puzzle)
            // High priority, so the block's drag wins over the page's ScrollView; the
            // gesture also reads the tap, since a Button would race it.
            .highPriorityGesture(drag(for: index, cell: cell, puzzle: puzzle))
            .accessibilityLabel(blockLabel(index, puzzle: puzzle))
            .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
            .accessibilityAction { tap(index) }
            // VoiceOver moves the block straight, one cell at a time, and hears only
            // the directions that are legal right now (issue spec).
            .accessibilityActions {
                ForEach(directions, id: \.self) { direction in
                    Button(AppLanguage.localized("game.sliding.move.\(direction.rawValue)")) {
                        slide(index, direction)
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
            if let selected, let puzzle, selected < puzzle.blocks.count, !puzzle.isSolved {
                HStack(spacing: 12) {
                    ForEach(Self.directions(in: puzzle)[selected] ?? [], id: \.self) { direction in
                        Button {
                            slide(selected, direction)
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

    /// The directions each block can slide in right now, in a stable order,
    /// from one pass over the legal moves.
    private static func directions(in puzzle: SlidingBlocksPuzzle) -> [Int: [SlidingDirection]] {
        let legal = Dictionary(grouping: puzzle.moves(), by: \.block).mapValues { Set($0.map(\.direction)) }
        return legal.mapValues { directions in SlidingDirection.allCases.filter(directions.contains) }
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

    /// A touch on a block is a tap until it has gone clearly one way
    /// (`SlidingDragRule`); then the block follows the finger along that axis,
    /// clamped to the cells that are actually clear, and letting go snaps it to
    /// the nearest cell. The minimum distance is 0 so this gesture owns the
    /// touch from the start and the page's ScrollView never sees it.
    private func drag(for index: Int, cell: CGFloat, puzzle: SlidingBlocksPuzzle) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if dragLimits == nil {
                    guard let axis = SlidingDragRule.axis(for: value.translation) else { return }
                    dragLimits = DragLimits(block: index, in: puzzle, axis: axis)
                }
                guard let limits = dragLimits else { return }
                dragged = index
                dragOffset = limits.clamped(value.translation, cell: cell)
            }
            .onEnded { value in
                guard let limits = dragLimits else {
                    if SlidingDragRule.isTap(value.translation) { tap(index) }
                    return
                }
                let offset = limits.clamped(value.translation, cell: cell)
                dragLimits = nil
                dragged = nil
                dragOffset = .zero
                let distance = limits.horizontal ? offset.width : offset.height
                let steps = Int((abs(distance) / cell).rounded())
                guard steps > 0 else { return }
                let direction: SlidingDirection =
                    limits.horizontal ? (distance > 0 ? .right : .left) : (distance > 0 ? .down : .up)
                apply(SlidingMove(block: index, direction: direction, steps: steps))
            }
    }

    /// One cell toward `direction` (arrows and VoiceOver). Right after a slide
    /// of the same block the same way, it lengthens that slide instead, so
    /// these players count moves the way `minMoves` does and a perfect run
    /// still scores 100; Undo takes the whole slide back.
    private func slide(_ index: Int, _ direction: SlidingDirection) {
        if let last = lastSlide, last.block == index, last.direction == direction, var undone = puzzle, undone.undo() {
            let longer = SlidingMove(block: index, direction: direction, steps: last.steps + 1)
            if undone.applying(longer) != nil {
                apply(longer, from: undone)
                return
            }
        }
        apply(SlidingMove(block: index, direction: direction, steps: 1))
    }

    /// Plays `move` on `base` (the current board unless a slide is being
    /// lengthened). A solved board takes no more moves, so the session is
    /// recorded once.
    private func apply(_ move: SlidingMove, from base: SlidingBlocksPuzzle? = nil) {
        guard let solvedAlready = puzzle?.isSolved, !solvedAlready else { return }
        guard var current = base ?? puzzle, current.apply(move) else { return }
        puzzle = current
        lastSlide = move
        Feedback.play(.tap)
        if current.isSolved {
            selected = nil
            finish(solved: current)
        }
    }

    private func undo() {
        guard var current = puzzle, current.undo() else { return }
        puzzle = current
        lastSlide = nil
        selected = nil
        Feedback.play(.tap)
    }

    private func startOver() {
        guard var current = puzzle, current.movesMade > 0 else { return }
        current.reset(to: initialBlocks)
        puzzle = current
        lastSlide = nil
        selected = nil
        Feedback.play(.tap)
    }

    /// "Show me a move": the hint table's best next slide is played for the
    /// player, so it teaches by moving, not by pointing.
    private func showMove() {
        guard let current = puzzle, let map = hintMap, let move = map.hint(from: current) else { return }
        apply(move)
    }

    /// Deals on first appearance; coming back to a dealt puzzle restarts the
    /// hint build that leaving the screen cancelled.
    private func dealIfNeeded() {
        if let puzzle {
            if hintMap == nil { buildHints(from: puzzle) }
        } else {
            deal()
        }
    }

    private func deal() {
        difficulty = Difficulty.stored(.slidingBlocks)
        var generator = SystemRandomNumberGenerator()
        let next = SlidingBlocksLevels.puzzle(for: difficulty, using: &generator)
        data = next
        let fresh = next.puzzle
        puzzle = fresh
        initialBlocks = fresh.blocks
        selected = nil
        dragged = nil
        dragOffset = .zero
        dragLimits = nil
        lastSlide = nil
        startedAt = .now
        buildHints(from: fresh)
    }

    /// Builds the hint table for the dealt puzzle. Any position of it works:
    /// slides are reversible, so every position reaches the same set.
    private func buildHints(from start: SlidingBlocksPuzzle) {
        dealID += 1
        hintMap = nil
        hintBuild?.cancel()
        let deal = dealID
        // Detached so the board stays responsive; the search stops early when
        // this task is cancelled (re-deal or leaving the screen).
        let work = Task.detached(priority: .userInitiated) {
            SlidingBlocksMap(from: start) { Task.isCancelled }
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

    /// "big block, top middle, row 1, column 2": size, rough place and exact
    /// cell, so the board can be read by ear and no two blocks sound the same.
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
        // Top-left cell, 1-based: unique per block, unlike the 3×3 place.
        let cell = AppLanguage.localized(
            "game.sliding.place.cell \(block.y + 1) \(block.x + 1)" as String.LocalizationValue)
        return [AppLanguage.localized(sizeKey), placeLabel(for: block, in: puzzle), cell].joined(separator: ", ")
    }

    /// The board as a 3×3 grid of places ("top middle"); a block is placed by
    /// its centre, so the big block at the exit reads "bottom middle".
    private func placeLabel(for block: SlidingBlock, in puzzle: SlidingBlocksPuzzle) -> String {
        let column = min(2, (2 * block.x + block.w) * 3 / (2 * puzzle.width))
        let row = min(2, (2 * block.y + block.h) * 3 / (2 * puzzle.height))
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

/// A drag's axis and how far the block can go each way along it, in cells.
/// The axis is the one the finger led on when the drag started (`SlidingDragRule`),
/// fixed for the whole drag; a block that cannot move that way stays put.
private struct DragLimits {
    let horizontal: Bool
    let back: Int
    let forward: Int

    init(block index: Int, in puzzle: SlidingBlocksPuzzle, axis: SlidingDragRule.Axis) {
        var reach: [SlidingDirection: Int] = [:]
        for move in puzzle.moves() where move.block == index {
            reach[move.direction] = max(reach[move.direction] ?? 0, move.steps)
        }
        horizontal = axis == .horizontal
        back = reach[horizontal ? .left : .up] ?? 0
        forward = reach[horizontal ? .right : .down] ?? 0
    }

    /// The translation on this axis, limited to the cells the block can
    /// legally reach, so a drag never crosses a neighbour.
    func clamped(_ translation: CGSize, cell: CGFloat) -> CGSize {
        let distance = horizontal ? translation.width : translation.height
        let limited = min(max(distance, -CGFloat(back) * cell), CGFloat(forward) * cell)
        return horizontal ? CGSize(width: limited, height: 0) : CGSize(width: 0, height: limited)
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
