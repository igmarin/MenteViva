import SwiftUI

/// A big answer tile (#122): the full width of its grid column, at least
/// 110pt tall (conventions §4), on a soft wash of the current tint (each game
/// sets its ink) with a tint outline. Dims a little while pressed.
struct AnswerTileStyle: ButtonStyle {
    var strength: Double = 0.15
    var minHeight: CGFloat = 110

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity, minHeight: minHeight)
            .background(.tint.opacity(strength), in: .rect(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(.tint, lineWidth: 2))
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

extension View {
    /// The 100pt hit area for toolbar buttons (conventions §4, #64).
    func bigTapTarget() -> some View {
        frame(minWidth: 100, minHeight: 100).contentShape(Rectangle())
    }
}

/// One answer on the first-run questions and in Settings → My plan (#212): as wide as the
/// screen, at least 100pt tall, `.title2`, on a soft wash of the current tint. The chosen one
/// also carries a tick, so "chosen" is never colour alone (conventions §4).
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
        .background(
            chosen ? AnyShapeStyle(.tint.opacity(0.22)) : AnyShapeStyle(.gray.opacity(0.12)),
            in: .rect(cornerRadius: 16)
        )
        .contentShape(Rectangle())
    }
}
