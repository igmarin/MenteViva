import PhotosUI
import SwiftUI

/// Set up (#141): the per-game choices and the family photos, split from
/// My progress. Open on purpose (owner decision 2026-10-01): no lock, nothing
/// here can break play. Everything covers this device only.
struct SetUpView: View {
    var body: some View {
        List {
            Section {
                ForEach(GameID.released, id: \.self) { game in
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
        .listPageBackground()
        .navigationTitle(AppLanguage.localized("setup.title"))
    }
}

/// The photo a caption sheet is open for: a sheet needs an `Identifiable` item, a URL is not one.
struct CaptionTarget: Identifiable {
    let url: URL
    var id: URL { url }
}

/// The one way picked photos reach the album (#110, #120), shared by Set up and the first run
/// (#374), so both import, shrink and count photos the same way and `MemoryPhotos.add` has a
/// single caller.
enum FamilyPhotoImport {
    /// Loads what the picker handed over and adds it off the main actor. Returns what happened
    /// and the new photos, oldest first, so the first run can ask for each one's name in the
    /// order they were picked; nil when the task was cancelled mid-pick.
    static func run(_ items: [PhotosPickerItem]) async -> (result: MemoryPhotos.AddResult, added: [URL])? {
        var loaded: [Data?] = []
        for item in items {
            loaded.append(try? await item.loadTransferable(type: Data.self))
        }
        guard !Task.isCancelled else { return nil }
        // Decoding, shrinking and writing up to 24 photos stays off the main actor.
        let batch = loaded
        return await Task.detached {
            let before = Set(MemoryPhotos.all())
            let result = MemoryPhotos.add(batch)
            return (result, MemoryPhotos.all().filter { !before.contains($0) })
        }.value
    }
}

/// Family photos (#110, #374): picked with the system photo picker (no library
/// permission), kept on this device only. Tapping one opens its name sheet, where Remove asks first (#403).
private struct FamilyPhotosSection: View {
    @State private var photos: [URL]
    /// Captions by photo, read when the album changes, never inside `body`.
    @State private var captions: [URL: String]
    @State private var picked: [PhotosPickerItem] = []
    /// What the last pick did, in plain words (#120); cleared on Remove.
    @State private var note: String?
    /// The photo being named (#139).
    @State private var captioning: CaptionTarget?
    private let columns = [GridItem(.adaptive(minimum: 120), spacing: 12)]

    init() {
        let all = MemoryPhotos.all()
        _photos = State(initialValue: all)
        _captions = State(initialValue: Self.captions(for: all))
    }

    private static func captions(for photos: [URL]) -> [URL: String] {
        Dictionary(
            photos.compactMap { url in MemoryPhotos.caption(for: url).map { (url, $0) } },
            uniquingKeysWith: { first, _ in first })
    }

    private func reload() {
        photos = MemoryPhotos.all()
        captions = Self.captions(for: photos)
    }

    var body: some View {
        Section {
            if !photos.isEmpty {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(Array(photos.enumerated()), id: \.element) { index, url in
                        VStack(spacing: 6) {
                            PhotoThumb(url: url)
                            // Bordered style keeps each button separate inside one list row.
                            Button {
                                captioning = CaptionTarget(url: url)
                            } label: {
                                Text(captions[url] ?? AppLanguage.localized("family.photos.caption.add"))
                                    .font(.body)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.center)
                                    .frame(minWidth: 104, minHeight: 60)
                            }
                            .buttonStyle(.bordered)
                            .accessibilityLabel(
                                String(format: AppLanguage.localized("family.photos.caption.a11y %lld"), index + 1)
                            )
                            // The label says which photo; the value says the name it has now.
                            .accessibilityValue(captions[url] ?? "")
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
            Text(String(format: AppLanguage.localized("family.photos.footer %lld"), MemoryPhotos.maxCount))
                .font(.footnote)
        }
        .sheet(item: $captioning) { target in
            FamilyPhotoCaptionSheet(photo: target.url) {
                reload()
                note = nil
            }
        }
        // A task, not onChange + Task: it is cancelled if Set up goes away mid-pick.
        .task(id: picked) {
            let items = picked
            guard !items.isEmpty, let imported = await FamilyPhotoImport.run(items) else { return }
            reload()
            note = imported.result.note
            picked = []
            if let note { AccessibilityNotification.Announcement(note).post() }
        }
    }
}

/// One photo in the Set up grid, decoded off the main actor.
private struct PhotoThumb: View {
    let url: URL
    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Color.gray.opacity(0.12)
            }
        }
        .frame(width: 120, height: 120)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityHidden(true)
        .task(id: url) { image = await MemoryPhotos.image(at: url) }
    }
}

extension MemoryPhotos.AddResult {
    /// One warm line about the last pick; nil when nothing happened. Never
    /// "error" or "failed": a photo "couldn't be used" and the album "holds 24".
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
        return levelLine(game, pin: FamilySettings.pinnedLevel(pin))
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
    private var isLastVisible: Bool {
        let unplayable = hidden.union(GameAvailability.unavailable())
        return !unplayable.contains(game) && unplayable.count == GameID.released.count - 1
    }

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
                    Toggle(
                        AppLanguage.localized("family.difficulty.auto"),
                        isOn: Binding(
                            get: { pin == FamilySettings.auto },
                            set: { on in
                                pin = FamilySettings.settingAuto(
                                    on, from: pin, currentLevel: Difficulty.stored(game).level)
                            })
                    )
                    .font(.title3)
                    .frame(minHeight: 100)
                    if pin != FamilySettings.auto {
                        levelStepper
                    }
                } header: {
                    Text(AppLanguage.localized("family.difficulty")).font(.title3)
                } footer: {
                    Text(AppLanguage.localized("family.difficulty.footer")).font(.footnote)
                }
            }
        }
        .listPageBackground()
        .navigationTitle(AppLanguage.localized(game.title))
    }

    /// Big − / + around the level, one adjustable element for VoiceOver (swipe up/down changes it).
    /// At 1 and 10 the button is dimmed and a line says why, so the limit isn't colour only.
    private var levelStepper: some View {
        VStack(spacing: 8) {
            HStack(spacing: 16) {
                stepButton(delta: -1, symbol: "minus", label: "family.level.lower")
                Text(String(format: AppLanguage.localized("difficulty.level"), pin))
                    .font(.title2.weight(.semibold))
                    .frame(maxWidth: .infinity)
                stepButton(delta: 1, symbol: "plus", label: "family.level.higher")
            }
            if !FamilySettings.canStep(pin, by: 1) {
                Text(AppLanguage.localized("family.level.max")).font(.body)
            } else if !FamilySettings.canStep(pin, by: -1) {
                Text(AppLanguage.localized("family.level.min")).font(.body)
            }
        }
        .frame(minHeight: 100)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(AppLanguage.localized("family.difficulty"))
        .accessibilityValue(String(format: AppLanguage.localized("difficulty.level"), pin))
        .accessibilityAdjustableAction { direction in
            pin = FamilySettings.stepped(pin, by: direction == .increment ? 1 : -1)
        }
    }

    private func stepButton(delta: Int, symbol: String, label: String) -> some View {
        Button {
            pin = FamilySettings.stepped(pin, by: delta)
        } label: {
            Image(systemName: symbol)
                .font(.title.weight(.bold))
                .frame(width: 100, height: 100)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
                .opacity(FamilySettings.canStep(pin, by: delta) ? 1 : 0.3)
        }
        .buttonStyle(.plain)
        .disabled(!FamilySettings.canStep(pin, by: delta))
        .accessibilityLabel(AppLanguage.localized(label))
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
