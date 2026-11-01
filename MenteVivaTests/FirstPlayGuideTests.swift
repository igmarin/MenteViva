import XCTest

@testable import MenteViva

/// #243: each game shows its "Let me show you" guide once, until Settings resets it.
final class FirstPlayGuideTests: XCTestCase {
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        // Own suite: .standard is the host app's real preferences.
        defaults = UserDefaults(suiteName: "FirstPlayGuideTests")!
        defaults.removePersistentDomain(forName: "FirstPlayGuideTests")
    }

    func testGivenUnseenGameWhenOpenedThenGuideShown() {
        XCTAssertTrue(FirstPlayGuideStore.shouldShow(.sudoku, defaults: defaults))
    }

    func testGivenSeenGameWhenOpenedThenNoGuide() {
        FirstPlayGuideStore.markSeen(.sudoku, defaults: defaults)
        XCTAssertFalse(FirstPlayGuideStore.shouldShow(.sudoku, defaults: defaults))
    }

    func testGivenSeenGameWhenAnotherOpenedThenItsGuideStillShown() {
        FirstPlayGuideStore.markSeen(.sudoku, defaults: defaults)
        XCTAssertTrue(FirstPlayGuideStore.shouldShow(.upOrDown, defaults: defaults))
    }

    func testGivenResetWhenOpenedThenGuideShownAgain() {
        FirstPlayGuideStore.markSeen(.sudoku, defaults: defaults)
        FirstPlayGuideStore.markSeen(.upOrDown, defaults: defaults)
        for game in [GameID.tangram, .slidingBlocks, .tilePairs] {
            FirstPlayGuideStore.markSeen(game, defaults: defaults)
        }
        FirstPlayGuideStore.resetAll(defaults: defaults)
        XCTAssertTrue(FirstPlayGuideStore.shouldShow(.sudoku, defaults: defaults))
        XCTAssertTrue(FirstPlayGuideStore.shouldShow(.upOrDown, defaults: defaults))
        for game in [GameID.tangram, .slidingBlocks, .tilePairs] {
            XCTAssertTrue(FirstPlayGuideStore.shouldShow(game, defaults: defaults))
        }
    }

    // MARK: Arrow (#531)

    func testGivenATargetHighOnTheScreenWhenTheArrowIsPlacedThenItStandsBesideTheRing() {
        let frame = CGRect(x: 20, y: 100, width: 80, height: 80)
        let arrow = GuideArrow.placement(frame: frame, container: CGSize(width: 400, height: 800))
        XCTAssertEqual(arrow.symbol, "arrow.left")
        XCTAssertGreaterThan(arrow.center.x, frame.maxX)
        XCTAssertEqual(arrow.center.y, frame.midY)
    }

    func testGivenAHighTargetOnTheRightWhenTheArrowIsPlacedThenItStandsOnTheLeftPointingRight() {
        let frame = CGRect(x: 300, y: 100, width: 80, height: 80)
        let arrow = GuideArrow.placement(frame: frame, container: CGSize(width: 400, height: 800))
        XCTAssertEqual(arrow.symbol, "arrow.right")
        XCTAssertLessThan(arrow.center.x, frame.minX)
    }

    func testGivenATargetLowerDownWhenTheArrowIsPlacedThenItPointsDownFromAbove() {
        let frame = CGRect(x: 100, y: 500, width: 80, height: 80)
        let arrow = GuideArrow.placement(frame: frame, container: CGSize(width: 400, height: 800))
        XCTAssertEqual(arrow.symbol, "arrow.down")
        XCTAssertLessThan(arrow.center.y, frame.minY)
    }

    func testGivenATallScreenWhenTheBoardStartsWellDownThenTheArrowStillStaysBesideTheRing() {
        // An iPad portrait Sudoku: the board's top is about 310pt down, the instruction just above it.
        let frame = CGRect(x: 100, y: 310, width: 90, height: 90)
        let arrow = GuideArrow.placement(frame: frame, container: CGSize(width: 834, height: 1194))
        XCTAssertEqual(arrow.symbol, "arrow.left")
        XCTAssertEqual(arrow.center.y, frame.midY)
    }

    func testGivenASideArrowWhenPlacedThenItStartsAtTheRingEdgeAndNotOverTheNextSquare() {
        let frame = CGRect(x: 20, y: 100, width: 80, height: 80)
        let arrow = GuideArrow.placement(frame: frame, container: CGSize(width: 400, height: 800))
        // The ring's stroke reaches 6pt past the frame.
        XCTAssertEqual(arrow.center.x - arrow.size / 2, frame.maxX + 6)
    }
}
