import Foundation

/// The short message the player can send to family once today's games are done (#381).
/// Plain text for the system share sheet: the date, one line per game and a warm footer.
/// No scores, levels, timing or counts, nothing about the player's health, no names or photos.
/// Every game line carries its title, so the check mark is never the only meaning when read
/// aloud. Sharing is always player-initiated; the app sends nothing by itself.
nonisolated enum TodayShare {
    /// `localize` and `locale` come in so a test (or a language change) controls the words.
    static func text(
        games: [GameID], date: Date, locale: Locale = AppLanguage.currentLocale,
        localize: (String.LocalizationValue) -> String
    ) -> String {
        let day = date.formatted(.dateTime.weekday(.wide).day().month(.wide).locale(locale))
        let title = String(format: localize("today.share.title"), day)
        return ([title] + games.map { line(for: $0, localize: localize) } + [localize("today.share.footer")])
            .joined(separator: "\n")
    }

    /// One game: its emoji, its name and a check mark.
    static func line(for game: GameID, localize: (String.LocalizationValue) -> String) -> String {
        "\(game.emoji) \(localize(game.title)) ✓"
    }
}
