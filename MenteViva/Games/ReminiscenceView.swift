import SwiftData
import SwiftUI

/// Photo Stories (#139, renamed #513): the family's photos one at a time, "Tell a story
/// about this photo", and a tap on "Show me" reveals the name that helps remember. Nothing
/// can be answered wrongly. It is only dealt once photos are added (`GameAvailability`); the
/// everyday-object cards stay in the deck, but nothing reaches them.
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
                    VStack(spacing: 8) {
                        Text(caption)
                            .font(.largeTitle.weight(.semibold))
                            .accessibilityAddTraits(.isHeader)
                        if let question = card.question {
                            Text(AppLanguage.localized(question))
                                .font(.title2)
                                .foregroundStyle(Color.inkSoft)
                        }
                    }
                    .multilineTextAlignment(.center)
                } else {
                    Text(AppLanguage.localized(card.promptKey))
                        .font(.title)
                        .multilineTextAlignment(.center)
                }
                controls(for: card)
            }
        }
        .gameColumn()
        .padding()
        .fitOrScroll()
        .gameHeader(.reminiscence, instruction: card.map { AppLanguage.localized($0.promptKey) } ?? "")
        // Not when the celebration closes: Play again has dealt already (#415).
        .onAppear { if cards.isEmpty { deal() } }
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
        case .object(let object):
            objectPicture(object)
                .accessibilityLabel(label ?? AppLanguage.localized("game.reminiscence.a11y.object"))
        }
    }

    /// Our picture of the object once its art ships (#324), its SF Symbol until then.
    @ViewBuilder
    private func objectPicture(_ object: EverydayObject) -> some View {
        if case .asset(let name) = object.picture.look(hasAsset: PictureView.bundleHasAsset) {
            Image(name)
                .resizable()
                .scaledToFit()
                .frame(width: 160, height: 160)
        } else {
            Image(systemName: object.symbol)
                .font(.system(size: 120))
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private func controls(for card: ReminiscenceCard) -> some View {
        if let caption = card.caption, !revealed {
            Button {
                reveal(caption, question: card.question)
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

    /// VoiceOver hears the name and the question in one announcement (#379).
    /// "Speak names" reads only the name, as it always has; the question stays on screen.
    private func reveal(_ caption: String, question: String?) {
        revealed = true
        Feedback.play(.tap)
        if CaptionSpeaker.autoSpeaks() {
            CaptionSpeaker.speak(caption)
        } else if UIAccessibility.isVoiceOverRunning {
            let spoken = question.map { "\(caption). \(AppLanguage.localized($0))" } ?? caption
            AccessibilityNotification.Announcement(spoken).post()
        }
    }

    private func next() {
        CaptionSpeaker.stop()
        revealed = false
        Feedback.play(.tap)
        if progress.completeRound() {
            finish()
        } else if let card {
            // The card and its buttons are replaced, so VoiceOver focus jumps and the new
            // prompt would not be read (#391).
            AccessibilityNotification.Announcement(AppLanguage.localized(card.promptKey)).post()
        }
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
        GameSession(gameID: .reminiscence, rounds: cards, durationSeconds: seconds)
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
