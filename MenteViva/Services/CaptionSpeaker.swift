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
        // BCP-47 ("en-US"); `identifier` gives "en_US", which names no voice.
        case .system: Locale.current.identifier(.bcp47)
        }
    }

    private static let synthesizer = AVSpeechSynthesizer()
    private static let sessionEnder = SessionEnder()

    /// True while a name is being read, so other audio code leaves the session alone.
    static var isSpeaking: Bool { synthesizer.isSpeaking }

    /// Gives other audio its volume back (ducking ends when the session deactivates)
    /// once the voice has finished or been cut off. Skipped when a newer utterance
    /// is already speaking, so replacing one name with another is never cut short.
    /// `nonisolated`: AVFoundation calls the delegate off the main thread.
    nonisolated private final class SessionEnder: NSObject, AVSpeechSynthesizerDelegate {
        func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
            end(synthesizer)
        }

        func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
            end(synthesizer)
        }

        private func end(_ synthesizer: AVSpeechSynthesizer) {
            guard !synthesizer.isSpeaking else { return }
            try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        }
    }

    /// Speech must be heard with the silent switch on: asking to hear a name is
    /// an explicit request, unlike the ambient game tones.
    static func configureSession(_ session: AVAudioSession = .sharedInstance()) throws {
        try session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
    }

    /// Cuts the voice off, so a name never carries over onto the next photo.
    static func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }

    static func speak(_ text: String) {
        synthesizer.stopSpeaking(at: .immediate)
        try? configureSession()
        try? AVAudioSession.sharedInstance().setActive(true)
        let utterance = AVSpeechUtterance(string: text)
        // A language with no installed voice still speaks, in English, not silently.
        utterance.voice =
            AVSpeechSynthesisVoice(language: voiceLanguage(for: AppLanguage.selected()))
            ?? AVSpeechSynthesisVoice(language: "en-US")
        synthesizer.delegate = sessionEnder
        synthesizer.speak(utterance)
    }
}
