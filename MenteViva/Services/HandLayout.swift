import Foundation

/// How today's cards sit on the Home table (#365): rows of at most three, each card as wide as
/// the table allows up to its full size. Five games used to share one row and ran off a phone's
/// edges; chunking them 3 + 2 and sizing by the measured width keeps every card inside the table
/// without the view doing any arithmetic.
nonisolated enum HandLayout {
    /// A card's full width, which iPad and wide phones keep.
    static let fullWidth: CGFloat = 112

    /// `games` in rows of `perRow`, in order (five become three and two).
    static func rows(_ games: [GameID], perRow: Int = 3) -> [[GameID]] {
        guard perRow > 0 else { return [games] }
        return stride(from: 0, to: games.count, by: perRow).map {
            Array(games[$0..<min($0 + perRow, games.count)])
        }
    }

    /// The width of each card in a row of `perRow` that overlap by `overlap`, so the row fits in
    /// `available` points. Never wider than `fullWidth`.
    static func cardWidth(available: CGFloat, perRow: Int, overlap: CGFloat = 6) -> CGFloat {
        min(fullWidth, (available + overlap * CGFloat(perRow - 1)) / CGFloat(perRow))
    }
}
