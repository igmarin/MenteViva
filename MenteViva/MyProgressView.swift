import SwiftData
import SwiftUI

/// My progress (#141): the same rates for whoever holds this device, the
/// owner on his iPhone or his father on the iPad. Rates, never sums
/// (decisions 2026-10-03), worked out in `ProgressRates`. Trends say it in
/// words with an icon, and an easier week never gets a down arrow. Sharing is
/// the player's choice: the share button, nothing automatic.
struct MyProgressView: View {
    /// Every play, unfiltered: `ProgressRates.week` keeps the days it needs.
    /// No date predicate here: on iOS 17, a `Query(filter:)` built in `init`
    /// for a view pushed from Settings re-rendered forever and froze the app
    /// (found on the iPad, 2026-10-13).
    @Query private var sessions: [GameSession]

    private var rates: [ProgressRates] { HotPath.measure("progress.rates") { ProgressRates.week(sessions) } }

    var body: some View {
        let rates = rates
        List {
            Section {
                Text(AppLanguage.localized("progress.intro"))
                    .font(.title3)
            }

            if rates.isEmpty {
                Text(AppLanguage.localized("progress.empty"))
                    .font(.title3)
            } else {
                Section {
                    ForEach(rates, id: \.game) { shareRow($0) }
                } header: {
                    Text(AppLanguage.localized("progress.share.header"))
                        .font(.title3.weight(.semibold))
                }

                ForEach(rates, id: \.game) { r in
                    Section {
                        ForEach(facts(r), id: \.self) { Text($0).font(.title3) }
                        ForEach(trends(r), id: \.text) { trendRow($0, ink: r.game.ink) }
                    } header: {
                        GameName(game: r.game)
                            .font(.title3.weight(.semibold))
                            .accessibilityAddTraits(.isHeader)
                    }
                }
            }
        }
        .navigationTitle(AppLanguage.localized("progress.title"))
        .toolbar {
            if !rates.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    ShareLink(item: shareText(rates)) {
                        Label(AppLanguage.localized("family.share"), systemImage: "square.and.arrow.up")
                            .font(.title3)
                            .labelStyle(.iconOnly)
                            .bigTapTarget()
                    }
                    .accessibilityHint(AppLanguage.localized("family.share.hint"))
                }
            }
        }
    }

    /// "Played this week": the game's part of the week, in words and a bar.
    private func shareRow(_ r: ProgressRates) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            GameName(game: r.game)
                .font(.title3.weight(.semibold))
            Text(shareLine(r))
                .font(.title3)
            ProgressView(value: r.share)
                .tint(r.game.ink)
                .accessibilityHidden(true)
        }
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
    }

    /// Up gets the up arrow; steady and an easier week both get the right
    /// arrow, and the words say which. Icon plus text, never colour alone.
    private func trendRow(_ trend: (up: Bool, text: String), ink: Color) -> some View {
        Label {
            Text(trend.text).font(.title3)
        } icon: {
            Image(systemName: trend.up ? "arrow.up.circle.fill" : "arrow.right.circle.fill")
                .font(.title2)
                // The game's own colour (Card Table); direction and words carry the meaning.
                .foregroundStyle(ink)
                .accessibilityHidden(true)
        }
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
    }

    private func shareLine(_ r: ProgressRates) -> String {
        String(format: AppLanguage.localized("progress.share %lld"), Int((r.share * 100).rounded()))
    }

    /// Days out of 7; then plays for a game with no accuracy, or accuracy per
    /// play and the level reached; then why there is no trend yet, if there isn't.
    private func facts(_ r: ProgressRates) -> [String] {
        var lines = [String(format: AppLanguage.localized("progress.days %lld"), r.daysPlayed)]
        guard r.accuracy != nil || r.level != nil else {
            // Interpolated so "1 time" / "3 times" picks its plural form.
            lines.append(AppLanguage.localized("progress.plays \(r.plays)" as String.LocalizationValue))
            return lines
        }
        if let accuracy = r.accuracy {
            lines.append(
                String(format: AppLanguage.localized("progress.accuracy %lld"), Int((accuracy * 100).rounded())))
        }
        if let level = r.level {
            lines.append(String(format: AppLanguage.localized("progress.level %@"), AppLanguage.localized(level.title)))
        }
        if r.plays < ProgressRates.minPlaysForTrend {
            lines.append(
                String(format: AppLanguage.localized("progress.trend.wait %lld"), ProgressRates.minPlaysForTrend))
        } else if r.accuracyTrend == nil && r.levelTrend == nil {
            lines.append(AppLanguage.localized("progress.trend.first"))
        }
        return lines
    }

    /// Each trend against the player's own earlier weeks. A level that stayed
    /// put says nothing; accuracy covers "about the same".
    private func trends(_ r: ProgressRates) -> [(up: Bool, text: String)] {
        var rows: [(up: Bool, text: String)] = []
        if let trend = r.levelTrend, trend != .steady, let level = r.level {
            let key = trend == .up ? "progress.trend.level.up %@" : "progress.trend.level.down %@"
            rows.append((trend == .up, String(format: AppLanguage.localized(key), AppLanguage.localized(level.title))))
        }
        if let trend = r.accuracyTrend {
            let key: String.LocalizationValue =
                switch trend {
                case .up: "progress.trend.accuracy.up"
                case .steady: "progress.trend.accuracy.steady"
                case .down: "progress.trend.accuracy.down"
                }
            rows.append((trend == .up, AppLanguage.localized(key)))
        }
        return rows
    }

    /// Plain text for WhatsApp/SMS/email: the same lines, one block per game.
    private func shareText(_ rates: [ProgressRates]) -> String {
        ([AppLanguage.localized("family.share.title")]
            + rates.map { r in
                ([
                    "\(r.game.emoji) \(AppLanguage.localized(r.game.title))", shareLine(r),
                ] + facts(r) + trends(r).map(\.text)).joined(separator: "\n")
            }).joined(separator: "\n\n")
    }
}

#Preview {
    NavigationStack {
        MyProgressView()
    }
    .modelContainer(for: GameSession.self, inMemory: true)
}
