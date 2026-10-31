import SwiftUI

/// A big answer tile (#122, #412): the full width of its grid column, at least
/// 110pt tall (conventions §4), printed like Home's cards: a paper face under a
/// soft wash of the current tint (each game sets its ink), a 3pt tint edge and
/// the same hard print shadow as `GameCard`. A press sinks the tile into its
/// shadow; under Reduce Motion it dims instead. A disabled tile loses its
/// shadow and fades its edge, so "not now" is a flatter tile, not only a paler one.
struct AnswerTileStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var strength: Double = 0.15
    var minHeight: CGFloat = 110

    /// How far the print shadow sits from the tile, and how far a press sinks it.
    private static let depth: CGFloat = 3

    func makeBody(configuration: Configuration) -> some View {
        let sunk = configuration.isPressed && !reduceMotion
        let shape = RoundedRectangle(cornerRadius: 16)
        configuration.label
            .frame(maxWidth: .infinity, minHeight: minHeight)
            .background {
                // Paper first, so the wash reads the same on any screen behind the tile.
                ZStack {
                    Color.paper
                    Rectangle().fill(.tint.opacity(strength))
                }
                .clipShape(shape)
            }
            .overlay(shape.strokeBorder(.tint.opacity(isEnabled ? 1 : 0.3), lineWidth: 3))
            // One shadow for the whole tile, not one per glyph (same as GameCard, #366).
            .compositingGroup()
            .shadow(
                color: .black.opacity(isEnabled ? 0.25 : 0), radius: 0,
                x: sunk ? 0 : Self.depth, y: sunk ? 0 : Self.depth
            )
            // The drawing sinks onto its shadow; the tap area below stays where the tile rests.
            .offset(x: sunk ? Self.depth : 0, y: sunk ? Self.depth : 0)
            .contentShape(shape)
            .opacity(configuration.isPressed && reduceMotion ? 0.7 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

/// The one primary button (#421): a brand-green card with a paper label, an espresso edge and the
/// same hard print shadow as `GameCard`, so Start, Next and the end-of-game actions share one look
/// with Home. At least 100pt tall (conventions §4). A press sinks it into its shadow; under
/// Reduce Motion it dims instead. The label sets only its text; the style owns the rest.
struct RetroButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// How far the print shadow sits from the button, and how far a press sinks it.
    private static let depth: CGFloat = 3

    func makeBody(configuration: Configuration) -> some View {
        let sunk = configuration.isPressed && !reduceMotion
        let shape = RoundedRectangle(cornerRadius: 20)
        configuration.label
            .font(.title2.weight(.semibold))
            .multilineTextAlignment(.center)
            .foregroundStyle(Color.paper)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, minHeight: 100)
            .background(Color.brand, in: shape)
            .overlay(shape.strokeBorder(Color.espresso, lineWidth: 2))
            // One shadow for the whole button, not one per glyph (same as GameCard, #366).
            .compositingGroup()
            .shadow(
                color: .black.opacity(0.25), radius: 0,
                x: sunk ? 0 : Self.depth, y: sunk ? 0 : Self.depth
            )
            // The drawing sinks onto its shadow; the tap area stays where the button rests.
            .offset(x: sunk ? Self.depth : 0, y: sunk ? Self.depth : 0)
            .contentShape(shape)
            .opacity(configuration.isPressed && reduceMotion ? 0.8 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

extension View {
    /// The 100pt hit area for toolbar buttons (conventions §4, #64).
    func bigTapTarget() -> some View {
        frame(minWidth: 100, minHeight: 100).contentShape(Rectangle())
    }
}

/// One answer on the first-run questions and in Settings → My plan (#212, #421): as wide as the
/// screen, at least 100pt tall, `.title2`, printed like Home's cards. An unchosen answer is a paper
/// tile with an espresso edge; the chosen one a brand wash with a thicker brand edge and a tick,
/// so "chosen" is never colour alone (conventions §4).
struct ProfileAnswerTile: View {
    let text: String
    let chosen: Bool

    var body: some View {
        HStack(spacing: 12) {
            Text(text)
                .font(.title2.weight(chosen ? .semibold : .regular))
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 8)
            if chosen {
                Image(systemName: "checkmark")
                    .font(.title2.weight(.semibold))
                    .accessibilityHidden(true)
            }
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, minHeight: 100, alignment: .leading)
        .background {
            // Paper first, so the wash reads the same on any screen behind the tile.
            ZStack {
                Color.paper
                if chosen { Color.brand.opacity(0.22) }
            }
            .clipShape(.rect(cornerRadius: 16))
        }
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(chosen ? Color.brand : Color.espresso, lineWidth: chosen ? 3 : 2)
        )
        .contentShape(Rectangle())
    }
}
