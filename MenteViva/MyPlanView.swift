import SwiftData
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
    @Environment(\.modelContext) private var modelContext
    /// Called once the warm-up has replaced today's plan. This screen is pushed inside Settings'
    /// own navigation stack, so its `dismiss` would only go back to Settings; the caller closes
    /// the whole Settings sheet instead, and Home re-reads the plan when it closes (#402).
    let onWarmUpStarted: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                ForEach(OnboardingSteps.questions, id: \.rawValue) { question in
                    section(question)
                }
                warmUp
                Text(AppLanguage.localized("myplan.note"))
                    .font(.footnote)
                    .foregroundStyle(Color.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding()
        }
        .pageBackground()
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

    /// The warm-up can always be started from here (#213), including by someone who was set up by
    /// a family member and so was not offered it. Today's plan becomes the three games, so the
    /// screen closes and Home shows them.
    private var warmUp: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(AppLanguage.localized("warmup.offer.title"))
                .font(.title2.weight(.semibold))
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            Button {
                WarmUpStore.start(profile: profile, today: PlanStore.dayStamp())
                onWarmUpStarted()
            } label: {
                ProfileAnswerTile(text: AppLanguage.localized("warmup.accept"), chosen: false)
            }
            .buttonStyle(.plain)
            .accessibilityHint(AppLanguage.localized("warmup.accept.hint"))
        }
    }

    /// Saves the moment an answer changes: this screen has no "save" button, and an answer
    /// must survive the app being closed. Today's plan was dealt this morning, so it stands;
    /// tomorrow's is dealt from here (the note at the end of the screen says so). A new start pace
    /// also moves the games never played to it (#419); `PlanStore` decides which.
    private func choose(_ answer: ProfileAnswer) {
        let old = profile
        profile = OnboardingSteps.choosing(answer, in: profile)
        ProfileStore.save(profile)
        PlanStore.startPaceChanged(from: old, to: profile, played: { modelContext.playedGames() })
    }
}

#Preview {
    NavigationStack {
        MyPlanView(onWarmUpStarted: {})
    }
    .modelContainer(for: GameSession.self, inMemory: true)
}
