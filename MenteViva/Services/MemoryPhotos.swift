import UIKit

/// Family photos for Memory Lane (#110). Picked with the system photo picker
/// (no library permission needed), shrunk to at most 600 px, and kept only in
/// this app's own storage on this device — nothing is uploaded or shared.
enum MemoryPhotos {
    static let maxCount = 8  // the largest board has 8 pairs
    static let maxSide: CGFloat = 600

    enum AddError: Error { case notAnImage, albumFull }

    /// What happened when several photos were added at once (#120).
    struct AddResult: Equatable {
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

    static func remove(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
    }
}
