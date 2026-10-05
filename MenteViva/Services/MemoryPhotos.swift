import UIKit

/// Family photos for Memory Lane (#110). Picked with the system photo picker
/// (no library permission needed), shrunk to at most 600 px, and kept only in
/// this app's own storage on this device — nothing is uploaded or shared.
enum MemoryPhotos {
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
        try HotPath.measure("photo.downscale") { try downscale(data, into: folder) }
    }

    /// Decode, shrink to `maxSide`, re-encode as JPEG and store it.
    private static func downscale(_ data: Data, into folder: URL) throws {
        guard let image = UIImage(data: data) else { throw AddError.notAnImage }
        let scale = min(1, maxSide / max(image.size.width, image.size.height))
        let size = CGSize(width: (image.size.width * scale).rounded(), height: (image.size.height * scale).rounded())
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let small = UIGraphicsImageRenderer(size: size, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
        guard let jpeg = small.jpegData(compressionQuality: 0.8) else { throw AddError.notAnImage }
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        try jpeg.write(to: folder.appendingPathComponent("\(UUID().uuidString).jpg"))
    }

    /// Adds each photo in order; one that can't be used never stops the rest.
    /// `nil` is a photo the picker couldn't hand over.
    static func add(_ photos: [Data?], to folder: URL = folder) -> AddResult {
        // The whole batch is what the family waits on after the picker closes;
        // photo.downscale inside shows which photo cost what.
        HotPath.measure("photo.import") {
            var result = AddResult()
            for data in photos {
                guard let data else {
                    result.unreadable += 1
                    continue
                }
                do {
                    try add(data, to: folder)
                    result.added += 1
                } catch AddError.albumFull {
                    result.overLimit += 1
                } catch {
                    result.unreadable += 1
                }
            }
            return result
        }
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
    /// Signposted because For family reads it inside a `ForEach` body, so the
    /// run count in a trace says how many times a redraw went back to disk.
    static func caption(for photo: URL) -> String? {
        HotPath.measure("photo.caption") {
            guard let text = try? String(contentsOf: captionFile(for: photo), encoding: .utf8) else { return nil }
            return text.isEmpty ? nil : text
        }
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
            try caption.write(to: file, atomically: true, encoding: .utf8)
        }
    }
}
