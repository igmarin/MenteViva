import XCTest

@testable import MenteViva

/// #142: Names and Faces' deal: which captioned photos make the board and how its cards lie.
final class PhotoCaptionDealTests: XCTestCase {
    private struct SeededGenerator: RandomNumberGenerator {
        var state: UInt64
        mutating func next() -> UInt64 {
            state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
            return state
        }
    }

    private func photos(_ captions: [String]) -> [(photo: URL, caption: String)] {
        captions.enumerated().map { (URL(fileURLWithPath: "/photos/\($0.offset).jpg"), $0.element) }
    }

    private func board(_ captions: [String], pairs: Int, seed: UInt64 = 1) -> PhotoCaptionDeal.Board {
        var generator = SeededGenerator(state: seed)
        return PhotoCaptionDeal.make(captioned: photos(captions), pairs: pairs, using: &generator)
    }

    private let names = ["Maria", "Papa", "Luis", "Abuela", "Rosa", "Tomas", "Elena", "Pablo", "Ines"]

    func testGivenTenLevelsWhenAskedThenFourToEightPairsNeverShrinking() {
        let pairs = (1...10).map { PhotoCaptionDeal.pairCount(for: Difficulty(level: $0)) }
        XCTAssertEqual(pairs.first, 4)
        XCTAssertEqual(pairs.last, 8)
        XCTAssertEqual(pairs, pairs.sorted())
        XCTAssertLessThanOrEqual(pairs.last ?? 0, MemoryPhotos.maxCount)
    }

    func testGivenDuplicateCaptionsWhenEligibleThenOnlyTheFirstOfEachStays() {
        let list = photos(["Maria", "maria ", "Papa", "MARIA"])
        XCTAssertEqual(PhotoCaptionDeal.eligible(list).map(\.caption), ["Maria", "Papa"])
    }

    func testGivenSixCaptionedPhotosWhenDealtFourPairsThenEightCardsOnePhotoAndCaptionPerPair() {
        let dealt = board(Array(names.prefix(6)), pairs: 4)
        XCTAssertEqual(dealt.cards.count, 8)
        XCTAssertEqual(dealt.pairIDs.count, 8)
        for id in Set(dealt.pairIDs) {
            let faces = zip(dealt.cards, dealt.pairIDs).filter { $0.1 == id }.map(\.0)
            XCTAssertEqual(faces.count, 2, "pair \(id)")
            let photos = faces.filter { if case .photo = $0 { true } else { false } }
            let captions = faces.filter { if case .caption = $0 { true } else { false } }
            XCTAssertEqual(photos.count, 1, "pair \(id)")
            XCTAssertEqual(captions.count, 1, "pair \(id)")
        }
    }

    func testGivenEachPairWhenDealtThenTheCaptionIsTheCaptionOfThatPhoto() {
        for seed in 1...200 {
            let dealt = board(names, pairs: 8, seed: UInt64(seed))
            for id in Set(dealt.pairIDs) {
                let faces = zip(dealt.cards, dealt.pairIDs).filter { $0.1 == id }.map(\.0)
                guard case .photo(let url) = faces.first(where: { if case .photo = $0 { true } else { false } }),
                    case .caption(let text) = faces.first(where: { if case .caption = $0 { true } else { false } })
                else { return XCTFail("pair \(id) seed \(seed) is missing a face") }
                let index = Int(url.deletingPathExtension().lastPathComponent) ?? -1
                XCTAssertEqual(text, names[index], "seed \(seed)")
            }
        }
    }

    func testGivenFewerPhotosThanPairsWhenDealtThenOnlyThePhotosAreUsed() {
        XCTAssertEqual(board(Array(names.prefix(5)), pairs: 8).cards.count, 10)
    }

    func testGivenTheSameSeedWhenDealtTwiceThenTheSameBoard() {
        XCTAssertEqual(board(names, pairs: 6, seed: 9), board(names, pairs: 6, seed: 9))
        XCTAssertNotEqual(board(names, pairs: 6, seed: 9), board(names, pairs: 6, seed: 10))
    }

    func testGivenTooFewCaptionedPhotosWhenCheckedThenTheGameIsUnavailable() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: folder) }
        XCTAssertEqual(GameAvailability.unavailable(in: folder), [.photoCaptions])
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        for (index, name) in names.prefix(4).enumerated() {
            let photo = folder.appendingPathComponent("\(index).jpg")
            try Data([0xFF]).write(to: photo)
            try MemoryPhotos.setCaption(index == 3 ? "" : name, for: photo)
        }
        XCTAssertEqual(GameAvailability.unavailable(in: folder), [.photoCaptions], "three captions are not enough")
        try MemoryPhotos.setCaption("Abuela", for: folder.appendingPathComponent("3.jpg"))
        XCTAssertEqual(GameAvailability.unavailable(in: folder), [])
    }
}
