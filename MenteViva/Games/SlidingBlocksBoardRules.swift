import CoreGraphics

/// The sizes Sliding Blocks decides with plain numbers, so the board can be
/// tested without a screen (#470).
nonisolated enum SlidingBoardLayout {
    /// Biggest cell that keeps the whole board inside `area`. Every shipped
    /// board (≤4 wide, ≤5 tall) lands at 68pt or more on an iPhone, above the
    /// 60pt floor (conventions §4).
    static func cellSize(in area: CGSize, columns: Int, rows: Int) -> CGFloat {
        min(area.width / CGFloat(columns), area.height / CGFloat(rows))
    }
}

/// When a finger on a block becomes a drag (#470). An unsteady hand wobbles, so
/// a touch is a tap until it has clearly gone one way.
nonisolated enum SlidingDragRule {
    /// How far the finger travels before a drag may start, in points.
    static let startDistance: CGFloat = 20
    /// How much further the leading axis must have gone than the other one, so a
    /// diagonal never starts a drag; it waits until one axis clearly leads.
    static let leadRatio: CGFloat = 1.5

    enum Axis: Equatable {
        case horizontal
        case vertical
    }

    /// The axis a drag locks to, or nil while the touch is still a tap or a
    /// diagonal that leads on neither axis.
    static func axis(for translation: CGSize) -> Axis? {
        let across = abs(translation.width)
        let down = abs(translation.height)
        guard max(across, down) >= startDistance else { return nil }
        if across >= down * leadRatio { return .horizontal }
        if down >= across * leadRatio { return .vertical }
        return nil
    }

    /// A finger that lifts after wobbling less than `startDistance` is a tap.
    static func isTap(_ translation: CGSize) -> Bool {
        hypot(translation.width, translation.height) < startDistance
    }
}
