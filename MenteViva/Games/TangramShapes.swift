import CoreGraphics
import Foundation

/// One of the 30 Tangram silhouettes (#218): seven tile placements that
/// exactly tile it — no overlaps, areas summing to the 8×8 square.
/// Authoring coordinates, y up (the screen flips them in #219). The
/// placements come from the authoring tool (`/tmp/tangram`, not in the
/// repo); every shape below passed its no-overlap and area checks there.
/// Names live in `Localizable.xcstrings` under `key`.
nonisolated struct TangramShape: Sendable {
    /// `Localizable.xcstrings` key `tangram.shape.NN`.
    let key: String
    /// Seven placements, one per tile: two larges, medium, two smalls,
    /// square, parallelogram.
    let placements: [TangramPlacement]
}

/// The library: 30 silhouettes, animals, people and things, in the order
/// the shape picker walks them.
nonisolated enum TangramShapes {
    static let all: [TangramShape] = [
        TangramShape(
            key: "tangram.shape.01",
            placements: [
                TangramPlacement(piece: .medium, position: CGPoint(x: 6.0, y: 8.0), rotation: 2, flipped: true),
                TangramPlacement(piece: .small, position: CGPoint(x: 8.0, y: 6.0), rotation: 7, flipped: true),
                TangramPlacement(piece: .small2, position: CGPoint(x: 8.0, y: 6.0), rotation: 3, flipped: false),
                TangramPlacement(piece: .large, position: CGPoint(x: 6.0, y: 8.0), rotation: 6, flipped: true),
                TangramPlacement(piece: .large2, position: CGPoint(x: 6.0, y: 8.0), rotation: 2, flipped: false),
                TangramPlacement(piece: .square, position: CGPoint(x: 6.0, y: 13.65685424949238), rotation: 1, flipped: false),
                TangramPlacement(piece: .parallelogram, position: CGPoint(x: 7.0, y: 4.0), rotation: 4, flipped: false),
            ]),
        TangramShape(
            key: "tangram.shape.02",
            placements: [
                TangramPlacement(piece: .large, position: CGPoint(x: 8.0, y: 9.0), rotation: 1, flipped: true),
                TangramPlacement(piece: .large2, position: CGPoint(x: 0.0, y: 9.0), rotation: 7, flipped: false),
                TangramPlacement(piece: .medium, position: CGPoint(x: 8.0, y: 13.0), rotation: 4, flipped: false),
                TangramPlacement(piece: .small, position: CGPoint(x: 2.0, y: 7.0), rotation: 3, flipped: true),
                TangramPlacement(
                    piece: .small2, position: CGPoint(x: 8.414213562373096, y: 6.585786437626905), rotation: 2, flipped: false),
                TangramPlacement(piece: .square, position: CGPoint(x: 4.0, y: 5.0), rotation: 3, flipped: true),
                TangramPlacement(piece: .parallelogram, position: CGPoint(x: 6.0, y: 3.0), rotation: 0, flipped: false),
            ]),
        TangramShape(
            key: "tangram.shape.03",
            placements: [
                TangramPlacement(piece: .parallelogram, position: CGPoint(x: 2.0, y: 3.0), rotation: 0, flipped: false),
                TangramPlacement(piece: .large, position: CGPoint(x: 6.0, y: 5.0), rotation: 6, flipped: true),
                TangramPlacement(piece: .large2, position: CGPoint(x: 6.0, y: 5.0), rotation: 0, flipped: true),
                TangramPlacement(piece: .medium, position: CGPoint(x: 6.0, y: 10.65685424949238), rotation: 0, flipped: false),
                TangramPlacement(
                    piece: .small, position: CGPoint(x: 9.414213562373096, y: 14.071067811865476), rotation: 4, flipped: false),
                TangramPlacement(piece: .small2, position: CGPoint(x: 6.0, y: 14.65685424949238), rotation: 2, flipped: true),
                TangramPlacement(
                    piece: .square, position: CGPoint(x: 3.1715728752538097, y: 0.1715728752538097), rotation: 0, flipped: false),
            ]),
        TangramShape(
            key: "tangram.shape.04",
            placements: [
                TangramPlacement(piece: .large, position: CGPoint(x: 6.656854249492381, y: 3.0), rotation: 6, flipped: true),
                TangramPlacement(piece: .large2, position: CGPoint(x: 6.656854249492381, y: 3.0), rotation: 0, flipped: true),
                TangramPlacement(
                    piece: .medium, position: CGPoint(x: 6.656854249492381, y: 8.65685424949238), rotation: 6, flipped: true),
                TangramPlacement(
                    piece: .small, position: CGPoint(x: 6.656854249492381, y: 12.65685424949238), rotation: 6, flipped: true),
                TangramPlacement(
                    piece: .square, position: CGPoint(x: 10.485281374238571, y: 4.82842712474619), rotation: 7, flipped: true),
                TangramPlacement(
                    piece: .parallelogram, position: CGPoint(x: 2.6568542494923806, y: 3.0), rotation: 4, flipped: true),
                TangramPlacement(piece: .small2, position: CGPoint(x: 14.313708498984761, y: 1.0), rotation: 7, flipped: true),
            ]),
        TangramShape(
            key: "tangram.shape.05",
            placements: [
                TangramPlacement(
                    piece: .large, position: CGPoint(x: 10.65685424949238, y: 10.65685424949238), rotation: 5, flipped: false),
                TangramPlacement(
                    piece: .medium, position: CGPoint(x: 10.65685424949238, y: 10.65685424949238), rotation: 0, flipped: false),
                TangramPlacement(
                    piece: .small, position: CGPoint(x: 14.071067811865476, y: 14.071067811865476), rotation: 4, flipped: false),
                TangramPlacement(
                    piece: .small2, position: CGPoint(x: 10.65685424949238, y: 14.65685424949238), rotation: 0, flipped: true),
                TangramPlacement(
                    piece: .large2, position: CGPoint(x: 6.656854249492381, y: 6.656854249492381), rotation: 4, flipped: false),
                TangramPlacement(
                    piece: .parallelogram, position: CGPoint(x: 9.65685424949238, y: 13.65685424949238), rotation: 2,
                    flipped: true),
                TangramPlacement(
                    piece: .square, position: CGPoint(x: 10.65685424949238, y: 6.656854249492381), rotation: 4, flipped: true),
            ]),
        TangramShape(
            key: "tangram.shape.06",
            placements: [
                TangramPlacement(
                    piece: .medium, position: CGPoint(x: 10.65685424949238, y: 6.656854249492381), rotation: 0, flipped: true),
                TangramPlacement(
                    piece: .small, position: CGPoint(x: 12.65685424949238, y: 8.65685424949238), rotation: 5, flipped: false),
                TangramPlacement(
                    piece: .small2, position: CGPoint(x: 12.65685424949238, y: 8.65685424949238), rotation: 1, flipped: true),
                TangramPlacement(
                    piece: .large, position: CGPoint(x: 14.65685424949238, y: 6.656854249492381), rotation: 6, flipped: true),
                TangramPlacement(
                    piece: .large2, position: CGPoint(x: 6.656854249492381, y: 6.656854249492381), rotation: 4, flipped: false),
                TangramPlacement(
                    piece: .parallelogram, position: CGPoint(x: 6.656854249492381, y: 6.656854249492381), rotation: 4,
                    flipped: true),
                TangramPlacement(
                    piece: .square, position: CGPoint(x: 12.65685424949238, y: 6.656854249492381), rotation: 4, flipped: true),
            ]),
        TangramShape(
            key: "tangram.shape.07",
            placements: [
                TangramPlacement(
                    piece: .large, position: CGPoint(x: 10.65685424949238, y: 6.656854249492381), rotation: 6, flipped: true),
                TangramPlacement(
                    piece: .medium, position: CGPoint(x: 15.48528137423857, y: 11.485281374238571), rotation: 2, flipped: true),
                TangramPlacement(
                    piece: .small, position: CGPoint(x: 15.48528137423857, y: 11.485281374238571), rotation: 6, flipped: true),
                TangramPlacement(
                    piece: .small2, position: CGPoint(x: 15.48528137423857, y: 11.485281374238571), rotation: 2, flipped: false),
                TangramPlacement(
                    piece: .square, position: CGPoint(x: 10.65685424949238, y: 9.65685424949238), rotation: 3, flipped: false),
                TangramPlacement(
                    piece: .parallelogram, position: CGPoint(x: 12.31370849898476, y: 6.656854249492381), rotation: 4,
                    flipped: true),
                TangramPlacement(
                    piece: .large2, position: CGPoint(x: 10.65685424949238, y: 6.656854249492381), rotation: 4, flipped: false),
            ]),
        TangramShape(
            key: "tangram.shape.08",
            placements: [
                TangramPlacement(piece: .medium, position: CGPoint(x: 10.65685424949238, y: 3.0), rotation: 0, flipped: true),
                TangramPlacement(piece: .small, position: CGPoint(x: 12.65685424949238, y: 5.0), rotation: 5, flipped: false),
                TangramPlacement(piece: .small2, position: CGPoint(x: 12.65685424949238, y: 5.0), rotation: 1, flipped: true),
                TangramPlacement(piece: .large, position: CGPoint(x: 14.65685424949238, y: 3.0), rotation: 0, flipped: false),
                TangramPlacement(piece: .large2, position: CGPoint(x: 6.656854249492381, y: 3.0), rotation: 0, flipped: true),
                TangramPlacement(piece: .square, position: CGPoint(x: 10.65685424949238, y: 7.0), rotation: 1, flipped: false),
                TangramPlacement(
                    piece: .parallelogram, position: CGPoint(x: 6.656854249492381, y: 3.0), rotation: 4, flipped: true),
            ]),
        TangramShape(
            key: "tangram.shape.09",
            placements: [
                TangramPlacement(
                    piece: .medium, position: CGPoint(x: 10.65685424949238, y: 12.65685424949238), rotation: 0, flipped: true),
                TangramPlacement(
                    piece: .small, position: CGPoint(x: 12.65685424949238, y: 14.65685424949238), rotation: 5, flipped: false),
                TangramPlacement(
                    piece: .small2, position: CGPoint(x: 12.65685424949238, y: 14.65685424949238), rotation: 1, flipped: true),
                TangramPlacement(
                    piece: .parallelogram, position: CGPoint(x: 10.65685424949238, y: 6.656854249492381), rotation: 2,
                    flipped: false),
                TangramPlacement(
                    piece: .large, position: CGPoint(x: 8.65685424949238, y: 8.65685424949238), rotation: 4, flipped: false),
                TangramPlacement(
                    piece: .large2, position: CGPoint(x: 10.65685424949238, y: 6.656854249492381), rotation: 4, flipped: true),
                TangramPlacement(
                    piece: .square, position: CGPoint(x: 12.65685424949238, y: 6.656854249492381), rotation: 1, flipped: false),
            ]),
        TangramShape(
            key: "tangram.shape.10",
            placements: [
                TangramPlacement(
                    piece: .parallelogram, position: CGPoint(x: 8.65685424949238, y: 16.65685424949238), rotation: 2,
                    flipped: false),
                TangramPlacement(
                    piece: .square, position: CGPoint(x: 8.65685424949238, y: 16.65685424949238), rotation: 3, flipped: true),
                TangramPlacement(
                    piece: .small, position: CGPoint(x: 9.071067811865476, y: 23.071067811865476), rotation: 4, flipped: false),
                TangramPlacement(
                    piece: .medium, position: CGPoint(x: 10.65685424949238, y: 14.65685424949238), rotation: 0, flipped: false),
                TangramPlacement(
                    piece: .small2, position: CGPoint(x: 14.071067811865476, y: 18.071067811865476), rotation: 2, flipped: true),
                TangramPlacement(
                    piece: .large, position: CGPoint(x: 8.65685424949238, y: 12.65685424949238), rotation: 4, flipped: true),
                TangramPlacement(
                    piece: .large2, position: CGPoint(x: 6.65685424949238, y: 14.65685424949238), rotation: 4, flipped: false),
            ]),
        TangramShape(
            key: "tangram.shape.11",
            placements: [
                TangramPlacement(
                    piece: .parallelogram, position: CGPoint(x: 6.656854249492381, y: 10.65685424949238), rotation: 0,
                    flipped: false),
                TangramPlacement(
                    piece: .small, position: CGPoint(x: 14.65685424949238, y: 11.65685424949238), rotation: 1, flipped: true),
                TangramPlacement(
                    piece: .small2, position: CGPoint(x: 9.65685424949238, y: 8.65685424949238), rotation: 7, flipped: true),
                TangramPlacement(
                    piece: .large, position: CGPoint(x: 6.656854249492381, y: 10.65685424949238), rotation: 2, flipped: true),
                TangramPlacement(
                    piece: .large2, position: CGPoint(x: 6.656854249492381, y: 10.65685424949238), rotation: 2, flipped: false),
                TangramPlacement(
                    piece: .medium, position: CGPoint(x: 1.8284271247461907, y: 5.82842712474619), rotation: 0, flipped: false),
                TangramPlacement(
                    piece: .square, position: CGPoint(x: 5.242640687119286, y: 5.82842712474619), rotation: 4, flipped: false),
            ]),
        TangramShape(
            key: "tangram.shape.12",
            placements: [
                TangramPlacement(piece: .large, position: CGPoint(x: 5.0, y: 11.0), rotation: 5, flipped: false),
                TangramPlacement(piece: .large2, position: CGPoint(x: 13.0, y: 11.0), rotation: 5, flipped: false),
                TangramPlacement(piece: .square, position: CGPoint(x: 9.0, y: 7.0), rotation: 1, flipped: false),
                TangramPlacement(
                    piece: .small, position: CGPoint(x: 1.5857864376269049, y: 10.414213562373096), rotation: 4, flipped: true),
                TangramPlacement(
                    piece: .small2, position: CGPoint(x: 16.414213562373096, y: 10.414213562373096), rotation: 4, flipped: false),
                TangramPlacement(piece: .medium, position: CGPoint(x: 1.0, y: 7.0), rotation: 4, flipped: true),
                TangramPlacement(piece: .parallelogram, position: CGPoint(x: 9.0, y: 7.0), rotation: 4, flipped: true),
            ]),
        TangramShape(
            key: "tangram.shape.13",
            placements: [
                TangramPlacement(
                    piece: .square, position: CGPoint(x: 6.656854249492381, y: 10.65685424949238), rotation: 0, flipped: false),
                TangramPlacement(
                    piece: .medium, position: CGPoint(x: 6.656854249492381, y: 13.485281374238571), rotation: 0, flipped: false),
                TangramPlacement(
                    piece: .small, position: CGPoint(x: 8.65685424949238, y: 15.485281374238571), rotation: 1, flipped: true),
                TangramPlacement(
                    piece: .small2, position: CGPoint(x: 6.656854249492381, y: 17.48528137423857), rotation: 0, flipped: true),
                TangramPlacement(
                    piece: .large, position: CGPoint(x: 9.485281374238571, y: 10.65685424949238), rotation: 4, flipped: true),
                TangramPlacement(
                    piece: .parallelogram, position: CGPoint(x: 9.485281374238571, y: 5.0), rotation: 0, flipped: false),
                TangramPlacement(
                    piece: .large2, position: CGPoint(x: 6.656854249492381, y: 10.65685424949238), rotation: 4, flipped: false),
            ]),
        TangramShape(
            key: "tangram.shape.14",
            placements: [
                TangramPlacement(
                    piece: .square, position: CGPoint(x: 8.65685424949238, y: 20.65685424949238), rotation: 1, flipped: false),
                TangramPlacement(
                    piece: .parallelogram, position: CGPoint(x: 6.65685424949238, y: 20.65685424949238), rotation: 4,
                    flipped: true),
                TangramPlacement(
                    piece: .large, position: CGPoint(x: 8.65685424949238, y: 18.65685424949238), rotation: 4, flipped: false),
                TangramPlacement(
                    piece: .large2, position: CGPoint(x: 12.65685424949238, y: 18.65685424949238), rotation: 4, flipped: true),
                TangramPlacement(
                    piece: .medium, position: CGPoint(x: 10.65685424949238, y: 20.65685424949238), rotation: 0, flipped: false),
                TangramPlacement(
                    piece: .small, position: CGPoint(x: 12.65685424949238, y: 18.65685424949238), rotation: 4, flipped: false),
                TangramPlacement(
                    piece: .small2, position: CGPoint(x: 8.65685424949238, y: 24.65685424949238), rotation: 0, flipped: false),
            ]),
        TangramShape(
            key: "tangram.shape.15",
            placements: [
                TangramPlacement(
                    piece: .small, position: CGPoint(x: 10.65685424949238, y: 25.65685424949238), rotation: 5, flipped: false),
                TangramPlacement(
                    piece: .medium, position: CGPoint(x: 10.65685424949238, y: 23.65685424949238), rotation: 5, flipped: false),
                TangramPlacement(
                    piece: .large, position: CGPoint(x: 10.65685424949238, y: 20.82842712474619), rotation: 5, flipped: false),
                TangramPlacement(
                    piece: .small2, position: CGPoint(x: 10.65685424949238, y: 25.65685424949238), rotation: 0, flipped: true),
                TangramPlacement(
                    piece: .parallelogram, position: CGPoint(x: 10.65685424949238, y: 16.82842712474619), rotation: 2,
                    flipped: true),
                TangramPlacement(
                    piece: .square, position: CGPoint(x: 10.65685424949238, y: 14.82842712474619), rotation: 5, flipped: true),
                TangramPlacement(
                    piece: .large2, position: CGPoint(x: 8.65685424949238, y: 10.82842712474619), rotation: 4, flipped: false),
            ]),
        TangramShape(
            key: "tangram.shape.16",
            placements: [
                TangramPlacement(piece: .large, position: CGPoint(x: 8.0, y: 9.0), rotation: 1, flipped: true),
                TangramPlacement(piece: .large2, position: CGPoint(x: 0.0, y: 9.0), rotation: 7, flipped: false),
                TangramPlacement(piece: .medium, position: CGPoint(x: 8.0, y: 9.0), rotation: 0, flipped: false),
                TangramPlacement(
                    piece: .small, position: CGPoint(x: 11.414213562373096, y: 12.414213562373096), rotation: 2, flipped: true),
                TangramPlacement(
                    piece: .small2, position: CGPoint(x: 7.414213562373095, y: 12.414213562373096), rotation: 4, flipped: false),
                TangramPlacement(piece: .square, position: CGPoint(x: 4.0, y: 5.0), rotation: 3, flipped: true),
                TangramPlacement(piece: .parallelogram, position: CGPoint(x: 6.0, y: 3.0), rotation: 0, flipped: false),
            ]),
        TangramShape(
            key: "tangram.shape.17",
            placements: [
                TangramPlacement(
                    piece: .large, position: CGPoint(x: 6.656854249492381, y: 11.65685424949238), rotation: 0, flipped: false),
                TangramPlacement(
                    piece: .large2, position: CGPoint(x: 6.656854249492381, y: 11.65685424949238), rotation: 4, flipped: false),
                TangramPlacement(
                    piece: .medium, position: CGPoint(x: 12.313708498984761, y: 11.65685424949238), rotation: 4, flipped: true),
                TangramPlacement(
                    piece: .small, position: CGPoint(x: 12.313708498984761, y: 11.65685424949238), rotation: 0, flipped: false),
                TangramPlacement(
                    piece: .square, position: CGPoint(x: 12.313708498984761, y: 14.48528137423857), rotation: 1, flipped: false),
                TangramPlacement(
                    piece: .parallelogram, position: CGPoint(x: 6.656854249492381, y: 11.65685424949238), rotation: 4,
                    flipped: true),
                TangramPlacement(piece: .small2, position: CGPoint(x: 1.0, y: 11.65685424949238), rotation: 4, flipped: true),
            ]),
        TangramShape(
            key: "tangram.shape.18",
            placements: [
                TangramPlacement(
                    piece: .medium, position: CGPoint(x: 10.65685424949238, y: 7.656854249492381), rotation: 0, flipped: true),
                TangramPlacement(
                    piece: .small, position: CGPoint(x: 12.65685424949238, y: 9.65685424949238), rotation: 5, flipped: false),
                TangramPlacement(
                    piece: .small2, position: CGPoint(x: 12.65685424949238, y: 9.65685424949238), rotation: 1, flipped: true),
                TangramPlacement(
                    piece: .square, position: CGPoint(x: 9.65685424949238, y: 10.65685424949238), rotation: 1, flipped: true),
                TangramPlacement(
                    piece: .parallelogram, position: CGPoint(x: 17.65685424949238, y: 8.65685424949238), rotation: 0,
                    flipped: true),
                TangramPlacement(
                    piece: .large, position: CGPoint(x: 6.656854249492381, y: 7.656854249492381), rotation: 4, flipped: false),
                TangramPlacement(
                    piece: .large2, position: CGPoint(x: 14.65685424949238, y: 7.656854249492381), rotation: 4, flipped: true),
            ]),
        TangramShape(
            key: "tangram.shape.19",
            placements: [
                TangramPlacement(
                    piece: .parallelogram, position: CGPoint(x: 8.65685424949238, y: 25.31370849898476), rotation: 2,
                    flipped: false),
                TangramPlacement(
                    piece: .medium, position: CGPoint(x: 6.65685424949238, y: 31.31370849898476), rotation: 0, flipped: false),
                TangramPlacement(
                    piece: .large, position: CGPoint(x: 8.65685424949238, y: 25.31370849898476), rotation: 4, flipped: false),
                TangramPlacement(
                    piece: .large2, position: CGPoint(x: 8.65685424949238, y: 25.31370849898476), rotation: 4, flipped: true),
                TangramPlacement(
                    piece: .square, position: CGPoint(x: 8.65685424949238, y: 19.65685424949238), rotation: 3, flipped: true),
                TangramPlacement(
                    piece: .small, position: CGPoint(x: 8.65685424949238, y: 15.65685424949238), rotation: 4, flipped: true),
                TangramPlacement(
                    piece: .small2, position: CGPoint(x: 10.65685424949238, y: 17.65685424949238), rotation: 0, flipped: false),
            ]),
        TangramShape(
            key: "tangram.shape.20",
            placements: [
                TangramPlacement(
                    piece: .square, position: CGPoint(x: 8.65685424949238, y: 16.65685424949238), rotation: 1, flipped: false),
                TangramPlacement(
                    piece: .parallelogram, position: CGPoint(x: 8.65685424949238, y: 16.65685424949238), rotation: 6,
                    flipped: false),
                TangramPlacement(
                    piece: .large, position: CGPoint(x: 8.65685424949238, y: 20.65685424949238), rotation: 0, flipped: false),
                TangramPlacement(
                    piece: .large2, position: CGPoint(x: 8.65685424949238, y: 20.65685424949238), rotation: 0, flipped: true),
                TangramPlacement(
                    piece: .medium, position: CGPoint(x: 8.65685424949238, y: 12.65685424949238), rotation: 4, flipped: true),
                TangramPlacement(
                    piece: .small, position: CGPoint(x: 8.65685424949238, y: 14.65685424949238), rotation: 4, flipped: false),
                TangramPlacement(
                    piece: .small2, position: CGPoint(x: 8.65685424949238, y: 16.65685424949238), rotation: 4, flipped: true),
            ]),
        TangramShape(
            key: "tangram.shape.21",
            placements: [
                TangramPlacement(
                    piece: .parallelogram, position: CGPoint(x: 7.656854249492381, y: 8.65685424949238), rotation: 0,
                    flipped: false),
                TangramPlacement(
                    piece: .large, position: CGPoint(x: 7.656854249492381, y: 8.65685424949238), rotation: 2, flipped: false),
                TangramPlacement(
                    piece: .large2, position: CGPoint(x: 13.65685424949238, y: 10.65685424949238), rotation: 6, flipped: true),
                TangramPlacement(
                    piece: .small, position: CGPoint(x: 9.65685424949238, y: 6.65685424949238), rotation: 7, flipped: true),
                TangramPlacement(
                    piece: .medium, position: CGPoint(x: 4.82842712474619, y: 5.82842712474619), rotation: 4, flipped: false),
                TangramPlacement(
                    piece: .square, position: CGPoint(x: 4.82842712474619, y: 8.65685424949238), rotation: 4, flipped: true),
                TangramPlacement(
                    piece: .small2, position: CGPoint(x: 11.65685424949238, y: 12.65685424949238), rotation: 5, flipped: false),
            ]),
        TangramShape(
            key: "tangram.shape.22",
            placements: [
                TangramPlacement(
                    piece: .large, position: CGPoint(x: 12.65685424949238, y: 12.65685424949238), rotation: 7, flipped: true),
                TangramPlacement(
                    piece: .parallelogram, position: CGPoint(x: 12.65685424949238, y: 12.65685424949238), rotation: 2,
                    flipped: true),
                TangramPlacement(
                    piece: .small, position: CGPoint(x: 13.071067811865476, y: 6.242640687119285), rotation: 0, flipped: true),
                TangramPlacement(
                    piece: .large2, position: CGPoint(x: 8.65685424949238, y: 16.65685424949238), rotation: 4, flipped: false),
                TangramPlacement(
                    piece: .medium, position: CGPoint(x: 16.65685424949238, y: 16.65685424949238), rotation: 4, flipped: true),
                TangramPlacement(
                    piece: .square, position: CGPoint(x: 8.65685424949238, y: 6.65685424949238), rotation: 1, flipped: false),
                TangramPlacement(
                    piece: .small2, position: CGPoint(x: 8.65685424949238, y: 12.65685424949238), rotation: 4, flipped: true),
            ]),
        TangramShape(
            key: "tangram.shape.23",
            placements: [
                TangramPlacement(
                    piece: .large, position: CGPoint(x: 10.65685424949238, y: 6.65685424949238), rotation: 7, flipped: true),
                TangramPlacement(
                    piece: .medium, position: CGPoint(x: 6.656854249492381, y: 10.65685424949238), rotation: 2, flipped: false),
                TangramPlacement(
                    piece: .small, position: CGPoint(x: 6.656854249492381, y: 14.65685424949238), rotation: 0, flipped: false),
                TangramPlacement(
                    piece: .square, position: CGPoint(x: 9.485281374238571, y: 14.65685424949238), rotation: 5, flipped: true),
                TangramPlacement(
                    piece: .small2, position: CGPoint(x: 14.65685424949238, y: 10.65685424949238), rotation: 6, flipped: true),
                TangramPlacement(
                    piece: .large2, position: CGPoint(x: 10.65685424949238, y: 6.65685424949238), rotation: 4, flipped: false),
                TangramPlacement(
                    piece: .parallelogram, position: CGPoint(x: 10.65685424949238, y: 6.65685424949238), rotation: 4,
                    flipped: true),
            ]),
        TangramShape(
            key: "tangram.shape.24",
            placements: [
                TangramPlacement(
                    piece: .parallelogram, position: CGPoint(x: 6.656854249492381, y: 6.656854249492381), rotation: 0,
                    flipped: false),
                TangramPlacement(
                    piece: .medium, position: CGPoint(x: 8.65685424949238, y: 8.65685424949238), rotation: 0, flipped: false),
                TangramPlacement(
                    piece: .large, position: CGPoint(x: 8.65685424949238, y: 12.65685424949238), rotation: 0, flipped: false),
                TangramPlacement(
                    piece: .small, position: CGPoint(x: 14.313708498984761, y: 12.65685424949238), rotation: 0, flipped: false),
                TangramPlacement(
                    piece: .small2, position: CGPoint(x: 8.65685424949238, y: 18.31370849898476), rotation: 0, flipped: true),
                TangramPlacement(
                    piece: .square, position: CGPoint(x: 11.485281374238571, y: 15.485281374238571), rotation: 5, flipped: true),
                TangramPlacement(
                    piece: .large2, position: CGPoint(x: 6.656854249492381, y: 6.656854249492381), rotation: 4, flipped: false),
            ]),
        TangramShape(
            key: "tangram.shape.25",
            placements: [
                TangramPlacement(
                    piece: .parallelogram, position: CGPoint(x: 6.656854249492381, y: 8.65685424949238), rotation: 0,
                    flipped: false),
                TangramPlacement(
                    piece: .medium, position: CGPoint(x: 12.65685424949238, y: 10.65685424949238), rotation: 6, flipped: true),
                TangramPlacement(
                    piece: .small, position: CGPoint(x: 12.65685424949238, y: 14.65685424949238), rotation: 0, flipped: false),
                TangramPlacement(
                    piece: .square, position: CGPoint(x: 12.65685424949238, y: 10.65685424949238), rotation: 2, flipped: false),
                TangramPlacement(
                    piece: .large, position: CGPoint(x: 10.65685424949238, y: 8.65685424949238), rotation: 4, flipped: true),
                TangramPlacement(
                    piece: .large2, position: CGPoint(x: 6.656854249492381, y: 8.65685424949238), rotation: 4, flipped: false),
                TangramPlacement(
                    piece: .small2, position: CGPoint(x: 6.656854249492381, y: 10.65685424949238), rotation: 0, flipped: true),
            ]),
        TangramShape(
            key: "tangram.shape.26",
            placements: [
                TangramPlacement(
                    piece: .square, position: CGPoint(x: 6.65685424949238, y: 10.65685424949238), rotation: 5, flipped: true),
                TangramPlacement(
                    piece: .large, position: CGPoint(x: 8.65685424949238, y: 12.65685424949238), rotation: 1, flipped: false),
                TangramPlacement(
                    piece: .large2, position: CGPoint(x: 12.65685424949238, y: 16.65685424949238), rotation: 5, flipped: true),
                TangramPlacement(
                    piece: .medium, position: CGPoint(x: 16.65685424949238, y: 20.65685424949238), rotation: 0, flipped: true),
                TangramPlacement(
                    piece: .small, position: CGPoint(x: 14.65685424949238, y: 18.65685424949238), rotation: 7, flipped: true),
                TangramPlacement(
                    piece: .parallelogram, position: CGPoint(x: 6.65685424949238, y: 8.65685424949238), rotation: 4, flipped: true
                ),
                TangramPlacement(
                    piece: .small2, position: CGPoint(x: 12.65685424949238, y: 6.65685424949238), rotation: 0, flipped: false),
            ]),
        TangramShape(
            key: "tangram.shape.27",
            placements: [
                TangramPlacement(
                    piece: .square, position: CGPoint(x: 13.65685424949238, y: 18.31370849898476), rotation: 1, flipped: false),
                TangramPlacement(
                    piece: .parallelogram, position: CGPoint(x: 15.65685424949238, y: 20.31370849898476), rotation: 4,
                    flipped: true),
                TangramPlacement(
                    piece: .large, position: CGPoint(x: 11.65685424949238, y: 20.31370849898476), rotation: 4, flipped: false),
                TangramPlacement(
                    piece: .small, position: CGPoint(x: 17.65685424949238, y: 22.31370849898476), rotation: 5, flipped: false),
                TangramPlacement(
                    piece: .medium, position: CGPoint(x: 21.65685424949238, y: 18.31370849898476), rotation: 4, flipped: false),
                TangramPlacement(
                    piece: .large2, position: CGPoint(x: 11.65685424949238, y: 14.65685424949238), rotation: 4, flipped: false),
                TangramPlacement(
                    piece: .small2, position: CGPoint(x: 13.65685424949238, y: 22.31370849898476), rotation: 0, flipped: false),
            ]),
        TangramShape(
            key: "tangram.shape.28",
            placements: [
                TangramPlacement(
                    piece: .parallelogram, position: CGPoint(x: 6.656854249492381, y: 10.65685424949238), rotation: 0,
                    flipped: false),
                TangramPlacement(
                    piece: .square, position: CGPoint(x: 9.65685424949238, y: 12.65685424949238), rotation: 1, flipped: false),
                TangramPlacement(
                    piece: .small, position: CGPoint(x: 12.65685424949238, y: 12.65685424949238), rotation: 0, flipped: false),
                TangramPlacement(
                    piece: .small2, position: CGPoint(x: 12.65685424949238, y: 15.48528137423857), rotation: 0, flipped: false),
                TangramPlacement(
                    piece: .large, position: CGPoint(x: 6.656854249492381, y: 10.65685424949238), rotation: 4, flipped: false),
                TangramPlacement(
                    piece: .medium, position: CGPoint(x: 10.65685424949238, y: 10.65685424949238), rotation: 4, flipped: true),
                TangramPlacement(
                    piece: .large2, position: CGPoint(x: 9.65685424949238, y: 16.65685424949238), rotation: 0, flipped: true),
            ]),
        TangramShape(
            key: "tangram.shape.29",
            placements: [
                TangramPlacement(
                    piece: .medium, position: CGPoint(x: 6.656854249492381, y: 8.65685424949238), rotation: 0, flipped: false),
                TangramPlacement(
                    piece: .large, position: CGPoint(x: 6.656854249492381, y: 12.65685424949238), rotation: 0, flipped: false),
                TangramPlacement(
                    piece: .small, position: CGPoint(x: 10.899494936611667, y: 16.899494936611667), rotation: 4, flipped: false),
                TangramPlacement(
                    piece: .small2, position: CGPoint(x: 3.8284271247461903, y: 8.65685424949238), rotation: 4, flipped: false),
                TangramPlacement(
                    piece: .square, position: CGPoint(x: 10.65685424949238, y: 8.65685424949238), rotation: 4, flipped: true),
                TangramPlacement(
                    piece: .parallelogram, position: CGPoint(x: 6.656854249492381, y: 11.48528137423857), rotation: 5,
                    flipped: false),
                TangramPlacement(
                    piece: .large2, position: CGPoint(x: 6.656854249492381, y: 12.65685424949238), rotation: 0, flipped: true),
            ]),
        TangramShape(
            key: "tangram.shape.30",
            placements: [
                TangramPlacement(
                    piece: .square, position: CGPoint(x: 6.656854249492381, y: 14.65685424949238), rotation: 5, flipped: true),
                TangramPlacement(
                    piece: .large, position: CGPoint(x: 6.656854249492381, y: 14.65685424949238), rotation: 2, flipped: false),
                TangramPlacement(
                    piece: .large2, position: CGPoint(x: 10.65685424949238, y: 14.65685424949238), rotation: 6, flipped: true),
                TangramPlacement(
                    piece: .small, position: CGPoint(x: 6.656854249492381, y: 14.65685424949238), rotation: 4, flipped: false),
                TangramPlacement(
                    piece: .small2, position: CGPoint(x: 10.65685424949238, y: 14.65685424949238), rotation: 4, flipped: true),
                TangramPlacement(
                    piece: .parallelogram, position: CGPoint(x: 6.656854249492381, y: 12.65685424949238), rotation: 4,
                    flipped: true),
                TangramPlacement(
                    piece: .medium, position: CGPoint(x: 12.65685424949238, y: 10.65685424949238), rotation: 4, flipped: true),
            ]),
    ]
}
