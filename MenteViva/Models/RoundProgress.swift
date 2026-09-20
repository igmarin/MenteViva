import Foundation

/// Round bookkeeping for a fixed-length game session.
///
/// Extracted because every game hand-rolled this and hand-rolled counters are
/// where the bugs live: the Name the Herd crash (#30) was a counter that ran one
/// past the end and indexed an array in `body`. One type, one set of boundary
/// tests, no game invents its own arithmetic.
///
/// `nonisolated` because default actor isolation is MainActor (Xcode 27
/// recommended setting) and this is plain data used from any context.
nonisolated struct RoundProgress: Equatable {
    let totalRounds: Int
    private(set) var completedRounds = 0

    init(totalRounds: Int) {
        self.totalRounds = max(0, totalRounds)
    }

    /// 1-based round number for display, clamped to the session length so a
    /// finished session still shows something sane instead of 11/10.
    var displayRound: Int {
        min(completedRounds + 1, max(totalRounds, 1))
    }

    var isFinished: Bool {
        completedRounds >= totalRounds
    }

    /// Records one completed round; returns true when that was the last one.
    /// Idempotent: calling it on a finished session is a no-op, so an extra tap
    /// (or a double-delivered event) can never over-count or index past the end.
    @discardableResult
    mutating func completeRound() -> Bool {
        guard !isFinished else { return true }
        completedRounds += 1
        return isFinished
    }

    mutating func reset() {
        completedRounds = 0
    }
}
