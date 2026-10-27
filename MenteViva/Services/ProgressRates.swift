import Foundation

/// One game's last 7 days for My progress (#141): rates, never sums
/// (decisions 2026-10-03). Days played out of 7, mean accuracy per play, the
/// level reached, and the game's share of the week's plays. A trend appears
/// only after `minPlaysForTrend` plays this week, and only against this
/// player's own earlier weeks of the same game. A game with no accuracy
/// (Remember Together) has plays and days only.
struct ProgressRates: Equatable {
    let game: GameID
    let plays: Int
    /// Calendar days with at least one play, out of the last 7.
    let daysPlayed: Int
    /// This game's part of all the week's plays, 0...1 ("played this week").
    let share: Double
    let accuracy: Double?
    /// The level of the latest play this week.
    let level: Difficulty?
    let accuracyTrend: GameProgress.Trend?
    let levelTrend: GameProgress.Trend?

    static let days = 7
    static let minPlaysForTrend = 3
    /// How far back "your earlier weeks" reaches.
    static let earlierWeeks = 4

    /// Start of the oldest day this needs: the week plus the earlier weeks.
    static func since(now: Date = .now, calendar: Calendar = .current) -> Date {
        calendar.date(byAdding: .day, value: -days * (earlierWeeks + 1) + 1, to: calendar.startOfDay(for: now)) ?? now
    }

    /// Games played in the last 7 calendar days (today included), in `GameID.allCases` order.
    static func week(_ sessions: [GameSession], now: Date = .now, calendar: Calendar = .current) -> [ProgressRates] {
        let today = calendar.startOfDay(for: now)
        let start = calendar.date(byAdding: .day, value: -(days - 1), to: today) ?? today
        let byGame = Dictionary(grouping: sessions.filter { $0.playedAt >= start && $0.playedAt <= now }) { $0.game }
        let earlier = Dictionary(
            grouping: sessions.filter { $0.playedAt >= since(now: now, calendar: calendar) && $0.playedAt < start }
        ) { $0.game }
        let total = GameID.released.reduce(0) { $0 + (byGame[$1]?.count ?? 0) }

        return GameID.released.compactMap { game in
            guard let mine = byGame[game], !mine.isEmpty else { return nil }
            let before = earlier[game] ?? []
            let accuracy = mine.meanAccuracy
            let level = latestLevel(mine)
            let enough = mine.count >= minPlaysForTrend
            return ProgressRates(
                game: game, plays: mine.count,
                daysPlayed: Set(mine.map { calendar.startOfDay(for: $0.playedAt) }).count,
                share: Double(mine.count) / Double(total),
                accuracy: accuracy, level: level,
                accuracyTrend: enough ? trend(accuracy, before.meanAccuracy) : nil,
                levelTrend: enough ? trend(level?.rawValue, latestLevel(before)?.rawValue) : nil)
        }
    }

    private static func trend(_ now: Double?, _ before: Double?) -> GameProgress.Trend? {
        guard let now, let before else { return nil }
        let change = now - before
        return change > GameProgress.accuracyNoise ? .up : change < -GameProgress.accuracyNoise ? .down : .steady
    }

    private static func trend(_ now: Int?, _ before: Int?) -> GameProgress.Trend? {
        guard let now, let before else { return nil }
        return now > before ? .up : now < before ? .down : .steady
    }

    private static func latestLevel(_ sessions: [GameSession]) -> Difficulty? {
        sessions.filter { $0.level != nil }.max { $0.playedAt < $1.playedAt }?.level
    }
}
