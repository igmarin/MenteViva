import SwiftUI

/// Shared end-of-game celebration: gentle confetti, warm headline, big score,
/// and two big actions — play again or go home. Pure SwiftUI, no deps.
/// Presented as a fullScreenCover by every game on finish.
struct CelebrationView: View {
    let score: Int
    let onPlayAgain: () -> Void
    let onHome: () -> Void

    var body: some View {
        ZStack {
            ConfettiView()
                .allowsHitTesting(false)
                .accessibilityHidden(true)

            VStack(spacing: 32) {
                Spacer()

                Text(String(localized: "game.common.welldone"))
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)

                // Fixed size, not a Dynamic Type style — the score is display
                // type, not body text. At AX5 it clips instead of growing.
                Text("\(score)")
                    .font(.system(size: 88, weight: .bold, design: .rounded))
                    .minimumScaleFactor(0.4)
                    .lineLimit(1)
                    .accessibilityLabel(String(localized: "game.celebration.score.a11y"))
                    .accessibilityValue("\(score)")

                Spacer()

                VStack(spacing: 16) {
                    Button(action: onPlayAgain) {
                        Text(String(localized: "game.celebration.playagain"))
                            .font(.title2)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity, minHeight: 100)
                            .background(.blue.opacity(0.2), in: .rect(cornerRadius: 20))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(String(localized: "game.celebration.playagain"))

                    Button(action: onHome) {
                        Text(String(localized: "game.celebration.home"))
                            .font(.title2)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity, minHeight: 100)
                            .background(.green.opacity(0.2), in: .rect(cornerRadius: 20))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(String(localized: "game.celebration.home"))
                }
            }
            .padding(24)
        }
    }
}

/// Gentle confetti: soft pieces drifting down with a slow sway, then looping.
/// Drawn with Canvas + TimelineView. Reduced Motion = a few static pieces.
private struct ConfettiView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private struct Piece: Identifiable {
        let id: Int
        let x: Double        // 0...1 horizontal start
        let size: Double     // 6...12 pt
        let delay: Double    // 0...8 s stagger
        let duration: Double // 7...12 s fall time
        let sway: Double     // 8...28 pt horizontal drift
        let spin: Double     // turns per fall
        let color: Color
        let isCircle: Bool
    }

    private static let palette: [Color] = [.pink, .orange, .yellow, .green, .mint, .blue, .purple]

    private let pieces: [Piece] = (0..<48).map { i in
        Piece(id: i,
              x: Double.random(in: 0...1),
              size: Double.random(in: 6...12),
              delay: Double.random(in: 0...8),
              duration: Double.random(in: 7...12),
              sway: Double.random(in: 8...28) * (Bool.random() ? 1 : -1),
              spin: Double.random(in: 0.5...1.5) * (Bool.random() ? 1 : -1),
              color: palette.randomElement()!.opacity(0.8),
              isCircle: Bool.random())
    }

    var body: some View {
        if reduceMotion {
            Canvas { context, size in
                for piece in pieces.prefix(12) {
                    let rect = CGRect(x: piece.x * size.width,
                                      y: size.height * Double(piece.id) / 12.0,
                                      width: piece.size, height: piece.size)
                    context.fill(Path(ellipseIn: rect), with: .color(piece.color))
                }
            }
        } else {
            TimelineView(.animation) { timeline in
                Canvas { context, size in
                    let now = timeline.date.timeIntervalSinceReferenceDate
                    for piece in pieces {
                        let cycle = (now - piece.delay)
                            .truncatingRemainder(dividingBy: piece.duration) / piece.duration
                        guard cycle >= 0 else { continue }
                        let x = piece.x * size.width
                            + piece.sway * sin(cycle * .pi * 4)
                        let y = -20 + cycle * (size.height + 40)
                        var ctx = context
                        ctx.translateBy(x: x, y: y)
                        ctx.rotate(by: .degrees(360 * piece.spin * cycle))
                        let rect = CGRect(x: -piece.size / 2, y: -piece.size / 2,
                                          width: piece.size,
                                          height: piece.isCircle ? piece.size : piece.size * 1.6)
                        let path = piece.isCircle
                            ? Path(ellipseIn: rect)
                            : Path(roundedRect: rect, cornerRadius: 2)
                        ctx.fill(path, with: .color(piece.color))
                    }
                }
            }
        }
    }
}

#Preview {
    CelebrationView(score: 120, onPlayAgain: {}, onHome: {})
}
