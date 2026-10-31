import SwiftUI

/// Settings a stranger can reach alone, in three sections (#421): "For you" (language, sound,
/// bigger text, guides), "For the family" (My progress, My plan, Set up; #141) and "About"
/// (why these games, privacy, version).
struct SettingsView: View {
    /// UserDefaults key of the Bigger text toggle.
    static let biggerTextKey = "biggerText"

    @AppStorage(AppLanguage.storageKey) private var appLanguage = AppLanguage.system.rawValue
    @AppStorage(SettingsView.biggerTextKey) private var biggerText = false
    @AppStorage(SoundPlayer.enabledKey) private var soundEnabled = true
    @AppStorage(CaptionSpeaker.speakNamesKey) private var speakNames = false
    @State private var guidesReset = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                // Everything about how the app looks and sounds to the player: one section (#421).
                Section {
                    Text(AppLanguage.localized("settings.language"))
                        .font(.title3.weight(.semibold))
                        .accessibilityAddTraits(.isHeader)
                    VStack(spacing: 0) {
                        ForEach(AppLanguage.allCases) { language in
                            Button {
                                AppLanguage.apply(language.rawValue)
                            } label: {
                                HStack {
                                    Text(language.label)
                                    Spacer()
                                    if language.rawValue == appLanguage {
                                        Image(systemName: "checkmark")
                                            .accessibilityHidden(true)
                                    }
                                }
                                .frame(maxWidth: .infinity, minHeight: 100, alignment: .leading)
                            }
                            .buttonStyle(.plain)
                            .frame(maxWidth: .infinity, minHeight: 100)
                            .contentShape(Rectangle())
                            .accessibilityAddTraits(language.rawValue == appLanguage ? [.isSelected] : [])
                            .accessibilityHint(AppLanguage.localized("settings.language.restart"))
                        }
                    }
                    Text(AppLanguage.localized("settings.language.restart"))
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    Toggle(AppLanguage.localized("settings.sound"), isOn: $soundEnabled)
                        .font(.title3)
                        .frame(minHeight: 100)
                        .accessibilityHint(AppLanguage.localized("settings.sound.hint"))

                    Toggle(AppLanguage.localized("settings.speak"), isOn: $speakNames)
                        .font(.title3)
                        .frame(minHeight: 100)
                        .accessibilityHint(AppLanguage.localized("settings.speak.hint"))

                    Toggle(AppLanguage.localized("settings.textsize"), isOn: $biggerText)
                        .font(.title3)
                        .frame(minHeight: 100)

                    // Brings back each game's "Let me show you" guide (#243).
                    Button {
                        FirstPlayGuideStore.resetAll()
                        guidesReset = true
                    } label: {
                        HStack {
                            Text(AppLanguage.localized("settings.guides"))
                            Spacer()
                            if guidesReset {
                                Image(systemName: "checkmark")
                                    .accessibilityHidden(true)
                            }
                        }
                        .font(.title3)
                        .frame(maxWidth: .infinity, minHeight: 100, alignment: .leading)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityValue(guidesReset ? AppLanguage.localized("settings.guides.done") : "")
                } header: {
                    sectionHeader("settings.section.you")
                }

                // The tools a family member uses to set the app up for someone else.
                Section {
                    NavigationLink {
                        MyProgressView()
                    } label: {
                        Label(AppLanguage.localized("progress.title"), systemImage: "chart.bar.fill")
                            .font(.title3)
                            .frame(maxWidth: .infinity, minHeight: 100, alignment: .leading)
                    }
                    .accessibilityHint(AppLanguage.localized("progress.open.hint"))

                    NavigationLink {
                        // Closes the whole sheet, not just this push, so Home shows the warm-up (#402).
                        MyPlanView(onWarmUpStarted: { dismiss() })
                    } label: {
                        Label(AppLanguage.localized("myplan.title"), systemImage: "checklist")
                            .font(.title3)
                            .frame(maxWidth: .infinity, minHeight: 100, alignment: .leading)
                    }
                    .accessibilityHint(AppLanguage.localized("myplan.open.hint"))

                    NavigationLink {
                        SetUpView()
                    } label: {
                        Label(AppLanguage.localized("setup.title"), systemImage: "slider.horizontal.3")
                            .font(.title3)
                            .frame(maxWidth: .infinity, minHeight: 100, alignment: .leading)
                    }
                    .accessibilityHint(AppLanguage.localized("setup.open.hint"))
                } header: {
                    sectionHeader("settings.section.family")
                }

                // What the app is, why it has these games, what it keeps, and which version.
                Section {
                    // The balanced, sourced words behind the games (#214), readable offline.
                    NavigationLink {
                        WhyTheseGamesView()
                    } label: {
                        Label(AppLanguage.localized("why.title"), systemImage: "questionmark.circle")
                            .font(.title3)
                            .frame(maxWidth: .infinity, minHeight: 100, alignment: .leading)
                    }
                    .accessibilityHint(AppLanguage.localized("why.open.hint"))

                    // How the pictures and the code were made, and that nothing uses AI in play (#378).
                    NavigationLink {
                        AboutView()
                    } label: {
                        Label(AppLanguage.localized("about.row"), systemImage: "info.circle")
                            .font(.title3)
                            .frame(maxWidth: .infinity, minHeight: 100, alignment: .leading)
                    }
                    .accessibilityHint(AppLanguage.localized("about.row.hint"))

                    // Short promises he can read at a glance.
                    Text(AppLanguage.localized("settings.privacy.title"))
                        .font(.title3.weight(.semibold))
                        .accessibilityAddTraits(.isHeader)
                    privacyLine(
                        String(format: AppLanguage.localized("settings.privacy.device %@"), device),
                        systemImage: device == "iPad" ? "ipad" : "iphone")
                    privacyLine(AppLanguage.localized("settings.privacy.noaccount"), systemImage: "nosign")
                    privacyLine(AppLanguage.localized("settings.privacy.photos"), systemImage: "photo.on.rectangle")
                    Text(String(format: AppLanguage.localized("settings.privacy.backup %@"), device))
                        .font(.body)
                        .foregroundStyle(.secondary)
                    if let policy = URL(string: AppLanguage.localized("settings.privacy.policy.url")) {
                        Link(destination: policy) {
                            Label(AppLanguage.localized("settings.privacy.policy"), systemImage: "hand.raised")
                                .font(.title3)
                                .frame(maxWidth: .infinity, minHeight: 100, alignment: .leading)
                        }
                    }
                    if let support = URL(string: AppLanguage.localized("settings.privacy.support.url")) {
                        Link(destination: support) {
                            Label(AppLanguage.localized("settings.privacy.support"), systemImage: "questionmark.circle")
                                .font(.title3)
                                .frame(maxWidth: .infinity, minHeight: 100, alignment: .leading)
                        }
                    }

                    LabeledContent(
                        AppLanguage.localized("settings.version"),
                        value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
                    )
                    .font(.body)
                } header: {
                    sectionHeader("settings.section.about")
                }
            }
            .listPageBackground()
            .navigationTitle(AppLanguage.localized("settings.title"))
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(AppLanguage.localized("settings.done")) { dismiss() }
                        .font(.title3)
                        .bigTapTarget()
                }
            }
        }
        .id(appLanguage)
    }

    /// A section's name, big and bold so the three groups are told apart at a glance (#421).
    private func sectionHeader(_ key: String) -> some View {
        Text(AppLanguage.localized(key))
            .font(.title3.weight(.heavy))
            .textCase(nil)
            .accessibilityAddTraits(.isHeader)
    }

    /// "iPad" or "iPhone", so each promise names the device in his hands.
    private var device: String { UIDevice.current.model }

    private func privacyLine(_ text: String, systemImage: String) -> some View {
        Label {
            Text(text).font(.title3.weight(.semibold))
        } icon: {
            Image(systemName: systemImage)
                .font(.title2)
                .foregroundStyle(Color.brand)
                .accessibilityHidden(true)
        }
        .padding(.vertical, 6)
    }
}

#Preview {
    SettingsView()
}
