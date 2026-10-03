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

    static var currentLocale: Locale {
        let defaults = UserDefaults.standard
        if let storedLanguage = defaults.array(forKey: "AppleLanguages")?.first as? String {
            return locale(for: storedLanguage)
        }
        return locale(for: defaults.string(forKey: storageKey) ?? system.rawValue)
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
