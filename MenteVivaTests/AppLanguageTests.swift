import XCTest

@testable import MenteViva

/// #134: switching language must change `AppLanguage.localized` at once. The
/// bundle's own preferred language is fixed at launch, so the lookup has to go
/// through the chosen language's bundle.
final class AppLanguageTests: XCTestCase {
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        // Own suite: .standard is the host app's real preferences.
        defaults = UserDefaults(suiteName: "AppLanguageTests")!
        defaults.removePersistentDomain(forName: "AppLanguageTests")
    }

    func testGivenSpanishChosenWhenLocalizedThenSpanishWithoutRelaunch() {
        AppLanguage.apply("es", to: defaults)
        XCTAssertEqual(AppLanguage.localized("settings.language", defaults: defaults), "Idioma")
    }

    func testGivenEnglishChosenAfterSpanishWhenLocalizedThenEnglishAtOnce() {
        AppLanguage.apply("es", to: defaults)
        AppLanguage.apply("en", to: defaults)
        XCTAssertEqual(AppLanguage.localized("settings.language", defaults: defaults), "Language")
    }

    func testGivenAChoiceWhenAppliedThenItIsStoredForTheViews() {
        AppLanguage.apply("es", to: defaults)
        XCTAssertEqual(defaults.string(forKey: AppLanguage.storageKey), "es")
    }

    func testGivenPluralValueWhenSpanishChosenThenPluralFormResolves() {
        AppLanguage.apply("es", to: defaults)
        XCTAssertEqual(
            AppLanguage.localized("family.week.last \(1)" as String.LocalizationValue, defaults: defaults),
            "Semana anterior: 1 juego")
    }
}
