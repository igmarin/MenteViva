import SwiftData
import SwiftUI

/// "My Week": a warm, big-type look back at the last 7 days of play.
/// One row per day, with each game played and how many times (#140). No scores (#45).
/// One warm progress line per game played (#107): words and an icon, never a
/// number and never a down arrow — the numbers live in the family screen.
struct HistoryView: View {
    @Query(sort: \GameSession.playedAt, order: .reverse)
    private var sessions: [GameSession]

    private var weekSessions: [GameSession] {
        DayGrouping.lastWeek(sessions, date: \.playedAt)
    }

    private var days: [DayTally] {
        DayGrouping.tally(weekSessions, date: \.playedAt, game: \.game)
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

            Section {
                ForEach(days, id: \.day) { dayRow($0) }
            } header: {
                Text(AppLanguage.localized("history.days.header"))
                    .font(.title3.weight(.semibold))
            }
        }
    }

    /// One row per day (#140): the day, then one chip per game with its count.
    /// The chips sit side by side while they fit and stack at large text sizes.
    private func dayRow(_ tally: DayTally) -> some View {
        let title = dayTitle(tally.day)
        let chips = ForEach(tally.games, id: \.game) { gameChip($0) }
        return VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title2.weight(.semibold))
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 10) { chips }
                VStack(alignment: .leading, spacing: 10) { chips }
            }
        }
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, minHeight: 100, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: "\(title): " + tally.games.map(spokenCount).joined(separator: "; ")))
    }

    /// The game's emblem and colour decorate; its name and count are the text.
    private func gameChip(_ entry: DayTally.Count) -> some View {
        HStack(spacing: 8) {
            Emblem(game: entry.game)
                .frame(width: 30, height: 30)
            Text(AppLanguage.localized(entry.game.title))
                .font(.title3)
            Text(verbatim: "×\(entry.count)")
                .font(.title3.weight(.heavy))
                .monospacedDigit()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        // A rounded rectangle, not a capsule, so a name wrapped at large text sizes stays a chip.
        .background(entry.game.ink.opacity(0.12), in: .rect(cornerRadius: 22))
        .overlay(RoundedRectangle(cornerRadius: 22).strokeBorder(entry.game.ink, lineWidth: 2))
    }

    /// "Memory Lane, 2 times" / "Memory Lane, once" for VoiceOver.
    private func spokenCount(_ entry: DayTally.Count) -> String {
        let times = AppLanguage.localized("history.day.times \(entry.count)" as String.LocalizationValue)
        return "\(AppLanguage.localized(entry.game.title)), \(times)"
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
}

#Preview {
    NavigationStack {
        HistoryView()
    }
    .modelContainer(for: GameSession.self, inMemory: true)
}
