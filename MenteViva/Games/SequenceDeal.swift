import Foundation

/// Repeat the Sequence logic (#216): pure deal and session rules, no UI.
nonisolated enum SequenceDeal {
    /// Tiles per level.
    static let columnsByLevel: [Int] = [2, 2, 2, 2, 2, 3, 3, 3, 3, 3]
    static let rowsByLevel: [Int] = [2, 2, 3, 3, 3, 3, 3, 3, 3, 3]
    /// Sequence length per level.
    static let lengthByLevel: [Int] = [2, 3, 3, 4, 4, 5, 5, 6, 7, 8]
    /// Light duration per level (seconds).
    static let lightByLevel: [Double] = [1.0, 1.0, 0.9, 0.9, 0.8, 0.8, 0.7, 0.65, 0.6, 0.55]

    static let tileMin: Double = 100
    static let gap: Double = 16
    static let horizontalPadding: Double = 32

    /// Grid for a level before fit capping.
    static func layout(for difficulty: Difficulty) -> (columns: Int, rows: Int) {
        (difficulty.values(columnsByLevel), difficulty.values(rowsByLevel))
    }

    /// Whether 3×3 at `width` keeps 100pt tiles.
    static func fittedLayout(for difficulty: Difficulty, width: Double) -> (columns: Int, rows: Int) {
        let (cols, rows) = layout(for: difficulty)
        if cols == 3, rows == 3 {
            let gridWidth = max(0, width - horizontalPadding)
            let tileWidth = (gridWidth - gap * Double(cols - 1)) / Double(cols)
            if tileWidth < tileMin {
                return (2, 3)
            }
        }
        return (cols, rows)
    }

    /// Rules for a level and width (fit-capped).
    static func rules(for difficulty: Difficulty, width: Double) -> (columns: Int, rows: Int, length: Int, light: Double) {
        let (cols, rows) = fittedLayout(for: difficulty, width: width)
        var length = difficulty.values(lengthByLevel)
        // Fit cap: 3×3 that doesn't fit becomes 2×3 with length+1 (spec).
        let baseLayout = layout(for: difficulty)
        if baseLayout.columns == 3, baseLayout.rows == 3, (cols, rows) == (2, 3) {
            length += 1
        }
        let light = difficulty.values(lightByLevel)
        return (cols, rows, length, light)
    }

    /// A sequence of tile indices for a level.
    static func deal(level: Difficulty, width: Double = 400, using generator: inout some RandomNumberGenerator) -> [Int] {
        let (cols, rows, length, _) = rules(for: level, width: width)
        let count = cols * rows
        var seq: [Int] = []
        for _ in 0..<length {
            var next = Int.random(in: 0..<count, using: &generator)
            // Levels 1-4 have no back-to-back repeats.
            if level.level <= 4, let last = seq.last {
                while next == last {
                    next = Int.random(in: 0..<count, using: &generator)
                }
            }
            seq.append(next)
        }
        return seq
    }

    /// Result of tapping tiles for one sequence.
    enum Result: Equatable {
        case correct
        case keepGoing
        case almost
    }

    /// One session: 5 sequences, replay once on miss.
    struct Session {
        var sequences: [[Int]]
        var index: Int = 0
        var attempts: Int = 0
        var correct: Int = 0
        var needsReplay: Bool = false

        init(sequences: [[Int]]) {
            self.sequences = sequences
        }

        var current: [Int]? {
            guard index < sequences.count else { return nil }
            return sequences[index]
        }

        var isFinished: Bool { index >= sequences.count }

        /// Record a tap of the full sequence length. Returns `.almost` on first
        /// miss (so caller can replay), second miss moves on warmly.
        mutating func record(tapped: [Int]) -> Result {
            guard let expected = current else { return .correct }
            // Partial prefix still needs more taps — not a completed attempt.
            if expected.starts(with: tapped), tapped.count < expected.count {
                return .keepGoing
            }
            attempts += 1
            if tapped == expected {
                correct += 1
                index += 1
                needsReplay = false
                return .correct
            }
            if !needsReplay {
                needsReplay = true
                return .almost
            }
            // Second miss: move on.
            index += 1
            needsReplay = false
            return .almost
        }
    }
}
