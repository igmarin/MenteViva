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
        var lines = [AppLanguage.localized("history.share.title"),
                     String(format: AppLanguage.localized("history.share.days %lld"), daysPlayed),
                     String(format: AppLanguage.localized("history.share.games %lld"), gamesPlayed)]
        if streak >= 2 {
            lines.append(String(format: AppLanguage.localized("history.share.streak %lld"), streak))
        }
        return lines.joined(separator: "\n")
    }
}

/// Day grouping shared by My Week and its tests: the last 7 days of items,
/// grouped by calendar day, newest day first.
enum DayGrouping {
    static func lastWeek<T>(_ items: [T], date: (T) -> Date,
                            now: Date = .now, calendar: Calendar = .current) -> [T] {
        let cutoff = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        return items.filter { date($0) >= cutoff }
    }

    static func byDay<T>(_ items: [T], date: (T) -> Date,
                         calendar: Calendar = .current) -> [(day: Date, items: [T])] {
        let grouped = Dictionary(grouping: items) { calendar.startOfDay(for: date($0)) }
        return grouped.keys.sorted(by: >).map { (day: $0, items: grouped[$0] ?? []) }
    }
}
