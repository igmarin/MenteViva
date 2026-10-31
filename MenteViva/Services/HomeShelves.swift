import Foundation

/// Home's "All games" as four short shelves instead of one flat grid of fourteen (#421).
/// `DailyPolicy.focus` already says what each game mostly exercises; this only orders and
/// groups by it, so the shelf names are the words the player chose in the first-run questions.
nonisolated enum HomeShelves {
    /// The shelves in the order they are shown. "Just have fun" is an answer, not an area, so
    /// no game belongs to it and it has no shelf.
    static let order: [PlayerProfile.Focus] = [.memory, .attention, .numbers, .words]

    /// `games` grouped by area in `order`, each shelf keeping the order given. An area with none of
    /// the given games (all hidden by the family) is left out, so no header sits over nothing.
    static func group(_ games: [GameID]) -> [(focus: PlayerProfile.Focus, games: [GameID])] {
        order.compactMap { focus in
            let shelf = games.filter { DailyPolicy.focus[$0] == focus }
            return shelf.isEmpty ? nil : (focus: focus, games: shelf)
        }
    }
}
