import CoreGraphics
import SwiftData
import SwiftUI

/// Tangram: fill the silhouette with the seven tiles (#219). Tap a tray tile, then tap where it
/// goes; a tray tile can also be dragged onto the board, and VoiceOver places tiles through custom
/// actions that name each slot. The rules live in `TangramPuzzle`; this view owns taps, drags and
/// drawing. A tile that doesn't fit goes back to the tray with a warm hint. Fully offline.
struct TangramView: View {
    @Environment(\.modelContext) private var modelContext

    /// The screen's coordinate space: a tray drag ends in it, so the drop reads as a board point.
    private static let space = "tangram.table"

    @State private var difficulty = Difficulty.stored(.tangram)
    /// Whether the first shape was dealt: the seen ids live in UserDefaults now (#416).
    @State private var dealt = false
    @State private var puzzle = TangramPuzzle(
        shape: TangramShapes.all[0], rules: TangramPuzzle.rules(for: Difficulty.stored(.tangram)))
    /// The turn and mirror the player gave each tray tile, keyed by the slot it was dealt for.
    @State private var turns: [Int: TangramPlacement] = [:]
    @State private var selected: Int?
    /// The grid tile under a finger and how far it has moved. A `GestureState`, so a drag the system
    /// cancels (Control Center, an alert, a resize) drops back to nil with no `onEnded` needed (#481).
    @GestureState private var grab: TrayGrab?
    @State private var boardFrame = CGRect.zero
    /// Each grid tray cell where it rests, in the table's space: a drop lands at the tile's middle.
    @State private var trayFrames: [Int: CGRect] = [:]
    @State private var hint: String?
    @State private var missed = false
    @State private var startedAt = Date.now
    @State private var showCelebration = false
    @State private var finalDetail = ""
    /// The beat between the whole figure and the celebration (#415); cancelled on leaving and on a deal.
    @State private var finishTask: Task<Void, Never>?
    /// The space the game gets, measured: it picks the layout (`TangramLayout`).
    @State private var area = CGSize.zero
    @Environment(\.dynamicTypeSize) private var typeSize
    /// Held here, above `fitOrScroll`: turning the phone can swap its fitting copy of the table for
    /// the scrolling one (or back), and a banner built afresh would lose today's note (#481).
    @State private var noteMemo = LevelExplainBanner.Memo()
    /// The tray cell's side, settled from the measured board so tiles and figure share one scale (#511).
    @State private var traySide = TangramLayout.cell

    private var shape: TangramShape { puzzle.shape }
    private var rules: TangramRules { puzzle.rules }
    private var layout: TangramLayout { TangramLayout.choose(for: area) }
    private var figure: CGSize { TangramPuzzle.boundingBox(of: shape).size }
    /// The tiles dealt to the tray this round: the grid keeps room for all of them as they go home.
    private var dealtTiles: Int { shape.placements.count - rules.prefill }
    /// Points per unit for the tray, and for the figure too when stacked: a tile is the size of its slot (#511).
    private var pieceScale: CGFloat {
        TangramLayout.pieceScale(board: boardFrame.size, tray: traySide, figure: figure)
    }

    var body: some View {
        measuredTable
            .padding(.horizontal, TangramLayout.padding)
            .padding(.vertical, layout == .sideBySide ? TangramLayout.cellGap / 2 : TangramLayout.padding)
            .coordinateSpace(.named(Self.space))
            .fitOrScroll()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onGeometryChange(for: CGSize.self) {
                $0.size
            } action: {
                area = $0
                // The board may report before the new area does; settle again for the new layout.
                settleTray()
            }
            // A whole figure is recorded already, so leaving in the beat before the cover never asks.
            .gameHeader(
                .tangram, instruction: AppLanguage.localized("game.tangram.instruction"),
                inProgress: puzzle.attempts > 0 || !turns.isEmpty,
                celebrating: showCelebration || puzzle.isComplete
            )
            .firstPlayGuide(
                .tangram, line: AppLanguage.localized("game.tangram.guide"),
                example: AppLanguage.localized("guide.tangram.example")
            )
            // Not when the celebration closes: Play again has dealt already (#415).
            .onAppear { if !dealt { deal() } }
            .onDisappear {
                CaptionSpeaker.stop()
                finishTask?.cancel()
                finishTask = nil
            }
            .celebration(isPresented: $showCelebration, game: .tangram, detail: finalDetail, onPlayAgain: deal)
    }

    /// Nothing until the space is measured: the first frame has no size, and drawing it would pick
    /// a layout from nothing and then swap it (#481).
    @ViewBuilder private var measuredTable: some View {
        if area.width > 0, area.height > 0 { table }
    }

    /// Stacked on an iPad or an upright iPhone; on an iPhone on its side the board takes the left
    /// half and the rest stands beside it, since the stack is taller than the screen there. The
    /// buttons sit under the tray, so the tiles come right after the figure they fill (#511). Side by
    /// side the gaps and the top and bottom padding are halved: an iPhone SE on its side leaves
    /// about 300pt, and the hint, buttons and tray need 272pt of it. One `AnyLayout` holds the same
    /// two groups either way, so the level note keeps its place in the tree (and its memo) when the
    /// phone turns; two separate branches built it afresh and the note vanished (#481).
    private var table: some View {
        let gap = TangramLayout.partGap
        let sideBySide = layout == .sideBySide
        let arrangement = sideBySide ? AnyLayout(HStackLayout(spacing: gap)) : AnyLayout(VStackLayout(spacing: gap))
        return arrangement {
            VStack(spacing: sideBySide ? gap / 2 : gap) {
                banner
                instruction
                boardArea
            }
            VStack(spacing: sideBySide ? TangramLayout.cellGap / 1.5 : gap) {
                hintLine
                tray
                controls
            }
        }
    }

    private var banner: some View {
        LevelExplainBanner(
            game: GameID.tangram, hasStarted: puzzle.attempts > 0, keepsSpace: true, sharedMemo: noteMemo)
    }

    private var instruction: some View {
        Text(AppLanguage.localized("game.tangram.instruction"))
            .font(.title2)
            .multilineTextAlignment(.center)
    }

    /// The hint's two lines are kept even while it is empty, so a miss never makes the page taller:
    /// on a small iPhone that pushed the page into scrolling and sent the tray back to its first tile.
    /// Never squeezed to one line either: the board's measured height sizes the tray (#511), and a
    /// squeezed hint let the tray grow by a line that the page then had to scroll for.
    private var hintLine: some View {
        ZStack {
            Text(verbatim: " \n ").hidden()
            if let hint { Text(hint) }
        }
        .font(.title2)
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Board

    private var boardArea: some View {
        GeometryReader { geometry in
            board(size: geometry.size)
        }
        .frame(minHeight: TangramLayout.boardMinimum)
        .onGeometryChange(for: CGRect.self) {
            $0.frame(in: .named(Self.space))
        } action: { frame in
            boardFrame = frame
            settleTray()
        }
        .modifier(MissCue(active: $missed))
    }

    /// Resizes the tray cells for the board just measured; the board then grows or shrinks by as
    /// much and is measured again, and that pass asks for the same side (`TangramLayout.traySide`).
    private func settleTray() {
        guard boardFrame.width > 0 else { return }
        let side = layout.traySide(board: boardFrame.size, tray: traySide, figure: figure, tiles: dealtTiles)
        if abs(side - traySide) >= 1 { traySide = side }
    }

    /// The board's transform, held to the tray's scale when stacked so a placed tile matches its tray tile.
    private func boardFit(_ size: CGSize) -> (scale: CGFloat, origin: CGPoint) {
        TangramPuzzle.fitTransform(
            box: TangramPuzzle.boundingBox(of: shape), in: size, maxScale: layout.boardCap(tray: traySide))
    }

    /// The silhouette and the slots already home. A free slot shows its own outline while the
    /// level gives it; a filled one is drawn solid with a dark edge. One tap handler reads the point.
    private func board(size: CGSize) -> some View {
        let fit = boardFit(size)
        return ZStack {
            ForEach(shape.placements.indices, id: \.self) { slot in
                slotView(slot, scale: fit.scale, origin: fit.origin)
            }
        }
        .frame(width: size.width, height: size.height)
        .contentShape(Rectangle())
        .onTapGesture { point in
            tapBoard(at: TangramPuzzle.fromScreen(point, scale: fit.scale, origin: fit.origin), boardSize: size)
        }
        // A sliding tray's tiles arrive by system drag (see `withDrag`), carrying their slot. Only a
        // tile that went home counts as dropped. After a miss it stays in the tray with the hint;
        // how the system draws the preview then (it may fade where it was dropped) is not ours.
        .dropDestination(for: String.self) { items, point in
            guard let slot = items.first.flatMap({ Int($0) }), puzzle.freeSlots.contains(slot) else { return false }
            let result = place(
                slot, at: TangramPuzzle.fromScreen(point, scale: fit.scale, origin: fit.origin), boardSize: size)
            if case .snapped = result { return true }
            return false
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            AppLanguage.localized(puzzle.isComplete ? shape.key : "game.tangram.instruction"))
    }

    private func slotView(_ slot: Int, scale: CGFloat, origin: CGPoint) -> some View {
        let path = Self.path(shape.placements[slot], scale: scale, origin: origin)
        let isFilled = puzzle.filled.contains(slot)
        let ink = GameID.tangram.ink
        let edge = isFilled ? Color.primary.opacity(0.6) : ink.opacity(puzzle.showsOutline(slot) ? 0.8 : 0)
        return
            path
            .fill(ink.opacity(isFilled ? 0.6 : 0.14))
            .overlay { path.stroke(edge, lineWidth: 2) }
    }

    private static func path(_ placement: TangramPlacement, scale: CGFloat, origin: CGPoint) -> Path {
        var path = Path()
        path.addLines(
            TangramPiece.placedCorners(
                placement.piece, position: placement.position,
                rotation: placement.rotation, flipped: placement.flipped
            ).map { TangramPuzzle.toScreen($0, scale: scale, origin: origin) })
        path.closeSubpath()
        return path
    }

    // MARK: - Controls

    /// Turn from level 7, Flip from level 9, "Show me one" at every level; all 100pt. "Show me one"
    /// is the quiet one, last and outlined with no fill (#511): it helps, it isn't the game.
    /// At accessibility text sizes the buttons stack, one to a row: three side by side leave a word
    /// about 80pt, and "Muéstrame" at that size would be cut to "Muést…" (#481).
    private var controls: some View {
        let spacing: CGFloat = layout == .sideBySide ? 8 : 12
        let arrangement =
            typeSize.isAccessibilitySize ? AnyLayout(VStackLayout(spacing: spacing)) : AnyLayout(HStackLayout(spacing: spacing))
        return arrangement {
            if rules.matchRotation {
                controlButton("game.tangram.turn", enabled: selected != nil) { adjustSelected(TangramPuzzle.turned) }
            }
            if rules.matchFlip {
                controlButton("game.tangram.flip", enabled: selected != nil) { adjustSelected(TangramPuzzle.mirrored) }
            }
            showOneButton
        }
    }

    private var showOneButton: some View {
        let title = AppLanguage.localized("game.tangram.showone")
        return Button(action: showOne) {
            controlLabel(title, weight: .regular)
        }
        .buttonStyle(QuietTileStyle())
        .accessibilityLabel(title)
        .disabled(puzzle.isComplete)
    }

    private func controlButton(_ key: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        let title = AppLanguage.localized(key)
        return Button(action: action) {
            controlLabel(title)
        }
        .buttonStyle(AnswerTileStyle(minHeight: 100))
        .accessibilityLabel(title)
        .disabled(!enabled)
    }

    /// One line when the button is wide enough. Otherwise one word to a line, and the whole label
    /// steps down a size together until the longest word fits: side by side at levels 9-10 three
    /// buttons share about 300pt, and a plain two-line label broke "Muéstrame" mid-word with a
    /// hyphen, which `minimumScaleFactor` does not prevent (#481). The last step may still shrink.
    private func controlLabel(_ title: String, weight: Font.Weight = .semibold) -> some View {
        let words = title.split(separator: " ").map(String.init)
        return ViewThatFits(in: .horizontal) {
            Text(title).font(.title2.weight(weight)).lineLimit(1)
            wordStack(words, font: .title2.weight(weight))
            wordStack(words, font: .title3.weight(weight))
            wordStack(words, font: .headline.weight(weight)).minimumScaleFactor(0.5)
        }
    }

    private func wordStack(_ words: [String], font: Font) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(words.enumerated()), id: \.offset) { _, word in
                Text(word).lineLimit(1)
            }
        }
        .font(font)
        // Keeps the word off the button's edge.
        .padding(.horizontal, 8)
    }

    // MARK: - Tray

    /// One square cell per tile still to place, at least 100pt and as big as the shared scale needs
    /// (#511): the tiles are drawn at the figure's own scale. Tapping selects (a thick edge, not colour, marks it);
    /// dragging drops it on the board; VoiceOver lists the slots it fits as actions. Where there is
    /// room (a full-screen iPad) the cells wrap in a grid. Elsewhere they sit in one row that
    /// scrolls sideways (#396): two or three wrapped rows pushed the whole page into scrolling. At
    /// 12pt apart a fourth tile peeks in at the edge, so there is plainly more; VoiceOver reads the
    /// tiles in the same order.
    @ViewBuilder private var tray: some View {
        let gap = TangramLayout.cellGap
        if layout.traySlides {
            ScrollView(.horizontal) {
                LazyHStack(spacing: gap) { trayTiles }
            }
            .frame(height: traySide)
            .scrollIndicators(.visible)
        } else {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: traySide), spacing: gap)], spacing: gap) {
                trayTiles
            }
            // The dealt rows stay, so the board keeps its scale as the tiles go home. No reserve until
            // the board is measured: at width 0 it would be one column of seven, squeezing the board.
            .frame(
                minHeight: boardFrame.width > 0
                    ? TangramLayout.gridHeight(side: traySide, width: boardFrame.width, tiles: dealtTiles) : 0,
                alignment: .top)
        }
    }

    private var trayTiles: some View {
        let scale = Double(pieceScale)
        return ForEach(puzzle.freeSlots, id: \.self) { slot in
            trayTile(slot, scale: scale)
        }
    }

    private func trayTile(_ slot: Int, scale: Double) -> some View {
        let tile = orientation(of: slot)
        let isSelected = selected == slot
        let button = Button {
            selected = isSelected ? nil : slot
            hint = nil
        } label: {
            Self.drawing(of: tile, scale: scale, cell: traySide)
                .frame(width: traySide, height: traySide)
                .background(Color.paper, in: .rect(cornerRadius: 16))
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(
                            isSelected ? GameID.tangram.ink : Color.secondary.opacity(0.4),
                            lineWidth: isSelected ? 6 : 2)
                }
        }
        .buttonStyle(.plain)
        return withDrag(button, slot: slot, preview: Self.drawing(of: tile, scale: scale, cell: traySide))
            .guideTarget(slot == puzzle.freeSlots.first)
            .accessibilityLabel(AppLanguage.localized(tile.piece.nameKey))
            .accessibilityAddTraits(isSelected ? .isSelected : [])
            .accessibilityActions {
                ForEach(puzzle.fittingSlots(for: tile.piece), id: \.self) { target in
                    Button(slotActionName(target)) { placeByName(slot, into: target) }
                }
            }
    }

    /// One drag path per tray. A sliding row hands its tile to the system drag, which lifts it after
    /// a press and leaves swipes to the scroll: any SwiftUI gesture on a tile, even one that waited
    /// for a hold, took every swipe and the row never scrolled (#396). The grid doesn't scroll, so
    /// its tile follows the finger and drops where the tile's middle is when the drag ends (#415).
    @ViewBuilder private func withDrag(_ tile: some View, slot: Int, preview: some View) -> some View {
        if layout.traySlides {
            tile.draggable(String(slot)) { preview.frame(width: traySide, height: traySide) }
        } else {
            tile
                .offset(grab?.slot == slot ? grab?.offset ?? .zero : .zero)
                .zIndex(grab?.slot == slot ? 1 : 0)
                // Read outside the offset, so this is the cell, not where the tile is being carried.
                .onGeometryChange(for: CGRect.self) {
                    $0.frame(in: .named(Self.space))
                } action: { frame in
                    trayFrames[slot] = frame
                }
                .simultaneousGesture(
                    DragGesture(minimumDistance: 10, coordinateSpace: .named(Self.space))
                        .updating($grab) { value, state, _ in
                            state = TrayGrab(slot: slot, offset: value.translation)
                        }
                        .onEnded { value in
                            let cell = trayFrames[slot]
                            drop(
                                slot,
                                at: cell.map { TangramPuzzle.dropPoint(cell: $0, translation: value.translation) }
                                    ?? value.location)
                        })
        }
    }

    /// A tray tile drawn turned and mirrored as it is now, at the figure's scale, in a `cell`-point square.
    private static func drawing(of tile: TangramPlacement, scale: Double, cell: CGFloat) -> some View {
        var path = Path()
        path.addLines(TangramPuzzle.trayPoints(of: tile, scale: scale, cell: Double(cell)))
        path.closeSubpath()
        return path.fill(GameID.tangram.ink.opacity(0.55))
    }

    // MARK: - Play

    /// A tray tile's current turn: what the player set, else the slot's own turn while the level
    /// turns tiles for the player, else unturned, so from level 7 turning is part of the puzzle.
    private func orientation(of slot: Int) -> TangramPlacement {
        if let turn = turns[slot] { return turn }
        let target = shape.placements[slot]
        return rules.matchRotation
            ? TangramPlacement(piece: target.piece, position: .zero, rotation: 0, flipped: false)
            : TangramPlacement(piece: target.piece, position: .zero, rotation: target.rotation, flipped: target.flipped)
    }

    private func adjustSelected(_ change: (TangramPlacement) -> TangramPlacement) {
        guard let slot = selected else { return }
        turns[slot] = change(orientation(of: slot))
    }

    private func tapBoard(at point: CGPoint, boardSize: CGSize) {
        // The finished figure stays up for a beat before the celebration; a tap on it asks for nothing.
        guard !puzzle.isComplete else { return }
        guard let slot = selected else {
            say(AppLanguage.localized("game.tangram.a11y.pickfirst"))
            return
        }
        place(slot, at: point, boardSize: boardSize)
    }

    /// A drag that ends over the board places the tile there; anywhere else it just goes back.
    private func drop(_ slot: Int, at location: CGPoint) {
        guard boardFrame.contains(location) else { return }
        let local = CGPoint(x: location.x - boardFrame.minX, y: location.y - boardFrame.minY)
        let fit = boardFit(boardFrame.size)
        place(slot, at: TangramPuzzle.fromScreen(local, scale: fit.scale, origin: fit.origin), boardSize: boardFrame.size)
    }

    /// Every slot takes a tap or drop within 30pt of its middle on a board of `boardSize`, a 60pt
    /// target (#396, #481): on an iPhone board a tile's own share of reach is under 30pt. On an
    /// iPad-sized board the share is usually wider already and stays as it was.
    @discardableResult
    private func place(_ slot: Int, at point: CGPoint, boardSize: CGSize) -> TangramPlaceResult {
        let tile = orientation(of: slot)
        let result = puzzle.place(
            tile.piece, at: point, rotation: tile.rotation, flipped: tile.flipped,
            minimumReach: TangramPuzzle.reachFloor(
                points: 30, shape: shape, in: boardSize,
                maxScale: layout.boardCap(tray: traySide)))
        respond(to: result, from: slot)
        return result
    }

    private func placeByName(_ slot: Int, into target: Int) {
        respond(to: puzzle.place(orientation(of: slot).piece, inSlot: target), from: slot)
    }

    /// Home: a happy sound, and the round ends when the figure is whole. Otherwise one warm line on
    /// what to try next, and the tile stays in the tray.
    private func respond(to result: TangramPlaceResult, from slot: Int) {
        switch result {
        case .snapped(let home):
            // A twin went into the other twin's slot: the tile left in the tray keeps that twin's turn.
            if home != slot { turns[slot] = turns[home] }
            turns[home] = nil
            selected = nil
            say(nil)
            Feedback.play(.success)
            if puzzle.isComplete { finish() }
        case .turnIt: miss("game.tangram.miss.turn")
        case .flipIt: miss("game.tangram.miss.flip")
        case .tryAnotherSpot: miss("game.tangram.miss.spot")
        }
    }

    private func miss(_ key: String) {
        missed = true
        say(AppLanguage.localized(key))
        Feedback.play(.miss)
    }

    /// Shows a hint under the board and reads it to VoiceOver; nil clears it.
    private func say(_ line: String?) {
        hint = line
        if let line { AccessibilityNotification.Announcement(line).post() }
    }

    /// "Show me one": the first free slot fills itself, at every level.
    private func showOne() {
        guard let slot = puzzle.showOne() else { return }
        if selected == slot { selected = nil }
        turns[slot] = nil
        say(nil)
        Feedback.play(.success)
        if puzzle.isComplete { finish() }
    }

    private func slotActionName(_ slot: Int) -> String {
        let region = TangramPuzzle.slot(of: shape.placements[slot], in: shape).keySuffix
        return String(
            format: AppLanguage.localized("game.tangram.a11y.place %@"),
            AppLanguage.localized("game.tangram.slot.\(region)"))
    }

    private func deal() {
        finishTask?.cancel()
        finishTask = nil
        difficulty = Difficulty.stored(.tangram)
        var generator = SystemRandomNumberGenerator()
        let next = TangramPuzzle.nextShape(defaults: .standard, using: &generator)
        dealt = true
        puzzle = TangramPuzzle(shape: next, rules: TangramPuzzle.rules(for: difficulty))
        settleTray()
        turns = [:]
        selected = nil
        hint = nil
        missed = false
        startedAt = .now
    }

    /// The whole figure, recorded and named aloud at once, then seen for a beat before the shared
    /// celebration (#415): the cover used to rise in the same frame and hide the finished figure.
    private func finish() {
        let elapsed = Int(Date.now.timeIntervalSince(startedAt))
        modelContext.record(
            GameSession(
                gameID: .tangram,
                rounds: shape.placements.count, durationSeconds: elapsed,
                correct: puzzle.correct, attempts: puzzle.attempts, difficulty: difficulty))
        finalDetail = AppLanguage.localized(shape.key)
        if CaptionSpeaker.autoSpeaks() { CaptionSpeaker.speak(finalDetail) }
        AccessibilityNotification.Announcement(finalDetail).post()
        finishTask?.cancel()
        finishTask = FinishBeat.after { showCelebration = true }
    }
}

/// "Show me one" (#511): as tall as the other buttons, but outlined in grey with no fill, wash or
/// shadow, so it reads as a helper beside the board and the tiles. A press dims it, with no motion.
private struct QuietTileStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        let shape = RoundedRectangle(cornerRadius: 16)
        configuration.label
            .foregroundStyle(Color.primary)
            .frame(maxWidth: .infinity, minHeight: 100)
            .overlay(shape.strokeBorder(Color.secondary.opacity(0.7), lineWidth: 2))
            .contentShape(shape)
            .opacity(isEnabled ? (configuration.isPressed ? 0.6 : 1) : 0.4)
    }
}

/// A grid tile held by a finger: which slot, and how far it has moved from its place.
private struct TrayGrab {
    let slot: Int
    let offset: CGSize
}

#Preview {
    TangramView()
}
