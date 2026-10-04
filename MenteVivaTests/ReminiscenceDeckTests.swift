import UIKit
import XCTest

@testable import MenteViva

/// #139: which cards a Remember Together session shows.
final class ReminiscenceDeckTests: XCTestCase {
    private func photos(_ count: Int) -> [URL] {
        (0..<count).map { URL(fileURLWithPath: "/\($0).jpg") }
    }

    func testGivenSevenPhotosWhenDealtThenFiveInGivenOrder() {
        let urls = photos(7)
        let cards = ReminiscenceDeck.deal(photos: urls, captions: [:])
        XCTAssertEqual(cards.map(\.picture), urls.prefix(5).map(ReminiscenceCard.Picture.photo))
        XCTAssertEqual(cards.map(\.id), [0, 1, 2, 3, 4])
    }

    func testGivenThreePhotosWhenDealtThenOnlyThoseThree() {
        XCTAssertEqual(ReminiscenceDeck.deal(photos: photos(3), captions: [:]).count, 3)
    }

    func testGivenOnePhotoWhenDealtThenOneCardAndNoObjects() {
        let cards = ReminiscenceDeck.deal(photos: photos(1), captions: [:])
        XCTAssertEqual(cards.count, 1)
        XCTAssertEqual(cards[0].picture, .photo(URL(fileURLWithPath: "/0.jpg")))
    }

    func testGivenNoPhotosWhenDealtThenFiveObjectCardsNamedByLocalizedKey() {
        let cards = ReminiscenceDeck.deal(photos: [], captions: [:], localize: { "L:" + $0 })
        XCTAssertEqual(cards.count, 5)
        XCTAssertEqual(cards[0].picture, .symbol(EverydayObjects.all[0].symbol))
        XCTAssertEqual(cards[0].caption, "L:" + EverydayObjects.all[0].nameKey)
        XCTAssertEqual(EverydayObjects.all[0].nameKey, "object.cup")
    }

    func testGivenPhotoWithoutCaptionWhenDealtThenCaptionIsNil() {
        let urls = photos(2)
        let cards = ReminiscenceDeck.deal(photos: urls, captions: [urls[0]: "Ana"])
        XCTAssertEqual(cards[0].caption, "Ana")
        XCTAssertNil(cards[1].caption)
    }

    func testGivenEveryObjectSymbolThenItResolvesToAnImage() {
        for object in EverydayObjects.all {
            XCTAssertNotNil(UIImage(systemName: object.symbol), object.symbol)
        }
        XCTAssertEqual(EverydayObjects.all.count, 8)
    }
}
