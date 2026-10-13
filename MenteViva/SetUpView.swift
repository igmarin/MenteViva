import PhotosUI
import SwiftUI

/// Set up (#141): the per-game choices and the Memory Lane photos, split from
/// My progress. Open on purpose (owner decision 2026-10-01): no lock, nothing
/// here can break play. Everything covers this device only.
struct SetUpView: View {
    var body: some View {
        List {
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
        }
        .navigationTitle(AppLanguage.localized("setup.title"))
    }
}

private struct CaptionTarget: Identifiable {
    let url: URL
    var id: URL { url }
}

/// Memory Lane photos (#110): picked with the system photo picker (no library
/// permission), kept on this device only. Each has its own Remove button.
private struct FamilyPhotosSection: View {
    @State private var photos = MemoryPhotos.all()
    @State private var picked: [PhotosPickerItem] = []
    /// What the last pick did, in plain words (#120); cleared on Remove.
    @State private var note: String?
    /// The photo being named (#139).
    @State private var captioning: CaptionTarget?
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
                            Button {
                                captioning = CaptionTarget(url: url)
                            } label: {
                                Text(MemoryPhotos.caption(for: url) ?? AppLanguage.localized("family.photos.caption.add"))
                                    .font(.body)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.center)
                                    .frame(width: 104, height: 60)
                            }
                            .buttonStyle(.bordered)
                            .accessibilityLabel(
                                String(format: AppLanguage.localized("family.photos.caption.a11y %lld"), index + 1))
                        }
                    }
                }
                .padding(.vertical, 8)
            }
            if let note {
                Text(note)
                    .font(.body)
            }
            if photos.count < MemoryPhotos.maxCount {
                PhotosPicker(
                    selection: $picked, maxSelectionCount: MemoryPhotos.maxCount - photos.count,
                    matching: .images
                ) {
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
        .sheet(item: $captioning) { target in
            FamilyPhotoCaptionSheet(photo: target.url) {
                photos = MemoryPhotos.all()
                note = nil
            }
        }
        .onChange(of: picked) { _, items in
            guard !items.isEmpty else { return }
            Task {
                var datas: [Data?] = []
                for item in items {
                    datas.append(try? await item.loadTransferable(type: Data.self))
                }
                let result = MemoryPhotos.add(datas)
                picked = []
                photos = MemoryPhotos.all()
                note = result.note
                if let note { AccessibilityNotification.Announcement(note).post() }
            }
        }
    }
}

extension MemoryPhotos.AddResult {
    /// One warm line about the last pick; nil when nothing happened. Never
    /// "error" or "failed": a photo "couldn't be used" and the album "holds 8".
    var note: String? {
        var parts: [String] = []
        if added > 0 {
            parts.append(AppLanguage.localized("family.photos.added \(added)" as String.LocalizationValue))
        }
        if unreadable > 0 {
            parts.append(AppLanguage.localized("family.photos.unreadable \(unreadable)" as String.LocalizationValue))
        }
        if overLimit > 0 {
            parts.append(String(format: AppLanguage.localized("family.photos.full %lld"), MemoryPhotos.maxCount))
        }
        return parts.isEmpty ? nil : parts.joined(separator: " ")
    }
}

/// One game in the Set up list: name, then its level and whether it shows.
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
            GameName(game: game)
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
        guard game.hasLevels else { return AppLanguage.localized("family.game.nolevel") }
        return levelLine(game, pin: Difficulty(rawValue: pin))
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
                Toggle(
                    AppLanguage.localized("family.show"),
                    isOn: Binding(
                        get: { !hidden.contains(game) },
                        set: { show in
                            var games = hidden
                            if show { games.remove(game) } else { games.insert(game) }
                            hiddenGames = FamilySettings.csv(games)
                        })
                )
                .font(.title3)
                .frame(minHeight: 100)
                .disabled(isLastVisible)
            } footer: {
                if isLastVisible {
                    Text(AppLanguage.localized("family.show.last")).font(.footnote)
                }
            }

            if game.hasLevels {
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
        }
        .navigationTitle(AppLanguage.localized(game.title))
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

/// "Next game: Easy (set by you)": the level a game will use and who chose
/// it (#122).
private func levelLine(_ game: GameID, pin: Difficulty?) -> String {
    String(
        format: AppLanguage.localized("family.level %@ %@"),
        AppLanguage.localized((pin ?? Difficulty.stored(game)).title),
        AppLanguage.localized(pin == nil ? "family.auto" : "family.pinned"))
}

#Preview {
    NavigationStack {
        SetUpView()
    }
}
