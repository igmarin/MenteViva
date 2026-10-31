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

    private static var synthesizer: AVSpeechSynthesizer?
    /// Exposes whether speech has needed the synthesizer, without creating it.
    static var isCreated: Bool { synthesizer != nil }
    private static let sessionEnder = SessionEnder()
    /// The latest name asked for; a name set up after a newer one (or a stop) never plays.
    private static var requested: AVSpeechUtterance?

    /// Gives other audio its volume back (ducking ends when the session deactivates)
    /// once the voice has finished or been cut off. `AudioSession` skips it when a
    /// newer name already owns the session, so replacing one name is never cut short.
    /// `nonisolated`: AVFoundation calls the delegate off the main thread.
    nonisolated private final class SessionEnder: NSObject, AVSpeechSynthesizerDelegate {
        func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
            AudioSession.endSpeech(ObjectIdentifier(utterance))
        }

        func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
            AudioSession.endSpeech(ObjectIdentifier(utterance))
        }
    }

    /// Speech must be heard with the silent switch on: asking to hear a name is
    /// an explicit request, unlike the ambient game tones.
    nonisolated static func configureSession(_ session: AVAudioSession = .sharedInstance()) throws {
        try session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
    }

    /// Cuts the voice off, so a name never carries over onto the next photo.
    static func stop() {
        requested = nil
        synthesizer?.stopSpeaking(at: .immediate)
    }

    /// Speaks only once the session is .playback, so the first name is never
    /// muted by the silent switch.
    static func speak(_ text: String) {
        if synthesizer == nil { synthesizer = AVSpeechSynthesizer() }
        guard let synthesizer else { return }
        synthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: text)
        // A language with no installed voice still speaks, in English, not silently.
        utterance.voice =
            AVSpeechSynthesisVoice(language: voiceLanguage(for: AppLanguage.selected()))
            ?? AVSpeechSynthesisVoice(language: "en-US")
        synthesizer.delegate = sessionEnder
        requested = utterance
        let id = ObjectIdentifier(utterance)
        AudioSession.beginSpeech(id) {
            guard requested === utterance else {
                AudioSession.endSpeech(id)
                return
            }
            synthesizer.speak(utterance)
        }
    }
}
