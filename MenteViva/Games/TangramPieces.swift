import CoreGraphics
import Foundation

/// The classic seven Tangram tiles (#218): 2 large right triangles, 1 medium,
/// 2 small, 1 square and 1 parallelogram. Corners are authoring coordinates on
/// an 8×8 unit square with y running UP (the game screen flips them in #219);
/// small legs are 2√2 units, so the seven areas sum to 64, the square's area.
nonisolated enum TangramPiece: Int, CaseIterable, Sendable {
    case large, large2, medium, small, small2, square, parallelogram

    /// The tile's corners, right angle (or first corner) at the origin.
    /// `large`/`large2` and `small`/`small2` share a shape; the cases exist so
    /// a shape's seven placements name seven distinct tiles.
    var corners: [CGPoint] {
        let root2 = sqrt(2.0)
        switch self {
        case .large, .large2:
            return [CGPoint(x: 0, y: 0), CGPoint(x: 4 * root2, y: 0), CGPoint(x: 0, y: 4 * root2)]
        case .medium:
            return [CGPoint(x: 0, y: 0), CGPoint(x: 4, y: 0), CGPoint(x: 0, y: 4)]
        case .small, .small2:
            return [CGPoint(x: 0, y: 0), CGPoint(x: 2 * root2, y: 0), CGPoint(x: 0, y: 2 * root2)]
        case .square:
            return [
                CGPoint(x: 0, y: 0), CGPoint(x: 2 * root2, y: 0),
                CGPoint(x: 2 * root2, y: 2 * root2), CGPoint(x: 0, y: 2 * root2),
            ]
        case .parallelogram:
            return [CGPoint(x: 0, y: 0), CGPoint(x: 4, y: 0), CGPoint(x: 6, y: 2), CGPoint(x: 2, y: 2)]
        }
    }

    /// Only the parallelogram shows a mirror: every other tile maps onto
    /// itself, so flip constrains nothing for them at levels 9–10.
    var showsFlip: Bool { self == .parallelogram }

    /// The string key naming the tile for VoiceOver (#219); the two large and
    /// the two small tiles share a shape, so each pair shares a name.
    var nameKey: String {
        switch self {
        case .large, .large2: "game.tangram.piece.large"
        case .medium: "game.tangram.piece.medium"
        case .small, .small2: "game.tangram.piece.small"
        case .square: "game.tangram.piece.square"
        case .parallelogram: "game.tangram.piece.parallelogram"
        }
    }

    /// The tile's corners after the placement motion: mirror across the
    /// vertical axis when flipped, then `rotation` steps of 45°, then move to
    /// `position`. The authoring tool (`/tmp/tangram`, not in the repo) uses
    /// the same motion, so its verified shapes land exactly.
    static func placedCorners(
        _ piece: TangramPiece, position: CGPoint, rotation: Int, flipped: Bool
    ) -> [CGPoint] {
        let angle = Double(((rotation % 8) + 8) % 8) * Double.pi / 4
        let cosine = cos(angle)
        let sine = sin(angle)
        return piece.corners.map { corner in
            let x = flipped ? -corner.x : corner.x
            return CGPoint(
                x: x * cosine - corner.y * sine + position.x,
                y: x * sine + corner.y * cosine + position.y)
        }
    }
}
