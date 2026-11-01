import SwiftData
import SwiftUI
import UIKit

/// Sudoku (#179): a 4×4, 6×6 or 9×9 board made fresh each game (`SudokuPuzzle`,
/// levels 1–10 in #201). Tap a square, then a big number. A number that doesn't
/// fit gets a gentle "try another"; "Show me one" fills the square when he's
/// stuck. The selection moves only when the player moves it, and a number with
/// every copy on the board leaves the pad (#510). No timer.
struct SudokuView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @ScaledMetric(relativeTo: .largeTitle) private var digitSize: CGFloat = 36

    @State private var difficulty = Difficulty.stored(.sudoku)
    @State private var puzzle: SudokuPuzzle?
    /// The play area inside the screen's padding, measured so the board and pad share what the
    /// screen can carry (#400). Zero until measured.
    @State private var playArea = CGSize.zero
    @State private var entries: [Int: Int] = [:]  // square -> number he placed
    @State private var shown: Set<Int> = []  // squares filled by "Show me one"
    @State private var selected: Int?
    @State private var correct = 0
    @State private var attempts = 0
    @State private var startedAt = Date.now
    @State private var missed = false
    @State private var missedSquare: Int?
    /// Squares of just-finished units, wearing the game's ink wash (#239).
    @State private var washed: Set<Int> = []
    @State private var washTask: Task<Void, Never>?
    /// The gentle note in the note slot, if any.
    @State private var note: Note?
    @State private var showCelebration = false
    @State private var finalDetail = ""

    /// Which gentle note shows: the near miss, or the ask to choose a square first (#510).
    private enum Note {
        case almost
        case chooseSquare

        var key: String {
            switch self {
            case .almost: "game.sudoku.miss"
            case .chooseSquare: "game.sudoku.tapfirst"
            }
        }
    }

    var body: some View {
        VStack(spacing: 20) {
            LevelExplainBanner(
                game: GameID.sudoku, hasStarted: attempts > 0 || !entries.isEmpty)
            Text(AppLanguage.localized("game.sudoku.instruction"))
                .font(.title2)
                .multilineTextAlignment(.center)

            if let puzzle {
                let arrangement = arrangement(for: puzzle)
                if arrangement.pad == .beside {
                    // Wide iPad: the board on the left, its keys and the note on the right (#400).
                    HStack(spacing: 20) {
                        board(puzzle, side: arrangement.side)
                        VStack(spacing: 20) {
                            almostNote
                            numberPad(puzzle, arrangement)
                            showMeButton
                        }
                    }
                } else {
                    almostNote
                    board(puzzle, side: arrangement.side)
                    numberPad(puzzle, arrangement)
                    showMeButton
                }
            } else {
                almostNote
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .fitOrScroll()
        // Measured outside the padding and the fit-or-scroll, so it is the space the screen offers
        // and not the height of what is in it.
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onGeometryChange(for: CGSize.self) {
            CGSize(width: $0.size.width - 32, height: $0.size.height - 32)
        } action: { area in
            guard area.width > 0, area.height > 0 else { return }
            playArea = area
            // A board that no longer fits by width (a 6×6 turned to portrait on a small iPhone)
            // is dealt again at a size that does: the squares never drop under 60pt. One that is
            // only too tall (a 9×9 turned to a short landscape) is kept, with its progress, and scrolls.
            if let puzzle, puzzle.fits(width: area.width) { return }
            restart()
        }
        .leaveGuard(inProgress: attempts > 0, celebrating: showCelebration)
        .gameHeader(.sudoku, instruction: AppLanguage.localized("game.sudoku.instruction"))
        .firstPlayGuide(.sudoku, line: AppLanguage.localized("game.sudoku.guide"), example: guideExample)
        .celebration(isPresented: $showCelebration, game: .sudoku, detail: finalDetail, onPlayAgain: restart)
    }

    // MARK: - Board

    /// The height to budget a board by: every iPad window counts it, Split View included, so a
    /// narrow window walks down to a board that fits; a phone is laid out by width as before (#400).
    private var budgetHeight: Double? {
        GameColumn.isPad ? playArea.height : nil
    }

    /// Square side and pad placement for the dealt board.
    private func arrangement(for puzzle: SudokuPuzzle) -> (side: Double, pad: SudokuPuzzle.PadPlacement) {
        SudokuPuzzle.keptArrangement(size: puzzle.size, width: playArea.width, height: budgetHeight)
    }

    /// The same soft amber note as Quick Eyes: kind and easy to read.
    @ViewBuilder
    private var almostNote: some View {
        if let note {
            AlmostNote(text: AppLanguage.localized(note.key))
        }
    }

    private var showMeButton: some View {
        Button(action: showMe) {
            Text(AppLanguage.localized("game.sudoku.showme"))
                .font(.title2.weight(.semibold))
        }
        .buttonStyle(AnswerTileStyle(strength: 0.08, minHeight: SudokuPuzzle.showMeHeight))
    }

    private func board(_ puzzle: SudokuPuzzle, side: Double) -> some View {
        let n = puzzle.size
        return Grid(horizontalSpacing: SudokuPuzzle.gap, verticalSpacing: SudokuPuzzle.gap) {
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
            .background(
                GameID.sudoku.ink.opacity(washed.contains(index) ? 0.35 : (shaded ? 0.14 : 0.05)),
                in: .rect(cornerRadius: 8))

        if let value {
            face.accessibilityLabel(
                String(format: AppLanguage.localized("game.sudoku.a11y.cell %lld %lld %lld"), row + 1, column + 1, value)
            )
            // Each placed digit pops gently; Reduce Motion fades it in.
            .transition(reduceMotion ? .opacity : .scale(scale: 1.12).combined(with: .opacity))
        } else {
            Button {
                selected = index
                if note == .chooseSquare { note = nil }
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

    /// Columns of keys as `SudokuPuzzle.padColumns` says: four on a phone (three for 6×6), one row
    /// of nine under a portrait iPad's 9×9 board, three beside a landscape iPad's, or one row of
    /// four beside a 4×4 (#400).
    /// The row is as wide as the board above it, so the keys line up with the squares.
    private func numberPad(
        _ puzzle: SudokuPuzzle, _ arrangement: (side: Double, pad: SudokuPuzzle.PadPlacement)
    ) -> some View {
        let pad = arrangement.pad
        let count = SudokuPuzzle.padColumns(size: puzzle.size, pad: pad)
        let spacing = pad == .row ? SudokuPuzzle.padSpacing : 12
        let rowWidth = SudokuPuzzle.rowPadWidth(side: arrangement.side, width: playArea.width)
        let keyHeight = pad == .row ? SudokuPuzzle.padKeyHeight(width: rowWidth) : 100
        let columns = Array(repeating: GridItem(.flexible(), spacing: spacing), count: count)
        let complete = puzzle.completedNumbers(entries: entries)
        return LazyVGrid(columns: columns, spacing: spacing) {
            ForEach(1...puzzle.size, id: \.self) { digit in
                let done = complete.contains(digit)
                Button {
                    place(digit)
                } label: {
                    Text(verbatim: "\(digit)")
                        .font(.system(size: digitSize, weight: .semibold))
                        .minimumScaleFactor(0.5)
                        // A complete number keeps its place, faded, with a tick: not colour alone (#510).
                        .opacity(done ? 0.35 : 1)
                        .overlay(alignment: .topTrailing) {
                            if done {
                                Image(systemName: "checkmark").font(.footnote.weight(.bold))
                                    .offset(x: 14, y: -10)
                            }
                        }
                }
                .buttonStyle(AnswerTileStyle(minHeight: keyHeight))
                .disabled(done)
                .accessibilityLabel(String(format: AppLanguage.localized("game.sudoku.a11y.put %lld"), digit))
                .accessibilityValue(done ? AppLanguage.localized("game.sudoku.a11y.allplaced") : "")
                .guideTarget(digit == guideDigit)
            }
        }
        .frame(maxWidth: pad == .row ? rowWidth : .infinity)
    }

    // MARK: - Play

    private var openSquares: [Int] {
        guard let puzzle else { return [] }
        return puzzle.solution.indices.filter { !puzzle.givens.contains($0) && entries[$0] == nil }
    }

    /// The number that fits the chosen square, or the first open one while nothing is chosen: the
    /// first-play guide points at it (#243).
    private var guideDigit: Int? {
        guard let puzzle, let index = selected ?? openSquares.first else { return nil }
        return puzzle.solution[index]
    }

    /// The guide's example move in words, for VoiceOver and for reading.
    private var guideExample: String {
        guard let guideDigit else { return "" }
        return String(format: AppLanguage.localized("guide.sudoku.example %lld"), guideDigit)
    }

    private func deal() {
        var generator = SystemRandomNumberGenerator()
        let layout = SudokuPuzzle.layout(for: difficulty, width: playArea.width, height: budgetHeight)
        puzzle = SudokuPuzzle.make(layout: layout, using: &generator)
        selected = nil
    }

    private func restart() {
        difficulty = Difficulty.stored(.sudoku)
        washTask?.cancel()
        washTask = nil
        washed = []
        entries = [:]
        shown = []
        correct = 0
        attempts = 0
        note = nil
        startedAt = .now
        deal()
    }

    private func place(_ digit: Int) {
        guard let puzzle else { return }
        guard case .place(let index) = SudokuPuzzle.padTap(selected: selected), entries[index] == nil else {
            askForSquare()
            return
        }
        attempts += 1
        if puzzle.solution[index] == digit {
            correct += 1
            let units = puzzle.completedUnits(after: index, entries: filled(putting: digit, at: index, in: puzzle))
            let finishes = openSquares.count == 1
            fill(index, with: digit)
            if finishes {
                // Only the celebration plays: no wash, no tone. The finished
                // units are still announced, once, like any other placement.
                if !units.isEmpty { announceAll(units) }
                finish()
            } else {
                // One tone even when several units finish together.
                Feedback.play(.success)
                if !units.isEmpty { reward(units, in: puzzle) }
            }
        } else {
            missedSquare = index
            missed = true
            note = .almost
            Feedback.play(.miss)
            // Posted here, not from a `.task(id:)`: two misses in a row keep the same text.
            AccessibilityNotification.Announcement(AppLanguage.localized("game.sudoku.miss")).post()
        }
    }

    /// The gentle "Tap a square first": no sound, no try. Posted here, not from a `.task(id:)`, so
    /// a second tap with the same text is still announced.
    private func askForSquare() {
        note = .chooseSquare
        AccessibilityNotification.Announcement(AppLanguage.localized(Note.chooseSquare.key)).post()
    }

    /// Fills the selected square with its answer; it counts as a try, not a right answer. With no
    /// square chosen it asks for one, as the pad does.
    private func showMe() {
        guard let puzzle else { return }
        guard let index = selected, entries[index] == nil else {
            askForSquare()
            return
        }
        attempts += 1
        shown.insert(index)
        let digit = puzzle.solution[index]
        let units = puzzle.completedUnits(after: index, entries: filled(putting: digit, at: index, in: puzzle))
        let finishes = openSquares.count == 1
        fill(index, with: digit)
        // A shown square earns the wash and the announcement, never a tone.
        if finishes {
            if !units.isEmpty { announceAll(units) }
            finish()
        } else if !units.isEmpty {
            reward(units, in: puzzle)
        }
    }

    /// Every filled square after putting `digit` at `index`: givens plus entries.
    private func filled(putting digit: Int, at index: Int, in puzzle: SudokuPuzzle) -> [Int: Int] {
        var filled = entries
        for given in puzzle.givens { filled[given] = puzzle.solution[given] }
        filled[index] = digit
        return filled
    }

    /// A finished unit's small reward: the game's ink washes over its squares
    /// for 0.6 s, and VoiceOver names each finished unit once.
    private func reward(_ units: [SudokuPuzzle.Unit], in puzzle: SudokuPuzzle) {
        washTask?.cancel()
        withAnimation(.easeIn(duration: 0.15)) {
            washed = Set(units.flatMap { puzzle.squares(of: $0) })
        }
        washTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.6))
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.2)) { washed = [] }
        }
        announceAll(units)
    }

    /// Names each finished unit once for VoiceOver.
    private func announceAll(_ units: [SudokuPuzzle.Unit]) {
        let message = units.map { announce($0) }.joined(separator: ", ")
        UIAccessibility.post(notification: .announcement, argument: message)
    }

    private func announce(_ unit: SudokuPuzzle.Unit) -> String {
        switch unit {
        case .row(let row):
            String(format: AppLanguage.localized("game.sudoku.done.row %lld"), row + 1)
        case .column(let column):
            String(format: AppLanguage.localized("game.sudoku.done.column %lld"), column + 1)
        case .box(let box):
            String(format: AppLanguage.localized("game.sudoku.done.box %lld"), box + 1)
        }
    }

    /// Fills one square and clears the selection; the callers decide the finish from their
    /// `finishes` flag, so this never finishes twice.
    private func fill(_ index: Int, with digit: Int) {
        // The spring animates the placed digit's pop; Reduce Motion fades it.
        withAnimation(.spring(duration: 0.25)) {
            entries[index] = digit
        }
        note = nil
        // No auto-jump (#510): the player taps the next square.
        selected = nil
    }

    private func finish() {
        guard let puzzle else { return }
        selected = nil
        let blanks = puzzle.solution.count - puzzle.givens.count
        modelContext.record(
            GameSession(
                gameID: .sudoku,
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
