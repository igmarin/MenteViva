import SwiftUI

/// The app's language, or "follow the device". Stored as a raw value in
/// UserDefaults so it can be read before the first view renders.
enum AppLanguage: String, CaseIterable, Identifiable {
    case system, english = "en", spanish = "es"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .system: AppLanguage.localized("settings.language.system")
        case .english: "English"
        case .spanish: "Español"
        }
    }

    static var currentLocale: Locale {
        let defaults = UserDefaults.standard
        if let storedLanguage = defaults.array(forKey: "AppleLanguages")?.first as? String {
            return locale(for: storedLanguage)
        }
        return locale(for: defaults.string(forKey: "appLanguage") ?? system.rawValue)
    }

    static func locale(for rawValue: String) -> Locale {
        guard let language = AppLanguage(rawValue: rawValue), language != .system else {
            return .current
        }
        return Locale(identifier: language.rawValue)
    }

    static func localized(_ key: String) -> String {
        String(localized: String.LocalizationValue(key), locale: currentLocale)
    }

    static func localized(_ resource: String.LocalizationValue) -> String {
        String(localized: resource, locale: currentLocale)
    }

    /// Applies the choice by writing AppleLanguages, which is what
    /// `AppLanguage.localized()` resolves against. The root view observes the
    /// stored choice, so the visible language changes without relaunching.
    static func apply(_ rawValue: String) {
        let defaults = UserDefaults.standard
        guard let language = AppLanguage(rawValue: rawValue), language != .system else {
            defaults.removeObject(forKey: "AppleLanguages")
            return
        }
        defaults.set([language.rawValue], forKey: "AppleLanguages")
    }
}

/// Settings a stranger can reach alone: language, sound & haptics, bigger text,
/// the family screen (#107), privacy, version.
struct SettingsView: View {
    @AppStorage("appLanguage") private var appLanguage = AppLanguage.system.rawValue
    @AppStorage("biggerText") private var biggerText = false
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
                        .frame(minWidth: 100, minHeight: 100)
                        .contentShape(Rectangle())
                }
            }
        }
        .id(appLanguage)
    }

}

#Preview {
    SettingsView()
}
