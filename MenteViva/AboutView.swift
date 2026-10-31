import SwiftUI

/// "About MenteViva" (#378): says plainly how the pictures and the code were made and that
/// nothing uses AI while someone plays, so players and App Store reviewers can read it in the app.
///
/// Three short paragraphs in reading order under a title that carries the header trait. The
/// words are fixed copy, so the screen reads nothing from the network and works offline. The
/// tool names are the ones recorded in docs/art-prompts.md and docs/decisions/2026-10.md.
struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text(AppLanguage.localized("about.title"))
                    .font(.title2.weight(.bold))
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                paragraph("about.pictures")
                paragraph("about.build")
                paragraph("about.offline")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .pageBackground()
        .navigationTitle(AppLanguage.localized("about.row"))
        .navigationBarTitleDisplayMode(.inline)
    }

    /// One paragraph at `.title2`; it wraps to any length instead of cutting the text short.
    private func paragraph(_ key: String) -> some View {
        Text(AppLanguage.localized(key))
            .font(.title2)
            .fixedSize(horizontal: false, vertical: true)
    }
}

#Preview {
    NavigationStack { AboutView() }
}
