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

    /// What a lifted finger does to a block (#482). Never nothing: a touch that
    /// moves no cell picks the block, so its arrows show.
    enum Lift: Equatable {
        /// Picks the block (or lets it go), as a tap does.
        case select
        /// Slides the block `steps` cells (at least 1) toward `direction`.
        case slide(SlidingDirection, steps: Int)
    }

    /// Decides a lift. `limits` is the drag's axis and reach, or nil for a touch
    /// that never locked and has no clear lead (a tap). A drag that rounds to 0
    /// cells, a wobble on a block that can go further or a block that cannot
    /// move at all (back = forward = 0), selects instead of doing nothing.
    static func lift(_ translation: CGSize, limits: SlidingDragLimits?, cell: CGFloat) -> Lift {
        guard let limits else { return .select }
        let offset = limits.clamped(translation, cell: cell)
        let distance = limits.horizontal ? offset.width : offset.height
        let steps = Int((abs(distance) / cell).rounded())
        guard steps > 0 else { return .select }
        let direction: SlidingDirection =
            limits.horizontal ? (distance > 0 ? .right : .left) : (distance > 0 ? .down : .up)
        return .slide(direction, steps: steps)
    }
}

/// A drag's axis and how far the block can go each way along it, in cells.
/// The axis is the finger's when the block can move that way, otherwise the
/// one it can move on (`SlidingDragRule.blockAxis`), fixed for the whole drag.
nonisolated struct SlidingDragLimits: Equatable {
    let horizontal: Bool
    let back: Int
    let forward: Int
    /// True when the block went to its own axis because the finger's was
    /// blocked. Then the finger must still travel `startDistance` on that axis,
    /// so a sideways-only block does not slide on a mostly vertical finger.
    let isFallback: Bool

    /// `reach` is the most cells the block can slide toward each direction.
    init(reach: [SlidingDirection: Int], finger: SlidingDragRule.Axis) {
        let axis = SlidingDragRule.blockAxis(
            finger: finger,
            canSide: reach[.left] != nil || reach[.right] != nil,
            canUpDown: reach[.up] != nil || reach[.down] != nil)
        horizontal = axis == .horizontal
        isFallback = axis != finger
        back = reach[horizontal ? .left : .up] ?? 0
        forward = reach[horizontal ? .right : .down] ?? 0
    }

    /// The translation on this axis, limited to the cells the block can
    /// legally reach, so a drag never crosses a neighbour. A fallback axis
    /// stays at 0 until the finger has gone `startDistance` along it.
    func clamped(_ translation: CGSize, cell: CGFloat) -> CGSize {
        let distance = horizontal ? translation.width : translation.height
        let follows = !isFallback || abs(distance) >= SlidingDragRule.startDistance
        let limited = follows ? min(max(distance, -CGFloat(back) * cell), CGFloat(forward) * cell) : 0
        return horizontal ? CGSize(width: limited, height: 0) : CGSize(width: 0, height: limited)
    }
}
