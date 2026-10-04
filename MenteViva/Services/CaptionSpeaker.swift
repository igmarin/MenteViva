import AVFoundation

/// Speaks a photo's name aloud (#139). Off by default: the name is spoken on
/// its own only if the player turned on "Read names aloud"; the speaker button
/// always works, because tapping it is asking to hear the name.
@MainActor
enum CaptionSpeaker {
    /// UserDefaults key of the "Read names aloud" toggle.
    nonisolated static let speakNamesKey = "speakNames"

    nonisolated static func autoSpeaks(defaults: UserDefaults = .standard) -> Bool {
        defaults.bool(forKey: speakNamesKey)
    }

    /// The speech voice's language for the app's chosen language.
    nonisolated static func voiceLanguage(for language: AppLanguage) -> String {
        switch language {
        case .spanish: "es-MX"
        case .english: "en-US"
        case .system: Locale.current.identifier
        }
    }

    private static let synthesizer = AVSpeechSynthesizer()

    static func speak(_ text: String) {
        synthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: voiceLanguage(for: AppLanguage.selected()))
        synthesizer.speak(utterance)
    }
}
