import SwiftData
import SwiftUI

/// Repeat the Sequence: watch the tiles light up and tap them in order.
/// Levels 1-10 change grid and length; on a narrow screen a 3×3 board
/// falls back to 2×3 with length+1 (#216).
struct RepeatSequenceView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// One tile: colour + shape + name, so colour alone never decides.
    private enum Tile: CaseIterable {
        case circle, star, square, triangle, heart, moon, drop, leaf, sun

        var color: Color {
            switch self {
            case .circle: .red
            case .star: .blue
            case .square: .green
            case .triangle: .orange
            case .heart: .pink
            case .moon: .purple
            case .drop: Color(red: 0.0, green: 0.55, blue: 0.8)
            case .leaf: Color(red: 0.2, green: 0.6, blue: 0.2)
            case .sun: Color(red: 0.8, green: 0.55, blue: 0.0)
            }
        }

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
    @State private var task: Task<Void, Never>?
    @State private var boardWidth: Double = 0
    @State private var isTransitioning = false

    private var instruction: String {
        if showing {
            return AppLanguage.localized("game.sequence.watch")
        }
        if showMiss {
            return AppLanguage.localized("game.sequence.almost")
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
        .padding()
        .fitOrScroll()
        .gameHeader(.repeatSequence, instruction: AppLanguage.localized("game.sequence.instruction"))
        .onAppear { setup() }
        .onDisappear { task?.cancel() }
        .celebration(isPresented: $showCelebration, game: .repeatSequence, detail: finalDetail, onPlayAgain: setup)
    }

    @ViewBuilder
    private var sequenceGrid: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            // Use a single width source for deal and grid; proxy is already inside .padding(),
            // so convert to the screen-width value SequenceDeal expects.
            let rules = SequenceDeal.rules(for: difficulty, width: width + 32)
            let cols = rules.columns
            let allTiles = Array(Tile.allCases.prefix(cols * rules.rows))
            let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: cols)
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(Array(allTiles.enumerated()), id: \.offset) { idx, tile in
                    Button {
                        tap(idx)
                    } label: {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(tile.color.opacity(lit == idx ? 0.95 : 0.75))
                            .frame(minHeight: 100)
                            .overlay {
                                Image(systemName: tile.shape)
                                    .font(.system(size: 40, weight: .bold))
                                    .foregroundStyle(.white)
                                    .shadow(color: .black.opacity(0.35), radius: 2, y: 1)
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
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .onAppear { boardWidth = width }
            .onChange(of: width) { _, newValue in boardWidth = newValue }
        }
        .frame(minHeight: 260)
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
        startedAt = .now
        var gen = SystemRandomNumberGenerator()
        let width = boardWidth > 0 ? boardWidth + 32 : Double(UIScreen.main.bounds.width)
        let sequences = (0..<Self.roundsPerSession).map { _ in
            SequenceDeal.deal(level: difficulty, width: width, using: &gen)
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
        isTransitioning = false
        tapped = []
        // VoiceOver: speak the sequence names.
        let names = seq.compactMap { idx in
            Tile.allCases[safe: idx]?.name
        }.joined(separator: ", ")
        if !names.isEmpty {
            AccessibilityNotification.Announcement(names).post()
        }
        let width = boardWidth > 0 ? boardWidth + 32 : Double(UIScreen.main.bounds.width)
        let rules = SequenceDeal.rules(for: difficulty, width: width)
        task?.cancel()
        task = Task { @MainActor in
            for idx in seq {
                guard !Task.isCancelled else { return }
                lit = idx
                SoundPlayer.play(.success)
                try? await Task.sleep(for: .seconds(rules.light))
                lit = nil
                try? await Task.sleep(for: .seconds(0.25))
            }
            showing = false
        }
    }

    private func tap(_ idx: Int) {
        guard !showing, !isTransitioning, session?.current != nil else { return }
        tapped.append(idx)
        SoundPlayer.play(.success)
        lit = idx
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.15))
            lit = nil
        }
        guard let expected = session?.current, tapped.count == expected.count else { return }
        let result = session?.record(tapped: tapped)
        tapped = []
        switch result {
        case .correct:
            showMiss = false
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
            SoundPlayer.play(.miss)
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
        case .keepGoing, .none:
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
