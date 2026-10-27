import XCTest

@testable import MenteViva

/// #212: every string the first-run questions and My plan show exists in English and Spanish,
/// so neither screen can ever fall back to a raw key. The keys are read out of the screens'
/// own sources and out of the flow itself, so a string that forgets its translation fails here.
final class OnboardingStringsTests: XCTestCase {
    /// The screens that ask the four questions, plus Settings, which opens My plan.
    private static let screens = [
        "MenteViva/OnboardingView.swift",
        "MenteViva/MyPlanView.swift",
        "MenteViva/SettingsView.swift",
        "MenteViva/Services/OnboardingSteps.swift",
    ]

    private func root() -> URL {
        URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
    }

    private func catalog() throws -> [String: Any] {
        let data = try Data(contentsOf: root().appendingPathComponent("MenteViva/Localizable.xcstrings"))
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        return try XCTUnwrap(json["strings"] as? [String: Any])
    }

    private func value(_ entry: Any?, _ language: String) -> String? {
        let localizations = (entry as? [String: Any])?["localizations"] as? [String: Any]
        let unit = (localizations?[language] as? [String: Any])?["stringUnit"] as? [String: Any]
        return unit?["value"] as? String
    }

    /// Every `onboarding.*` / `myplan.*` key written in the screens. Keys built at runtime are
    /// deliberately left out here: `keysOfTheFlow` covers those from the flow itself.
    private func keysInTheScreens() throws -> [String] {
        var keys: Set<String> = []
        let regex = try NSRegularExpression(pattern: #""((?:onboarding|myplan)\.[A-Za-z0-9 .%]*)""#)
        for screen in Self.screens {
            let source = try String(contentsOf: root().appendingPathComponent(screen), encoding: .utf8)
            let range = NSRange(source.startIndex..., in: source)
            for match in regex.matches(in: source, range: range) {
                guard let found = Range(match.range(at: 1), in: source) else { continue }
                keys.insert(String(source[found]))
            }
        }
        return keys.sorted()
    }

    /// Every word the four questions can offer, taken from the flow: the titles and all the
    /// answers, including the minutes keys that are built from their number.
    private func keysOfTheFlow() -> [String] {
        var keys: Set<String> = []
        for question in OnboardingSteps.questions {
            keys.insert(question.titleKey)
            for profile in [PlayerProfile(), PlayerProfile(forWhom: .familyMember)] {
                for answer in OnboardingSteps.answers(for: question, profile: profile) {
                    keys.insert(answer.labelKey)
                }
            }
        }
        return keys.sorted()
    }

    func testGivenEveryOnboardingAndMyPlanKeyWhenReadThenEnAndEsAreBothPresentAndNotEmpty() throws {
        let strings = try catalog()
        let keys = Set(try keysInTheScreens()).union(keysOfTheFlow()).sorted()
        XCTAssertGreaterThan(keys.count, 20, "the questions alone are more than twenty strings")
        for key in keys {
            for language in ["en", "es"] {
                let text = value(strings[key], language)?.trimmingCharacters(in: .whitespaces) ?? ""
                XCTAssertFalse(text.isEmpty, "\(key) [\(language)]")
            }
        }
    }

    /// The words the issue fixes, word for word (#212), so that changing them later is a
    /// deliberate edit rather than a slip.
    func testGivenTheQuestionWordsWhenReadThenTheyAreTheOnesTheIssueAsksFor() throws {
        let strings = try catalog()
        XCTAssertEqual(value(strings["onboarding.who.title"], "en"), "Who will play?")
        XCTAssertEqual(value(strings["onboarding.who.title"], "es"), "¿Quién va a jugar?")
        XCTAssertEqual(value(strings["onboarding.focus.title"], "en"), "What would you like to exercise? Pick any.")
        XCTAssertEqual(value(strings["onboarding.focus.title"], "es"), "¿Qué te gustaría ejercitar? Elige las que quieras.")
        XCTAssertEqual(value(strings["onboarding.minutes.title"], "en"), "How long a day?")
        XCTAssertEqual(value(strings["onboarding.pace.title"], "es"), "¿Cómo quieres empezar?")
        XCTAssertEqual(value(strings["myplan.title"], "en"), "My plan")
    }
}
