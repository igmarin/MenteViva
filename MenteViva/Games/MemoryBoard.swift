import Foundation

/// #237: Memory Lane's pure board — which cards are face up after each tap.
///
/// The view animates this state and owns the 1.2 s turn-back timer; the board
/// only decides what each tap means, so tests can drive a whole game without
/// touching the UI.
struct MemoryBoard {
    /// What one tap did, so the view knows what to animate and which cue to play.
    enum Tap: Equatable {
        /// The card was already face up or found; nothing changes.
        case ignored
        /// One card turned up; the next tap decides the pair.
        case turnedUp(Int)
        /// Both cards match; `found` holds every found card index.
        case matched(pair: [Int], found: Set<Int>)
        /// Two different cards; the pair stays up until the view turns it back.
        case missed(pair: [Int])
        /// A different card tapped while a missed pair was showing: the pair
        /// turned back at once, and only the new card is face up.
        case missedBackThenUp(turnedBack: [Int], up: Int)
    }

    /// Pair identity per card, index-aligned; two cards match when equal.
    private(set) var pairs: [Int]
    /// Unmatched cards currently face up (at most one; empty while a miss shows).
    private(set) var faceUp: Set<Int> = []
    /// Found card indices, face up for the rest of the game.
    private(set) var matched: Set<Int> = []
    /// The missed pair the view is showing, until it turns back.
    private(set) var pendingMiss: [Int] = []
    /// Bumped on every pair decision and deal; the view's timer only turns a
    /// pair back when its generation still matches, so a stale timer can never
    /// touch a newer board.
    private(set) var generation = 0

    init(pairs: [Int]) {
        self.pairs = pairs
    }

    var isComplete: Bool { !pairs.isEmpty && matched.count == pairs.count }

    mutating func tap(_ index: Int) -> Tap {
        // Cards of the showing miss ignore taps, as they did before the board
        // existed; only a different card turns the pair back. Found cards and
        // the card already up ignore taps too.
        guard pairs.indices.contains(index), !matched.contains(index), !faceUp.contains(index),
            !pendingMiss.contains(index)
        else {
            return .ignored
        }
        if !pendingMiss.isEmpty {
            let back = pendingMiss
            pendingMiss = []
            faceUp = [index]
            generation += 1
            return .missedBackThenUp(turnedBack: back, up: index)
        }
        faceUp.insert(index)
        let up = faceUp.sorted()
        guard up.count == 2 else { return .turnedUp(index) }
        generation += 1
        if pairs[up[0]] == pairs[up[1]] {
            matched.formUnion(up)
            faceUp = []
            return .matched(pair: up, found: matched)
        }
        pendingMiss = up
        faceUp = []
        return .missed(pair: up)
    }

    /// The view's turn-back timer fired: turn the pair back only if no tap or
    /// deal happened since. Returns the indices to turn face down.
    mutating func resolveMiss(generation: Int) -> [Int] {
        guard generation == self.generation, !pendingMiss.isEmpty else { return [] }
        defer { pendingMiss = [] }
        return pendingMiss
    }

    mutating func deal(pairs: [Int]) {
        self.pairs = pairs
        faceUp = []
        matched = []
        pendingMiss = []
        generation += 1
    }
}
