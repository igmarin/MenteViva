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
}
