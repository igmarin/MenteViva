import SwiftUI

/// "Round 3 of 10" under a game, as progress cards plus the same words, which
/// VoiceOver also reads (#119: never "3 slash 10"). Shared so every round-based
/// game shows it the same way.
struct RoundCounter: View {
    let progress: RoundProgress

    var body: some View {
        ProgressCards(
            done: progress.completedRounds, total: progress.totalRounds,
            words: String(
                format: AppLanguage.localized("game.round.a11y %lld %lld"),
                progress.displayRound, progress.totalRounds))
    }
}
