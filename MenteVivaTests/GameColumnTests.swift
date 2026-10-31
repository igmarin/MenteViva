import XCTest

@testable import MenteViva

/// #400: games keep their controls in a readable column on an iPad and are unchanged on a phone.
final class GameColumnTests: XCTestCase {
    func testGivenARegularWidthWhenTextIsScaledThenBigWordsGrowByThirty() {
        XCTAssertEqual(GameColumn.textScale(isRegularWidth: true), 1.3, accuracy: 0.0001)
    }

    func testGivenACompactWidthWhenTextIsScaledThenBigWordsKeepTheirSize() {
        XCTAssertEqual(GameColumn.textScale(isRegularWidth: false), 1)
    }
}
