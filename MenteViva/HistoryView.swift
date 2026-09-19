import SwiftUI
import SwiftData

/// "My Week": a warm, big-type look back at the last 7 days of play.
/// One row per session: game emoji, localized game name, score.
struct HistoryView: View {
    @Query(sort: \GameSession.playedAt, order: .reverse)
    private var sessions: [GameSession]

    private var weekSessions: [GameSession] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -7, to: .now) ?? .now
        return sessions.filter { $0.playedAt >= cutoff }
    }

    private var groupedDays: [(day: Date, sessions: [GameSession])] {
        let grouped = Dictionary(grouping: weekSessions) {
            Calendar.current.startOfDay(for: $0.playedAt)
        }
        return grouped.keys.sorted(by: >).map { (day: $0, sessions: grouped[$0] ?? []) }
    }

    var body: some View {
        Group {
            if weekSessions.isEmpty {
                emptyState
            } else {
                sessionList
            }
        }
        .navigationTitle(String(localized: "history.title"))
    }

    // MARK: - Content

    private var sessionList: some View {
        List {
            Section {
                Text("history.summary \(weekSessions.count)")
                    .font(.title2)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
            }

            ForEach(groupedDays, id: \.day) { group in
                Section {
                    ForEach(group.sessions, id: \.persistentModelID) { session in
                        sessionRow(session)
                    }
                } header: {
                    Text(dayTitle(group.day))
                        .font(.title3.weight(.semibold))
                }
            }
        }
    }

    private func sessionRow(_ session: GameSession) -> some View {
        let info = gameInfo(for: session.gameID)
        return HStack(spacing: 16) {
            Text(info.emoji)
                .font(.system(size: 44))
                .accessibilityHidden(true)

            Text(info.name)
                .font(.title2)
                .lineLimit(2)

            Spacer(minLength: 8)

            Text("history.score \(session.score)")
                .font(.title2.weight(.bold))
        }
        .frame(minHeight: 72)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("history.a11y.session \(info.name) \(session.score)"))
    }

    private var emptyState: some View {
        VStack(spacing: 24) {
            Text("🌻")
                .font(.system(size: 80))
                .accessibilityHidden(true)
            Text("history.empty")
                .font(.title2)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Helpers

    private func dayTitle(_ day: Date) -> String {
        if Calendar.current.isDateInToday(day) {
            return String(localized: "history.today")
        }
        if Calendar.current.isDateInYesterday(day) {
            return String(localized: "history.yesterday")
        }
        return day.formatted(.dateTime.weekday(.wide).day().month(.wide))
    }

    private func gameInfo(for gameID: String) -> (emoji: String, name: String) {
        switch gameID {
        case "memory":
            return ("🧩", String(localized: "game.memory.title"))
        case "stroop":
            return ("🎨", String(localized: "game.colorclash.title"))
        case "category_fluency":
            return ("🐾", String(localized: "game.category.title"))
        case "math_streaks":
            return ("🔢", String(localized: "game.math.title"))
        default:
            return ("🎮", String(localized: "history.game.unknown"))
        }
    }
}

#Preview {
    NavigationStack {
        HistoryView()
    }
    .modelContainer(for: GameSession.self, inMemory: true)
}
