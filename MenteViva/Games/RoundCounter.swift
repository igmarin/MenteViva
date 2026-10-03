import SwiftUI

/// "3 / 10" under a game, spoken by VoiceOver as "Round 3 of 10" rather than
/// "3 slash 10" (#119). Shared so every round-based game shows it the same way.
struct RoundCounter: View {
    let progress: RoundProgress

    var body: some View {
        Text(verbatim: "\(progress.displayRound) / \(progress.totalRounds)")
            .font(.title3)
            .foregroundStyle(.secondary)
            .accessibilityLabel(String(format: AppLanguage.localized("game.round.a11y %lld %lld"),
                                       progress.displayRound, progress.totalRounds))
    }
}
