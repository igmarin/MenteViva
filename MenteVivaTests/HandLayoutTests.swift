import XCTest

@testable import MenteViva

/// Today's hand on Home (#365): rows of at most three cards, each card narrow enough that a row
/// fits the table on any phone. Pure numbers; the view only forwards what these return.
final class HandLayoutTests: XCTestCase {

    private let games: [GameID] = [.memoryMatch, .stroop, .sudoku, .tangram, .sayings]

    // MARK: Rows

    func testGivenFiveGamesWhenRowsOfThreeThenThreeAndTwo() {
        let rows = HandLayout.rows(games)

        XCTAssertEqual(rows.map(\.count), [3, 2])
        XCTAssertEqual(rows.flatMap { $0 }, games)
    }

    func testGivenThreeGamesWhenRowsOfThreeThenOneRow() {
        XCTAssertEqual(HandLayout.rows(Array(games.prefix(3))).map(\.count), [3])
    }

    func testGivenNoGamesWhenRowsThenNoRows() {
        XCTAssertTrue(HandLayout.rows([]).isEmpty)
    }

    // MARK: Card width

    func testGivenAvailable307AndThreeCardsWhenCardWidthThenAtMost112AndFitsWithOverlap() {
        let width = HandLayout.cardWidth(available: 307, perRow: 3)

        XCTAssertLessThanOrEqual(width, 112)
        XCTAssertLessThanOrEqual(width * 3 - 6 * 2, 307)
        XCTAssertGreaterThanOrEqual(width, 100, "a card stays a comfortable target on the smallest phone")
    }

    func testGivenAvailable800WhenCardWidthThen112() {
        XCTAssertEqual(HandLayout.cardWidth(available: 800, perRow: 3), 112)
    }
}
