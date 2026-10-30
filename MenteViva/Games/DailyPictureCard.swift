import SwiftUI

/// Today's picture for the album (#376), shown by the celebration after the day's first finished game.
/// It lands face down and turns over once in 0.4 s to show the illustration and its name; with Reduce
/// Motion it cross-fades instead. It never says how many pictures exist or are left (decision 2026-10-30).
struct DailyPictureCard: View {
    let picture: GamePicture

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var turned = false

    private static let shape = RoundedRectangle(cornerRadius: 18)
    /// Small enough that the celebration's main action still fits on a 6.1" iPhone (#376 review).
    private static let side: CGFloat = 140
    /// At accessibility text sizes the celebration scrolls anyway, so the card widens to keep a long
    /// name such as "Tienda de campaña" whole instead of truncating it.
    private var width: CGFloat { typeSize.isAccessibilitySize ? 260 : Self.side }

    var body: some View {
        // Both faces swap at the halfway point, when the card is edge-on; Reduce Motion fades instead.
        let swap: Animation = reduceMotion ? .easeInOut(duration: 0.4).delay(0.5) : .easeInOut(duration: 0.1).delay(0.65)
        // The face sets the size, so a long name at large text sizes grows the card instead of truncating.
        front
            .opacity(turned ? 1 : 0)
            .animation(swap, value: turned)
            .overlay {
                back
                    .opacity(turned ? 0 : 1)
                    .animation(swap, value: turned)
            }
            .frame(width: width)
            .rotation3DEffect(.degrees(turned && !reduceMotion ? 180 : 0), axis: (x: 0, y: 1, z: 0))
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.4).delay(0.5), value: turned)
            // After the turn, so the print shadow lands bottom-right like every card's, not mirrored.
            .compositingGroup()
            .shadow(color: .black.opacity(0.25), radius: 0, x: 3, y: 3)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(Self.line(for: picture)))
            .accessibilityAddTraits(.isImage)
            .onAppear { turned = true }
    }

    /// "Today's picture: Dog. It's in your album." Spoken on arrival and used as the card's label.
    static func line(for picture: GamePicture) -> String {
        String(format: AppLanguage.localized("album.today %@"), AppLanguage.localized(picture.nameKey))
    }

    /// The jade back with a small leaf, like Memory Lane's cards.
    private var back: some View {
        ZStack {
            Self.shape.fill(Color.brand.gradient)
            Image(systemName: "leaf.fill")
                .font(.system(size: 54))
                .foregroundStyle(Color.paper.opacity(0.5))
        }
        .overlay(Self.shape.strokeBorder(Color.espresso, lineWidth: 2))
    }

    /// The paper face; pre-turned so it reads upright once the card has turned over.
    private var front: some View {
        VStack(spacing: 6) {
            PictureView(picture: picture, size: 96)
            Text(AppLanguage.localized(picture.nameKey))
                .font(.title3.weight(.heavy))
                .fontDesign(.rounded)
                .foregroundStyle(Color.espresso)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.6)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, minHeight: Self.side)
        .background(Color.paper, in: Self.shape)
        .overlay(Self.shape.strokeBorder(Color.espresso, lineWidth: 2))
        .rotation3DEffect(.degrees(reduceMotion ? 0 : 180), axis: (x: 0, y: 1, z: 0))
    }
}

#Preview {
    DailyPictureCard(picture: GamePictures.named("teapot"))
}
