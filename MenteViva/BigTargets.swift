import SwiftUI

/// A big answer tile (#122): the full width of its grid column, at least
/// 110pt tall (conventions §4), on a soft wash of the current tint (each game
/// sets its ink). Dims a little while pressed.
struct AnswerTileStyle: ButtonStyle {
    var strength: Double = 0.15
    var minHeight: CGFloat = 110

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity, minHeight: minHeight)
            .background(.tint.opacity(strength), in: .rect(cornerRadius: 16))
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

extension View {
    /// The 100pt hit area for toolbar buttons (conventions §4, #64).
    func bigTapTarget() -> some View {
        frame(minWidth: 100, minHeight: 100).contentShape(Rectangle())
    }
}
