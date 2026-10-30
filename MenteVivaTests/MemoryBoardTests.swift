import XCTest

@testable import MenteViva

/// #237: the pure part of Memory Lane — which cards are face up after each
/// tap. The view animates this state; the 1.2 s turn-back timer lives there.
final class MemoryBoardTests: XCTestCase {
    /// Four cards, two pairs: card 0 matches 2, card 1 matches 3.
    private var board: MemoryBoard!

    override func setUp() {
        board = MemoryBoard(pairs: [0, 1, 0, 1])
    }

    func testGivenMissedPairWhenThirdCardTappedThenPairTurnsBackFirst() {
        XCTAssertEqual(board.tap(0), .turnedUp(0))
        XCTAssertEqual(board.tap(1), .missed(pair: [0, 1]))

        XCTAssertEqual(board.tap(2), .missedBackThenUp(turnedBack: [0, 1], up: 2))

        XCTAssertEqual(board.faceUp, [2])
        XCTAssertTrue(board.pendingMiss.isEmpty)
        XCTAssertTrue(board.matched.isEmpty)
    }

    func testGivenNewDealWhenOldTurnBackFiresThenBoardUnchanged() {
        XCTAssertEqual(board.tap(0), .turnedUp(0))
        XCTAssertEqual(board.tap(1), .missed(pair: [0, 1]))
        let staleGeneration = board.generation

        board.deal(pairs: [0, 1, 0, 1])

        XCTAssertEqual(board.resolveMiss(generation: staleGeneration), [])
        XCTAssertTrue(board.faceUp.isEmpty)
        XCTAssertTrue(board.matched.isEmpty)
        XCTAssertTrue(board.pendingMiss.isEmpty)
    }

    func testGivenMatchingPairWhenSecondTappedThenBothFound() {
        XCTAssertEqual(board.tap(0), .turnedUp(0))

        let result = board.tap(2)

        XCTAssertEqual(result, .matched(pair: [0, 2], found: [0, 2]))
        XCTAssertEqual(board.matched, [0, 2])
        XCTAssertTrue(board.faceUp.isEmpty)
    }

    func testGivenFoundCardWhenTappedThenIgnored() {
        _ = board.tap(0)
        _ = board.tap(2)

        XCTAssertEqual(board.tap(0), .ignored)
        XCTAssertEqual(board.matched, [0, 2])
    }

    func testGivenMissedPairCardWhenTappedThenIgnoredAndMissStaysShowing() {
        _ = board.tap(0)
        _ = board.tap(1)

        XCTAssertEqual(board.tap(0), .ignored)
        XCTAssertEqual(board.pendingMiss, [0, 1])
        XCTAssertTrue(board.faceUp.isEmpty)
    }

    // MARK: - VoiceOver announcements (#393)

    /// The shipped catalog's text for one language, so the tests hear what a player hears.
    private func catalogText(_ language: String) throws -> (String) -> String {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        let data = try Data(contentsOf: root.appendingPathComponent("MenteViva/Localizable.xcstrings"))
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let strings = try XCTUnwrap(json["strings"] as? [String: [String: Any]])
        return { key in
            let localizations = strings[key]?["localizations"] as? [String: [String: [String: String]]]
            return localizations?[language]?["stringUnit"]?["value"] ?? "MISSING \(key)"
        }
    }

    /// Names by card index; every card has a distinct name except the twins of a pair.
    private let names = ["Cat", "Dog", "Cat", "Dog"]

    private func announce(_ tap: MemoryBoard.Tap, language: String = "en") throws -> String? {
        board.announcement(for: tap, label: { names[$0] }, text: try catalogText(language))
    }

    func testGivenNewMissKeyWhenCatalogCheckedThenEnglishAndSpanishPresent() throws {
        let english = try catalogText("en")("game.memory.miss")
        let spanish = try catalogText("es")("game.memory.miss")

        XCTAssertEqual(english, "Almost — %1$@ and %2$@ are different")
        XCTAssertEqual(spanish, "Casi — %1$@ y %2$@ no son pareja")
    }

    func testGivenCardTurnedUpWhenAnnouncedThenItsNameIsSpoken() throws {
        XCTAssertEqual(try announce(board.tap(0)), "Cat")
        XCTAssertEqual(try announce(board.tap(1), language: "es"), "Casi — Cat y Dog no son pareja")
    }

    func testGivenMatchWhenAnnouncedThenNameAndPairFoundAreSpoken() throws {
        _ = board.tap(0)

        XCTAssertEqual(try announce(board.tap(2)), "Cat - Pair found")
        XCTAssertEqual(try announce(.matched(pair: [0, 2], found: [0, 2]), language: "es"), "Cat - Pareja encontrada")
    }

    func testGivenPhotoAndCaptionMatchWhenAnnouncedThenBothNamesAreSpoken() throws {
        let tap = MemoryBoard.Tap.matched(pair: [0, 1], found: [0, 1])
        XCTAssertEqual(try announce(tap), "Cat, Dog - Pair found")
    }

    func testGivenMissWhenAnnouncedThenBothNamesAreSpoken() throws {
        _ = board.tap(0)

        XCTAssertEqual(try announce(board.tap(1)), "Almost — Cat and Dog are different")
    }

    func testGivenMissedPairWhenDifferentCardTappedThenNewCardIsSpokenAndPairStaysUntilThen() throws {
        _ = board.tap(0)
        _ = board.tap(1)
        XCTAssertEqual(board.pendingMiss, [0, 1])

        XCTAssertEqual(try announce(board.tap(2)), "Cat")
        XCTAssertTrue(board.pendingMiss.isEmpty)
    }

    func testGivenLastPairWhenAnnouncedThenAllFoundIsSpokenToo() throws {
        _ = board.tap(0)
        _ = board.tap(2)
        _ = board.tap(1)

        XCTAssertEqual(try announce(board.tap(3)), "Dog - Pair found. You found all 2 pairs!")
        XCTAssertEqual(
            try announce(.matched(pair: [1, 3], found: [0, 1, 2, 3]), language: "es"),
            "Dog - Pareja encontrada. ¡Encontraste las 2 parejas!")
    }

    func testGivenIgnoredTapWhenAnnouncedThenNothingIsSpoken() throws {
        _ = board.tap(0)

        XCTAssertNil(try announce(board.tap(0)))
    }
}
