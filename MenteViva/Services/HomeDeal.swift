import Foundation

/// The rules behind Home's deal (#383), kept out of the view so they can be tested: which plan
/// is on the table in the very first frame, and whether the cards still need dealing. Home
/// used to start with an empty plan and jump to a full table a moment later; reading the saved
/// plan up front puts the table there at once, so the deal is the only thing that moves.
nonisolated enum HomeDeal {
    /// Seconds between one card and the next (the design's 70 ms).
    static let stagger: Double = 0.07

    /// Today's games from the plan saved on this device, or none if nothing was saved today.
    /// Yesterday's plan must not flash on the table before the new day's plan is made.
    static func preloadedPlan(cached: DailyPlan?, today: String) -> [GameID] {
        guard let cached, cached.dayStamp == today else { return [] }
        return cached.games
    }

    /// True while today's cards are still waiting to be dealt: there is a plan, and this day has
    /// not been dealt yet. Coming back from a game, or a plan that is made again later the same
    /// day (the warm-up), never deals a second time.
    static func needsDeal(plan: [GameID], dealtDay: String?, planDay: String) -> Bool {
        !plan.isEmpty && dealtDay != planDay
    }

    /// How long card `index` waits before it is dealt, so the cards land one after another.
    static func delay(forCardAt index: Int) -> Double { stagger * Double(index) }
}
