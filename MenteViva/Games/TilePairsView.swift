import SwiftData
import SwiftUI

/// Tile Pairs: mahjong-solitaire pairs (#221). Tap two free tiles that match;
/// covered tiles shake warmly, mismatches glow amber, pairs lift away.
/// Rules live in `TilePairsDeal`; this view owns taps, drawing and celebration.
struct TilePairsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var difficulty = Difficulty.stored(.tilePairs)
    @State private var deal: TilePairsDeal?
    @State private var boardSize = CGSize.zero
    @State private var selected: Int?
    @State private var removing: Set<Int> = []
    @State private var highlighted: Set<Int> = []
    @State private var mismatched: Set<Int> = []
    @State private var shakeID: Int?
    @State private var hint: String?
    @State private var startedAt = Date.now
    @State private var showCelebration = false
    @State private var finalDetail = ""

    /// Gap between tiles, kept in sync with the logic's 6pt.
    private let gap: CGFloat = 6
    private let layerOffset: CGFloat = 10

    var body: some View {
        VStack(spacing: 20) {
            LevelExplainBanner(
                change: PlanStore.cachedPlan()?.changes[GameID.tilePairs], game: GameID.tilePairs,
                hasStarted: (deal?.attempts ?? 0) > 0)
            Text(AppLanguage.localized("game.tilepairs.instruction"))
                .font(.title2)
                .multilineTextAlignment(.center)

            if let hint {
                Text(hint)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(Color.todaysPick)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color.amber.opacity(0.24), in: .rect(cornerRadius: 14))
                    .accessibilityAddTraits(.isHeader)
            }

            board
                .frame(minHeight: 320)

            Button {
                showPair()
            } label: {
                Text(AppLanguage.localized("game.tilepairs.showpair"))
                    .font(.title2.weight(.semibold))
            }
            .buttonStyle(AnswerTileStyle(minHeight: 100))
            .accessibilityLabel(AppLanguage.localized("game.tilepairs.showpair"))
        }
        .padding()
        .fitOrScroll()
        .gameHeader(.tilePairs, instruction: AppLanguage.localized("game.tilepairs.instruction"))
        .onAppear { dealIfNeeded() }
        .celebration(isPresented: $showCelebration, game: .tilePairs, detail: finalDetail, onPlayAgain: restart)
    }

    // MARK: - Board

    private var board: some View {
        GeometryReader { proxy in
            let size = proxy.size
            Color.clear
                .onAppear {
                    boardSize = size
                    if deal == nil { dealNew(size: size) }
                }
                .onChange(of: size) { _, newValue in
                    boardSize = newValue
                    // Redeal only before the first move if the board no longer fits.
                    if (deal?.attempts ?? 0) == 0, let current = deal, !fits(current, in: newValue) {
                        dealNew(size: newValue)
                    }
                }
                .overlay {
                    if let deal {
                        let tileSize = tileSize(for: deal, in: size)
                        let boardDims = boardDimensions(for: deal, tileSize: tileSize)
                        ZStack(alignment: .topLeading) {
                            ForEach(deal.tiles.sorted(by: { $0.layer < $1.layer }), id: \.id) { tile in
                                tileButton(tile, tileSize: tileSize)
                            }
                        }
                        .frame(width: boardDims.width, height: boardDims.height)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
        }
    }

    private func tileButton(_ tile: TilePairsTile, tileSize: CGFloat) -> some View {
        let free = deal?.isFree(tile) ?? false
        let isSelected = selected == tile.id
        let isHighlighted = highlighted.contains(tile.id)
        let isRemoving = removing.contains(tile.id)
        let isMismatched = mismatched.contains(tile.id)
        let isShaking = shakeID == tile.id
        let offset = offset(for: tile, tileSize: tileSize)

        return Button {
            tap(tile)
        } label: {
            tileFace(tile, size: tileSize, free: free, selected: isSelected, highlighted: isHighlighted)
                .frame(width: tileSize, height: tileSize)
                .shadow(color: .black.opacity(0.22), radius: 4, y: 3)
                // Lifting vs fading on Remove
                .opacity(isRemoving && reduceMotion ? 0 : 1)
                .offset(y: isRemoving && !reduceMotion ? -44 : 0)
                .scaleEffect(isRemoving && !reduceMotion ? 1.06 : 1)
                .animation(reduceMotion ? .easeOut(duration: 0.2) : .easeOut(duration: 0.35), value: isRemoving)
                // Shake for covered tile
                .offset(x: isShaking ? 6 : 0)
                .animation(isShaking ? .easeInOut(duration: 0.08).repeatCount(3, autoreverses: true) : .default, value: shakeID)
                // Miss cue for mismatch pair
                .modifier(MissCue(active: Binding(get: { isMismatched }, set: { if !$0 { mismatched.remove(tile.id) } })))
        }
        .buttonStyle(.plain)
        .offset(x: offset.x, y: offset.y)
        // VoiceOver: only free tiles are focusable; covered tiles keep the pattern + dim so it isn't colour-only.
        .accessibilityHidden(!free)
        .accessibilityLabel(symbolLabel(tile.symbol))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityHint(AppLanguage.localized("game.tilepairs.a11y.hint"))
        // Keep the tappable area comfortably large even when the tile itself is 60pt.
        .frame(width: tileSize, height: tileSize)
    }

    /// Tile face: paper card with the 18 symbols drawn in code, game ink on a
    /// paper background. Covered tiles are dimmed and hatched so free vs covered
    /// never relies on colour alone (WCAG 1.4.1).
    private func tileFace(
        _ tile: TilePairsTile, size: CGFloat, free: Bool, selected: Bool, highlighted: Bool
    ) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.paper)
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(
                    highlighted ? Color.amber : (selected ? GameID.tilePairs.ink : Color.secondary.opacity(0.4)),
                    lineWidth: selected || highlighted ? 5 : 1.5
                )
            symbolView(tile.symbol, size: size)
                .opacity(free ? 1 : 0.55)
            if !free {
                // Covered pattern: diagonal hatching over a soft dim.
                HatchOverlay(size: size)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .opacity(0.9)
            }
        }
        .opacity(free ? 1 : 0.7)
    }

    @ViewBuilder
    private func symbolView(_ symbol: TilePairsSymbol, size: CGFloat) -> some View {
        let ink = GameID.tilePairs.ink
        let iconSize = size * 0.52
        switch symbol {
        case .circle:
            Circle().fill(ink).frame(width: iconSize, height: iconSize)
        case .square:
            RoundedRectangle(cornerRadius: 4).fill(ink).frame(width: iconSize, height: iconSize)
        case .triangle:
            TriangleShape().fill(ink).frame(width: iconSize, height: iconSize)
        case .diamond:
            DiamondShape().fill(ink).frame(width: iconSize * 0.7, height: iconSize * 0.7)
        case .star:
            Image(systemName: "star.fill").font(.system(size: iconSize * 0.85, weight: .bold)).foregroundStyle(ink)
        case .heart:
            Image(systemName: "heart.fill").font(.system(size: iconSize * 0.85)).foregroundStyle(ink)
        case .number1:
            Text("1").font(.system(size: iconSize, weight: .heavy, design: .rounded)).foregroundStyle(ink)
        case .number2:
            Text("2").font(.system(size: iconSize, weight: .heavy, design: .rounded)).foregroundStyle(ink)
        case .number3:
            Text("3").font(.system(size: iconSize, weight: .heavy, design: .rounded)).foregroundStyle(ink)
        case .number4:
            Text("4").font(.system(size: iconSize, weight: .heavy, design: .rounded)).foregroundStyle(ink)
        case .number5:
            Text("5").font(.system(size: iconSize, weight: .heavy, design: .rounded)).foregroundStyle(ink)
        case .number6:
            Text("6").font(.system(size: iconSize, weight: .heavy, design: .rounded)).foregroundStyle(ink)
        case .number7:
            Text("7").font(.system(size: iconSize, weight: .heavy, design: .rounded)).foregroundStyle(ink)
        case .number8:
            Text("8").font(.system(size: iconSize, weight: .heavy, design: .rounded)).foregroundStyle(ink)
        case .number9:
            Text("9").font(.system(size: iconSize, weight: .heavy, design: .rounded)).foregroundStyle(ink)
        case .leaf:
            Image(systemName: "leaf.fill").font(.system(size: iconSize * 0.9)).foregroundStyle(ink)
        case .sun:
            Image(systemName: "sun.max.fill").font(.system(size: iconSize * 0.9)).foregroundStyle(ink)
        case .flower:
            Image(systemName: "apple.meditate").font(.system(size: iconSize * 0.85)).foregroundStyle(ink)
                .accessibilityHidden(true)
        }
    }

    /// VoiceOver label for the symbol: "number 7", "leaf", etc.
    private func symbolLabel(_ symbol: TilePairsSymbol) -> String {
        switch symbol {
        case .circle: AppLanguage.localized("game.tilepairs.symbol.circle")
        case .square: AppLanguage.localized("game.tilepairs.symbol.square")
        case .triangle: AppLanguage.localized("game.tilepairs.symbol.triangle")
        case .diamond: AppLanguage.localized("game.tilepairs.symbol.diamond")
        case .star: AppLanguage.localized("game.tilepairs.symbol.star")
        case .heart: AppLanguage.localized("game.tilepairs.symbol.heart")
        case .number1: String(format: AppLanguage.localized("game.tilepairs.symbol.number %@"), "1")
        case .number2: String(format: AppLanguage.localized("game.tilepairs.symbol.number %@"), "2")
        case .number3: String(format: AppLanguage.localized("game.tilepairs.symbol.number %@"), "3")
        case .number4: String(format: AppLanguage.localized("game.tilepairs.symbol.number %@"), "4")
        case .number5: String(format: AppLanguage.localized("game.tilepairs.symbol.number %@"), "5")
        case .number6: String(format: AppLanguage.localized("game.tilepairs.symbol.number %@"), "6")
        case .number7: String(format: AppLanguage.localized("game.tilepairs.symbol.number %@"), "7")
        case .number8: String(format: AppLanguage.localized("game.tilepairs.symbol.number %@"), "8")
        case .number9: String(format: AppLanguage.localized("game.tilepairs.symbol.number %@"), "9")
        case .leaf: AppLanguage.localized("game.tilepairs.symbol.leaf")
        case .sun: AppLanguage.localized("game.tilepairs.symbol.sun")
        case .flower: AppLanguage.localized("game.tilepairs.symbol.flower")
        }
    }

    // MARK: - Layout

    private func offset(for tile: TilePairsTile, tileSize: CGFloat) -> CGPoint {
        CGPoint(
            x: CGFloat(tile.x) * (tileSize + gap) + CGFloat(tile.layer) * layerOffset,
            y: CGFloat(tile.y) * (tileSize + gap) + CGFloat(tile.layer) * layerOffset
        )
    }

    private func boardDimensions(for deal: TilePairsDeal, tileSize: CGFloat) -> CGSize {
        let maxX = deal.tiles.map(\.x).max() ?? 0
        let maxY = deal.tiles.map(\.y).max() ?? 0
        let w = CGFloat(maxX + 1) * tileSize + CGFloat(maxX) * gap + CGFloat(max(0, deal.layers - 1)) * layerOffset
        let h = CGFloat(maxY + 1) * tileSize + CGFloat(maxY) * gap + CGFloat(max(0, deal.layers - 1)) * layerOffset
        return CGSize(width: w, height: h)
    }

    private func tileSize(for deal: TilePairsDeal, in size: CGSize) -> CGFloat {
        let dims = { (ts: CGFloat) -> CGSize in boardDimensions(for: deal, tileSize: ts) }
        // Aim for 100pt (conventions §4) but stay ≥60pt even when capped (#220).
        for ts in stride(from: 100, through: 80, by: -1) {
            let d = dims(CGFloat(ts))
            if d.width <= size.width && d.height <= size.height { return CGFloat(ts) }
        }
        for ts in stride(from: 79, through: 60, by: -1) {
            let d = dims(CGFloat(ts))
            if d.width <= size.width && d.height <= size.height { return CGFloat(ts) }
        }
        return 60
    }

    private func fits(_ deal: TilePairsDeal, in size: CGSize) -> Bool {
        let ts = tileSize(for: deal, in: size)
        let d = boardDimensions(for: deal, tileSize: ts)
        return d.width <= size.width && d.height <= size.height && ts >= 60
    }

    // MARK: - Play

    private func dealIfNeeded() {
        if deal == nil { dealNew(size: boardSize) }
    }

    private func dealNew(size: CGSize) {
        let w = size.width > 0 ? Double(size.width) : Double(UIScreen.main.bounds.width - 32)
        let h = size.height > 0 ? Double(size.height) : 520
        var gen = SystemRandomNumberGenerator()
        deal = TilePairsDeal.make(difficulty: difficulty, width: w, height: h, using: &gen)
        selected = nil
        removing = []
        highlighted = []
        mismatched = []
        shakeID = nil
        hint = nil
        startedAt = .now
    }

    private func restart() {
        dealNew(size: boardSize)
    }

    private func tap(_ tile: TilePairsTile) {
        guard deal != nil, !removing.contains(tile.id) else { return }
        let free = deal!.isFree(tile)
        if !free {
            // Covered → shake + warm line, nothing removed.
            shakeID = tile.id
            hint = AppLanguage.localized("game.tilepairs.covered")
            Feedback.play(.miss)
            AccessibilityNotification.Announcement(hint!).post()
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(420))
                if shakeID == tile.id { shakeID = nil }
            }
            return
        }
        if selected == nil {
            selected = tile.id
            highlighted = []
            hint = nil
            Feedback.play(.tap)
            return
        }
        if selected == tile.id {
            selected = nil
            return
        }
        // Second tile: try the pair.
        guard let first = selected else { return }
        var mutable = deal!
        let ok = mutable.tryPair(first, tile.id)
        if ok {
            removing = [first, tile.id]
            highlighted = []
            hint = nil
            Feedback.play(.success)
            let label = symbolLabel(tile.symbol)
            AccessibilityNotification.Announcement(
                String(format: AppLanguage.localized("game.tilepairs.matched %@"), label)
            ).post()
            let delay = reduceMotion ? 0.22 : 0.38
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(delay))
                deal = mutable
                removing = []
                selected = nil
                if mutable.isCleared { finish(with: mutable) }
            }
        } else {
            // Different symbols → warm miss, clear the pick.
            hint = AppLanguage.localized("game.tilepairs.mismatch")
            mismatched = [first, tile.id]
            selected = nil
            Feedback.play(.miss)
            AccessibilityNotification.Announcement(hint!).post()
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(850))
                mismatched = []
                // Keep the hint until the next successful pick.
            }
        }
    }

    private func showPair() {
        guard var current = deal else { return }
        if current.isStuck {
            hint = AppLanguage.localized("game.tilepairs.stuck")
            AccessibilityNotification.Announcement(hint!).post()
            Feedback.play(.success)
            var gen = SystemRandomNumberGenerator()
            if current.reshuffle(using: &gen) {
                withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.3)) {
                    deal = current
                    selected = nil
                    highlighted = []
                    removing = []
                }
            }
            return
        }
        let free = current.freeTiles()
        let groups = Dictionary(grouping: free, by: \.symbol)
        if let pair = groups.first(where: { $0.value.count >= 2 })?.value.prefix(2) {
            highlighted = Set(pair.map(\.id))
            Feedback.play(.success)
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(1.4))
                highlighted = []
            }
        }
    }

    private func finish(with final: TilePairsDeal) {
        let elapsed = Int(Date.now.timeIntervalSince(startedAt))
        let pairs = (final.correct > 0 ? final.correct : (deal?.correct ?? 0))
        modelContext.record(
            GameSession(
                gameID: .tilePairs, score: pairs * 10,
                rounds: max(1, pairs), durationSeconds: elapsed,
                correct: final.correct, attempts: final.attempts,
                difficulty: difficulty))
        finalDetail = AppLanguage.localized("game.celebration.table")
        showCelebration = true
    }
}

// MARK: - Shapes drawn in code (no copied art)

private struct TriangleShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

private struct DiamondShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        p.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        p.closeSubpath()
        return p
    }
}

/// Diagonal hatching so covered vs free isn't colour only.
private struct HatchOverlay: View {
    let size: CGFloat
    var body: some View {
        Canvas { ctx, sz in
            let step: CGFloat = 8
            var path = Path()
            for i in stride(from: -sz.height, through: sz.width + sz.height, by: step) {
                path.move(to: CGPoint(x: i, y: 0))
                path.addLine(to: CGPoint(x: i + sz.height, y: sz.height))
            }
            ctx.stroke(path, with: .color(.primary.opacity(0.14)), lineWidth: 1.8)
        }
        .opacity(0.9)
        .background(Color.primary.opacity(0.08))
    }
}

#Preview {
    TilePairsView()
}
