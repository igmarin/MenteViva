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

/// Show the line until `hasStarted` is true, only on the first open of the
/// day for this game. The game view owns the dismiss by passing its progress.
/// With `keepsSpace`, the line then fades out but keeps its height, for games
/// whose board is sized by the space left over. The note is decided once per
/// open, and once dismissed it stays dismissed (replay, undo, start over).
struct LevelExplainBanner: View {
    let game: GameID
    let hasStarted: Bool
    let keepsSpace: Bool
    @State private var key: String?
    @State private var dismissed = false

    init(change: LevelChange?, game: GameID, hasStarted: Bool, keepsSpace: Bool = false) {
        self.game = game
        self.hasStarted = hasStarted
        self.keepsSpace = keepsSpace
        let seen = LevelOfferStore.hasSeenExplain(for: game, today: PlanStore.dayStamp())
        let show = LevelExplainPolicy.shouldShow(change: change, alreadySeenToday: seen)
        _key = State(initialValue: show ? LevelExplainPolicy.key(for: change) : nil)
    }

    var body: some View {
        let slot = LevelExplainSlot.slot(hasNote: key != nil, hasStarted: hasStarted, dismissed: dismissed)
        Group {
            if let key, slot == .showing || (keepsSpace && slot.takesSpace) {
                LevelExplainLine(key: key)
                    .opacity(slot == .showing ? 1 : 0)
                    .accessibilityHidden(slot != .showing)
                    .onAppear { LevelOfferStore.markExplainSeen(for: game, today: PlanStore.dayStamp()) }
            }
        }
        .onChange(of: hasStarted) { _, started in
            if started { dismissed = true }
        }
    }
}
