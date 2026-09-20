import SwiftUI

/// The app's language, or "follow the device". Stored as a raw value in
/// UserDefaults so it can be read before the first view renders.
enum AppLanguage: String, CaseIterable, Identifiable {
    case system, english = "en", spanish = "es"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .system: String(localized: "settings.language.system")
        case .english: "English"
        case .spanish: "Español"
        }
    }

    /// Applies the choice by writing AppleLanguages, which is what
    /// `String(localized:)` resolves against. Takes effect on next launch —
    /// the settings screen says so plainly rather than pretending otherwise.
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
/// privacy, version.
struct SettingsView: View {
    @AppStorage("appLanguage") private var appLanguage = AppLanguage.system.rawValue
    @AppStorage("biggerText") private var biggerText = false
    @AppStorage(SoundPlayer.enabledKey) private var soundEnabled = true
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker(String(localized: "settings.language"), selection: $appLanguage) {
                        ForEach(AppLanguage.allCases) { language in
                            Text(language.label).tag(language.rawValue)
                        }
                    }
                    .pickerStyle(.inline)
                    .accessibilityHint(String(localized: "settings.language.restart"))
                } header: {
                    Text(String(localized: "settings.language"))
                        .font(.title3)
                } footer: {
                    Text(String(localized: "settings.language.restart"))
                        .font(.footnote)
                }

                Section {
                    Toggle(String(localized: "settings.sound"), isOn: $soundEnabled)
                        .font(.title3)
                        .frame(minHeight: 60)
                        .accessibilityHint(String(localized: "settings.sound.hint"))
                }

                Section {
                    Toggle(String(localized: "settings.textsize"), isOn: $biggerText)
                        .font(.title3)
                        .frame(minHeight: 60)
                }

                Section {
                    Text(String(localized: "settings.privacy.body"))
                        .font(.body)
                        .accessibilityAddTraits(.isStaticText)
                } header: {
                    Text(String(localized: "settings.privacy.title"))
                        .font(.title3)
                }

                Section {
                    LabeledContent(String(localized: "settings.version"),
                                   value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—")
                        .font(.body)
                }
            }
            .navigationTitle(String(localized: "settings.title"))
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "settings.done")) { dismiss() }
                        .font(.title3)
                }
            }
            .onChange(of: appLanguage) { _, newValue in
                AppLanguage.apply(newValue)
            }
        }
    }
}

#Preview {
    SettingsView()
}
