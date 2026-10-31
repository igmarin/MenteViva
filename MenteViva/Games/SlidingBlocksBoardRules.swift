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

    /// What a touch on a block is once the finger lifts.
    enum Touch: Equatable {
        /// Picks the block (or lets it go), so its arrows show.
        case tap
        /// Slides the block along this axis of the finger.
        case drag(Axis)
    }

    /// A touch that never locked an axis while it moved, decided as the finger
    /// lifts. A clear lead by then still drags (a quick flick); anything else,
    /// a small wobble or a diagonal that led on neither axis, is a tap: the
    /// block is picked and its arrows show the ways it can go. No touch is lost.
    static func onLift(_ translation: CGSize) -> Touch {
        axis(for: translation).map(Touch.drag) ?? .tap
    }

    /// The axis the block moves on for a finger leading on `finger`: that one
    /// when the block can go that way, otherwise the one it can go on, so a
    /// block that only slides sideways still follows a finger that drifts down.
    static func blockAxis(finger: Axis, canSide: Bool, canUpDown: Bool) -> Axis {
        switch finger {
        case .horizontal: canSide || !canUpDown ? .horizontal : .vertical
        case .vertical: canUpDown || !canSide ? .vertical : .horizontal
        }
    }
}
