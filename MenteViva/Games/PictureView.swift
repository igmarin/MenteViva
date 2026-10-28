import SwiftUI
import UIKit

/// Draws a game picture at a given size (#324): our illustration when the art
/// batch has shipped it, the emoji until then, so batches land one at a time
/// without touching the games. Callers set the VoiceOver label, because one
/// game (Remember Together) hides the name until it is revealed.
struct PictureView: View {
    let picture: GamePicture
    let size: CGFloat

    var body: some View {
        switch picture.look(hasAsset: Self.bundleHasAsset) {
        case .asset(let name):
            Image(name)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
        case .emoji(let emoji):
            Text(emoji)
                .font(.system(size: size))
        }
    }

    /// Whether the app ships an image of that name.
    nonisolated static func bundleHasAsset(_ name: String) -> Bool {
        UIImage(named: name) != nil
    }
}
