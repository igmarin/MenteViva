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

    // MARK: A bigger album (#374)

    func testGivenAlbumOfEightWhenAddingTwoThenBothAreStored() throws {
        for _ in 0..<8 { try MemoryPhotos.add(photoData(width: 10, height: 10), to: folder) }
        let result = MemoryPhotos.add(Array(repeating: photoData(width: 10, height: 10), count: 2), to: folder)
        XCTAssertEqual(result, MemoryPhotos.AddResult(added: 2, unreadable: 0, overLimit: 0))
        XCTAssertEqual(MemoryPhotos.all(in: folder).count, 10)
    }

    func testGivenAlbumAtMaxWhenAddingThenAlbumFullIsReported() throws {
        XCTAssertEqual(MemoryPhotos.maxCount, 24)
        let full = MemoryPhotos.add(Array(repeating: photoData(width: 10, height: 10), count: 24), to: folder)
        XCTAssertEqual(full, MemoryPhotos.AddResult(added: 24, unreadable: 0, overLimit: 0))
        let result = MemoryPhotos.add([photoData(width: 10, height: 10)], to: folder)
        XCTAssertEqual(result, MemoryPhotos.AddResult(added: 0, unreadable: 0, overLimit: 1))
        XCTAssertEqual(MemoryPhotos.all(in: folder).count, 24)
        XCTAssertNotNil(result.note)
    }

    func testGivenTwoResultsWhenCombiningThenEachCountAdds() {
        var total = MemoryPhotos.AddResult(added: 1, unreadable: 0, overLimit: 0)
        total += MemoryPhotos.AddResult(added: 2, unreadable: 1, overLimit: 3)
        XCTAssertEqual(total, MemoryPhotos.AddResult(added: 3, unreadable: 1, overLimit: 3))
    }

    /// #417: the originals were all loaded before any was shrunk. Each photo must be on disk, small,
    /// before the next one is asked for, so only one original is in memory at a time.
    func testGivenSeveralPicksWhenImportingThenEachIsStoredBeforeTheNextIsLoaded() async throws {
        let folder = try XCTUnwrap(folder)
        var storedWhenLoading: [Int] = []

        let imported = await FamilyPhotoImport.run(Array(0..<3), folder: folder) { _ in
            storedWhenLoading.append(MemoryPhotos.all(in: folder).count)
            return self.photoData(width: 10, height: 10)
        }

        XCTAssertEqual(storedWhenLoading, [0, 1, 2])
        XCTAssertEqual(imported?.result, MemoryPhotos.AddResult(added: 3, unreadable: 0, overLimit: 0))
        XCTAssertEqual(imported?.added.count, 3)
    }

    /// #496 review: once the import is cancelled (the sheet closed), no other photo is asked for,
    /// so no large transfer starts after the view has gone.
    func testGivenACancelledImportWhenRunningThenNoPhotoIsLoaded() async throws {
        let folder = try XCTUnwrap(folder)

        let (cancelled, loads) = await Task { () -> (Bool, Int) in
            withUnsafeCurrentTask { $0?.cancel() }
            var loads = 0
            let imported = await FamilyPhotoImport.run(Array(0..<2), folder: folder) { _ in
                loads += 1
                return Data()
            }
            return (imported == nil, loads)
        }.value

        XCTAssertTrue(cancelled)
        XCTAssertEqual(loads, 0)
    }

    func testGivenAnUnreadablePickAndAFullAlbumWhenImportingThenTheCountsAddUp() async throws {
        let folder = try XCTUnwrap(folder)
        _ = MemoryPhotos.add(Array(repeating: photoData(width: 10, height: 10), count: 23), to: folder)
        let data: [Data?] = [nil, photoData(width: 10, height: 10), photoData(width: 10, height: 10)]

        let imported = await FamilyPhotoImport.run(data, folder: folder) { $0 }

        XCTAssertEqual(imported?.result, MemoryPhotos.AddResult(added: 1, unreadable: 1, overLimit: 1))
        XCTAssertEqual(MemoryPhotos.all(in: folder).count, 24)
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

    // MARK: Backups (#419)

    /// A fresh URL, so the flag is read from disk and not from this URL's cache.
    private func isExcludedFromBackup(_ url: URL) throws -> Bool? {
        try URL(fileURLWithPath: url.path).resourceValues(forKeys: [.isExcludedFromBackupKey]).isExcludedFromBackup
    }

    func testGivenAnExistingPhotoFolderWhenExcludingAtLaunchThenItIsExcludedFromBackup() throws {
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        XCTAssertNotEqual(try isExcludedFromBackup(folder), true, "a folder made by an older version")

        MemoryPhotos.excludeFromBackup(folder: folder)

        XCTAssertEqual(try isExcludedFromBackup(folder), true)
    }

    func testGivenNoPhotoFolderWhenExcludingAtLaunchThenNoneIsCreated() {
        MemoryPhotos.excludeFromBackup(folder: folder)

        XCTAssertFalse(FileManager.default.fileExists(atPath: folder.path))
    }

    // MARK: Board faces

    private let theme = GamePictures.named([
        "coffee", "teapot", "bread", "cheese", "wine_glass", "croissant", "lemon", "olives",
    ])

    func testGivenNoPhotosWhenDealingThenThemePicturesFillTheBoard() {
        let faces = MemoryDeal.faces(photos: [], theme: theme, pairs: 4)
        XCTAssertEqual(faces, theme.prefix(4).map(MemoryFace.picture))
    }

    func testGivenSomePhotosWhenDealingThenPhotosComeFirstAndPicturesFillTheRest() {
        let photos = [URL(fileURLWithPath: "/a.jpg"), URL(fileURLWithPath: "/b.jpg")]
        let faces = MemoryDeal.faces(photos: photos, theme: theme, pairs: 4)
        XCTAssertEqual(faces, [.photo(photos[0]), .photo(photos[1]), .picture(theme[0]), .picture(theme[1])])
    }

    func testGivenMorePhotosThanPairsWhenDealingThenOnlyPhotosAreUsed() {
        let photos = (0..<6).map { URL(fileURLWithPath: "/\($0).jpg") }
        let faces = MemoryDeal.faces(photos: photos, theme: theme, pairs: 4)
        XCTAssertEqual(faces, photos.prefix(4).map(MemoryFace.photo))
    }
}
