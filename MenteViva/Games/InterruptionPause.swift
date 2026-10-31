import Foundation

/// Whether the app is away (a call, the app switcher) and a round owes a fresh start on return (#415).
/// A view keeps this in `@State`: timer and beat closures hold a copy of the view struct made when
/// they started, so only reference-backed state shows them that the app has since gone away.
nonisolated struct InterruptionPause {
    private(set) var isAway = false
    private(set) var owesRestart = false

    /// The app left. If a flash or demo was running it is cut short and owed again on return.
    mutating func leave(roundRunning: Bool) {
        isAway = true
        if roundRunning { owesRestart = true }
    }

    /// A round (or demo) wants to start now. False while away: nothing is shown or spoken, and the
    /// start is owed for the return.
    mutating func roundStarts() -> Bool {
        if isAway {
            owesRestart = true
            return false
        }
        return true
    }

    /// The app is active again. True when a round must be started again, uncounted.
    mutating func comeBack() -> Bool {
        isAway = false
        let owed = owesRestart
        owesRestart = false
        return owed
    }
}
