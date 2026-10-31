import SwiftUI

/// The soft amber note a game shows after a near miss (or when it offers help): one look in one
/// place, so every game's kindest line is equally easy to read. Amber on a tint, not secondary
/// grey. Styling only; each game decides when it shows and what it announces.
struct AlmostNote: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.title2.weight(.semibold))
            .foregroundStyle(Color.todaysPick)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color.amber.opacity(0.24), in: .rect(cornerRadius: 14))
    }
}
