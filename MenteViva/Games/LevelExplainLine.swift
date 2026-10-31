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

/// What the level-change note takes up above a game's board (#470). A board
/// sized by a `GeometryReader` follows the height left over, so a note that
/// disappears at the first move makes every cell grow, and `ViewThatFits` may
/// switch from its scrolling layout to its fixed one. Such a game asks the
/// banner to keep the note's height: gone from sight, never gone from the layout.
nonisolated enum LevelExplainSlot: Equatable {
    /// The note is on screen.
    case showing
    /// The note is dismissed but still takes its height.
    case reserved
    /// There is no note this open, so nothing is held back.
    case none

    /// `hasStarted` is the game's own progress; `dismissed` is true once the
    /// game has started at any point, so undoing back to zero or replaying
    /// never brings the note back.
    static func slot(hasNote: Bool, hasStarted: Bool, dismissed: Bool) -> LevelExplainSlot {
        guard hasNote else { return .none }
        return hasStarted || dismissed ? .reserved : .showing
    }

    /// Whether the note's height is part of the page.
    var takesSpace: Bool { self != .none }
}

/// One open's level note (#470): which line, decided once, and whether play has
/// dismissed it. Once the game has started, the note stays dismissed for the
/// rest of the open, whatever the game's progress does next (undo, "Start
/// over", "Play again").
nonisolated struct LevelExplainNote: Equatable {
    /// The line to show, or nil when this open has no note.
    let key: String?
    private(set) var dismissed = false

    init(change: LevelChange?, seenToday: Bool) {
        key =
            LevelExplainPolicy.shouldShow(change: change, alreadySeenToday: seenToday)
            ? LevelExplainPolicy.key(for: change) : nil
    }

    /// Where the note stands now that the game reports `hasStarted`.
    mutating func slot(hasStarted: Bool) -> LevelExplainSlot {
        if hasStarted { dismissed = true }
        return LevelExplainSlot.slot(hasNote: key != nil, hasStarted: hasStarted, dismissed: dismissed)
    }
}

/// Show the line until `hasStarted` is true, only on the first open of the
/// day for this game. The game view owns the dismiss by passing its progress.
/// With `keepsSpace`, the line then fades out but keeps its height, for games
/// whose board is sized by the space left over. The note is decided once per
/// open, and once dismissed it stays dismissed (replay, undo, start over).
struct LevelExplainBanner: View {
    let change: LevelChange?
    let game: GameID
    let hasStarted: Bool
    var keepsSpace = false
    /// Holds this open's note. A reference, so the store is read on the first
    /// render only (not on every drag frame of the parent), and the dismissal
    /// is latched while the body reads `hasStarted`, with no `onChange` that a
    /// removed line could take with it.
    @State private var memo = Memo()

    var body: some View {
        let slot = memo.slot(change: change, game: game, hasStarted: hasStarted)
        if let key = memo.note?.key, slot == .showing || (keepsSpace && slot.takesSpace) {
            LevelExplainLine(key: key)
                .opacity(slot == .showing ? 1 : 0)
                .accessibilityHidden(slot != .showing)
                .onAppear { LevelOfferStore.markExplainSeen(for: game, today: PlanStore.dayStamp()) }
        }
    }

    private final class Memo {
        var note: LevelExplainNote?

        func slot(change: LevelChange?, game: GameID, hasStarted: Bool) -> LevelExplainSlot {
            var current =
                note
                ?? LevelExplainNote(
                    change: change,
                    seenToday: LevelOfferStore.hasSeenExplain(for: game, today: PlanStore.dayStamp()))
            let slot = current.slot(hasStarted: hasStarted)
            note = current
            return slot
        }
    }
}
