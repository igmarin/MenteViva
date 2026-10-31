import Foundation

/// Caregiver-friendly weekly summary (#71): days played and games played this
/// calendar week, the same week as the week board. No streak (decisions
/// 2026-10-03: no loss state), no scores, no judgments (#45), no medical
/// claims. Sharing is always player-initiated (History share button).
struct WeeklySummary: Equatable {
    var daysPlayed: Int
    var gamesPlayed: Int

    init(playedAt dates: [Date], now: Date = .now, calendar: Calendar = .current) {
        let week = DayGrouping.thisWeek(dates, date: { $0 }, now: now, calendar: calendar).flatMap(\.items)
        gamesPlayed = week.count
        daysPlayed = Set(week.map { calendar.startOfDay(for: $0) }).count
    }

    /// Warm, plain-text card used on screen and as the share payload.
    var text: String {
        [
            AppLanguage.localized("history.share.title"),
            String(format: AppLanguage.localized("history.share.days %lld"), daysPlayed),
            String(format: AppLanguage.localized("history.share.games %lld"), gamesPlayed),
        ].joined(separator: "\n")
    }
}

/// One game's week against the week before (#107). Level reached is the
/// progression signal, accuracy the secondary one (Jev 012). The player sees
/// only warm words built from this; the family screen sees the numbers.
struct GameProgress: Equatable {
    enum Trend: Equatable { case up, steady, down }

    let game: GameID
    let sessions: Int
    let previousSessions: Int
    let accuracy: Double?
    let previousAccuracy: Double?
    let level: Difficulty?
    let previousLevel: Difficulty?

    /// Accuracy moves smaller than this read as "about the same".
    static let accuracyNoise = 0.05

    var levelTrend: Trend? {
        guard let level, let previousLevel else { return nil }
        return level.level > previousLevel.level
            ? .up
            : level.level < previousLevel.level ? .down : .steady
    }

    var accuracyTrend: Trend? {
        guard let accuracy, let previousAccuracy else { return nil }
        let change = accuracy - previousAccuracy
        return change > Self.accuracyNoise ? .up : change < -Self.accuracyNoise ? .down : .steady
    }

    /// Games played this week or the week before, in `GameID.allCases` order.
    /// "This week" starts at `weekStart`, by default the calendar week's first
    /// day, so My Week's lines cover the same days as its board (#170).
    static func weekly(
        _ sessions: [GameSession], now: Date = .now,
        calendar: Calendar = .current, weekStart: Date? = nil
    ) -> [GameProgress] {
        let start =
            weekStart ?? calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? calendar.startOfDay(for: now)
        let previousStart = calendar.date(byAdding: .day, value: -7, to: start) ?? start
        let thisWeek = sessions.filter { $0.playedAt >= start }
        let lastWeek = sessions.filter { $0.playedAt >= previousStart && $0.playedAt < start }
        return GameID.released.compactMap { game in
            let mine = thisWeek.filter { $0.game == game }
            let before = lastWeek.filter { $0.game == game }
            guard !mine.isEmpty || !before.isEmpty else { return nil }
            return GameProgress(
                game: game, sessions: mine.count, previousSessions: before.count,
                accuracy: mine.meanAccuracy, previousAccuracy: before.meanAccuracy,
                level: latestLevel(mine), previousLevel: latestLevel(before))
        }
    }

    private static func latestLevel(_ sessions: [GameSession]) -> Difficulty? {
        sessions.filter { $0.resolvedLevel != nil }.max { $0.playedAt < $1.playedAt }?.resolvedLevel
    }
}

/// Day grouping shared by My Week, the week board and their tests: items
/// grouped by calendar day, newest day first.
enum DayGrouping {
    static func byDay<T>(
        _ items: [T], date: (T) -> Date,
        calendar: Calendar = .current
    ) -> [(day: Date, items: [T])] {
        let grouped = Dictionary(grouping: items) { calendar.startOfDay(for: date($0)) }
        return grouped.keys.sorted(by: >).map { (day: $0, items: grouped[$0] ?? []) }
    }

    /// What My Week calls a day (#407): "Today", "Yesterday", else the weekday, day and month in
    /// the app's own language. `Date.formatted` alone follows the device's language, so a player
    /// who picked Spanish on an English phone read "Wednesday, October 28" under a Spanish "Hoy".
    /// `defaults` is where the app's language is read, so tests control it.
    static func dayTitle(
        _ day: Date, now: Date = .now, calendar: Calendar = .current,
        locale: Locale, defaults: UserDefaults = .standard
    ) -> String {
        if calendar.isDate(day, inSameDayAs: now) {
            return AppLanguage.localized("history.today", defaults: defaults)
        }
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: now),
            calendar.isDate(day, inSameDayAs: yesterday)
        {
            return AppLanguage.localized("history.yesterday", defaults: defaults)
        }
        // The style carries the locale (the wording), and the calendar and its time zone, so the day
        // named is the day the calendar grouped, whatever zone the device is in.
        return Date.FormatStyle(locale: locale, calendar: calendar, timeZone: calendar.timeZone)
            .weekday(.wide).day().month(.wide).format(day)
    }
}
