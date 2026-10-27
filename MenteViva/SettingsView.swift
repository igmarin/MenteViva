import SwiftUI

/// Settings a stranger can reach alone: language, sound & haptics, bigger text,
/// My progress and Set up (#141), privacy, version.
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
                Section {
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
                } header: {
                    Text(AppLanguage.localized("settings.language"))
                        .font(.title3)
                } footer: {
                    Text(AppLanguage.localized("settings.language.restart"))
                        .font(.footnote)
                }

                Section {
                    Toggle(AppLanguage.localized("settings.sound"), isOn: $soundEnabled)
                        .font(.title3)
                        .frame(minHeight: 100)
                        .accessibilityHint(AppLanguage.localized("settings.sound.hint"))
                }

                Section {
                    Toggle(AppLanguage.localized("settings.speak"), isOn: $speakNames)
                        .font(.title3)
                        .frame(minHeight: 100)
                        .accessibilityHint(AppLanguage.localized("settings.speak.hint"))
                }

                Section {
                    Toggle(AppLanguage.localized("settings.textsize"), isOn: $biggerText)
                        .font(.title3)
                        .frame(minHeight: 100)
                }

                Section {
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
                }

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
                        SetUpView()
                    } label: {
                        Label(AppLanguage.localized("setup.title"), systemImage: "slider.horizontal.3")
                            .font(.title3)
                            .frame(maxWidth: .infinity, minHeight: 100, alignment: .leading)
                    }
                    .accessibilityHint(AppLanguage.localized("setup.open.hint"))

                    // The balanced, sourced words behind the games (#214), readable offline.
                    NavigationLink {
                        WhyTheseGamesView()
                    } label: {
                        Label(AppLanguage.localized("why.title"), systemImage: "questionmark.circle")
                            .font(.title3)
                            .frame(maxWidth: .infinity, minHeight: 100, alignment: .leading)
                    }
                    .accessibilityHint(AppLanguage.localized("why.open.hint"))
                }

                // Short promises he can read at a glance.
                Section {
                    privacyLine(
                        String(format: AppLanguage.localized("settings.privacy.device %@"), device),
                        systemImage: device == "iPad" ? "ipad" : "iphone")
                    privacyLine(AppLanguage.localized("settings.privacy.noaccount"), systemImage: "nosign")
                    privacyLine(AppLanguage.localized("settings.privacy.photos"), systemImage: "photo.on.rectangle")
                    Text(String(format: AppLanguage.localized("settings.privacy.backup %@"), device))
                        .font(.body)
                        .foregroundStyle(.secondary)
                } header: {
                    Text(AppLanguage.localized("settings.privacy.title"))
                        .font(.title3)
                }

                Section {
                    LabeledContent(
                        AppLanguage.localized("settings.version"),
                        value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
                    )
                    .font(.body)
                }
            }
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
