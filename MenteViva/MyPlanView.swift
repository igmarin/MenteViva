import SwiftUI

/// Settings → My plan (#212): the four first-run questions on one screen, so nothing asked
/// once at the start is a trap. Every change saves at once and shapes tomorrow's plan, and
/// tapping the chosen answer again leaves that question unanswered — which is how a first-run
/// answer is taken back without a "none" button to explain. The questions, their order and
/// their answers all come from `OnboardingSteps`, the same data the first run uses.
struct MyPlanView: View {
    /// The saved answers. Loaded once when the screen is made; this screen is the only writer
    /// while it is open.
    @State private var profile = ProfileStore.load()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                ForEach(OnboardingSteps.questions, id: \.rawValue) { question in
                    section(question)
                }
                Text(AppLanguage.localized("myplan.note"))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding()
        }
        .navigationTitle(AppLanguage.localized("myplan.title"))
    }

    /// One question and its answers, in the same big tiles as the first run: the two screens
    /// teach each other, and the tick plus the filled tile say "chosen" without colour alone
    /// (conventions §4).
    private func section(_ question: OnboardingQuestion) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(AppLanguage.localized(question.titleKey))
                .font(.title2.weight(.semibold))
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            ForEach(OnboardingSteps.answers(for: question, profile: profile), id: \.labelKey) { answer in
                let chosen = OnboardingSteps.isChosen(answer, in: profile)
                Button {
                    choose(answer)
                } label: {
                    ProfileAnswerTile(text: AppLanguage.localized(answer.labelKey), chosen: chosen)
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(chosen ? [.isSelected] : [])
            }
        }
    }

    /// Saves the moment an answer changes: this screen has no "save" button, and an answer
    /// must survive the app being closed. Today's plan was dealt this morning, so it stands;
    /// tomorrow's is dealt from here (the note at the end of the screen says so).
    private func choose(_ answer: ProfileAnswer) {
        profile = OnboardingSteps.choosing(answer, in: profile)
        ProfileStore.save(profile)
    }
}

#Preview {
    NavigationStack {
        MyPlanView()
    }
}
