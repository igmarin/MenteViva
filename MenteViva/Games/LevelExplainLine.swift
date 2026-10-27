import SwiftUI

/// The one warm line under the header that explains today's level move (#207 1).
/// `.title2`, read by VoiceOver, gone once the first round starts. Never
/// mentions misses or accuracy.
struct LevelExplainLine: View {
    let key: String

    var body: some View {
        Text(AppLanguage.localized(key))
            .font(.title2)
            .multilineTextAlignment(.center)
            .accessibilityAddTraits(.isHeader)
            .padding(.horizontal)
    }
}

/// Show the line until `hasStarted` is true, only on the first open of the
/// day for this game. The game view owns the dismiss by passing its progress.
struct LevelExplainBanner: View {
    let change: LevelChange?
    let game: GameID
    let hasStarted: Bool

    var body: some View {
        let today = PlanStore.dayStamp()
        let alreadySeen = LevelOfferStore.hasSeenExplain(for: game, today: today)
        if !hasStarted,
            LevelExplainPolicy.shouldShow(change: change, alreadySeenToday: alreadySeen),
            let key = LevelExplainPolicy.key(for: change)
        {
            LevelExplainLine(key: key)
                .onAppear { LevelOfferStore.markExplainSeen(for: game, today: today) }
        }
    }
}
