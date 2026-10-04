import XCTest

@testable import MenteViva

/// #139: names are spoken aloud only when the player opts in.
final class CaptionSpeakerTests: XCTestCase {
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        // Own suite: .standard is the host app's real preferences.
        defaults = UserDefaults(suiteName: "CaptionSpeakerTests")!
        defaults.removePersistentDomain(forName: "CaptionSpeakerTests")
    }

    func testGivenNothingStoredWhenAutoSpeaksThenFalse() {
        XCTAssertFalse(CaptionSpeaker.autoSpeaks(defaults: defaults))
    }

    func testGivenToggleOnWhenAutoSpeaksThenTrue() {
        defaults.set(true, forKey: CaptionSpeaker.speakNamesKey)
        XCTAssertTrue(CaptionSpeaker.autoSpeaks(defaults: defaults))
    }

    func testGivenLanguageWhenVoiceLanguageThenRegionalCode() {
        XCTAssertEqual(CaptionSpeaker.voiceLanguage(for: .spanish), "es-MX")
        XCTAssertEqual(CaptionSpeaker.voiceLanguage(for: .english), "en-US")
    }
}
