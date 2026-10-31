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
    private static func bundle(for language: AppLanguage) -> Bundle {
        guard language != .system,
            let path = Bundle.main.path(forResource: language.rawValue, ofType: "lproj"),
            let bundle = Bundle(path: path)
        else { return .main }
        return bundle
    }

    private static let lock = NSLock()
    nonisolated(unsafe) private static var resolved: (language: AppLanguage, bundle: Bundle, locale: Locale)?

    /// The bundle and locale for the stored choice, kept between lookups: a Sliding Blocks
    /// drag redraws ~40 strings a frame and finding the bundle again was most of each
    /// lookup (#417, docs/profiling.md). Rebuilt when the stored choice differs, so the
    /// live switch (#134) still lands on the next lookup.
    private static func lookup(in defaults: UserDefaults) -> (bundle: Bundle, locale: Locale) {
        let language = selected(in: defaults)
        lock.lock()
        defer { lock.unlock() }
        if let resolved, resolved.language == language { return (resolved.bundle, resolved.locale) }
        // "Follow the device" keeps following it: a kept `.current` would miss a change in Settings.
        let locale = language == .system ? Locale.autoupdatingCurrent : locale(for: language.rawValue)
        let fresh = (language: language, bundle: bundle(for: language), locale: locale)
        resolved = fresh
        return (fresh.bundle, fresh.locale)
    }

    static func localized(_ key: String, defaults: UserDefaults = .standard) -> String {
        localized(String.LocalizationValue(key), defaults: defaults)
    }

    static func localized(_ resource: String.LocalizationValue, defaults: UserDefaults = .standard) -> String {
        let (bundle, locale) = lookup(in: defaults)
        return String(localized: resource, bundle: bundle, locale: locale)
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
