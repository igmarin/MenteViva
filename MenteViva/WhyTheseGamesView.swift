import SwiftUI

/// "Why these games" (#214): the words the owner approved in #210, readable offline in Settings.
///
/// Three parts, each opened by a real heading, so the VoiceOver rotor lists them and someone
/// listening can jump to the part they came for. The sentences are the approved ones, kept whole:
/// this screen adds no claim of its own. Every line that rests on a source keeps that source beside
/// it as a link whose label names where it goes — a listener has nothing else to go on — and the
/// last line says what MenteViva is not, because a screen about memory is exactly where a promise
/// would be expected.
struct WhyTheseGamesView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                section("why.research.title") {
                    line("why.research.small", source: .cct)
                    line("why.research.transfer", source: .simons)
                    line("why.research.stanford", source: .stanford)
                    line("why.research.varied", source: .globalCouncil)
                    line("why.research.bundle", source: .finger)
                    line("why.research.promise")
                }

                section("why.games.title") {
                    line("why.game.memory", source: .cct)
                    line("why.game.colorclash", source: .simons)
                    line("why.game.category", source: .fluency)
                    line("why.game.math")
                    line("why.game.quickeyes", source: .processingSpeed)
                    line("why.game.reminiscence", source: .globalCouncil)
                    line("why.game.sudoku", source: .simons)
                    line("why.game.upordown", source: .simons)
                    line("why.game.sayings", source: .fluency)
                    line("why.game.sequence", source: .workingMemory)
                    line("why.game.tangram", source: .simons)
                    line("why.game.tilepairs", source: .simons)
                    line("why.game.sliding", source: .simons)
                }

                section("why.not.title") {
                    line("why.not.device", source: .fda)
                    line("why.not.test")
                    line("why.not.advice", source: .fda)
                    line("why.not.doctor")
                    line("why.not.fun")
                }

                footer
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .navigationTitle(AppLanguage.localized("why.title"))
    }

    /// The screen's closing line: the one sentence that has to survive being read on its own, so it
    /// stands apart from the three parts instead of being mixed into one of them.
    private var footer: some View {
        VStack(alignment: .leading, spacing: 24) {
            Divider()
            Text(AppLanguage.localized("why.footer"))
                .font(.title2.weight(.semibold))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    /// One part of the screen. The heading carries the header trait, which is what puts the three
    /// parts in the VoiceOver rotor rather than making someone read the whole screen to find theirs.
    private func section<Content: View>(_ titleKey: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 24) {
            Text(AppLanguage.localized(titleKey))
                .font(.title2.weight(.bold))
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            content()
        }
    }

    /// One approved sentence and, when it rests on one, its source underneath: the two stay together
    /// without either one fixing the other's height, so the largest text size only makes the screen
    /// longer. The link keeps a 100pt target (conventions §4).
    private func line(_ key: String, source: WhySource? = nil) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(AppLanguage.localized(key))
                .font(.title2)
                .fixedSize(horizontal: false, vertical: true)
            if let source {
                Link(destination: source.url) {
                    Text(AppLanguage.localized(source.labelKey))
                        .font(.title2)
                        .multilineTextAlignment(.leading)
                        // The label fills the row so it lines up with the paragraph above it,
                        // instead of the button's own centring; the whole row is the target.
                        .frame(maxWidth: .infinity, minHeight: 100, alignment: .leading)
                }
                .contentShape(Rectangle())
                .accessibilityHint(AppLanguage.localized("why.source.hint"))
            }
        }
    }
}

/// One outside source and the label that names it. The address lives here and nowhere else: the app
/// reads nothing over the network, it only hands the address to Safari when the player taps, so the
/// screen itself works with no connection at all.
private struct WhySource {
    let labelKey: String
    let url: URL

    static let cct = WhySource(
        labelKey: "why.source.cct", url: URL(string: "https://pmc.ncbi.nlm.nih.gov/articles/PMC4236015/")!)
    static let simons = WhySource(
        labelKey: "why.source.simons",
        url: URL(string: "https://journals.sagepub.com/doi/10.1177/1529100616661983")!)
    static let stanford = WhySource(
        labelKey: "why.source.stanford",
        url: URL(
            string:
                "https://longevity.stanford.edu/a-consensus-on-the-brain-training-industry-from-the-scientific-community/"
        )!)
    static let globalCouncil = WhySource(
        labelKey: "why.source.globalcouncil", url: URL(string: "https://www.globalcouncilonbrainhealth.org/")!)
    static let finger = WhySource(
        labelKey: "why.source.finger", url: URL(string: "https://doi.org/10.1016/S0140-6736(15)60461-5")!)
    static let fluency = WhySource(
        labelKey: "why.source.fluency", url: URL(string: "https://pmc.ncbi.nlm.nih.gov/articles/PMC3394709/")!)
    static let processingSpeed = WhySource(
        labelKey: "why.source.processing", url: URL(string: "https://pmc.ncbi.nlm.nih.gov/articles/PMC5700828/")!)
    static let workingMemory = WhySource(
        labelKey: "why.source.workingmemory", url: URL(string: "https://pubmed.ncbi.nlm.nih.gov/22612437/")!)
    static let fda = WhySource(
        labelKey: "why.source.fda",
        url: URL(
            string:
                "https://www.fda.gov/regulatory-information/search-fda-guidance-documents/general-wellness-policy-low-risk-devices"
        )!)
}

#Preview {
    NavigationStack {
        WhyTheseGamesView()
    }
}
