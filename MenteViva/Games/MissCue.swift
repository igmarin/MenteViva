import SwiftUI

/// Gentle, text-free "not that one" cue for a wrong pick (#64): a soft amber
/// outline and a tiny shrink, gone in under a second. Motion is skipped under
/// Reduce Motion; the outline alone carries the cue. Never says "wrong".
struct MissCue: ViewModifier {
    @Binding var active: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(.orange, lineWidth: 6)
                    .opacity(active ? 0.9 : 0)
                    .accessibilityHidden(true)
            }
            .scaleEffect(active && !reduceMotion ? 0.94 : 1)
            .animation(.easeOut(duration: 0.25), value: active)
            .task(id: active) {
                guard active else { return }
                try? await Task.sleep(for: .milliseconds(700))
                active = false
            }
    }
}
