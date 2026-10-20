import SwiftData
import SwiftUI

/// Sudoku (#179): a 4×4 or 6×6 board made fresh each game (`SudokuPuzzle`). Tap a
/// square, then a big number. A number that doesn't fit gets a gentle "try another";
/// "Show me one" fills the square when he's stuck. No timer.
struct SudokuView: View {
    @Environment(\.modelContext) private var modelContext

    /// Space between squares; the 60pt rule in `SudokuPuzzle.layout` leaves room for it.
    private static let gap = 2.0

    @ScaledMetric(relativeTo: .largeTitle) private var digitSize: CGFloat = 36

    @State private var difficulty = Difficulty.stored(.sudoku)
    @State private var puzzle: SudokuPuzzle?
    @State private var boardWidth = 0.0
    @State private var entries: [Int: Int] = [:]  // square -> number he placed
    @State private var shown: Set<Int> = []  // squares filled by "Show me one"
    @State private var selected: Int?
    @State private var correct = 0
    @State private var attempts = 0
    @State private var startedAt = Date.now
    @State private var missed = false
    @State private var missedSquare: Int?
    @State private var showAlmost = false
    @State private var showCelebration = false
    @State private var finalDetail = ""

    var body: some View {
        VStack(spacing: 20) {
            Text(AppLanguage.localized("game.sudoku.instruction"))
                .font(.title2)
                .multilineTextAlignment(.center)

            if showAlmost {
                // The same soft amber note as Quick Eyes: kind and easy to read.
                Text(AppLanguage.localized("game.sudoku.miss"))
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(Color.todaysPick)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color.amber.opacity(0.24), in: .rect(cornerRadius: 14))
            }

            if let puzzle {
                board(puzzle)
                numberPad(puzzle)
                Button(action: showMe) {
                    Text(AppLanguage.localized("game.sudoku.showme"))
                        .font(.title2.weight(.semibold))
                }
                .buttonStyle(AnswerTileStyle(strength: 0.08, minHeight: 70))
            }
        }
        .frame(maxWidth: .infinity)
        .onGeometryChange(for: Double.self) {
            $0.size.width
        } action: { width in
            guard width > 0 else { return }
            boardWidth = width
            if puzzle == nil { deal() }
        }
        .padding()
        .fitOrScroll()
        .gameHeader(.sudoku, instruction: AppLanguage.localized("game.sudoku.instruction"))
        .celebration(isPresented: $showCelebration, game: .sudoku, detail: finalDetail, onPlayAgain: restart)
    }

    // MARK: - Board

    private func board(_ puzzle: SudokuPuzzle) -> some View {
        let n = puzzle.size
        let side = min(100, (boardWidth - Self.gap * Double(n - 1)) / Double(n))
        return Grid(horizontalSpacing: Self.gap, verticalSpacing: Self.gap) {
            ForEach(0..<n, id: \.self) { row in
                GridRow {
                    ForEach(0..<n, id: \.self) { column in
                        square(row * n + column, in: puzzle, side: side)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func square(_ index: Int, in puzzle: SudokuPuzzle, side: Double) -> some View {
        let row = index / puzzle.size
        let column = index % puzzle.size
        // Alternate boxes get a light tint so the boxes read at a glance.
        let shaded = (row / puzzle.boxRows + column / puzzle.boxColumns).isMultiple(of: 2)
        let value = puzzle.givens.contains(index) ? puzzle.solution[index] : entries[index]
        let face = Text(value.map { "\($0)" } ?? " ")
            .font(.system(size: digitSize, weight: puzzle.givens.contains(index) ? .bold : .semibold))
            .foregroundStyle(
                puzzle.givens.contains(index) ? Color.primary : GameID.sudoku.ink.opacity(shown.contains(index) ? 0.55 : 1)
            )
            .minimumScaleFactor(0.5)
            .frame(width: side, height: side)
            .background(GameID.sudoku.ink.opacity(shaded ? 0.14 : 0.05), in: .rect(cornerRadius: 8))

        if let value {
            face.accessibilityLabel(
                String(format: AppLanguage.localized("game.sudoku.a11y.cell %lld %lld %lld"), row + 1, column + 1, value))
        } else {
            Button {
                selected = index
            } label: {
                face.overlay {
                    if selected == index {
                        RoundedRectangle(cornerRadius: 8).strokeBorder(GameID.sudoku.ink, lineWidth: 4)
                    }
                }
            }
            .buttonStyle(.plain)
            .modifier(MissCue(active: missedSquare == index ? $missed : .constant(false)))
            .accessibilityLabel(
                String(format: AppLanguage.localized("game.sudoku.a11y.empty %lld %lld"), row + 1, column + 1)
            )
            .accessibilityValue(selected == index ? AppLanguage.localized("game.sudoku.a11y.selected") : "")
            .accessibilityAddTraits(selected == index ? .isSelected : [])
        }
    }

    private func numberPad(_ puzzle: SudokuPuzzle) -> some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: puzzle.size == 6 ? 3 : 4)
        return LazyVGrid(columns: columns, spacing: 12) {
            ForEach(1...puzzle.size, id: \.self) { digit in
                Button {
                    place(digit)
                } label: {
                    Text(verbatim: "\(digit)")
                        .font(.system(size: digitSize, weight: .semibold))
                }
                .buttonStyle(AnswerTileStyle(minHeight: 80))
                .accessibilityLabel(String(format: AppLanguage.localized("game.sudoku.a11y.put %lld"), digit))
            }
        }
    }

    // MARK: - Play

    private var openSquares: [Int] {
        guard let puzzle else { return [] }
        return puzzle.solution.indices.filter { !puzzle.givens.contains($0) && entries[$0] == nil }
    }

    private func deal() {
        var generator = SystemRandomNumberGenerator()
        puzzle = SudokuPuzzle.make(difficulty: difficulty, width: boardWidth, using: &generator)
        selected = openSquares.first
    }

    private func restart() {
        entries = [:]
        shown = []
        correct = 0
        attempts = 0
        showAlmost = false
        startedAt = .now
        deal()
    }

    private func place(_ digit: Int) {
        guard let puzzle, let index = selected, entries[index] == nil else { return }
        attempts += 1
        if puzzle.solution[index] == digit {
            correct += 1
            fill(index, with: digit)
            Feedback.play(.success)
        } else {
            missedSquare = index
            missed = true
            showAlmost = true
            Feedback.play(.miss)
        }
    }

    /// Fills the selected square with its answer; it counts as a try, not a right answer.
    private func showMe() {
        guard let puzzle, let index = selected, entries[index] == nil else { return }
        attempts += 1
        shown.insert(index)
        fill(index, with: puzzle.solution[index])
    }

    private func fill(_ index: Int, with digit: Int) {
        entries[index] = digit
        showAlmost = false
        let open = openSquares
        guard !open.isEmpty else { return finish() }
        selected = open.first { $0 > index } ?? open.first
    }

    private func finish() {
        guard let puzzle else { return }
        selected = nil
        let blanks = puzzle.solution.count - puzzle.givens.count
        modelContext.record(
            GameSession(
                gameID: .sudoku, score: correct * 10,
                rounds: blanks, durationSeconds: Int(Date.now.timeIntervalSince(startedAt)),
                correct: correct, attempts: attempts,
                difficulty: difficulty))
        finalDetail = String(format: AppLanguage.localized("game.celebration.squares %lld"), blanks)
        showCelebration = true
    }
}

#Preview {
    SudokuView()
}
