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
    @State private var seen: Set<String> = []
    @State private var puzzle = TangramPuzzle(
        shape: TangramShapes.all[0], rules: TangramPuzzle.rules(for: Difficulty.stored(.tangram)))
    /// The turn and mirror the player gave each tray tile, keyed by the slot it was dealt for.
    @State private var turns: [Int: TangramPlacement] = [:]
    @State private var selected: Int?
    @State private var dragged: Int?
    @State private var dragOffset = CGSize.zero
    @State private var boardFrame = CGRect.zero
    @State private var hint: String?
    @State private var missed = false
    @State private var startedAt = Date.now
    @State private var showCelebration = false
    @State private var finalDetail = ""
    /// The space the game gets, measured: it picks the layout (`TangramLayout`).
    @State private var area = CGSize.zero

    private var shape: TangramShape { puzzle.shape }
    private var rules: TangramRules { puzzle.rules }
    private var layout: TangramLayout { TangramLayout.choose(for: area) }

    var body: some View {
        table
            .padding(.horizontal, TangramLayout.padding)
            .padding(.vertical, layout == .sideBySide ? TangramLayout.cellGap / 2 : TangramLayout.padding)
            .coordinateSpace(.named(Self.space))
            .fitOrScroll()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onGeometryChange(for: CGSize.self) {
                $0.size
            } action: {
                area = $0
            }
            .gameHeader(.tangram, instruction: AppLanguage.localized("game.tangram.instruction"))
            .onAppear(perform: deal)
            .onDisappear { CaptionSpeaker.stop() }
            .celebration(isPresented: $showCelebration, game: .tangram, detail: finalDetail, onPlayAgain: deal)
    }

    /// Stacked on an iPad or an upright iPhone; on an iPhone on its side the board takes the left
    /// half and the rest stands beside it, since the stack is taller than the screen there. Side by
    /// side the gaps and the top and bottom padding are halved: an iPhone SE on its side leaves
    /// about 300pt, and the hint, buttons and tray need 272pt of it.
    @ViewBuilder private var table: some View {
        let gap = TangramLayout.partGap
        if layout == .sideBySide {
            HStack(spacing: gap) {
                VStack(spacing: gap / 2) {
                    banner
                    instruction
                    boardArea
                }
                VStack(spacing: TangramLayout.cellGap / 1.5) {
                    hintLine
                    controls
                    tray
                }
            }
        } else {
            VStack(spacing: gap) {
                banner
                instruction
                boardArea
                hintLine
                controls
                tray
            }
        }
    }

    private var banner: some View {
        LevelExplainBanner(
            change: PlanStore.cachedPlan()?.changes[GameID.tangram], game: GameID.tangram,
            hasStarted: puzzle.attempts > 0)
    }

    private var instruction: some View {
        Text(AppLanguage.localized("game.tangram.instruction"))
            .font(.title2)
            .multilineTextAlignment(.center)
    }

    /// The hint's two lines are kept even while it is empty, so a miss never makes the page taller:
    /// on a small iPhone that pushed the page into scrolling and sent the tray back to its first tile.
    private var hintLine: some View {
        ZStack {
            Text(verbatim: " \n ").hidden()
            if let hint { Text(hint) }
        }
        .font(.title2)
        .multilineTextAlignment(.center)
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
        }
        .modifier(MissCue(active: $missed))
    }

    /// The silhouette and the slots already home. A free slot shows its own outline while the
    /// level gives it; a filled one is drawn solid with a dark edge. One tap handler reads the point.
    private func board(size: CGSize) -> some View {
        let fit = TangramPuzzle.fitTransform(box: TangramPuzzle.boundingBox(of: shape), in: size)
        return ZStack {
            ForEach(shape.placements.indices, id: \.self) { slot in
                slotView(slot, scale: fit.scale, origin: fit.origin)
            }
        }
        .frame(width: size.width, height: size.height)
        .contentShape(Rectangle())
        .onTapGesture { point in
            tapBoard(at: TangramPuzzle.fromScreen(point, scale: fit.scale, origin: fit.origin), scale: fit.scale)
        }
        // A sliding tray's tiles arrive by system drag (see `withDrag`), carrying their slot. Only a
        // tile that went home counts as dropped; after a miss the system sends it back to the tray.
        .dropDestination(for: String.self) { items, point in
            guard let slot = items.first.flatMap({ Int($0) }), puzzle.freeSlots.contains(slot) else { return false }
            let result = place(
                slot, at: TangramPuzzle.fromScreen(point, scale: fit.scale, origin: fit.origin), scale: fit.scale)
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

    /// Turn from level 7, Flip from level 9, "Show me one" at every level; all 100pt.
    private var controls: some View {
        HStack(spacing: 12) {
            if rules.matchRotation {
                controlButton("game.tangram.turn", enabled: selected != nil) { adjustSelected(TangramPuzzle.turned) }
            }
            if rules.matchFlip {
                controlButton("game.tangram.flip", enabled: selected != nil) { adjustSelected(TangramPuzzle.mirrored) }
            }
            controlButton("game.tangram.showone", enabled: !puzzle.isComplete, action: showOne)
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

    // MARK: - Tray

    /// One 100pt cell per tile still to place. Tapping selects (a thick edge, not colour, marks it);
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
            .frame(height: TangramLayout.cell)
            .scrollIndicators(.visible)
        } else {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: TangramLayout.cell), spacing: gap)], spacing: gap) {
                trayTiles
            }
        }
    }

    private var trayTiles: some View {
        let scale = TangramPuzzle.trayScale(for: puzzle.freeSlots.map { shape.placements[$0].piece })
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
            Self.drawing(of: tile, scale: scale)
                .frame(width: 100, height: 100)
                .background(Color.paper, in: .rect(cornerRadius: 16))
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(
                            isSelected ? GameID.tangram.ink : Color.secondary.opacity(0.4),
                            lineWidth: isSelected ? 6 : 2)
                }
        }
        .buttonStyle(.plain)
        return withDrag(button, slot: slot, preview: Self.drawing(of: tile, scale: scale))
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
    /// its tile follows the finger and drops where the drag ends.
    @ViewBuilder private func withDrag(_ tile: some View, slot: Int, preview: some View) -> some View {
        if layout.traySlides {
            tile.draggable(String(slot)) { preview.frame(width: 100, height: 100) }
        } else {
            tile
                .offset(dragged == slot ? dragOffset : .zero)
                .zIndex(dragged == slot ? 1 : 0)
                .simultaneousGesture(
                    DragGesture(minimumDistance: 10, coordinateSpace: .named(Self.space))
                        .onChanged { value in
                            dragged = slot
                            dragOffset = value.translation
                        }
                        .onEnded { value in
                            dragged = nil
                            dragOffset = .zero
                            drop(slot, at: value.location)
                        })
        }
    }

    /// A tray tile drawn turned and mirrored as it is now, at the tray's one shared scale.
    private static func drawing(of tile: TangramPlacement, scale: Double) -> some View {
        var path = Path()
        path.addLines(TangramPuzzle.trayPoints(of: tile, scale: scale))
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

    private func tapBoard(at point: CGPoint, scale: CGFloat) {
        guard let slot = selected else {
            say(AppLanguage.localized("game.tangram.a11y.pickfirst"))
            return
        }
        place(slot, at: point, scale: scale)
    }

    /// A drag that ends over the board places the tile there; anywhere else it just goes back.
    private func drop(_ slot: Int, at location: CGPoint) {
        guard boardFrame.contains(location) else { return }
        let local = CGPoint(x: location.x - boardFrame.minX, y: location.y - boardFrame.minY)
        let fit = TangramPuzzle.fitTransform(box: TangramPuzzle.boundingBox(of: shape), in: boardFrame.size)
        place(slot, at: TangramPuzzle.fromScreen(local, scale: fit.scale, origin: fit.origin), scale: fit.scale)
    }

    /// `scale` is the board's points per unit. Every slot takes a tap or drop within 30pt of its
    /// middle, a 60pt target (#396): on an iPhone board a small tile's own share of reach is
    /// under 30pt. On an iPad-sized board the share is usually wider already and stays as it was.
    @discardableResult
    private func place(_ slot: Int, at point: CGPoint, scale: CGFloat) -> TangramPlaceResult {
        let tile = orientation(of: slot)
        let result = puzzle.place(
            tile.piece, at: point, rotation: tile.rotation, flipped: tile.flipped,
            minimumReach: TangramPuzzle.reachFloor(points: 30, scale: scale))
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
        difficulty = Difficulty.stored(.tangram)
        var generator = SystemRandomNumberGenerator()
        let next = TangramPuzzle.pick(from: TangramShapes.all, seen: seen, using: &generator)
        seen.insert(next.key)
        puzzle = TangramPuzzle(shape: next, rules: TangramPuzzle.rules(for: difficulty))
        turns = [:]
        selected = nil
        dragged = nil
        dragOffset = .zero
        hint = nil
        missed = false
        startedAt = .now
    }

    /// The whole figure, named on screen and aloud, then the shared celebration.
    private func finish() {
        let elapsed = Int(Date.now.timeIntervalSince(startedAt))
        modelContext.record(
            GameSession(
                gameID: .tangram, score: Self.score(misses: puzzle.attempts - puzzle.correct),
                rounds: shape.placements.count, durationSeconds: elapsed,
                correct: puzzle.correct, attempts: puzzle.attempts, difficulty: difficulty))
        finalDetail = AppLanguage.localized(shape.key)
        if CaptionSpeaker.autoSpeaks() { CaptionSpeaker.speak(finalDetail) }
        AccessibilityNotification.Announcement(finalDetail).post()
        showCelebration = true
    }

    /// Progress, never points: a full round starts at 140 and each miss costs 5.
    static func score(misses: Int) -> Int {
        max(10, 140 - misses * 5)
    }
}

#Preview {
    TangramView()
}
