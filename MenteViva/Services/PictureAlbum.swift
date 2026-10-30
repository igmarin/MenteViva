import Foundation

/// The player's album of illustrations (#376), kept on this device in `UserDefaults` like `PlanStore`.
/// It only ever grows: no count, lock, empty slot or loss (decision 2026-10-30), and a missed day
/// simply turns nothing over. The album shelf (#377) reads `all(defaults:)`.
///
/// Stored state, two keys:
/// - `album.slugs` (`[String]`): picture slugs in the order collected, each once.
/// - `album.day` (`String`): the day stamp ("yyyy-MM-dd") of the last picture turned over, so a
///   day turns over one picture even when it is a favourite that is already in the album.
nonisolated enum PictureAlbum {
    static let slugsKey = "album.slugs"
    static let dayKey = "album.day"

    /// Every collected slug, oldest first.
    static func all(defaults: UserDefaults = .standard) -> [String] {
        defaults.stringArray(forKey: slugsKey) ?? []
    }

    /// Adds a slug to the end of the album; a slug already there stays where it is.
    static func collect(_ slug: String, defaults: UserDefaults = .standard) {
        var slugs = all(defaults: defaults)
        guard !slugs.contains(slug) else { return }
        slugs.append(slug)
        defaults.set(slugs, forKey: slugsKey)
    }

    /// Today's picture when no picture has turned over yet today, collected as it is returned; nil
    /// once one has. It picks among pictures not yet in the album, so each of them arrives before any
    /// repeats; once every one is collected it picks from them all and the album stays as it is.
    static func turnOver(
        on date: Date = .now, calendar: Calendar = .current, from pictures: [GamePicture],
        defaults: UserDefaults = .standard
    ) -> GamePicture? {
        let today = PlanStore.dayStamp(date, calendar: calendar)
        guard !pictures.isEmpty, defaults.string(forKey: dayKey) != today else { return nil }
        let collected = Set(all(defaults: defaults))
        let fresh = pictures.filter { !collected.contains($0.slug) }
        let picture = DailyPicture.pick(dayStamp: today, from: fresh.isEmpty ? pictures : fresh)
        collect(picture.slug, defaults: defaults)
        defaults.set(today, forKey: dayKey)
        return picture
    }
}
