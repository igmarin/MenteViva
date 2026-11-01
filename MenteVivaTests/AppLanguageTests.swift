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

    /// #529: "Device" / "Sistema" meant nothing to a non-technical reader and the two words did
    /// not match; both languages now say the same plain thing.
    func testGivenTheFollowThePhoneChoiceWhenLabelledThenBothLanguagesSaySameAsMyPhone() {
        AppLanguage.apply("en", to: defaults)
        XCTAssertEqual(AppLanguage.localized("settings.language.system", defaults: defaults), "Same as my phone")
        AppLanguage.apply("es", to: defaults)
        XCTAssertEqual(AppLanguage.localized("settings.language.system", defaults: defaults), "Igual que el teléfono")
    }

    func testGivenPluralValueWhenSpanishChosenThenPluralFormResolves() {
        AppLanguage.apply("es", to: defaults)
        XCTAssertEqual(
            AppLanguage.localized("progress.plays \(1)" as String.LocalizationValue, defaults: defaults),
            "Jugaste 1 vez esta semana")
    }
}
