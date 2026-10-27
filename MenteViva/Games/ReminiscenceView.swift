import SwiftData
import SwiftUI

/// Remember Together (#139): the family's photos one at a time, "Who is this?",
/// and a tap on "Show me" reveals the name that helps remember. Nothing can be
/// answered wrongly. With no photos it shows everyday objects instead.
struct ReminiscenceView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var cards: [ReminiscenceCard] = []
    @State private var progress = RoundProgress(totalRounds: 0)
    @State private var revealed = false
    @State private var startedAt = Date.now
    @State private var showCelebration = false
    @State private var finalDetail = ""

    private var card: ReminiscenceCard? {
        cards.indices.contains(progress.completedRounds) ? cards[progress.completedRounds] : nil
    }

    var body: some View {
        VStack(spacing: 20) {
            if let card {
                RoundCounter(progress: progress)
                picture(of: card)
                    .frame(maxWidth: .infinity, minHeight: 160, maxHeight: .infinity)
                if revealed, let caption = card.caption {
                    Text(caption)
                        .font(.largeTitle.weight(.semibold))
                        .multilineTextAlignment(.center)
                        .accessibilityAddTraits(.isHeader)
                } else {
                    Text(AppLanguage.localized(prompt(for: card)))
                        .font(.title)
                        .multilineTextAlignment(.center)
                }
                controls(for: card)
            }
        }
        .padding()
        .fitOrScroll()
        .gameHeader(.reminiscence, instruction: card.map { AppLanguage.localized(prompt(for: $0)) } ?? "")
        .onAppear(perform: deal)
        .celebration(isPresented: $showCelebration, game: .reminiscence, detail: finalDetail, onPlayAgain: deal)
    }

    // MARK: - Pieces

    @ViewBuilder
    private func picture(of card: ReminiscenceCard) -> some View {
        let label = revealed ? card.caption : nil
        switch card.picture {
        case .photo(let url):
            PhotoCard(url: url)
                .id(card.id)
                .accessibilityLabel(label ?? AppLanguage.localized("game.reminiscence.a11y.photo"))
        case .symbol(let name):
            Image(systemName: name)
                .font(.system(size: 120))
                .foregroundStyle(.secondary)
                .accessibilityLabel(label ?? AppLanguage.localized("game.reminiscence.a11y.object"))
        }
    }

    private func prompt(for card: ReminiscenceCard) -> String {
        guard card.caption != nil else { return "game.reminiscence.together" }
        if case .photo = card.picture { return "game.reminiscence.prompt.photo" }
        return "game.reminiscence.prompt.object"
    }

    @ViewBuilder
    private func controls(for card: ReminiscenceCard) -> some View {
        if let caption = card.caption, !revealed {
            Button {
                reveal(caption)
            } label: {
                bigLabel("game.reminiscence.show")
            }
            .buttonStyle(AnswerTileStyle(minHeight: 100))
        } else {
            HStack(spacing: 12) {
                if let caption = card.caption {
                    Button {
                        CaptionSpeaker.speak(caption)
                    } label: {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.title)
                            .frame(minWidth: 100, minHeight: 100)
                    }
                    .buttonStyle(AnswerTileStyle(minHeight: 100))
                    .fixedSize(horizontal: true, vertical: false)
                    .accessibilityLabel(AppLanguage.localized("game.reminiscence.hear"))
                }
                Button(action: next) { bigLabel("game.reminiscence.next") }
                    .buttonStyle(AnswerTileStyle(minHeight: 100))
            }
        }
    }

    private func bigLabel(_ key: String) -> some View {
        Text(AppLanguage.localized(key)).font(.title2.weight(.semibold))
    }

    // MARK: - Flow

    private func reveal(_ caption: String) {
        revealed = true
        Feedback.play(.tap)
        if CaptionSpeaker.autoSpeaks() {
            CaptionSpeaker.speak(caption)
        } else if UIAccessibility.isVoiceOverRunning {
            AccessibilityNotification.Announcement(caption).post()
        }
    }

    private func next() {
        CaptionSpeaker.stop()
        revealed = false
        Feedback.play(.tap)
        if progress.completeRound() { finish() }
    }

    private func deal() {
        HotPath.measure("reminiscence.deal") { dealCards() }
    }

    /// Reads the album and one caption file per photo: main-thread file I/O,
    /// the same shape as Memory Lane's deal. See docs/profiling.md.
    private func dealCards() {
        let photos = MemoryPhotos.all()
        let captions = Dictionary(
            uniqueKeysWithValues: photos.compactMap { url in
                MemoryPhotos.caption(for: url).map { (url, $0) }
            })
        var generator = SystemRandomNumberGenerator()
        cards = ReminiscenceDeck.dealSession(photos: photos, captions: captions, using: &generator)
        progress = RoundProgress(totalRounds: cards.count)
        revealed = false
        startedAt = .now
    }

    private func finish() {
        let elapsed = Int(Date.now.timeIntervalSince(startedAt))
        modelContext.record(Self.makeSession(cards: cards.count, seconds: elapsed))
        finalDetail = AppLanguage.localized("game.celebration.reminiscence \(cards.count)" as String.LocalizationValue)
        showCelebration = true
    }

    /// No accuracy: a look-and-remember round has no right or wrong, so it
    /// counts toward plays and days only (never toward levels or trends).
    static func makeSession(cards: Int, seconds: Int) -> GameSession {
        GameSession(gameID: .reminiscence, score: 0, rounds: cards, durationSeconds: seconds)
    }
}

/// One family photo, loaded once per card.
private struct PhotoCard: View {
    let url: URL
    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 18))
            } else {
                Image(systemName: "photo").font(.system(size: 80)).foregroundStyle(.secondary)
            }
        }
        .task { image = await HotPath.measure("reminiscence.photo") { await MemoryPhotos.image(at: url) } }
    }
}

#Preview {
    NavigationStack { ReminiscenceView() }
        .modelContainer(for: GameSession.self, inMemory: true)
}
