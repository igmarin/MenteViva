import SwiftData
import SwiftUI

/// "My Week": a warm, big-type look back at the last 7 days of play.
/// One row per session: game emoji, localized game name. No scores (#45).
/// One warm progress line per game played (#107): words and an icon, never a
/// number and never a down arrow — the numbers live in the family screen.
struct HistoryView: View {
    @Query(sort: \GameSession.playedAt, order: .reverse)
    private var sessions: [GameSession]

    private var weekSessions: [GameSession] {
        DayGrouping.lastWeek(sessions, date: \.playedAt)
    }

    private var groupedDays: [(day: Date, items: [GameSession])] {
        DayGrouping.byDay(weekSessions, date: \.playedAt)
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
                            .bigTapTarget()
                    }
                    .accessibilityHint(AppLanguage.localized("history.share.hint"))
                }
            }
        }
    }

    private var progress: [GameProgress] {
        HotPath.measure("progress.weekly") { GameProgress.weekly(sessions) }.filter { $0.sessions > 0 }
    }

    private var summary: WeeklySummary { WeeklySummary(playedAt: sessions.map(\.playedAt)) }

    /// Family-share payload: plain text so it works over any channel (WhatsApp,
    /// SMS, email) with no account, network, or CloudKit share required.
    private var shareSummary: String { summary.text }

    // MARK: - Content

    private var sessionList: some View {
        List {
            // The week as cards (Card Table, step 5), the same board as on Home.
            Section {
                WeekBoard(
                    days: DayGrouping.thisWeek(sessions, date: \.playedAt).map {
                        (day: $0.day, games: $0.items.compactMap(\.game))
                    }
                )
                .padding(.vertical, 8)
            }

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

            Section {
                ForEach(progress, id: \.game) { progressRow($0) }
            } header: {
                Text(AppLanguage.localized("history.progress.header"))
                    .font(.title3.weight(.semibold))
            }

            ForEach(groupedDays, id: \.day) { group in
                Section {
                    ForEach(group.items, id: \.persistentModelID) { session in
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
        let info = gameInfo(for: session)
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

    /// Level up gets the up arrow; everything else, including an easier week,
    /// reads as steady. Icon plus text, never color alone.
    private func progressRow(_ p: GameProgress) -> some View {
        let name = AppLanguage.localized(p.game.title)
        let movedUp = p.levelTrend == .up
        return Label {
            Text(String(format: AppLanguage.localized(movedUp ? "history.progress.up %@" : "history.progress.steady %@"), name))
                .font(.title3)
        } icon: {
            Image(systemName: movedUp ? "arrow.up.circle.fill" : "arrow.right.circle.fill")
                .font(.title2)
                // The game's own colour (Card Table); direction and words carry the meaning.
                .foregroundStyle(p.game.ink)
        }
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
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

    private func gameInfo(for session: GameSession) -> (emoji: String, name: String) {
        guard let game = session.game else {
            return ("🎮", AppLanguage.localized("history.game.unknown"))
        }
        return (game.emoji, AppLanguage.localized(game.title))
    }
}

#Preview {
    NavigationStack {
        HistoryView()
    }
    .modelContainer(for: GameSession.self, inMemory: true)
}
