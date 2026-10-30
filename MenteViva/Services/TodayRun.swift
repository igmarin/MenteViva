import Foundation
import SwiftData

/// Where today's games stand on Home's table (Card Table, step 4): which are
/// done, which one is next, and whether the day is finished. The plan is saved
/// once per day (PlanStore), so the picks don't shift as games are played.
nonisolated struct TodayRun: Equatable {
    /// Today's picks still on the table (hidden games left out), in plan order.
    let games: [GameID]
    /// Picks with a session today.
    let done: Set<GameID>

    init(
        plan: [GameID], hidden: Set<GameID> = [], sessions: [GameSession],
        now: Date = .now, calendar: Calendar = .current
    ) {
        games = plan.filter { !hidden.contains($0) }
        let playedToday = sessions.filter { calendar.isDate($0.playedAt, inSameDayAs: now) }.compactMap(\.game)
        done = Set(playedToday).intersection(games)
    }

    /// The first pick not played yet, in plan order; nil once all are done.
    var next: GameID? { games.first { !done.contains($0) } }
    var remaining: Int { games.count - done.count }
    /// False before the plan exists, so an empty table never says "done".
    var isFinished: Bool { !games.isEmpty && next == nil }

    /// Whether `finished` was the game that completed today's table: the day is done and the game
    /// was one of the picks. An off-plan game played after the table is cleared closes nothing, so
    /// it gets the ordinary celebration (#375).
    func closesTheDay(finishing finished: GameID) -> Bool {
        isFinished && games.contains(finished)
    }

    /// What the end of `finished` offers (step 5): the next pick while it was
    /// one of today's games and some are left; nil means "Play again".
    func next(after finished: GameID) -> GameID? {
        games.contains(finished) ? next : nil
    }
}

/// Home's greeting by the hour: morning until noon, afternoon until six.
nonisolated enum Greeting {
    static func key(hour: Int) -> String {
        switch hour {
        case ..<12: "home.greeting.morning"
        case ..<18: "home.greeting.afternoon"
        default: "home.greeting.evening"
        }
    }
}

extension GameSession {
    /// This calendar week's sessions, oldest first: everything Home's table and
    /// week board and the end-of-game screen read. History keeps growing, so
    /// they never load all of it (#157 review).
    static func thisWeek(now: Date = .now, calendar: Calendar = .current) -> FetchDescriptor<GameSession> {
        let start = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? calendar.startOfDay(for: now)
        return FetchDescriptor(predicate: #Predicate { $0.playedAt >= start }, sortBy: [SortDescriptor(\.playedAt)])
    }
}

extension DayGrouping {
    /// The current calendar week from the locale's first weekday: seven days,
    /// each with its items oldest first, empty days included (the week board).
    static func thisWeek<T>(
        _ items: [T], date: (T) -> Date,
        now: Date = .now, calendar: Calendar = .current
    ) -> [(day: Date, items: [T])] {
        let start = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? calendar.startOfDay(for: now)
        return (0..<7).compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: offset, to: start) else { return nil }
            let onDay = items.filter { calendar.isDate(date($0), inSameDayAs: day) }
            return (day: day, items: onDay.sorted { date($0) < date($1) })
        }
    }

    /// My Week's rows (#140): one tally per day, newest day first. Sessions of
    /// games this build doesn't know are left out, and so is a day with only those.
    static func tally<T>(
        _ items: [T], date: (T) -> Date, game: (T) -> GameID?,
        calendar: Calendar = .current
    ) -> [DayTally] {
        byDay(items, date: date, calendar: calendar).compactMap { group in
            var order: [GameID] = []
            var counts: [GameID: Int] = [:]
            for id in group.items.sorted(by: { date($0) < date($1) }).compactMap(game) {
                if counts[id] == nil { order.append(id) }
                counts[id, default: 0] += 1
            }
            guard !order.isEmpty else { return nil }
            return DayTally(day: group.day, games: order.map { .init(game: $0, count: counts[$0] ?? 0) })
        }
    }
}

/// One day of My Week: each game played that day with how many times, in the
/// order it was first played. No scores (#45).
nonisolated struct DayTally: Equatable {
    struct Count: Equatable {
        let game: GameID
        let count: Int
    }

    let day: Date
    let games: [Count]
}
