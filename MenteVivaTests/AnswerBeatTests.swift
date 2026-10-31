import XCTest

@testable import MenteViva

/// #235: after every answer the tiles show it for a beat, a miss included, before the next round.
final class AnswerBeatTests: XCTestCase {
    func testGivenRightTapWhenBeatThenTappedTileShowsCheck() {
        let beat = AnswerBeat(tapped: 7, right: 7)
        XCTAssertTrue(beat.isRight)
        XCTAssertEqual(beat.mark(for: 7), .check)
        XCTAssertEqual(beat.mark(for: 5), .plain)
    }

    func testGivenWrongTapWhenBeatThenTappedTileMissedAndRightTileChecked() {
        let beat = AnswerBeat(tapped: "red", right: "blue")
        XCTAssertFalse(beat.isRight)
        XCTAssertEqual(beat.mark(for: "red"), .missed)
        XCTAssertEqual(beat.mark(for: "blue"), .check)
        XCTAssertEqual(beat.mark(for: "green"), .plain)
    }

    func testGivenVoiceOverWhenBeatThenLonger() {
        let beat = AnswerBeat(tapped: 1, right: 2)
        XCTAssertEqual(beat.duration(voiceOver: false), 0.7)
        XCTAssertEqual(beat.duration(voiceOver: true), 1.2)
    }

    @MainActor
    func testGivenCancelledBeatWhenWaitingThenNextRoundDoesNotRun() async {
        var advanced = false
        let beat = AnswerBeat(tapped: 1, right: 1)
        let task = beat.after { advanced = true }
        task.cancel()
        await task.value
        XCTAssertFalse(advanced)
    }

    @MainActor
    func testGivenBeatWhenWaitCompletesThenNextRoundRuns() async {
        var advanced = false
        let beat = AnswerBeat(tapped: 1, right: 1)
        await beat.after { advanced = true }.value
        XCTAssertTrue(advanced)
    }

    func testGivenAnAnswerWhenAnnouncedThenBothLinesAreWarmInEnglishAndSpanish() throws {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        let data = try Data(contentsOf: root.appendingPathComponent("MenteViva/Localizable.xcstrings"))
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let strings = try XCTUnwrap(json["strings"] as? [String: Any])
        let entry = try XCTUnwrap(strings["game.answer.was %@"] as? [String: Any])
        let localizations = try XCTUnwrap(entry["localizations"] as? [String: [String: [String: String]]])
        XCTAssertEqual(localizations["en"]?["stringUnit"]?["value"], "The answer was %@")
        XCTAssertEqual(localizations["es"]?["stringUnit"]?["value"], "La respuesta era %@")
        let right = try XCTUnwrap(strings["game.answer.right"] as? [String: Any])
        let rightLines = try XCTUnwrap(right["localizations"] as? [String: [String: [String: String]]])
        XCTAssertEqual(rightLines["en"]?["stringUnit"]?["value"], "That's it!")
        XCTAssertEqual(rightLines["es"]?["stringUnit"]?["value"], "¡Eso es!")
    }
}
