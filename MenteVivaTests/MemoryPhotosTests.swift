import UIKit
import XCTest

@testable import MenteViva

/// #110: his own photos as Memory Lane cards — stored small, on the device only.
final class MemoryPhotosTests: XCTestCase {
    private var folder: URL!

    override func setUpWithError() throws {
        folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: folder)
    }

    private func photoData(width: CGFloat, height: CGFloat) -> Data {
        UIGraphicsImageRenderer(size: CGSize(width: width, height: height)).image { ctx in
            UIColor.orange.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))
        }.pngData()!
    }

    func testGivenNoPhotosWhenListingThenEmpty() {
        XCTAssertEqual(MemoryPhotos.all(in: folder), [])
    }

    func testGivenLargePhotoWhenAddedThenItIsStoredSmall() throws {
        try MemoryPhotos.add(photoData(width: 2000, height: 1000), to: folder)
        let stored = MemoryPhotos.all(in: folder)
        XCTAssertEqual(stored.count, 1)
        let image = try XCTUnwrap(UIImage(contentsOfFile: stored[0].path))
        XCTAssertLessThanOrEqual(max(image.size.width, image.size.height) * image.scale, 600.5)
    }

    func testGivenNotAnImageWhenAddedThenNothingIsStored() {
        XCTAssertThrowsError(try MemoryPhotos.add(Data("hello".utf8), to: folder))
        XCTAssertEqual(MemoryPhotos.all(in: folder), [])
    }

    func testGivenStoredPhotoWhenRemovedThenItIsGone() throws {
        try MemoryPhotos.add(photoData(width: 100, height: 100), to: folder)
        MemoryPhotos.remove(MemoryPhotos.all(in: folder)[0])
        XCTAssertEqual(MemoryPhotos.all(in: folder), [])
    }

    func testGivenFullAlbumWhenAddingThenTheExtraPhotoIsRefused() throws {
        for _ in 0..<MemoryPhotos.maxCount { try MemoryPhotos.add(photoData(width: 10, height: 10), to: folder) }
        XCTAssertThrowsError(try MemoryPhotos.add(photoData(width: 10, height: 10), to: folder))
        XCTAssertEqual(MemoryPhotos.all(in: folder).count, MemoryPhotos.maxCount)
    }

    // MARK: Adding several at once (#120)

    func testGivenGoodAndUnreadablePhotosWhenAddingThenEachIsCounted() {
        let result = MemoryPhotos.add(
            [
                photoData(width: 10, height: 10), Data("hello".utf8), nil,
                photoData(width: 20, height: 20),
            ], to: folder)
        XCTAssertEqual(result, MemoryPhotos.AddResult(added: 2, unreadable: 2, overLimit: 0))
        XCTAssertEqual(MemoryPhotos.all(in: folder).count, 2)
    }

    func testGivenAlmostFullAlbumWhenAddingSeveralThenTheExtraOnesAreCountedAsOverLimit() throws {
        for _ in 0..<(MemoryPhotos.maxCount - 1) { try MemoryPhotos.add(photoData(width: 10, height: 10), to: folder) }
        let result = MemoryPhotos.add(Array(repeating: photoData(width: 10, height: 10), count: 3), to: folder)
        XCTAssertEqual(result, MemoryPhotos.AddResult(added: 1, unreadable: 0, overLimit: 2))
    }

    func testGivenNothingHappenedWhenSummarizingThenThereIsNoNote() {
        XCTAssertNil(MemoryPhotos.AddResult().note)
        XCTAssertNotNil(MemoryPhotos.AddResult(added: 0, unreadable: 1, overLimit: 0).note)
    }

    // MARK: Captions (#139)

    private func addOnePhoto() throws -> URL {
        try MemoryPhotos.add(photoData(width: 100, height: 100), to: folder)
        return try XCTUnwrap(MemoryPhotos.all(in: folder).first)
    }

    func testGivenCaptionWhenSetThenItReadsBack() throws {
        let photo = try addOnePhoto()
        try MemoryPhotos.setCaption("Mamá, Ñandú 🙂", for: photo)
        XCTAssertEqual(MemoryPhotos.caption(for: photo), "Mamá, Ñandú 🙂")
    }

    func testGivenPhotoGoneWhenCaptionSetThenItThrowsSoTheSheetCanSaySo() {
        let gone = folder.appendingPathComponent("missing-folder/\(UUID().uuidString).jpg")
        XCTAssertThrowsError(try MemoryPhotos.setCaption("Ana", for: gone))
    }

    func testGivenCaptionThatCannotBeRemovedWhenClearedThenItThrows() throws {
        let photo = try addOnePhoto()
        try MemoryPhotos.setCaption("Ana", for: photo)
        // A read-only folder: the old caption file can't be deleted.
        try FileManager.default.setAttributes([.posixPermissions: 0o500], ofItemAtPath: folder.path)
        defer { try? FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: folder.path) }
        XCTAssertThrowsError(try MemoryPhotos.setCaption("", for: photo))
    }

    func testGivenNoCaptionFileWhenClearedThenItIsANoOp() throws {
        let photo = try addOnePhoto()
        XCTAssertNoThrow(try MemoryPhotos.setCaption("  ", for: photo))
    }

    func testGivenWhitespaceOnlyWhenSetThenThereIsNoCaption() throws {
        let photo = try addOnePhoto()
        try MemoryPhotos.setCaption("  \n ", for: photo)
        XCTAssertNil(MemoryPhotos.caption(for: photo))
    }

    func testGivenCaptionOverSixtyWhenSetThenItIsTruncatedToSixty() throws {
        let photo = try addOnePhoto()
        try MemoryPhotos.setCaption(String(repeating: "a", count: 90), for: photo)
        XCTAssertEqual(MemoryPhotos.caption(for: photo)?.count, MemoryPhotos.maxCaptionLength)
        XCTAssertEqual(MemoryPhotos.maxCaptionLength, 60)
    }

    func testGivenEmptyTextWhenSetThenTheExistingCaptionIsRemoved() throws {
        let photo = try addOnePhoto()
        try MemoryPhotos.setCaption("Ana", for: photo)
        try MemoryPhotos.setCaption("", for: photo)
        XCTAssertNil(MemoryPhotos.caption(for: photo))
    }

    func testGivenCaptionWhenPhotoRemovedThenNoTextFileRemains() throws {
        let photo = try addOnePhoto()
        try MemoryPhotos.setCaption("Ana", for: photo)
        MemoryPhotos.remove(photo)
        let left = try FileManager.default.contentsOfDirectory(atPath: folder.path)
        XCTAssertEqual(left, [])
    }

    func testGivenCaptionWhenListingPhotosThenTheCaptionFileIsNotListed() throws {
        let photo = try addOnePhoto()
        try MemoryPhotos.setCaption("Ana", for: photo)
        XCTAssertEqual(MemoryPhotos.all(in: folder).count, 1)
    }

    // MARK: Board faces

    private let theme = ["☕️", "🫖", "🍞", "🧀", "🍷", "🥐", "🍋", "🫒"]

    func testGivenNoPhotosWhenDealingThenThemeEmojiFillTheBoard() {
        let faces = MemoryMatchView.faces(photos: [], theme: theme, pairs: 4)
        XCTAssertEqual(faces, theme.prefix(4).map(MemoryMatchView.Face.emoji))
    }

    func testGivenSomePhotosWhenDealingThenPhotosComeFirstAndEmojiFillTheRest() {
        let photos = [URL(fileURLWithPath: "/a.jpg"), URL(fileURLWithPath: "/b.jpg")]
        let faces = MemoryMatchView.faces(photos: photos, theme: theme, pairs: 4)
        XCTAssertEqual(faces, [.photo(photos[0]), .photo(photos[1]), .emoji("☕️"), .emoji("🫖")])
    }

    func testGivenMorePhotosThanPairsWhenDealingThenOnlyPhotosAreUsed() {
        let photos = (0..<6).map { URL(fileURLWithPath: "/\($0).jpg") }
        let faces = MemoryMatchView.faces(photos: photos, theme: theme, pairs: 4)
        XCTAssertEqual(faces, photos.prefix(4).map(MemoryMatchView.Face.photo))
    }
}
