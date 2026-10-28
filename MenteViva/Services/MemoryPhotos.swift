import ImageIO
import UIKit

/// Family photos for Memory Lane (#110). Picked with the system photo picker
/// (no library permission needed), shrunk to at most 600 px, and kept only in
/// this app's own storage on this device — nothing is uploaded or shared.
///
/// `nonisolated` on purpose: importing and decoding photos is file I/O and
/// image work, so callers run it off the main actor.
nonisolated enum MemoryPhotos {
    static let maxCount = 8  // the largest board has 8 pairs
    static let maxSide: CGFloat = 600

    enum AddError: Error { case notAnImage, albumFull }

    /// What happened when several photos were added at once (#120).
    nonisolated struct AddResult: Equatable {
        var added = 0
        var unreadable = 0
        var overLimit = 0
    }

    static var folder: URL {
        URL.applicationSupportDirectory.appendingPathComponent("MemoryPhotos", isDirectory: true)
    }

    /// Stored photos, oldest first.
    static func all(in folder: URL = folder) -> [URL] {
        let files =
            (try? FileManager.default.contentsOfDirectory(
                at: folder, includingPropertiesForKeys: [.creationDateKey])) ?? []
        return files.filter { $0.pathExtension == "jpg" }.sorted { a, b in
            let date = { (url: URL) in
                (try? url.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
            }
            return (date(a), a.lastPathComponent) < (date(b), b.lastPathComponent)
        }
    }

    static func add(_ data: Data, to folder: URL = folder) throws {
        guard all(in: folder).count < maxCount else { throw AddError.albumFull }
        try store(data, in: folder)
    }

    private static func store(_ data: Data, in folder: URL) throws {
        try HotPath.measure("photo.downscale") { try downscale(data, into: folder) }
    }

    /// Decode, shrink to `maxSide`, re-encode as JPEG and store it.
    ///
    /// ImageIO decodes straight to the target size, so a 12-megapixel photo is
    /// never held in memory at full size. Never upscales; honours EXIF rotation.
    private static func downscale(_ data: Data, into folder: URL) throws {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
            let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
            let width = properties[kCGImagePropertyPixelWidth] as? CGFloat,
            let height = properties[kCGImagePropertyPixelHeight] as? CGFloat
        else { throw AddError.notAnImage }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: min(maxSide, max(width, height)),
        ]
        guard let small = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary),
            let jpeg = UIImage(cgImage: small).jpegData(compressionQuality: 0.8)
        else { throw AddError.notAnImage }
        try prepare(folder)
        try jpeg.write(to: folder.appendingPathComponent("\(UUID().uuidString).jpg"), options: writeOptions)
    }

    /// Photos and captions are written atomically and locked while the device is.
    private static let writeOptions: Data.WritingOptions = [.atomic, .completeFileProtection]

    /// Creates the folder and keeps it out of iCloud and device backups, so the
    /// "stays on this device" promise holds for the photos and captions in it.
    private static func prepare(_ folder: URL) throws {
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        var folder = folder
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try folder.setResourceValues(values)
    }

    /// Adds each photo in order; one that can't be used never stops the rest.
    /// `nil` is a photo the picker couldn't hand over.
    static func add(_ photos: [Data?], to folder: URL = folder) -> AddResult {
        // The whole batch is what the family waits on after the picker closes;
        // photo.downscale inside shows which photo cost what.
        HotPath.measure("photo.import") {
            var result = AddResult()
            // Listed once for the batch, not once per photo.
            var count = all(in: folder).count
            for data in photos {
                guard let data else {
                    result.unreadable += 1
                    continue
                }
                guard count < maxCount else {
                    result.overLimit += 1
                    continue
                }
                do {
                    try store(data, in: folder)
                    count += 1
                    result.added += 1
                } catch {
                    result.unreadable += 1
                }
            }
            return result
        }
    }

    /// A stored photo, decoded off the main actor and ready to draw, so showing
    /// it never stalls a tap or a card flip.
    static func image(at url: URL) async -> UIImage? {
        await UIImage(contentsOfFile: url.path)?.byPreparingForDisplay()
    }

    static func remove(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
        try? FileManager.default.removeItem(at: captionFile(for: url))
    }

    // MARK: Captions (#139)

    /// A name or a few words that help remember who or what a photo shows.
    /// Kept in a `.txt` next to the photo, on this device only.
    static let maxCaptionLength = 60

    private static func captionFile(for photo: URL) -> URL {
        photo.deletingPathExtension().appendingPathExtension("txt")
    }

    /// The photo's caption, or nil when it has none.
    ///
    /// Signposted because Set up reads it inside a `ForEach` body, so the
    /// run count in a trace says how many times a redraw went back to disk.
    static func caption(for photo: URL) -> String? {
        HotPath.measure("photo.caption") {
            guard let text = try? String(contentsOf: captionFile(for: photo), encoding: .utf8) else { return nil }
            return text.isEmpty ? nil : text
        }
    }

    /// Photos that have a caption, oldest first, each with its caption (#142).
    static func captioned(in folder: URL = folder) -> [(photo: URL, caption: String)] {
        all(in: folder).compactMap { url in caption(for: url).map { (url, $0) } }
    }

    /// Saves the trimmed text, cut to `maxCaptionLength`; empty text removes the caption.
    static func setCaption(_ text: String, for photo: URL) throws {
        let file = captionFile(for: photo)
        let caption = String(text.trimmingCharacters(in: .whitespacesAndNewlines).prefix(maxCaptionLength))
        if caption.isEmpty {
            // Nothing to clear is fine; any other failure must reach the sheet.
            guard FileManager.default.fileExists(atPath: file.path) else { return }
            try FileManager.default.removeItem(at: file)
        } else {
            try Data(caption.utf8).write(to: file, options: writeOptions)
        }
    }
}

/// Games that cannot be played yet, kept off Home, the plan and the family's list (#142).
nonisolated enum GameAvailability {
    /// Games that need the family's own photos and names (Set up → Photos) have nothing to deal
    /// until enough are there.
    static func unavailable(in folder: URL = MemoryPhotos.folder) -> Set<GameID> {
        PhotoCaptionDeal.eligible(MemoryPhotos.captioned(in: folder)).count < PhotoCaptionDeal.minPairs
            ? [.photoCaptions] : []
    }
}
