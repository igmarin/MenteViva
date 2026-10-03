import SwiftUI

/// Settings a stranger can reach alone: language, sound & haptics, bigger text,
/// the family screen (#107), privacy, version.
struct SettingsView: View {
    /// UserDefaults key of the Bigger text toggle.
    static let biggerTextKey = "biggerText"

    @AppStorage(AppLanguage.storageKey) private var appLanguage = AppLanguage.system.rawValue
    @AppStorage(SettingsView.biggerTextKey) private var biggerText = false
    @AppStorage(SoundPlayer.enabledKey) private var soundEnabled = true
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(spacing: 0) {
                        ForEach(AppLanguage.allCases) { language in
                            Button {
                                AppLanguage.apply(language.rawValue)
                                appLanguage = language.rawValue
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
                    Toggle(AppLanguage.localized("settings.textsize"), isOn: $biggerText)
                        .font(.title3)
                        .frame(minHeight: 100)
                }

                Section {
                    NavigationLink {
                        FamilyView()
                    } label: {
                        Label(AppLanguage.localized("family.title"), systemImage: "person.2.fill")
                            .font(.title3)
                            .frame(maxWidth: .infinity, minHeight: 100, alignment: .leading)
                    }
                    .accessibilityHint(AppLanguage.localized("family.open.hint"))
                }

                Section {
                    Text(AppLanguage.localized("settings.privacy.body"))
                        .font(.body)
                        .accessibilityAddTraits(.isStaticText)
                } header: {
                    Text(AppLanguage.localized("settings.privacy.title"))
                        .font(.title3)
                }

                Section {
                    LabeledContent(AppLanguage.localized("settings.version"),
                                   value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—")
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

}

#Preview {
    SettingsView()
}
