import XCTest

@testable import MenteViva

/// #242: the end of a game gets one of five warm headlines, and never the same one twice in a row.
final class CelebrationHeadlineTests: XCTestCase {
    /// Deterministic generator so the property runs never flake.
    private struct SeededGenerator: RandomNumberGenerator {
        var state: UInt64
        mutating func next() -> UInt64 {
            state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
            return state
        }
    }

    private var defaults: UserDefaults!

    override func setUp() {
        defaults = UserDefaults(suiteName: "CelebrationHeadlineTests")!
        defaults.removePersistentDomain(forName: "CelebrationHeadlineTests")
    }

    func testGivenLastHeadlineWhenNextThenDifferent() {
        var generator = SeededGenerator(state: 1)
        for last in 0..<CelebrationHeadline.count {
            for _ in 0..<50 {
                XCTAssertNotEqual(CelebrationHeadline.next(after: last, using: &generator), last)
            }
        }
    }

    func testGivenNoLastHeadlineWhenNextThenIndexIsInRange() {
        var generator = SeededGenerator(state: 2)
        for _ in 0..<50 {
            XCTAssertTrue((0..<CelebrationHeadline.count).contains(CelebrationHeadline.next(after: nil, using: &generator)))
        }
    }

    func testGivenHundredCelebrationsWhenShownThenNoTwoInARowMatchAndAllFiveAppear() {
        var generator = SeededGenerator(state: 7)
        var shown: [Int] = []
        for _ in 0..<100 {
            shown.append(CelebrationHeadline.next(after: shown.last, using: &generator))
        }
        let repeatsInARow = zip(shown, shown.dropFirst()).filter { $0 == $1 }
        XCTAssertTrue(repeatsInARow.isEmpty)
        XCTAssertEqual(Set(shown), Set(0..<CelebrationHeadline.count))
    }

    func testGivenPickedHeadlineWhenPickedAgainThenStoredIndexChanges() {
        var generator = SeededGenerator(state: 3)
        _ = CelebrationHeadline.pick(defaults: defaults, using: &generator)
        let first = defaults.object(forKey: CelebrationHeadline.lastIndexKey) as? Int
        _ = CelebrationHeadline.pick(defaults: defaults, using: &generator)
        let second = defaults.object(forKey: CelebrationHeadline.lastIndexKey) as? Int
        XCTAssertNotNil(first)
        XCTAssertNotEqual(first, second)
    }

    func testGivenTheDayClosedWhenPickedThenTheDayDoneLineShowsAndTheRotationIsUntouched() {
        defaults.set(2, forKey: CelebrationHeadline.lastIndexKey)
        var generator = SeededGenerator(state: 5)
        let line = CelebrationHeadline.pick(closesTheDay: true, defaults: defaults, using: &generator)
        XCTAssertEqual(line, AppLanguage.localized(CelebrationHeadline.dayDoneKey, defaults: defaults))
        XCTAssertNotEqual(line, CelebrationHeadline.dayDoneKey)
        XCTAssertEqual(defaults.object(forKey: CelebrationHeadline.lastIndexKey) as? Int, 2)
    }

    func testGivenIndexWhenKeyThenNumberedFromOne() {
        XCTAssertEqual(CelebrationHeadline.key(for: 0), "game.celebration.headline.1")
        XCTAssertEqual(CelebrationHeadline.key(for: 4), "game.celebration.headline.5")
    }

    func testGivenEveryIndexWhenLocalizedThenCatalogHasTheHeadline() {
        for index in 0..<CelebrationHeadline.count {
            let key = CelebrationHeadline.key(for: index)
            XCTAssertNotEqual(AppLanguage.localized(key, defaults: defaults), key)
        }
    }
}
