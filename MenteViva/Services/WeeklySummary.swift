import Foundation

/// Caregiver-friendly weekly summary (#71): days played, games played, streak.
/// Built only from session dates. No scores, no judgments (#45), no medical
/// claims. Sharing is always player-initiated (History share button).
struct WeeklySummary: Equatable {
    var daysPlayed: Int
    var gamesPlayed: Int
    /// Consecutive days with play, counting back from today (or yesterday if
    /// today has no play yet, so the streak isn't lost before the player sits down).
    var streak: Int

    init(playedAt dates: [Date], now: Date = .now, calendar: Calendar = .current) {
        let today = calendar.startOfDay(for: now)
        let weekStart = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        let week = dates.filter { $0 >= weekStart && $0 <= now }
        gamesPlayed = week.count
        daysPlayed = Set(week.map { calendar.startOfDay(for: $0) }).count

        let allDays = Set(dates.map { calendar.startOfDay(for: $0) })
        var day = allDays.contains(today) ? today : (calendar.date(byAdding: .day, value: -1, to: today) ?? today)
        var run = 0
        while allDays.contains(day) {
            run += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = previous
        }
        streak = run
    }

    /// Warm, plain-text card used on screen and as the share payload.
    var text: String {
        var lines = [
            AppLanguage.localized("history.share.title"),
            String(format: AppLanguage.localized("history.share.days %lld"), daysPlayed),
            String(format: AppLanguage.localized("history.share.games %lld"), gamesPlayed),
        ]
        if streak >= 2 {
            lines.append(String(format: AppLanguage.localized("history.share.streak %lld"), streak))
        }
        return lines.joined(separator: "\n")
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
        return level.rawValue > previousLevel.rawValue
            ? .up
            : level.rawValue < previousLevel.rawValue ? .down : .steady
    }

    var accuracyTrend: Trend? {
        guard let accuracy, let previousAccuracy else { return nil }
        let change = accuracy - previousAccuracy
        return change > Self.accuracyNoise ? .up : change < -Self.accuracyNoise ? .down : .steady
    }

    /// Games played in the last 14 days, in `GameID.allCases` order.
    static func weekly(
        _ sessions: [GameSession], now: Date = .now,
        calendar: Calendar = .current
    ) -> [GameProgress] {
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        let thisWeek = DayGrouping.lastWeek(sessions, date: \.playedAt, now: now, calendar: calendar)
            .filter { $0.playedAt <= now }
        let lastWeek = DayGrouping.lastWeek(sessions, date: \.playedAt, now: weekAgo, calendar: calendar)
            .filter { $0.playedAt < weekAgo }
        return GameID.allCases.compactMap { game in
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
        sessions.filter { $0.level != nil }.max { $0.playedAt < $1.playedAt }?.level
    }
}

/// Day grouping shared by My Week and its tests: the last 7 days of items,
/// grouped by calendar day, newest day first.
enum DayGrouping {
    static func lastWeek<T>(
        _ items: [T], date: (T) -> Date,
        now: Date = .now, calendar: Calendar = .current
    ) -> [T] {
        let cutoff = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        return items.filter { date($0) >= cutoff }
    }

    static func byDay<T>(
        _ items: [T], date: (T) -> Date,
        calendar: Calendar = .current
    ) -> [(day: Date, items: [T])] {
        let grouped = Dictionary(grouping: items) { calendar.startOfDay(for: date($0)) }
        return grouped.keys.sorted(by: >).map { (day: $0, items: grouped[$0] ?? []) }
    }
}
