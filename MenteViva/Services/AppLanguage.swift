import Foundation

/// The app's language, or "follow the device". Stored as a raw value in
/// UserDefaults so it can be read before the first view renders.
enum AppLanguage: String, CaseIterable, Identifiable {
    case system
    case english = "en"
    case spanish = "es"

    /// UserDefaults key of the stored choice (raw value).
    static let storageKey = "appLanguage"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .system: AppLanguage.localized("settings.language.system")
        case .english: "English"
        case .spanish: "Español"
        }
    }

    /// The choice in effect: the stored language, else "follow the device".
    static func selected(in defaults: UserDefaults = .standard) -> AppLanguage {
        AppLanguage(rawValue: defaults.string(forKey: storageKey) ?? "") ?? .system
    }

    static var currentLocale: Locale { locale(for: selected().rawValue) }

    static func locale(for rawValue: String) -> Locale {
        guard let language = AppLanguage(rawValue: rawValue), language != .system else {
            return .current
        }
        return Locale(identifier: language.rawValue)
    }

    /// Strings come from the chosen language's own bundle: `locale:` alone only
    /// formats, and the main bundle's language is fixed at launch (#134).
    private static func bundle(in defaults: UserDefaults) -> Bundle {
        let language = selected(in: defaults)
        guard language != .system,
            let path = Bundle.main.path(forResource: language.rawValue, ofType: "lproj"),
            let bundle = Bundle(path: path)
        else { return .main }
        return bundle
    }

    static func localized(_ key: String, defaults: UserDefaults = .standard) -> String {
        localized(String.LocalizationValue(key), defaults: defaults)
    }

    static func localized(_ resource: String.LocalizationValue, defaults: UserDefaults = .standard) -> String {
        String(
            localized: resource, bundle: bundle(in: defaults),
            locale: locale(for: selected(in: defaults).rawValue))
    }

    /// Stores the choice; the views observe it through `@AppStorage`, so the
    /// visible language changes without relaunching.
    static func apply(_ rawValue: String, to defaults: UserDefaults = .standard) {
        defaults.set(rawValue, forKey: storageKey)
        // Older builds also wrote this; left behind, it would pin the main
        // bundle to the old choice at the next launch.
        defaults.removeObject(forKey: "AppleLanguages")
    }
}
