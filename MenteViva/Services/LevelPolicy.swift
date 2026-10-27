import Foundation

/// Decision logic for #207's two prompts, kept pure so views only show it.
/// Every string stays in `Localizable.xcstrings` (warm copy, §5); no medical
/// claims, no mention of misses or accuracy.
nonisolated enum LevelExplainPolicy {
    /// The `Localizable.xcstrings` key for the one-line note under the header,
    /// or nil when nothing should be shown for this `change` (#207 1).
    /// `.chosen` never explains itself — the player already chose it.
    static func key(for change: LevelChange?) -> String? {
        guard let change else { return nil }
        switch change.reason {
        case .raised(let by):
            return by >= 2 ? "level.explain.raised2" : "level.explain.raised1"
        case .eased:
            return "level.explain.eased"
        case .chosen:
            return nil
        }
    }

    /// Whether the header note should appear on this open: there is a staircase
    /// change today and this is the first open of the day for this game.
    static func shouldShow(change: LevelChange?, alreadySeenToday: Bool) -> Bool {
        change != nil && !alreadySeenToday && key(for: change) != nil
    }

    /// Whether the celebration should offer the next level (#207 2).
    static func shouldOffer(
        accuracy: Double?,
        game: GameID,
        level: Difficulty,
        isPinned: Bool,
        alreadyOfferedToday: Bool
    ) -> Bool {
        guard !isPinned, !alreadyOfferedToday, level.level < 10 else { return false }
        guard game.hasLevels else { return false }
        guard let accuracy else { return false }
        return accuracy >= DailyPolicy.strongAccuracy(for: game)
    }
}
