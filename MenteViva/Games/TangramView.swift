import SwiftData
import SwiftUI

/// Tangram: fill the silhouette with the seven tiles (#219). Tap a tray tile,
/// then tap where it goes; dragging a tile on the board also works, and
/// VoiceOver places tiles through custom actions. Pure rules live in
/// `TangramPuzzle`; this view owns taps, drags and layout. Fully offline.
struct TangramView: View {
    @Environment(\.modelContext) private var modelContext

    /// Off the board: tiles waiting in the tray carry this spot, far outside
    /// every silhouette, so the board simply never draws them.
    static let traySpot = CGPoint(x: -1000, y: -1000)

    @State private var difficulty = Difficulty.stored(.tangram)
    @State private var shape = TangramShapes.all[0]
    @State private var seen: Set<String> = []
    @State private var placed: [TangramPlacement] = []
    @State private var selected: Int?
    @State private var moves = 0
    @State private var misses = 0
    @State private var startedAt = Date.now
    @State private var missMessage: String?
    @State private var missed = false
    @State private var showCelebration = false
    @State private var finalDetail = ""
    /// Each dragged tile's spot when its drag began: the displacement applies
    /// onto this snapshot, never onto the already-moving state.
    @State private var dragStart: [Int: CGPoint] = [:]

    private var rules: TangramRules { TangramPuzzle.rules(for: difficulty) }

    /// Tiles still out of place, the tray's contents in target order.
    private var remaining: [Int] {
        placed.indices.filter {
            !TangramPuzzle.snapped(
                placed[$0], to: shape.placements[$0],
                matchRotation: rules.matchRotation, matchFlip: rules.matchFlip)
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            LevelExplainBanner(
                change: PlanStore.cachedPlan()?.changes[GameID.tangram], game: GameID.tangram,
                hasStarted: moves > 0)
            Text(AppLanguage.localized("game.tangram.instruction"))
                .font(.title2)
                .multilineTextAlignment(.center)

            GeometryReader { geometry in
                board(size: geometry.size)
            }
            .frame(minHeight: 300)
            .modifier(MissCue(active: $missed))

            if let missMessage {
                Text(missMessage)
                    .font(.title2)
                    .multilineTextAlignment(.center)
                    .accessibilityLiveRegion(.polite)
            }

            controls
            tray
        }
        .padding()
        .fitOrScroll()
        .gameHeader(.tangram, instruction: AppLanguage.localized("game.tangram.instruction"))
        .onAppear(perform: deal)
        .onDisappear { CaptionSpeaker.stop() }
        .celebration(
            isPresented: $showCelebration, game: .tangram, detail: finalDetail, onPlayAgain: deal)
    }

    // MARK: - Board

    /// The silhouette with the player's tiles on it. One tap handler reads the
    /// position; tiles are labelled shapes, not buttons, so taps land here.
    private func board(size: CGSize) -> some View {
        let box = TangramPuzzle.boundingBox(of: shape)
        let fit = TangramPuzzle.fitTransform(box: box, in: size)
        return ZStack {
            ForEach(shape.placements.indices, id: \.self) { index in
                silhouetteTile(index: index, scale: fit.scale, origin: fit.origin)
            }
            ForEach(placed.indices, id: \.self) { index in
                if placed[index].position != Self.traySpot {
                    playerTile(index: index, scale: fit.scale, origin: fit.origin)
                }
            }
        }
        .frame(width: size.width, height: size.height)
        .contentShape(Rectangle())
        .onTapGesture { point in
            placeSelected(
                at: TangramPuzzle.fromScreen(point, scale: fit.scale, origin: fit.origin))
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(AppLanguage.localized(shape.key))
    }

    /// One target: a wash of ink, stroked from level 3 when the outline shows.
    private func silhouetteTile(index: Int, scale: CGFloat, origin: CGPoint) -> some View {
        let target = shape.placements[index]
        return poly(points: target, scale: scale, origin: origin)
            .fill(GameID.tangram.ink.opacity(0.12))
            .overlay {
                poly(points: target, scale: scale, origin: origin)
                    .stroke(
                        GameID.tangram.ink.opacity(rules.outline ? 0.8 : 0.25),
                        lineWidth: rules.outline ? 2 : 1)
            }
            .accessibilityHidden(true)
    }

    /// One tile the player put down: ink, a dark edge, and a thick edge while
    /// selected (thickness, not colour, marks the selection). Draggable.
    private func playerTile(index: Int, scale: CGFloat, origin: CGPoint) -> some View {
        let tile = placed[index]
        return poly(points: tile, scale: scale, origin: origin)
            .fill(GameID.tangram.ink.opacity(0.55))
            .overlay {
                poly(points: tile, scale: scale, origin: origin)
                    .stroke(
                        Color.primary.opacity(0.6),
                        lineWidth: selected == index ? 6 : 2)
            }
            .accessibilityLabel(AppLanguage.localized(tile.piece.nameKey))
            .gesture(
                DragGesture(minimumDistance: 8)
                    .onChanged { drag in
                        if dragStart[index] == nil { dragStart[index] = tile.position }
                        let from = TangramPuzzle.fromScreen(
                            drag.startLocation, scale: scale, origin: origin)
                        let at = TangramPuzzle.fromScreen(
                            drag.location, scale: scale, origin: origin)
                        guard let base = dragStart[index] else { return }
                        placed[index] = TangramPlacement(
                            piece: tile.piece,
                            position: CGPoint(
                                x: base.x + at.x - from.x,
                                y: base.y + at.y - from.y),
                            rotation: tile.rotation, flipped: tile.flipped)
                    }
                    .onEnded { _ in
                        dragStart[index] = nil
                        moves += 1
                        settle(index: index)
                    }
            )
    }

    private func poly(points: TangramPlacement, scale: CGFloat, origin: CGPoint) -> Path {
        var path = Path()
        path.addLines(
            TangramPiece.placedCorners(
                points.piece, position: points.position,
                rotation: points.rotation, flipped: points.flipped
            ).map { TangramPuzzle.toScreen($0, scale: scale, origin: origin) })
        path.closeSubpath()
        return path
    }

    // MARK: - Controls

    /// Turn from level 7, Flip from level 9, "Show me one" at every level.
    private var controls: some View {
        HStack(spacing: 12) {
            if rules.matchRotation {
                Button {
                    adjustSelected(TangramPuzzle.turned)
                } label: {
                    Text(AppLanguage.localized("game.tangram.turn"))
                        .font(.title2.weight(.semibold))
                }
                .buttonStyle(AnswerTileStyle(minHeight: 100))
                .disabled(selected == nil)
                .accessibilityHint(
                    selected == nil ? AppLanguage.localized("game.tangram.a11y.pickfirst") : "")
            }
            if rules.matchFlip {
                Button {
                    adjustSelected(TangramPuzzle.mirrored)
                } label: {
                    Text(AppLanguage.localized("game.tangram.flip"))
                        .font(.title2.weight(.semibold))
                }
                .buttonStyle(AnswerTileStyle(minHeight: 100))
                .disabled(selected == nil)
                .accessibilityHint(
                    selected == nil ? AppLanguage.localized("game.tangram.a11y.pickfirst") : "")
            }
            Button {
                showOne()
            } label: {
                Text(AppLanguage.localized("game.tangram.showone"))
                    .font(.title2.weight(.semibold))
            }
            .buttonStyle(AnswerTileStyle(minHeight: 100))
            .disabled(remaining.isEmpty)
        }
    }

    /// The tray: every tile still out of place in a 100pt cell. Tapping
    /// selects; the selected tile offers each free slot as a VoiceOver action.
    private var tray: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(remaining, id: \.self) { index in
                    Button {
                        selected = index
                        missMessage = nil
                    } label: {
                        trayCell(index: index)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(AppLanguage.localized(placed[index].piece.nameKey))
                    .accessibilityAddTraits(selected == index ? .isSelected : [])
                    .accessibilityActions {
                        if selected == index {
                            ForEach(remaining, id: \.self) { slot in
                                Button(slotActionName(slot)) {
                                    placeViaAction(piece: index, slot: slot)
                                }
                            }
                        }
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    /// The tile drawn in its current turn and mirror, fitted into a 100pt cell
    /// with a thick edge while selected.
    private func trayCell(index: Int) -> some View {
        let tile = placed[index]
        let corners = TangramPiece.placedCorners(
            tile.piece, position: .zero, rotation: tile.rotation, flipped: tile.flipped)
        let xs = corners.map(\.x)
        let ys = corners.map(\.y)
        let box = CGRect(
            x: xs.min() ?? 0, y: ys.min() ?? 0,
            width: (xs.max() ?? 1) - (xs.min() ?? 0), height: (ys.max() ?? 1) - (ys.min() ?? 0))
        let side: CGFloat = 76
        let scale = min(side / max(box.width, 0.001), side / max(box.height, 0.001))
        var path = Path()
        path.addLines(
            corners.map {
                CGPoint(
                    x: 50 + ($0.x - box.minX - box.width / 2) * scale,
                    y: 50 - ($0.y - box.minY - box.height / 2) * scale)
            })
        path.closeSubpath()
        return
            path
            .fill(GameID.tangram.ink.opacity(0.45))
            .frame(width: 100, height: 100)
            .background(Color(.systemBackground), in: .rect(cornerRadius: 16))
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        selected == index ? GameID.tangram.ink : .secondary.opacity(0.4),
                        lineWidth: selected == index ? 6 : 2)
            }
    }

    // MARK: - Play

    /// A board tap: with a tile selected, its middle moves onto the tap; with
    /// none, a tap on a tile's body picks it up instead.
    private func placeSelected(at point: CGPoint) {
        guard let index = selected else {
            selected = placed.indices.min {
                middle(of: placed[$0], to: point) < middle(of: placed[$1], to: point)
            }.flatMap { middle(of: placed[$0], to: point) < grab(placed[$0]) ? $0 : nil }
            return
        }
        moves += 1
        let anchor = TangramPuzzle.centroidOffset(of: placed[index])
        placed[index] = TangramPlacement(
            piece: placed[index].piece,
            position: CGPoint(x: point.x - anchor.x, y: point.y - anchor.y),
            rotation: placed[index].rotation, flipped: placed[index].flipped)
        settle(index: index)
    }

    /// Tap-to-tile distance through the tile's middle, and how close a tap
    /// must be to pick it up; tray tiles sit a thousand units out, far beyond
    /// any grab.
    private func middle(of placement: TangramPlacement, to point: CGPoint) -> CGFloat {
        let offset = TangramPuzzle.centroidOffset(of: placement)
        return hypot(
            point.x - (placement.position.x + offset.x),
            point.y - (placement.position.y + offset.y))
    }

    private func grab(_ placement: TangramPlacement) -> CGFloat {
        TangramPuzzle.grabRadius(of: placement.piece)
    }

    /// After a tile lands: snapped tiles stay with a happy sound, the rest say
    /// what to try next — another spot, or a turn when it sits nearly right.
    private func settle(index: Int) {
        let target = shape.placements[index]
        if TangramPuzzle.snapped(
            placed[index], to: target,
            matchRotation: rules.matchRotation, matchFlip: rules.matchFlip)
        {
            missMessage = nil
            selected = nil
            Feedback.play(.success)
            if puzzleDone { finish() }
            return
        }
        misses += 1
        missed = true
        let near =
            hypot(
                placed[index].position.x - target.position.x,
                placed[index].position.y - target.position.y) <= TangramPuzzle.snapTolerance
        missMessage = AppLanguage.localized(
            near && rules.matchRotation ? "game.tangram.miss.turn" : "game.tangram.miss.spot")
        Feedback.play(.miss)
    }

    private var puzzleDone: Bool {
        TangramPuzzle(shape: shape, placed: placed).isCorrect(
            matchRotation: rules.matchRotation, matchFlip: rules.matchFlip)
    }

    /// Turn and Flip re-check a tile on the board, so one that lands right
    /// snaps at once; a tile still in the tray just turns, with no miss, since
    /// lining it up before placing it is the normal way to play.
    private func adjustSelected(_ change: (TangramPlacement) -> TangramPlacement) {
        guard let index = selected else { return }
        placed[index] = change(placed[index])
        guard placed[index].position != Self.traySpot else { return }
        moves += 1
        settle(index: index)
    }

    /// "Show me one": the first tile still out goes home, at every level.
    private func showOne() {
        guard
            let index = TangramPuzzle.firstMisplacedIndex(
                placed: placed, in: shape,
                matchRotation: rules.matchRotation, matchFlip: rules.matchFlip)
        else { return }
        moves += 1
        placed[index] = shape.placements[index]
        if selected == index { selected = nil }
        missMessage = nil
        Feedback.play(.success)
        if puzzleDone { finish() }
    }

    /// A VoiceOver slot action: the tile moves to the named slot. Choosing its
    /// own slot also straightens it — picking the tile and the slot is the
    /// puzzle; the fine turning is the accommodation, so the game stays
    /// finishable by ear at every level.
    private func placeViaAction(piece: Int, slot: Int) {
        moves += 1
        let target = shape.placements[slot]
        placed[piece] = TangramPlacement(
            piece: placed[piece].piece, position: target.position,
            rotation: slot == piece ? target.rotation : placed[piece].rotation,
            flipped: slot == piece ? target.flipped : placed[piece].flipped)
        selected = nil
        settle(index: piece)
    }

    private func slotActionName(_ slot: Int) -> String {
        String(
            format: AppLanguage.localized("game.tangram.a11y.place %@"),
            AppLanguage.localized(
                "game.tangram.slot.\(TangramPuzzle.slot(of: shape.placements[slot], in: shape).keySuffix)"))
    }

    private func deal() {
        var generator = SystemRandomNumberGenerator()
        shape = TangramPuzzle.pick(from: TangramShapes.all, seen: seen, using: &generator)
        seen.insert(shape.key)
        placed = shape.placements.enumerated().map { index, target in
            index < rules.prefill
                ? target
                : TangramPlacement(
                    piece: target.piece, position: Self.traySpot,
                    rotation: target.rotation, flipped: target.flipped)
        }
        selected = nil
        dragStart = [:]
        moves = 0
        misses = 0
        startedAt = .now
        missMessage = nil
        missed = false
        // Level 1 deals the full ghost, already complete: celebrate the figure
        // by name instead of leaving a finished board with nothing to do.
        if puzzleDone { finish() }
    }

    private func finish() {
        let elapsed = Int(Date.now.timeIntervalSince(startedAt))
        modelContext.record(
            GameSession(
                gameID: .tangram, score: Self.score(misses: misses), rounds: 1,
                durationSeconds: elapsed, correct: shape.placements.count, attempts: moves,
                difficulty: difficulty))
        finalDetail = AppLanguage.localized(shape.key)
        if CaptionSpeaker.autoSpeaks() { CaptionSpeaker.speak(finalDetail) }
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
