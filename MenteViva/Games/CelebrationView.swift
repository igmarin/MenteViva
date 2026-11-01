import SwiftData
import SwiftUI

/// Shared end-of-game screen (Card Table, step 5): the game's card arrives on
/// the table stamped "Added to your week", then today's picture for the album
/// after the day's first game (#376), a warm headline, the progress line (never points, #45),
/// two big actions, then the week board with today's new card (the actions come first so they
/// stay on screen, #526). During today's games the main one names the next game; otherwise it
/// is "Play again". Presented as a fullScreenCover by every game on finish.
struct CelebrationView: View {
    let game: GameID
    let detail: String
    let onPlayAgain: () -> Void
    let onNext: (GameID) -> Void
    let onHome: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// This week's sessions, including the one just saved: every game records
    /// before celebrating.
    @Query(GameSession.thisWeek()) private var sessions: [GameSession]
    @AppStorage(FamilySettings.hiddenKey) private var hiddenGames = ""
    @State private var arrived = false
    /// This celebration's warm headline, picked once when it appears (#242).
    @State private var headline: String?
    /// Today's picture for the album, turned over only by the day's first finished game (#376).
    @State private var dailyPicture: GamePicture?
    /// Whether the offer has been answered in this presentation (#207): flipping
    /// this triggers a re-render so the offer disappears even though
    /// `LevelOfferStore` (UserDefaults) is not observed by SwiftUI.
    @State private var offerAnswered = false
    /// Whether the answer was Yes (#418): the offer is replaced by a line saying the level went up,
    /// so a tap never makes the question vanish without a word.
    @State private var offerAccepted = false
    /// Where the card must travel to reach today's slot on the week board; nil until both are
    /// measured. Frozen once the flight starts, so a layout change mid-flight cannot redirect the card (#421).
    @State private var landingOffset: CGSize?
    /// The card has started its flight to the slot (#421).
    @State private var flown = false
    /// The card has faded out, on the slot (or, under Reduce Motion, in place).
    @State private var faded = false
    /// The slot is showing that the card arrived: a short swell, or a steady highlight under Reduce Motion.
    @State private var landed = false

    /// Today's games from the plan saved for today; nil before there is one.
    private var today: TodayRun? {
        guard let plan = PlanStore.cachedPlan(), plan.dayStamp == PlanStore.dayStamp() else { return nil }
        return TodayRun(
            plan: plan.games, hidden: FamilySettings.hidden(from: hiddenGames).union(GameAvailability.unavailable()),
            sessions: sessions)
    }

    /// Offer context for #207 2: strong game, not pinned, below 10, once per day.
    /// The view only gathers the inputs; `LevelExplainPolicy.shouldOffer` decides.
    private var shouldShowOffer: Bool {
        guard !offerAnswered else { return false }
        let todaySessions = sessions.filter { $0.game == game && Calendar.current.isDate($0.playedAt, inSameDayAs: .now) }
        guard let last = todaySessions.max(by: { $0.playedAt < $1.playedAt }) else { return false }
        return LevelExplainPolicy.shouldOffer(
            accuracy: last.accuracy, game: game,
            level: last.resolvedLevel ?? PlanStore.storedDifficulty()[game] ?? Difficulty(level: 4),
            isPinned: FamilySettings.pinned()[game] != nil,
            alreadyOfferedToday: LevelOfferStore.hasOfferedToday(for: game, today: PlanStore.dayStamp()))
    }

    /// What replaces the offer after Yes: the same words the level explanation uses for a raise.
    private var raisedLine: some View {
        Text(AppLanguage.localized("level.explain.raised1"))
            .font(.title2)
            .multilineTextAlignment(.center)
            .padding(.vertical, 8)
    }

    private var offerSection: some View {
        VStack(spacing: 12) {
            Text(AppLanguage.localized("level.offer.prompt"))
                .font(.title2.weight(.semibold))
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)
            HStack(spacing: 12) {
                Button {
                    // A double tap reaches here twice; `applyChosen` itself allows one raise a day.
                    guard !offerAnswered else { return }
                    offerAnswered = true
                    offerAccepted = true
                    let today = PlanStore.dayStamp()
                    LevelOfferStore.applyChosen(for: game, today: today)
                    LevelOfferStore.markOffered(for: game, today: today)
                    Feedback.play(.success)
                    AccessibilityNotification.Announcement(AppLanguage.localized("level.explain.raised1")).post()
                } label: {
                    Text(AppLanguage.localized("level.offer.yes")).font(.title2.weight(.semibold))
                }
                // Outlined, so the next action below stays the one filled button (#526).
                .buttonStyle(AnswerTileStyle(strength: 0.08, minHeight: 100))
                .accessibilityLabel(AppLanguage.localized("level.offer.yes"))
                Button {
                    offerAnswered = true
                    LevelOfferStore.markOffered(for: game, today: PlanStore.dayStamp())
                    Feedback.play(.success)
                } label: {
                    Text(AppLanguage.localized("level.offer.keep")).outlineButton()
                }
                .buttonStyle(.plain)
                .accessibilityLabel(AppLanguage.localized("level.offer.keep"))
            }
        }
        .padding(.vertical, 8)
    }

    /// The "n of m today" capsule. When this game closed the table it wears the amber seal, a shape
    /// and a colour together, so the finish never rests on colour alone.
    private func progressCapsule(_ today: TodayRun, closesTheDay: Bool) -> some View {
        HStack(spacing: 8) {
            if closesTheDay {
                Image(systemName: "checkmark.seal.fill").accessibilityHidden(true)
            }
            Text(
                String(
                    format: AppLanguage.localized("game.celebration.today %lld %lld"),
                    today.done.count, today.games.count))
        }
        .font(.headline.weight(.heavy))
        .foregroundStyle(closesTheDay ? Color.onAmber : Color.primary)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(closesTheDay ? Color.amber : Color.paper, in: .capsule)
        .overlay(Capsule().strokeBorder(Color.espresso, lineWidth: 2))
    }

    private var closesTheDay: Bool { today?.closesTheDay(finishing: game) ?? false }

    var body: some View {
        let today = today
        VStack(spacing: 0) {
            VStack(spacing: 22) {
                if let today, today.games.contains(game) {
                    progressCapsule(today, closesTheDay: closesTheDay)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 24)
            // The card hangs below the capsule and reserves no room, so the sheet never moves and its
            // buttons stay put under the finger; for its short rest it floats over the sheet's top (#526).
            // Hit testing is off: it is only a picture, and opacity 0 would not stop it catching taps.
            .overlay(alignment: .top) {
                VStack(spacing: 22) {
                    // Invisible twin of the capsule, so the card sits where it did at any text size.
                    if let today, today.games.contains(game) {
                        progressCapsule(today, closesTheDay: closesTheDay).hidden()
                    }
                    card
                }
                .padding(.top, 24)
                .allowsHitTesting(false)
            }
            // Above the paper sheet below, so the card flies over it to the week board instead of behind it.
            .zIndex(1)

            Spacer(minLength: 0)

            VStack(spacing: 14) {
                if let dailyPicture {
                    DailyPictureCard(picture: dailyPicture)
                }
                // Picked in onAppear; until then nothing, so VoiceOver never lands on an empty header.
                if let headline {
                    Text(headline)
                        .font(.largeTitle.bold())
                        .fontDesign(.serif)
                        .multilineTextAlignment(.center)
                        .accessibilityAddTraits(.isHeader)
                }
                Text(detail)
                    .font(.title2.weight(.semibold))
                    .multilineTextAlignment(.center)
                if offerAccepted {
                    raisedLine
                } else if shouldShowOffer {
                    offerSection
                }
                // Before the week board: the next step is always on screen, never below the fold (#526).
                actions(next: today?.next(after: game))
                WeekBoard(
                    days: DayGrouping.thisWeek(sessions, date: \.playedAt).map {
                        (day: $0.day, games: $0.items.compactMap(\.game))
                    },
                    landed: landed
                )
                .padding(.vertical, 6)
            }
            .padding(24)
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
            .background {
                UnevenRoundedRectangle(topLeadingRadius: 36, topTrailingRadius: 36)
                    .fill(Color.paper)
                    .ignoresSafeArea(edges: .bottom)
            }
        }
        .fitOrScroll()
        // The sheet's paper continues under the home indicator.
        .background(alignment: .bottom) {
            Color.paper.frame(height: 200).ignoresSafeArea(edges: .bottom)
        }
        .background(.table)
        // Reads the card's and today's slot's frames in one space, so the flight is one vector.
        .overlayPreferenceValue(LandingTargets.self) { targets in
            GeometryReader { proxy in
                let offset = offsetToSlot(targets, in: proxy)
                Color.clear
                    .onChange(of: offset, initial: true) { _, new in
                        if !flown { landingOffset = new }
                    }
            }
            .allowsHitTesting(false)
        }
        .task { await landOnTheWeek() }
        .onAppear {
            if headline == nil {
                var generator = SystemRandomNumberGenerator()
                headline = CelebrationHeadline.pick(closesTheDay: closesTheDay, using: &generator)
                dailyPicture = PictureAlbum.turnOver(
                    from: DailyPicture.candidates(from: GamePictures.all, hasAsset: PictureView.bundleHasAsset))
                // Only the day-done line and today's picture are spoken on arrival, as one announcement so
                // neither cuts the other off; the ordinary headlines stay a header to swipe to.
                let pictureLine = dailyPicture.map { DailyPictureCard.line(for: $0) }
                let spoken = [closesTheDay ? headline : nil, pictureLine].compactMap { $0 }
                if !spoken.isEmpty { AccessibilityNotification.Announcement(spoken.joined(separator: " ")).post() }
            }
            Feedback.play(.complete)
            withAnimation(.spring(duration: 0.55, bounce: 0.3).delay(0.1)) { arrived = true }
        }
    }

    /// How far the card must move to sit on today's slot, or nil when either is not on screen.
    private func offsetToSlot(_ targets: LandingTargets, in proxy: GeometryProxy) -> CGSize? {
        guard let card = targets.card, let slot = targets.slot else { return nil }
        return CardLanding.offset(from: proxy[card], to: proxy[slot], tiltedBy: Self.cardTilt)
    }

    /// The card rests, then shrinks onto today's slot and the slot answers (#421). After the arrival
    /// spring and a hold so the caption can be read. Under Reduce Motion the card cross-fades out
    /// where it is and the slot is highlighted. The stamp leaves with the card; VoiceOver still
    /// hears the card's fixed label.
    private func landOnTheWeek() async {
        let arrival = reduceMotion ? 0 : 0.65
        try? await Task.sleep(for: .seconds(arrival + CardLanding.hold))
        guard !Task.isCancelled, landingOffset != nil else { return }
        if reduceMotion {
            withAnimation(.easeOut(duration: 0.3)) { faded = true }
            landed = true
            return
        }
        withAnimation(.easeInOut(duration: CardLanding.flight)) { flown = true }
        // Fades only over the last part of the flight, so the card is seen arriving.
        withAnimation(.easeIn(duration: 0.25).delay(CardLanding.flight * 0.7)) { faded = true }
        try? await Task.sleep(for: .seconds(CardLanding.flight))
        guard !Task.isCancelled else { return }
        landed = true
        try? await Task.sleep(for: .seconds(0.4))
        landed = false
    }

    private static let cardTilt = -4.0

    /// The finished game's card, stamped and tilted as it lands on the table.
    private var card: some View {
        GameCard(game: game)
            .frame(width: 190)
            // Measured before the flight moves it, so the vector starts from where it rests.
            .anchorPreference(key: LandingTargets.self, value: .bounds) { LandingTargets(card: $0) }
            .scaleEffect(flown && !reduceMotion ? CardLanding.shrink : 1)
            .offset(flown && !reduceMotion ? (landingOffset ?? .zero) : .zero)
            .opacity(faded ? 0 : 1)
            .overlay(alignment: .bottom) {
                Text(AppLanguage.localized("game.celebration.added"))
                    .font(.headline.weight(.heavy))
                    .foregroundStyle(Color.onAmber)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .background(Color.amber, in: .rect(cornerRadius: 12))
                    .fixedSize()
                    .rotationEffect(.degrees(6))
                    // Below the name band, never over it: the name says which game.
                    .offset(y: 40)
                    // Lifts away as the card sets off: with no room of its own it would sit over the headline.
                    .opacity(flown || faded ? 0 : 1)
            }
            .rotationEffect(.degrees(Self.cardTilt))
            .scaleEffect(arrived || reduceMotion ? 1 : 0.8)
            .opacity(arrived || reduceMotion ? 1 : 0)
            .accessibilityElement(children: .combine)
            // Fixed, so the name is still spoken after the card fades out (opacity 0 drops its text).
            .accessibilityLabel(
                Text(
                    AppLanguage.localized(game.title) + ", "
                        + AppLanguage.localized("game.celebration.added")))
    }

    private func actions(next: GameID?) -> some View {
        VStack(spacing: 12) {
            if let next {
                Button {
                    onNext(next)
                } label: {
                    Label(
                        String(
                            format: AppLanguage.localized("game.celebration.next %@"),
                            AppLanguage.localized(next.title)),
                        systemImage: "arrow.forward"
                    )
                    .labelStyle(.titleAndIcon)
                }
                .buttonStyle(RetroButtonStyle())
            } else {
                Button(action: onPlayAgain) {
                    Text(AppLanguage.localized("game.celebration.playagain"))
                }
                .buttonStyle(RetroButtonStyle())
            }
            Button(action: onHome) {
                Text(AppLanguage.localized("game.celebration.home")).outlineButton()
            }
            .buttonStyle(.plain)
        }
    }
}

extension View {
    /// The shared end-of-session screen (#45): progress, never points.
    func celebration(
        isPresented: Binding<Bool>, game: GameID, detail: String,
        onPlayAgain: @escaping () -> Void
    ) -> some View {
        modifier(CelebrationCover(isPresented: isPresented, game: game, detail: detail, onPlayAgain: onPlayAgain))
    }

    /// The quieter 100pt action beside a `RetroButtonStyle` one: an espresso outline with a blue label.
    fileprivate func outlineButton() -> some View {
        font(.title2.weight(.semibold))
            .foregroundStyle(Color.fadedBlue)
            .frame(maxWidth: .infinity, minHeight: 100)
            .overlay { RoundedRectangle(cornerRadius: 20).strokeBorder(Color.espresso, lineWidth: 2) }
            .contentShape(Rectangle())
    }
}

private struct CelebrationCover: ViewModifier {
    @Environment(\.dismiss) private var dismiss
    /// Home's open games; nil anywhere else (previews), where "Next" just closes.
    @Environment(GamePath.self) private var path: GamePath?
    @Binding var isPresented: Bool
    let game: GameID
    let detail: String
    let onPlayAgain: () -> Void
    @State private var exit = CelebrationExit()

    func body(content: Content) -> some View {
        content.fullScreenCover(isPresented: $isPresented, onDismiss: runPending) {
            CelebrationView(
                game: game,
                detail: detail,
                onPlayAgain: {
                    exit.choose(.playAgain)
                    isPresented = false
                },
                onNext: { next in
                    exit.choose(.next(next))
                    isPresented = false
                },
                onHome: {
                    isPresented = false
                    dismiss()
                })
        }
    }

    private func runPending() {
        switch exit.coverClosed() {
        case .playAgain: onPlayAgain()
        case .next(let next): path?.games = [next]
        case nil: break
        }
    }
}

/// What the celebration's buttons asked for, carried out only once the cover is gone (#415).
/// "Play again" dealing under the closing cover started a timed or announced round there, and
/// the game's `.onAppear`, which fires again as the cover leaves, then dealt a second one.
/// "Next" changing the path mid-dismissal would remove the game while it still presents.
nonisolated struct CelebrationExit: Equatable {
    enum Action: Equatable {
        case playAgain
        case next(GameID)
    }

    private(set) var pending: Action?

    mutating func choose(_ action: Action) {
        pending = action
    }

    /// The chosen action, once: a later dismissal (Home, a swipe) finds nothing to run.
    mutating func coverClosed() -> Action? {
        defer { pending = nil }
        return pending
    }
}

/// Non-color cue for found/picked tiles: a solid checkmark in the game's ink, readable on any tint
/// (WCAG 1.4.1, conventions.md §4).
struct CheckBadge: View {
    var body: some View {
        Image(systemName: "checkmark.circle.fill")
            .font(.title2)
            // The game's ink behind a paper-coloured tick: 3:1+ in both modes.
            .foregroundStyle(Color.paper, .tint)
            .padding(6)
            .accessibilityHidden(true)
    }
}

#Preview {
    CelebrationView(game: .memoryMatch, detail: "You found all 8 pairs!", onPlayAgain: {}, onNext: { _ in }, onHome: {})
        .modelContainer(for: GameSession.self, inMemory: true)
}
