import SwiftData
import SwiftUI

/// Repeat the Sequence: watch the tiles light up and tap them in order.
/// Levels 1-10 change grid and length; on a narrow screen a 3×3 board
/// falls back to 2×3 with length+1 (#216).
struct RepeatSequenceView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase

    /// One tile: colour + shape + name, so colour alone never decides.
    private enum Tile: CaseIterable {
        case circle, star, square, triangle, heart, moon, drop, leaf, sun

        /// The print palette (#398): the same in light and dark, each with an espresso edge.
        var color: Color {
            switch self {
            case .circle: Self.fixed(0x246456)
            case .star: Self.fixed(0xAF3F32)
            case .square: Self.fixed(0xE7AC45)
            case .triangle: Self.fixed(0x35566D)
            case .heart: Self.fixed(0x7A4B2A)
            case .moon: Self.fixed(0x6B3FA0)
            case .drop: Self.fixed(0x2E7D4F)
            case .leaf: Self.fixed(0xC8372D)
            case .sun: Self.fixed(0x1F5F7A)
            }
        }

        /// White on every tile but the light mustard one, which takes `onAmber`: espresso that stays
        /// dark in dark mode too (`Color.espresso` turns cream there, unreadable on mustard).
        var symbolColor: Color { self == .square ? Color.onAmber : .white }

        private static func fixed(_ rgb: UInt32) -> Color { Color(light: rgb, dark: rgb) }

        var shape: String {
            switch self {
            case .circle: "circle.fill"
            case .star: "star.fill"
            case .square: "square.fill"
            case .triangle: "triangle.fill"
            case .heart: "heart.fill"
            case .moon: "moon.fill"
            case .drop: "drop.fill"
            case .leaf: "leaf.fill"
            case .sun: "sun.max.fill"
            }
        }

        var nameKey: String {
            switch self {
            case .circle: "game.sequence.shape.circle"
            case .star: "game.sequence.shape.star"
            case .square: "game.sequence.shape.square"
            case .triangle: "game.sequence.shape.triangle"
            case .heart: "game.sequence.shape.heart"
            case .moon: "game.sequence.shape.moon"
            case .drop: "game.sequence.shape.drop"
            case .leaf: "game.sequence.shape.leaf"
            case .sun: "game.sequence.shape.sun"
            }
        }

        var name: String { AppLanguage.localized(nameKey) }
    }

    private static let roundsPerSession = 5

    @State private var difficulty = Difficulty.stored(.repeatSequence)
    @State private var session: SequenceDeal.Session?
    @State private var showing = true
    @State private var lit: Int?
    @State private var tapped: [Int] = []
    @State private var progress = RoundProgress(totalRounds: roundsPerSession)
    @State private var startedAt = Date.now
    @State private var showCelebration = false
    @State private var finalDetail = ""
    @State private var showMiss = false
    /// True during the short pause after a right round, so "That's it!" shows.
    @State private var showRight = false
    @State private var task: Task<Void, Never>?
    /// The board's measured width, inside the screen padding; 0 until it is measured.
    @State private var boardWidth: Double = 0
    /// The grid the sequences were dealt for (#415); a width change that fits a different one deals again.
    @State private var layout = SequenceDeal.fittedLayout(
        for: Difficulty.stored(.repeatSequence), width: Double(UIScreen.main.bounds.width))
    /// A call or the app switcher cut the demo short (#415): show it again on return, uncounted.
    /// `@State`, not `scenePhase`: the pause and demo closures hold an old copy of the view.
    @State private var away = InterruptionPause()
    @State private var isTransitioning = false

    private var instruction: String {
        if showing {
            return AppLanguage.localized("game.sequence.watch")
        }
        if showMiss {
            return AppLanguage.localized("game.sequence.almost")
        }
        if showRight {
            return AppLanguage.localized("game.answer.right")
        }
        return AppLanguage.localized("game.sequence.turn")
    }

    var body: some View {
        VStack(spacing: 24) {
            LevelExplainBanner(
                change: PlanStore.cachedPlan()?.changes[GameID.repeatSequence], game: GameID.repeatSequence,
                hasStarted: progress.completedRounds > 0 || tapped.count > 0)
            Text(AppLanguage.localized("game.sequence.instruction"))
                .font(.title2)
                .multilineTextAlignment(.center)
            Text(instruction)
                .font(.title3.weight(.semibold))
                .multilineTextAlignment(.center)
                .modifier(MissCue(active: $showMiss))
            sequenceGrid
            RoundCounter(progress: progress)
        }
        .gameColumn()
        .padding()
        .fitOrScroll()
        // The board no longer stretches to fill the screen, so the screen does: the paper
        // background from `gameHeader` then reaches every edge.
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .gameHeader(.repeatSequence, instruction: AppLanguage.localized("game.sequence.instruction"))
        .onAppear {
            // Dealt on the first measured width (the geometry action below): the screen is wider than
            // a Slide Over or Split View window, and a deal for it would be dealt again at once.
            if boardWidth > 0 { setup() }
        }
        .onChange(of: scenePhase) { _, newPhase in pauseOrResume(for: newPhase) }
        .onDisappear { task?.cancel() }
        .celebration(isPresented: $showCelebration, game: .repeatSequence, detail: finalDetail, onPlayAgain: setup)
    }

    /// The screen-width value `SequenceDeal` expects: the board plus the padding around it.
    private var screenWidth: Double {
        boardWidth > 0 ? boardWidth + SequenceDeal.horizontalPadding : Double(UIScreen.main.bounds.width)
    }

    private var sequenceGrid: some View {
        let allTiles = Array(Tile.allCases.prefix(layout.columns * layout.rows))
        let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: layout.columns)
        return LazyVGrid(columns: columns, spacing: 16) {
            ForEach(Array(allTiles.enumerated()), id: \.offset) { idx, tile in
                Button {
                    tap(idx)
                } label: {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(tile.color.opacity(lit == idx ? 0.95 : 0.75))
                        .frame(minHeight: 100)
                        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Color.espresso, lineWidth: 3))
                        .overlay {
                            Image(systemName: tile.shape)
                                .font(.system(size: 40, weight: .bold))
                                .foregroundStyle(tile.symbolColor)
                                .accessibilityHidden(true)
                        }
                        .scaleEffect(lit == idx && !reduceMotion ? 1.06 : 1)
                        .animation(.easeInOut(duration: 0.2), value: lit)
                }
                .buttonStyle(.plain)
                .disabled(showing || isTransitioning)
                .accessibilityLabel(tile.name)
                .accessibilityHint(AppLanguage.localized("game.sequence.a11y.hint"))
            }
        }
        .onGeometryChange(for: CGFloat.self) {
            $0.size.width
        } action: { width in
            guard width > 0 else { return }
            boardWidth = Double(width)
            if session == nil { setup() } else { fitLayoutToBoard() }
        }
    }

    /// A rotation or split view can make the board fit a different grid. Deal the sequences still
    /// to play again for it, so no tile is stranded off the board, and show the new one (#415).
    private func fitLayoutToBoard() {
        let fitted = SequenceDeal.fittedLayout(for: difficulty, width: screenWidth)
        guard fitted != layout, session?.current != nil else { return }
        layout = fitted
        var gen = SystemRandomNumberGenerator()
        session?.redeal(level: difficulty, width: screenWidth, using: &gen)
        showNext()
    }

    /// A call or the app switcher during the demo must not cost the round (#415): stop the demo,
    /// and when the app is active again show it again. Taps cannot happen meanwhile (`showing`),
    /// so no attempt is counted. The answer pauses are left alone: cancelling one would lock the board.
    private func pauseOrResume(for newPhase: ScenePhase) {
        if newPhase != .active {
            let demoing = showing && session != nil
            away.leave(roundRunning: demoing)
            if demoing { task?.cancel() }
        } else if away.comeBack() {
            showNext()
        }
    }

    private func setup() {
        difficulty = Difficulty.stored(.repeatSequence)
        task?.cancel()
        progress.reset()
        tapped = []
        lit = nil
        showing = true
        isTransitioning = false
        showMiss = false
        showRight = false
        startedAt = .now
        var gen = SystemRandomNumberGenerator()
        layout = SequenceDeal.fittedLayout(for: difficulty, width: screenWidth)
        let sequences = (0..<Self.roundsPerSession).map { _ in
            SequenceDeal.deal(level: difficulty, width: screenWidth, using: &gen)
        }
        session = SequenceDeal.Session(sequences: sequences)
        showNext()
    }

    private func showNext() {
        guard let seq = session?.current else {
            finish()
            return
        }
        showing = true
        showRight = false
        isTransitioning = false
        tapped = []
        // Started while the app is away (an answer pause ended in the background): `showing` keeps the
        // board locked, and the demo plays when the app is active again.
        guard away.roundStarts() else {
            task?.cancel()
            return
        }
        // VoiceOver: speak the sequence names.
        let names = seq.compactMap { idx in
            Tile.allCases[safe: idx]?.name
        }.joined(separator: ", ")
        if !names.isEmpty {
            AccessibilityNotification.Announcement(names).post()
        }
        let rules = SequenceDeal.rules(for: difficulty, width: screenWidth)
        task?.cancel()
        task = Task { @MainActor in
            for idx in seq {
                guard !Task.isCancelled else { return }
                lit = idx
                SoundPlayer.playTile(idx)
                // A cancelled sleep throws at once: leave before touching `lit`, or a demo stopped by an
                // interruption could put out the first tile of the demo that replaces it.
                do {
                    try await Task.sleep(for: .seconds(rules.light))
                    lit = nil
                    try await Task.sleep(for: .seconds(0.25))
                } catch { return }
            }
            // A demo stopped by an interruption is shown again, so it must not unlock the board.
            guard !Task.isCancelled else { return }
            showing = false
        }
    }

    private func tap(_ idx: Int) {
        guard !showing, !isTransitioning, session?.current != nil else { return }
        tapped.append(idx)
        Feedback.playTile(idx)
        lit = idx
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.15))
            lit = nil
        }
        // Ask the rules after every tap: a wrong tap is caught at once, a correct
        // prefix stays quiet until the sequence is complete.
        guard let result = session?.record(tapped: tapped), result != .keepGoing else { return }
        tapped = []
        // The result tone below deliberately interrupts the last tile's note: the result wins.
        switch result {
        case .correct:
            showMiss = false
            showRight = true
            Feedback.play(.success)
            // Short on purpose: showNext() announces the next names ~0.6 s later.
            AccessibilityNotification.Announcement(AppLanguage.localized("game.answer.right")).post()
            _ = progress.completeRound()
            if progress.isFinished {
                finish()
            } else {
                // Brief pause before next show — keep input disabled.
                isTransitioning = true
                task?.cancel()
                task = Task { @MainActor in
                    try? await Task.sleep(for: .seconds(0.6))
                    guard !Task.isCancelled else { return }
                    showNext()
                }
            }
        case .almost:
            // First miss: warm cue then replay same sequence once.
            showMiss = true
            Feedback.play(.miss)
            AccessibilityNotification.Announcement(AppLanguage.localized("game.sequence.almost")).post()
            // If we already consumed replay, session moved on.
            let wasReplay = session?.needsReplay == true
            if wasReplay {
                // Still need to replay: show again after cue.
                isTransitioning = true
                task?.cancel()
                task = Task { @MainActor in
                    try? await Task.sleep(for: .seconds(0.8))
                    guard !Task.isCancelled else { return }
                    showMiss = false
                    showNext()
                }
            } else {
                // Second miss just advanced.
                _ = progress.completeRound()
                if progress.isFinished {
                    finish()
                } else {
                    isTransitioning = true
                    task?.cancel()
                    task = Task { @MainActor in
                        try? await Task.sleep(for: .seconds(0.8))
                        guard !Task.isCancelled else { return }
                        showMiss = false
                        showNext()
                    }
                }
            }
        case .keepGoing:
            break
        }
    }

    private func finish() {
        let elapsed = Int(Date.now.timeIntervalSince(startedAt))
        let sess = session
        modelContext.record(
            GameSession(
                gameID: .repeatSequence, score: (sess?.correct ?? 0) * 10,
                rounds: Self.roundsPerSession, durationSeconds: elapsed,
                correct: sess?.correct ?? 0, attempts: sess?.attempts ?? 0,
                difficulty: difficulty))
        finalDetail = String(format: AppLanguage.localized("game.celebration.rounds %lld"), Self.roundsPerSession)
        showCelebration = true
    }
}

extension Collection {
    fileprivate subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

#Preview {
    RepeatSequenceView()
}
