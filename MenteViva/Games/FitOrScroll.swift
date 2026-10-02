import SwiftUI

extension View {
    /// Shows the screen as laid out when it fits, and scrolls it only when it
    /// doesn't (#117): at the largest text sizes an instruction must never be
    /// cut short. At everyday sizes nothing moves.
    func fitOrScroll() -> some View {
        ViewThatFits(in: .vertical) {
            self
            ScrollView { self }
        }
    }
}
