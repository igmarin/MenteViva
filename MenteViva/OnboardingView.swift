import SwiftUI

/// First run, for someone who has never heard of this app and has nobody to ask (#212).
///
/// Step 1 is the welcome screen, kept as it was: title, three short lines, the language
/// choice, Start. Steps 2-5 are the four questions from `OnboardingSteps`, one per screen:
/// big answer tiles, a visible Skip, Back, and a "2 of 5" dot row. Answers save as they are
/// given, so a flow left half-way keeps what was answered, and every one of them can be
/// changed later in Settings -> My plan. No age, no health question, no text field.
///
/// Claim ceiling is deliberate (research §1, App Store 1.4.1): "keep your mind
/// active", never treatment, prevention or diagnosis.
struct OnboardingView: View {
    /// UserDefaults key: true once the first-run screens have been passed.
    static let seenKey = "hasSeenOnboarding"

    @AppStorage(OnboardingView.seenKey) private var hasSeenOnboarding = false
    @AppStorage(AppLanguage.storageKey) private var appLanguage = AppLanguage.system.rawValue
    /// Bigger text needs the whole width for one answer, so the grid becomes a single column.
    @Environment(\.dynamicTypeSize) private var typeSize
    /// The step on screen: 1 is the welcome screen, 2-5 are the questions in order.
    @State private var step = 1
    /// The answers so far. Saved after every tap, so leaving mid-way loses nothing.
    @State private var profile = ProfileStore.load()

    /// This step's question, or nil on the welcome screen.
    private var question: OnboardingQuestion? {
        step >= 2 ? OnboardingSteps.questions[step - 2] : nil
    }

    var body: some View {
        VStack(spacing: 24) {
            if let question {
                questionStep(question)
            } else {
                welcome
            }
        }
        // At the largest text sizes the screens scroll, so the answers and Skip stay reachable.
        .fitOrScroll()
        .padding(24)
    }

    // MARK: Step 1 - the welcome screen, kept as it was

    private var welcome: some View {
        VStack(spacing: 28) {
            Spacer()

            Text(verbatim: "🧩")
                .font(.system(size: 88))
                .accessibilityHidden(true)

            Text(AppLanguage.localized("app.title"))
                .font(.largeTitle.weight(.bold))
                .fontDesign(.serif)

            VStack(spacing: 12) {
                line(AppLanguage.localized("onboarding.line1"))
                line(AppLanguage.localized("onboarding.line2"))
                line(AppLanguage.localized("onboarding.line3"))
            }
            .padding(.horizontal, 8)

            Text(AppLanguage.localized("onboarding.disclaimer"))
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Spacer()

            languageChoice

            Button {
                next()
            } label: {
                Text(AppLanguage.localized("onboarding.start"))
                    .font(.title2.weight(.semibold))
                    .frame(maxWidth: .infinity, minHeight: 100)
                    .foregroundStyle(Color(.systemBackground))
                    .background(Color.brand, in: .rect(cornerRadius: 20))
            }
            .buttonStyle(.plain)
            .accessibilityHint(AppLanguage.localized("onboarding.start.hint"))
        }
    }

    // MARK: Steps 2-5 - one question each

    /// One question per screen. The question comes before its answers in the layout, so
    /// VoiceOver reads what is being asked and then each answer with its state.
    private func questionStep(_ question: OnboardingQuestion) -> some View {
        VStack(spacing: 16) {
            stepDots

            Spacer(minLength: 0)

            Text(AppLanguage.localized(question.titleKey))
                .font(.title2.weight(.semibold))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)

            // Five answers one per row would push Next and Skip off an everyday screen, so the
            // multi-select question lays its tiles out two by two; every other question shows one
            // per row, and at bigger text sizes every question does, because the words need the
            // whole width. Each tile keeps its 100pt height either way (conventions §4).
            if question.allowsMultiple {
                LazyVGrid(columns: answerColumns, spacing: 10) {
                    answerTiles(question)
                }
            } else {
                VStack(spacing: 10) {
                    answerTiles(question)
                }
            }

            // The focus question takes more than one answer, so it is the only one that waits
            // for "Next" instead of moving on at the first tap.
            if question.allowsMultiple {
                Button {
                    next()
                } label: {
                    Text(AppLanguage.localized("onboarding.next"))
                        .font(.title2.weight(.semibold))
                        .frame(maxWidth: .infinity, minHeight: 100)
                        .foregroundStyle(Color(.systemBackground))
                        .background(Color.brand, in: .rect(cornerRadius: 20))
                }
                .buttonStyle(.plain)
            }

            Spacer(minLength: 0)

            footer
        }
    }

    /// One tile per answer, in the order the flow offers them. The chosen ones carry a tick and a
    /// filled background, never colour alone.
    @ViewBuilder
    private func answerTiles(_ question: OnboardingQuestion) -> some View {
        ForEach(OnboardingSteps.answers(for: question, profile: profile), id: \.labelKey) { answer in
            let chosen = OnboardingSteps.isChosen(answer, in: profile)
            Button {
                choose(answer, in: question)
            } label: {
                ProfileAnswerTile(text: AppLanguage.localized(answer.labelKey), chosen: chosen)
            }
            .buttonStyle(.plain)
            .accessibilityAddTraits(chosen ? [.isSelected] : [])
        }
    }

    /// Two columns for the question that offers five answers, one column everywhere else and at
    /// accessibility text sizes, where two short columns would break the words in half.
    private var answerColumns: [GridItem] {
        typeSize.isAccessibilitySize
            ? [GridItem(.flexible())]
            : [GridItem(.flexible(), spacing: 12), GridItem(.flexible())]
    }

    /// "2 of 5" and one dot per step: the words say where the player is, the dots show it,
    /// so the progress is never colour alone (conventions §4).
    private var stepDots: some View {
        VStack(spacing: 10) {
            Text(String(format: AppLanguage.localized("onboarding.step %lld %lld"), step, OnboardingSteps.stepCount))
                .font(.body)
                .foregroundStyle(.secondary)

            HStack(spacing: 10) {
                ForEach(1...OnboardingSteps.stepCount, id: \.self) { dot in
                    Circle()
                        .fill(dot <= step ? Color.brand : Color.clear)
                        .overlay(Circle().strokeBorder(Color.brand, lineWidth: 2))
                        .frame(width: 14, height: 14)
                }
            }
            .accessibilityHidden(true)
        }
    }

    /// Back and Skip, both 100pt and always on screen: leaving a question unanswered is as
    /// easy as answering it (#212).
    private var footer: some View {
        HStack(spacing: 12) {
            Button {
                back()
            } label: {
                Text(AppLanguage.localized("onboarding.back"))
                    .font(.title2)
            }
            .buttonStyle(AnswerTileStyle(strength: 0.10))
            .accessibilityHint(AppLanguage.localized("onboarding.back.hint"))

            Button {
                next()
            } label: {
                Text(AppLanguage.localized("onboarding.skip"))
                    .font(.title2)
            }
            .buttonStyle(AnswerTileStyle(strength: 0.10))
            .accessibilityHint(AppLanguage.localized("onboarding.skip.hint"))
        }
    }

    private func line(_ text: String) -> some View {
        Text(text)
            .font(.title2)
            .multilineTextAlignment(.center)
    }

    /// Language is asked here rather than buried in settings: for a stranger,
    /// this is the one setting that must be right before anything else.
    private var languageChoice: some View {
        HStack(spacing: 12) {
            ForEach(AppLanguage.allCases) { language in
                Button {
                    AppLanguage.apply(language.rawValue)
                } label: {
                    Text(language.label)
                        .font(.title3.weight(language.rawValue == appLanguage ? .bold : .regular))
                        .frame(maxWidth: .infinity, minHeight: 100)
                        .background(
                            language.rawValue == appLanguage
                                ? AnyShapeStyle(.tint.opacity(0.22)) : AnyShapeStyle(.gray.opacity(0.12)),
                            in: .rect(cornerRadius: 16))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(language.label)
                .accessibilityAddTraits(language.rawValue == appLanguage ? [.isSelected] : [])
            }
        }
    }

    // MARK: Answers

    /// Answers save as they are given, so a flow left half-way keeps what was answered. A
    /// question that takes one answer moves on at the tap; the others wait for Next.
    private func choose(_ answer: ProfileAnswer, in question: OnboardingQuestion) {
        profile = OnboardingSteps.choosing(answer, in: profile)
        ProfileStore.save(profile)
        if !question.allowsMultiple { next() }
    }

    /// Forward: the next question, or Home once the last one is done. Skip calls this too,
    /// leaving the profile exactly as it is.
    private func next() {
        guard step < OnboardingSteps.stepCount else {
            hasSeenOnboarding = true
            return
        }
        step += 1
    }

    /// Back: the previous question, or the welcome screen.
    private func back() {
        step = max(1, step - 1)
    }
}

#Preview {
    OnboardingView()
}
