import SwiftUI
import SwiftData

/// "For family" (#107): the numbers behind My Week, for the adult child.
/// Open on purpose (owner decision 2026-10-01): no lock, nothing here can break
/// play. Each game played in the last 14 days: this week against the week
/// before, the level the next game will use, and plain trend words — declines
/// included (Jev 012), worded kindly and never as a medical reading.
struct FamilyView: View {
    @Query(sort: \GameSession.playedAt, order: .reverse)
    private var sessions: [GameSession]

    private var progress: [GameProgress] { GameProgress.weekly(sessions) }

    var body: some View {
        List {
            Section {
                Text(AppLanguage.localized("family.intro"))
                    .font(.body)
            }

            if progress.isEmpty {
                Text(AppLanguage.localized("family.empty"))
                    .font(.title3)
            } else {
                ForEach(progress, id: \.game) { p in
                    Section {
                        ForEach(lines(for: p), id: \.self) { Text($0).font(.body) }
                    } header: {
                        Text(verbatim: "\(p.game.emoji) \(AppLanguage.localized(p.game.title))")
                            .font(.title3.weight(.semibold))
                            .accessibilityAddTraits(.isHeader)
                    }
                }
            }
        }
        .navigationTitle(AppLanguage.localized("family.title"))
        .toolbar {
            if !progress.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    ShareLink(item: shareText) {
                        Label(AppLanguage.localized("family.share"), systemImage: "square.and.arrow.up")
                            .font(.title3)
                            .labelStyle(.iconOnly)
                            .frame(minWidth: 100, minHeight: 100)
                            .contentShape(Rectangle())
                    }
                    .accessibilityHint(AppLanguage.localized("family.share.hint"))
                }
            }
        }
    }

    /// Level the next game will use, then this week, last week, and trends.
    private func lines(for p: GameProgress) -> [String] {
        var lines = [String(format: AppLanguage.localized("family.level %@ %@"),
                            AppLanguage.localized(Difficulty.stored(p.game).title),
                            AppLanguage.localized("family.auto")),
                     week("family.week.this %lld", p.sessions, p.accuracy),
                     week("family.week.last %lld", p.previousSessions, p.previousAccuracy)]
        if let from = p.previousLevel, let to = p.level, let trend = p.levelTrend, trend != .steady {
            lines.append(String(format: AppLanguage.localized(trend == .up ? "family.level.up %@ %@" : "family.level.down %@ %@"),
                                AppLanguage.localized(from.title), AppLanguage.localized(to.title)))
        }
        if let trend = p.accuracyTrend {
            lines.append(AppLanguage.localized(trend == .up ? "family.accuracy.up"
                                               : trend == .down ? "family.accuracy.down" : "family.accuracy.steady"))
        }
        return lines
    }

    private func week(_ key: String, _ count: Int, _ accuracy: Double?) -> String {
        let games = String(format: AppLanguage.localized(key), count)
        guard let accuracy else { return games }
        return games + " · " + String(format: AppLanguage.localized("family.right %lld"), Int((accuracy * 100).rounded()))
    }

    /// Plain text for WhatsApp/SMS/email: the same lines, one block per game.
    private var shareText: String {
        ([AppLanguage.localized("family.share.title")] + progress.map { p in
            "\(p.game.emoji) \(AppLanguage.localized(p.game.title))\n" + lines(for: p).joined(separator: "\n")
        }).joined(separator: "\n\n")
    }
}

extension Difficulty {
    var title: String.LocalizationValue {
        switch self {
        case .easy: "difficulty.easy"
        case .medium: "difficulty.medium"
        case .hard: "difficulty.hard"
        }
    }
}

#Preview {
    NavigationStack {
        FamilyView()
    }
    .modelContainer(for: GameSession.self, inMemory: true)
}
