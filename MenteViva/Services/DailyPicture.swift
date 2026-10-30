import Foundation

/// Which illustration belongs to a day (#376). Pure: the same day stamp gives the same picture on
/// every launch and device, because the stamp is hashed with FNV-1a rather than Swift's `hashValue`,
/// which is seeded afresh each launch.
nonisolated enum DailyPicture {
    /// The pictures a day may turn over: our illustrations only. Colour slugs are drawn as plain
    /// circles, never art, and a picture whose art has not shipped would turn over as an emoji.
    static func candidates(from pictures: [GamePicture], hasAsset: (String) -> Bool) -> [GamePicture] {
        pictures.filter { !$0.slug.hasPrefix("color.") && hasAsset($0.assetName) }
    }

    /// The day's picture among `pictures` (never empty): the stamp's hash modulo their count.
    static func pick(dayStamp: String, from pictures: [GamePicture]) -> GamePicture {
        precondition(!pictures.isEmpty, "A day needs at least one picture to pick from")
        return pictures[Int(fnv1a(dayStamp) % UInt64(pictures.count))]
    }

    /// 64-bit FNV-1a over the UTF-8 bytes: small, stable and well spread for short strings.
    static func fnv1a(_ text: String) -> UInt64 {
        var hash: UInt64 = 0xcbf2_9ce4_8422_2325
        for byte in text.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 0x0000_0100_0000_01b3
        }
        return hash
    }
}
