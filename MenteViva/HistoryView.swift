import SwiftData
import SwiftUI

/// "My Week": a warm, big-type look at this calendar week of play, the same
/// week as the board at the top, so every count on the screen agrees.
/// One row per day, with each game played and how many times (#140). No scores (#45).
/// One warm progress line per game played (#107): words and an icon, never a
/// number and never a down arrow — the numbers live in the family screen.
struct HistoryView: View {
    @Query(sort: \GameSession.playedAt, order: .reverse)
    private var sessions: [GameSession]

    /// Everything the screen shows, derived from `sessions` once per redraw
    /// instead of once per read (the list used to regroup the week three times).
    private struct Snapshot {
        let weekGroups: [(day: Date, items: [GameSession])]
        let weekCount: Int
        let days: [DayTally]
        /// Only games played this week, so the list matches the board and the counts.
        let progress: [GameProgress]
        let summary: WeeklySummary
        /// Everything collected so far, newest first (#377); empty hides the shelf.
        let album: [GamePicture]

        init(sessions: [GameSession]) {
            album = PictureAlbum.shelf()
            weekGroups = DayGrouping.thisWeek(sessions, date: \.playedAt)
            let week = weekGroups.flatMap(\.items)
            weekCount = week.count
            days = DayGrouping.tally(week, date: \.playedAt, game: \.game)
            let played = Set(week.compactMap(\.game))
            progress = HotPath.measure("progress.weekly") { GameProgress.weekly(sessions) }
                .filter { played.contains($0.game) }
            summary = WeeklySummary(playedAt: sessions.map(\.playedAt))
        }
    }

    var body: some View {
        let snapshot = Snapshot(sessions: sessions)
        Group {
            if snapshot.weekCount == 0 {
                if snapshot.album.isEmpty { emptyState } else { emptyStateWithAlbum(snapshot.album) }
            } else {
                sessionList(snapshot)
            }
        }
        .pageBackground()
        .navigationTitle(AppLanguage.localized("history.title"))
        .toolbar {
            if snapshot.weekCount > 0 {
                ToolbarItem(placement: .topBarTrailing) {
                    // Family-share payload: plain text so it works over any channel
                    // (WhatsApp, SMS, email) with no account, network, or CloudKit share.
                    ShareLink(item: snapshot.summary.text) {
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

    // MARK: - Content

    private func sessionList(_ snapshot: Snapshot) -> some View {
        List {
            // The week as cards (Card Table, step 5), the same board as on Home.
            Section {
                WeekBoard(
                    days: snapshot.weekGroups.map { (day: $0.day, games: $0.items.compactMap(\.game)) }
                )
                .padding(.vertical, 8)
            }

            Section {
                Text("history.summary \(snapshot.weekCount)")
                    .font(.title2)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
                    .accessibilityAddTraits(.isHeader)
                Text(snapshot.summary.text)
                    .font(.title3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
            }

            Section {
                ForEach(snapshot.progress, id: \.game) { progressRow($0) }
            } header: {
                Text(AppLanguage.localized("history.progress.header"))
                    .font(.title3.weight(.semibold))
            }

            Section {
                ForEach(snapshot.days, id: \.day) { dayRow($0) }
            } header: {
                Text(AppLanguage.localized("history.days.header"))
                    .font(.title3.weight(.semibold))
            }

            if !snapshot.album.isEmpty {
                Section {
                    albumShelf(snapshot.album)
                        .listRowBackground(Color.clear)
                } header: {
                    Text(AppLanguage.localized("album.title"))
                        .font(.title3.weight(.semibold))
                }
            }
        }
        .listPageBackground()
    }

    /// The pictures the player has collected, newest first (#377): in colour, each with its name.
    /// Only what was earned is drawn, so there is nothing to count, no empty slot and nothing to lose.
    private func albumShelf(_ pictures: [GamePicture]) -> some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 16, alignment: .top)], spacing: 20) {
            ForEach(pictures, id: \.slug) { picture in
                let name = AppLanguage.localized(picture.nameKey)
                VStack(spacing: 6) {
                    PictureView(picture: picture, size: 72)
                    Text(verbatim: name)
                        .font(.callout)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, minHeight: 100)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(verbatim: name))
            }
        }
        .padding(.vertical, 8)
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

    /// Nothing played yet this week: the invitation, centred, exactly as before the album existed.
    private var emptyState: some View {
        VStack(spacing: 24) {
            invitation
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// Nothing played yet this week, but pictures from earlier weeks: the invitation, then the shelf.
    private func emptyStateWithAlbum(_ album: [GamePicture]) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                invitation
                Text(AppLanguage.localized("album.title"))
                    .font(.title3.weight(.semibold))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityAddTraits(.isHeader)
                albumShelf(album)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
            .frame(maxWidth: .infinity)
        }
    }

    @ViewBuilder private var invitation: some View {
        PictureView(picture: GamePictures.named("sunflower"), size: 160)
            .accessibilityHidden(true)
        Text("history.empty")
            .font(.title2)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 32)
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
