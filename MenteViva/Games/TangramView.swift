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

    private var shape: TangramShape { puzzle.shape }
    private var rules: TangramRules { puzzle.rules }

    var body: some View {
        VStack(spacing: 16) {
            LevelExplainBanner(
                change: PlanStore.cachedPlan()?.changes[GameID.tangram], game: GameID.tangram,
                hasStarted: puzzle.attempts > 0)
            Text(AppLanguage.localized("game.tangram.instruction"))
                .font(.title2)
                .multilineTextAlignment(.center)

            GeometryReader { geometry in
                board(size: geometry.size)
            }
            .frame(minHeight: 280)
            .onGeometryChange(for: CGRect.self) {
                $0.frame(in: .named(Self.space))
            } action: { frame in
                boardFrame = frame
            }
            .modifier(MissCue(active: $missed))

            if let hint {
                Text(hint)
                    .font(.title2)
                    .multilineTextAlignment(.center)
            }

            controls
            tray
        }
        .padding()
        .coordinateSpace(.named(Self.space))
        .fitOrScroll()
        .gameHeader(.tangram, instruction: AppLanguage.localized("game.tangram.instruction"))
        .onAppear(perform: deal)
        .onDisappear { CaptionSpeaker.stop() }
        .celebration(isPresented: $showCelebration, game: .tangram, detail: finalDetail, onPlayAgain: deal)
    }

    // MARK: - Board

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
            tapBoard(at: TangramPuzzle.fromScreen(point, scale: fit.scale, origin: fit.origin))
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
    /// dragging drops it on the board; VoiceOver lists the slots it fits as actions.
    private var tray: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 12)], spacing: 12) {
            ForEach(puzzle.freeSlots, id: \.self) { slot in
                trayTile(slot)
            }
        }
    }

    private func trayTile(_ slot: Int) -> some View {
        let tile = orientation(of: slot)
        let isSelected = selected == slot
        return Button {
            selected = isSelected ? nil : slot
            hint = nil
        } label: {
            Self.drawing(of: tile)
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
                }
        )
        .accessibilityLabel(AppLanguage.localized(tile.piece.nameKey))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityActions {
            ForEach(puzzle.fittingSlots(for: tile.piece), id: \.self) { target in
                Button(slotActionName(target)) { placeByName(slot, into: target) }
            }
        }
    }

    /// A tray tile drawn turned and mirrored as it is now, fitted into a 76pt square in its cell.
    private static func drawing(of tile: TangramPlacement) -> some View {
        let corners = TangramPiece.placedCorners(
            tile.piece, position: .zero, rotation: tile.rotation, flipped: tile.flipped)
        let xs = corners.map(\.x)
        let ys = corners.map(\.y)
        let minX = xs.min() ?? 0
        let minY = ys.min() ?? 0
        let width = max((xs.max() ?? 0) - minX, 0.001)
        let height = max((ys.max() ?? 0) - minY, 0.001)
        let scale = 76 / max(width, height)
        var path = Path()
        path.addLines(
            corners.map {
                CGPoint(x: 50 + ($0.x - minX - width / 2) * scale, y: 50 - ($0.y - minY - height / 2) * scale)
            })
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

    private func tapBoard(at point: CGPoint) {
        guard let slot = selected else {
            say(AppLanguage.localized("game.tangram.a11y.pickfirst"))
            return
        }
        place(slot, at: point)
    }

    /// A drag that ends over the board places the tile there; anywhere else it just goes back.
    private func drop(_ slot: Int, at location: CGPoint) {
        guard boardFrame.contains(location) else { return }
        let local = CGPoint(x: location.x - boardFrame.minX, y: location.y - boardFrame.minY)
        let fit = TangramPuzzle.fitTransform(box: TangramPuzzle.boundingBox(of: shape), in: boardFrame.size)
        place(slot, at: TangramPuzzle.fromScreen(local, scale: fit.scale, origin: fit.origin))
    }

    private func place(_ slot: Int, at point: CGPoint) {
        let tile = orientation(of: slot)
        respond(to: puzzle.place(tile.piece, at: point, rotation: tile.rotation, flipped: tile.flipped), from: slot)
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
