import SwiftData
import SwiftUI

/// Shared end-of-game screen (Card Table, step 5): the game's card arrives on
/// the table stamped "Added to your week", then a warm headline, the progress
/// line (never points, #45), the week board with today's new card, and two big
/// actions. During today's games the main one names the next game; otherwise
/// it is "Play again". Presented as a fullScreenCover by every game on finish.
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
    /// Whether the offer has been answered in this presentation (#207): flipping
    /// this triggers a re-render so the offer disappears even though
    /// `LevelOfferStore` (UserDefaults) is not observed by SwiftUI.
    @State private var offerAnswered = false

    /// Today's games from the plan saved for today; nil before there is one.
    private var today: TodayRun? {
        guard let plan = PlanStore.cachedPlan(), plan.dayStamp == PlanStore.dayStamp() else { return nil }
        return TodayRun(plan: plan.games, hidden: FamilySettings.hidden(from: hiddenGames), sessions: sessions)
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
                    let today = PlanStore.dayStamp()
                    LevelOfferStore.applyChosen(for: game, today: today)
                    LevelOfferStore.markOffered(for: game, today: today)
                    Feedback.play(.success)
                } label: {
                    Text(AppLanguage.localized("level.offer.yes"))
                        .font(.title2.weight(.semibold))
                        .frame(maxWidth: .infinity, minHeight: 100)
                        .background(Color.brand, in: .rect(cornerRadius: 20))
                        .foregroundStyle(Color.paper)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(AppLanguage.localized("level.offer.yes"))
                Button {
                    offerAnswered = true
                    LevelOfferStore.markOffered(for: game, today: PlanStore.dayStamp())
                    Feedback.play(.success)
                } label: {
                    Text(AppLanguage.localized("level.offer.keep"))
                        .font(.title2.weight(.semibold))
                        .frame(maxWidth: .infinity, minHeight: 100)
                        .background(Color.clear, in: .rect(cornerRadius: 20))
                        .overlay { RoundedRectangle(cornerRadius: 20).strokeBorder(Color.espresso, lineWidth: 2) }
                        .foregroundStyle(Color.fadedBlue)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(AppLanguage.localized("level.offer.keep"))
            }
        }
        .padding(.vertical, 8)
    }

    var body: some View {
        let today = today
        VStack(spacing: 0) {
            VStack(spacing: 22) {
                if let today, today.games.contains(game) {
                    Text(
                        String(
                            format: AppLanguage.localized("game.celebration.today %lld %lld"),
                            today.done.count, today.games.count)
                    )
                    .font(.headline.weight(.heavy))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.paper, in: .capsule)
                    .overlay(Capsule().strokeBorder(Color.espresso, lineWidth: 2))
                }
                card
            }
            .padding(.top, 24)
            .padding(.bottom, 60)

            Spacer(minLength: 0)

            VStack(spacing: 14) {
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
                if shouldShowOffer {
                    offerSection
                }
                WeekBoard(
                    days: DayGrouping.thisWeek(sessions, date: \.playedAt).map {
                        (day: $0.day, games: $0.items.compactMap(\.game))
                    }
                )
                .padding(.vertical, 6)
                actions(next: today?.next(after: game))
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
        .onAppear {
            if headline == nil {
                var generator = SystemRandomNumberGenerator()
                headline = CelebrationHeadline.pick(using: &generator)
            }
            Feedback.play(.complete)
            withAnimation(.spring(duration: 0.55, bounce: 0.3).delay(0.1)) { arrived = true }
        }
    }

    /// The finished game's card, stamped and tilted as it lands on the table.
    private var card: some View {
        GameCard(game: game)
            .frame(width: 190)
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
            }
            .rotationEffect(.degrees(-4))
            .scaleEffect(arrived || reduceMotion ? 1 : 0.8)
            .opacity(arrived || reduceMotion ? 1 : 0)
            .accessibilityElement(children: .combine)
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
                    .bigButton(filled: true)
                }
                .buttonStyle(.plain)
            } else {
                Button(action: onPlayAgain) {
                    Text(AppLanguage.localized("game.celebration.playagain")).bigButton(filled: true)
                }
                .buttonStyle(.plain)
            }
            Button(action: onHome) {
                Text(AppLanguage.localized("game.celebration.home")).bigButton(filled: false)
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

    /// A 100pt action: jade fill with paper-coloured text, or an espresso outline with a blue label.
    fileprivate func bigButton(filled: Bool) -> some View {
        font(.title2.weight(.semibold))
            .foregroundStyle(filled ? Color.paper : Color.fadedBlue)
            .frame(maxWidth: .infinity, minHeight: 100)
            .background(filled ? Color.brand : Color.clear, in: .rect(cornerRadius: 20))
            .overlay {
                if !filled { RoundedRectangle(cornerRadius: 20).strokeBorder(Color.espresso, lineWidth: 2) }
            }
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
    /// The game chosen with "Next", opened only once the cover is gone: changing
    /// the path mid-dismissal would remove this view while it still presents.
    @State private var pendingNext: GameID?

    func body(content: Content) -> some View {
        content.fullScreenCover(isPresented: $isPresented, onDismiss: openPendingNext) {
            CelebrationView(
                game: game,
                detail: detail,
                onPlayAgain: {
                    isPresented = false
                    onPlayAgain()
                },
                onNext: { next in
                    pendingNext = next
                    isPresented = false
                },
                onHome: {
                    isPresented = false
                    dismiss()
                })
        }
    }

    private func openPendingNext() {
        guard let next = pendingNext else { return }
        pendingNext = nil
        path?.games = [next]
    }
}

/// Non-color cue for found/picked tiles: a solid checkmark in the game's ink, readable on any tint
/// (WCAG 1.4.1, conventions.md §4).
struct CheckBadge: View {
    var body: some View {
        Image(systemName: "checkmark.circle.fill")
            .font(.title2)
            // The game's ink behind a background-coloured tick: 3:1+ in both modes.
            .foregroundStyle(Color.paper, .tint)
            .padding(6)
            .accessibilityHidden(true)
    }
}

#Preview {
    CelebrationView(game: .memoryMatch, detail: "You found all 8 pairs!", onPlayAgain: {}, onNext: { _ in }, onHome: {})
        .modelContainer(for: GameSession.self, inMemory: true)
}
