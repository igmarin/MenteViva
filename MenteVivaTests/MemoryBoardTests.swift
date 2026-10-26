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
}
