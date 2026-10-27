import XCTest

@testable import MenteViva

/// #244: Memory Lane's deal — the theme, the pairs the board shows and the
/// order the cards lie in — with the generator passed in, so a seeded run
/// reproduces and a thousand seeds can be checked for a playable board.
final class MemoryDealTests: XCTestCase {
    /// Deterministic generator so the property runs never flake.
    private struct SeededGenerator: RandomNumberGenerator {
        var state: UInt64
        mutating func next() -> UInt64 {
            state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
            return state
        }
    }

    private let photos = [URL(fileURLWithPath: "/a.jpg"), URL(fileURLWithPath: "/b.jpg")]

    private func deal(photos: [URL] = [], pairs: Int = 6, seed: UInt64 = 1) -> MemoryDeal {
        var generator = SeededGenerator(state: seed)
        return MemoryDeal.make(photos: photos, pairs: pairs, using: &generator)
    }

    /// The picture of a picture face, or nil for a photo: what the theme check needs.
    private func picture(of face: MemoryFace) -> GamePicture? {
        guard case .picture(let picture) = face else { return nil }
        return picture
    }

    func testGivenTheSameSeedWhenDealtTwiceThenTheSameBoard() {
        XCTAssertEqual(deal(seed: 7), deal(seed: 7))
    }

    func testGivenDifferentSeedsWhenDealtThenTheBoardsDiffer() {
        XCTAssertNotEqual(deal(seed: 1), deal(seed: 2))
    }

    func testGivenOneThousandSeedsWhenDealtThenEveryBoardIsValid() {
        for seed in 1...1000 {
            let dealt = deal(pairs: 6, seed: UInt64(seed))
            XCTAssertEqual(dealt.faces.count, 6, "seed \(seed)")
            XCTAssertEqual(dealt.order.count, 12, "seed \(seed)")
            // Every face lies on exactly two cards: none missing, none repeated.
            XCTAssertEqual(dealt.order.sorted(), (0..<6).flatMap { [$0, $0] }, "seed \(seed)")
            XCTAssertEqual(Set(dealt.faces).count, 6, "seed \(seed)")
        }
    }

    func testGivenOneThousandSeedsWhenDealtThenEveryBoardComesFromOneTheme() {
        for seed in 1...1000 {
            let drawn = deal(seed: UInt64(seed)).faces.compactMap { picture(of: $0) }
            let themes = MemoryDeal.themes.filter { Set(drawn).isSubset(of: Set($0)) }
            XCTAssertEqual(themes.count, 1, "seed \(seed)")
        }
    }

    func testGivenPhotosWhenDealtThenTheyFillTheBoardFirst() {
        let dealt = deal(photos: photos, pairs: 4, seed: 3)
        XCTAssertEqual(Array(dealt.faces.prefix(2)), photos.map(MemoryFace.photo))
        XCTAssertEqual(dealt.faces.count, 4)
        XCTAssertTrue(dealt.faces.dropFirst(2).allSatisfy { picture(of: $0) != nil })
    }

    func testGivenMorePhotosThanPairsWhenDealtThenOnlyPhotosAreUsed() {
        let many = (0..<6).map { URL(fileURLWithPath: "/\($0).jpg") }
        let dealt = deal(photos: many, pairs: 4, seed: 5)
        XCTAssertEqual(Set(dealt.faces).count, 4)
        XCTAssertTrue(dealt.faces.allSatisfy { picture(of: $0) == nil })
    }
}
