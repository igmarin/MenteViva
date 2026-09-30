import SwiftUI
import SwiftData

/// "My Week": a warm, big-type look back at the last 7 days of play.
/// One row per session: game emoji, localized game name. No scores (#45).
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
        .navigationTitle(AppLanguage.localized("history.title"))
        .toolbar {
            if !weekSessions.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    ShareLink(item: shareSummary) {
                        Label(AppLanguage.localized("history.share"), systemImage: "square.and.arrow.up")
                            .font(.title3)
                            .labelStyle(.iconOnly)
                            .frame(minWidth: 100, minHeight: 100)
                            .contentShape(Rectangle())
                    }
                    .accessibilityHint(AppLanguage.localized("history.share.hint"))
                }
            }
        }
    }

    private var summary: WeeklySummary { WeeklySummary(playedAt: sessions.map(\.playedAt)) }

    /// Family-share payload: plain text so it works over any channel (WhatsApp,
    /// SMS, email) with no account, network, or CloudKit share required.
    private var shareSummary: String { summary.text }

    // MARK: - Content

    private var sessionList: some View {
        List {
            Section {
                Text("history.summary \(weekSessions.count)")
                    .font(.title2)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
                    .accessibilityAddTraits(.isHeader)
                Text(summary.text)
                    .font(.title3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
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
        }
        .frame(minHeight: 100)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("history.a11y.played \(info.name)"))
    }

    private var emptyState: some View {
        VStack(spacing: 24) {
            Text(verbatim: "🌻")
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
            return AppLanguage.localized("history.today")
        }
        if Calendar.current.isDateInYesterday(day) {
            return AppLanguage.localized("history.yesterday")
        }
        return day.formatted(.dateTime.weekday(.wide).day().month(.wide))
    }

    private func gameInfo(for gameID: String) -> (emoji: String, name: String) {
        let game = GameID(rawValue: gameID) ?? (gameID == "memory" ? .memoryMatch : nil)
        guard let game else {
            return ("🎮", AppLanguage.localized("history.game.unknown"))
        }
        return (game.emoji, AppLanguage.localized( game.title))
    }
}

#Preview {
    NavigationStack {
        HistoryView()
    }
    .modelContainer(for: GameSession.self, inMemory: true)
}
