import SwiftUI

/// First run, for someone who has never heard of this app and has nobody to ask.
/// One screen, three short lines, a language choice, one big button.
///
/// Claim ceiling is deliberate (research §1, App Store 1.4.1): "keep your mind
/// active", never treatment, prevention or diagnosis.
struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @AppStorage("appLanguage") private var appLanguage = AppLanguage.system.rawValue

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            Text(verbatim: "🧩")
                .font(.system(size: 88))
                .accessibilityHidden(true)

            Text(AppLanguage.localized("app.title"))
                .font(.largeTitle.weight(.bold))

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
                hasSeenOnboarding = true
            } label: {
                Text(AppLanguage.localized("onboarding.start"))
                    .font(.title2.weight(.semibold))
                    .frame(maxWidth: .infinity, minHeight: 100)
                    .background(.blue.opacity(0.15), in: .rect(cornerRadius: 20))
            }
            .buttonStyle(.plain)
            .accessibilityHint(AppLanguage.localized("onboarding.start.hint"))
        }
        .padding(24)
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
                    appLanguage = language.rawValue
                } label: {
                    Text(language.label)
                        .font(.title3.weight(language.rawValue == appLanguage ? .bold : .regular))
                        .frame(maxWidth: .infinity, minHeight: 100)
                        .background(language.rawValue == appLanguage ? .blue.opacity(0.22) : .gray.opacity(0.12),
                                    in: .rect(cornerRadius: 16))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(language.label)
                .accessibilityAddTraits(language.rawValue == appLanguage ? [.isSelected] : [])
            }
        }
    }
}

#Preview {
    OnboardingView()
}
