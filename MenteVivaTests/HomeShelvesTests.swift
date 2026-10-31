import XCTest

@testable import MenteViva

/// Home's "All games" shelves (#421): one shelf per area, in the order Memory, Attention, Numbers,
/// Words, so fourteen cards read as four short groups instead of one flat grid.
final class HomeShelvesTests: XCTestCase {

    func testGivenReleasedGamesWhenGroupedThenEveryGameAppearsOnceInFocusOrder() {
        let shelves = HomeShelves.group(GameID.released)

        XCTAssertEqual(shelves.map(\.focus), [.memory, .attention, .numbers, .words])
        let shown = shelves.flatMap(\.games)
        XCTAssertEqual(shown.count, GameID.released.count)
        XCTAssertEqual(Set(shown), Set(GameID.released))
        for shelf in shelves {
            XCTAssertTrue(shelf.games.allSatisfy { DailyPolicy.focus[$0] == shelf.focus })
        }
    }

    func testGivenAllGamesOfAnAreaHiddenWhenGroupedThenAreaOmitted() {
        let withoutNumbers = GameID.released.filter { DailyPolicy.focus[$0] != .numbers }

        let shelves = HomeShelves.group(withoutNumbers)

        XCTAssertEqual(shelves.map(\.focus), [.memory, .attention, .words])
        XCTAssertEqual(shelves.flatMap(\.games).count, withoutNumbers.count)
    }

    func testGivenGamesInAnyOrderWhenGroupedThenEachShelfKeepsTheGivenOrder() {
        let shelves = HomeShelves.group([.tilePairs, .quickEyes, .stroop])

        XCTAssertEqual(shelves.map(\.focus), [.attention])
        XCTAssertEqual(shelves[0].games, [.tilePairs, .quickEyes, .stroop])
    }

    func testGivenNoGamesWhenGroupedThenNoShelves() {
        XCTAssertTrue(HomeShelves.group([]).isEmpty)
    }
}
