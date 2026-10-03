import SwiftUI
import SwiftData
import PhotosUI

/// "For family" (#107, #108): the numbers behind My Week and the per-game
/// choices, for the adult child. Open on purpose (owner decision 2026-10-01):
/// no lock, nothing here can break play. Everything covers this device only.
/// Each game played in the last 14 days: this week against the week before,
/// the level the next game will use, and plain trend words — declines included
/// (Jev 012), worded kindly and never as a medical reading.
struct FamilyView: View {
    @Query(sort: \GameSession.playedAt, order: .reverse)
    private var sessions: [GameSession]

    private var progress: [GameProgress] { GameProgress.weekly(sessions) }
    /// Kept in state so a level changed on a game's screen shows here on the
    /// way back (#124); refreshed whenever this device's settings change.
    @State private var pinned = FamilySettings.pinned()

    var body: some View {
        List {
            Section {
                Text(AppLanguage.localized("family.intro"))
                    .font(.body)
            }

            Section {
                ForEach(GameID.allCases, id: \.self) { game in
                    NavigationLink {
                        FamilyGameView(game: game)
                    } label: {
                        FamilyGameRow(game: game)
                    }
                    .accessibilityHint(AppLanguage.localized("family.game.hint"))
                }
            } header: {
                Text(AppLanguage.localized("family.games.header"))
                    .font(.title3.weight(.semibold))
            } footer: {
                Text(AppLanguage.localized("family.games.footer"))
                    .font(.footnote)
            }

            FamilyPhotosSection()

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
        .task {
            for await _ in NotificationCenter.default.notifications(named: UserDefaults.didChangeNotification) {
                pinned = FamilySettings.pinned()
            }
        }
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
                            AppLanguage.localized((pinned[p.game] ?? Difficulty.stored(p.game)).title),
                            AppLanguage.localized(pinned[p.game] == nil ? "family.auto" : "family.pinned")),
                     // Interpolated so "1 game" / "3 games" picks its plural form.
                     week(AppLanguage.localized("family.week.this \(p.sessions)" as String.LocalizationValue), p.accuracy),
                     week(AppLanguage.localized("family.week.last \(p.previousSessions)" as String.LocalizationValue),
                          p.previousAccuracy)]
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

    private func week(_ games: String, _ accuracy: Double?) -> String {
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

/// Memory Lane photos (#110): picked with the system photo picker (no library
/// permission), kept on this device only. Each has its own Remove button.
private struct FamilyPhotosSection: View {
    @State private var photos = MemoryPhotos.all()
    @State private var picked: [PhotosPickerItem] = []
    private let columns = [GridItem(.adaptive(minimum: 120), spacing: 12)]

    var body: some View {
        Section {
            if !photos.isEmpty {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(Array(photos.enumerated()), id: \.element) { index, url in
                        VStack(spacing: 6) {
                            if let image = UIImage(contentsOfFile: url.path) {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 120, height: 120)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .accessibilityHidden(true)
                            }
                            // Bordered style keeps each button separate inside one list row.
                            Button(role: .destructive) {
                                MemoryPhotos.remove(url)
                                photos = MemoryPhotos.all()
                            } label: {
                                Text(AppLanguage.localized("family.photos.remove"))
                                    .font(.body)
                                    .frame(width: 104, height: 60)
                            }
                            .buttonStyle(.bordered)
                            .accessibilityLabel(String(format: AppLanguage.localized("family.photos.remove.a11y %lld"), index + 1))
                        }
                    }
                }
                .padding(.vertical, 8)
            }
            if photos.count < MemoryPhotos.maxCount {
                PhotosPicker(selection: $picked, maxSelectionCount: MemoryPhotos.maxCount - photos.count,
                             matching: .images) {
                    Label(AppLanguage.localized("family.photos.add"), systemImage: "photo.on.rectangle.angled")
                        .font(.title3)
                        .frame(maxWidth: .infinity, minHeight: 100, alignment: .leading)
                }
            }
        } header: {
            Text(AppLanguage.localized("family.photos.header"))
                .font(.title3.weight(.semibold))
        } footer: {
            Text(AppLanguage.localized("family.photos.footer"))
                .font(.footnote)
        }
        .onChange(of: picked) { _, items in
            guard !items.isEmpty else { return }
            Task {
                for item in items {
                    if let data = try? await item.loadTransferable(type: Data.self) {
                        try? MemoryPhotos.add(data)
                    }
                }
                picked = []
                photos = MemoryPhotos.all()
            }
        }
    }
}

/// One game in the family list: name, then its level and whether it shows.
private struct FamilyGameRow: View {
    let game: GameID
    @AppStorage private var pin: Int
    @AppStorage(FamilySettings.hiddenKey) private var hiddenGames = ""

    init(game: GameID) {
        self.game = game
        _pin = AppStorage(wrappedValue: FamilySettings.auto, FamilySettings.pinKey(game))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(verbatim: "\(game.emoji) \(AppLanguage.localized(game.title))")
                .font(.title3.weight(.semibold))
            Text(status)
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 100, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private var status: String {
        if FamilySettings.hidden(from: hiddenGames).contains(game) {
            return AppLanguage.localized("family.hidden")
        }
        let level = Difficulty(rawValue: pin) ?? Difficulty.stored(game)
        return String(format: AppLanguage.localized("family.level %@ %@"),
                      AppLanguage.localized(level.title),
                      AppLanguage.localized(pin == FamilySettings.auto ? "family.auto" : "family.pinned"))
    }
}

/// One game's choices: show it on Home, and Automatic or a fixed level.
/// 100pt rows with a checkmark, same pattern as the language picker.
private struct FamilyGameView: View {
    let game: GameID
    @AppStorage private var pin: Int
    @AppStorage(FamilySettings.hiddenKey) private var hiddenGames = ""

    init(game: GameID) {
        self.game = game
        _pin = AppStorage(wrappedValue: FamilySettings.auto, FamilySettings.pinKey(game))
    }

    private var hidden: Set<GameID> { FamilySettings.hidden(from: hiddenGames) }
    /// The last game on Home can't be hidden: the app must always have one to play.
    private var isLastVisible: Bool { !hidden.contains(game) && hidden.count == GameID.allCases.count - 1 }

    var body: some View {
        List {
            Section {
                Toggle(AppLanguage.localized("family.show"), isOn: Binding(
                    get: { !hidden.contains(game) },
                    set: { show in
                        var games = hidden
                        if show { games.remove(game) } else { games.insert(game) }
                        hiddenGames = FamilySettings.csv(games)
                    }))
                    .font(.title3)
                    .frame(minHeight: 100)
                    .disabled(isLastVisible)
            } footer: {
                if isLastVisible {
                    Text(AppLanguage.localized("family.show.last")).font(.footnote)
                }
            }

            Section {
                choice(FamilySettings.auto, AppLanguage.localized("family.difficulty.auto"))
                ForEach([Difficulty.easy, .medium, .hard], id: \.self) { level in
                    choice(level.rawValue, AppLanguage.localized(level.title))
                }
            } header: {
                Text(AppLanguage.localized("family.difficulty")).font(.title3)
            } footer: {
                Text(AppLanguage.localized("family.difficulty.footer")).font(.footnote)
            }
        }
        .navigationTitle(Text(verbatim: "\(game.emoji) \(AppLanguage.localized(game.title))"))
    }

    private func choice(_ value: Int, _ label: String) -> some View {
        Button {
            pin = value
        } label: {
            HStack {
                Text(label).font(.title3)
                Spacer()
                if pin == value {
                    Image(systemName: "checkmark").accessibilityHidden(true)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 100, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(pin == value ? [.isSelected] : [])
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
