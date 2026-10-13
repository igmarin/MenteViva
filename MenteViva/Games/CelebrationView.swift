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

    /// Today's games from the plan saved for today; nil before there is one.
    private var today: TodayRun? {
        guard let plan = PlanStore.cachedPlan(), plan.dayStamp == PlanStore.dayStamp() else { return nil }
        return TodayRun(plan: plan.games, hidden: FamilySettings.hidden(from: hiddenGames), sessions: sessions)
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
                    .background(Color(.systemBackground), in: .capsule)
                }
                card
            }
            .padding(.top, 24)
            .padding(.bottom, 60)

            Spacer(minLength: 0)

            VStack(spacing: 14) {
                Text(AppLanguage.localized("game.common.welldone"))
                    .font(.largeTitle.bold())
                    .fontDesign(.serif)
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)
                Text(detail)
                    .font(.title2.weight(.semibold))
                    .multilineTextAlignment(.center)
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
                    .fill(Color(.systemBackground))
                    .ignoresSafeArea(edges: .bottom)
            }
        }
        .fitOrScroll()
        // The sheet's paper continues under the home indicator.
        .background(alignment: .bottom) {
            Color(.systemBackground).frame(height: 200).ignoresSafeArea(edges: .bottom)
        }
        .background(.table)
        .onAppear {
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

    /// A 100pt action: icon-teal fill with background-coloured text, or an outline.
    fileprivate func bigButton(filled: Bool) -> some View {
        font(.title2.weight(.semibold))
            .foregroundStyle(filled ? Color(.systemBackground) : Color.primary)
            .frame(maxWidth: .infinity, minHeight: 100)
            .background(filled ? Color.brand : Color.clear, in: .rect(cornerRadius: 20))
            .overlay {
                if !filled { RoundedRectangle(cornerRadius: 20).strokeBorder(.secondary, lineWidth: 2) }
            }
    }
}

private struct CelebrationCover: ViewModifier {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.playNext) private var playNext
    @Binding var isPresented: Bool
    let game: GameID
    let detail: String
    let onPlayAgain: () -> Void

    func body(content: Content) -> some View {
        content.fullScreenCover(isPresented: $isPresented) {
            CelebrationView(
                game: game,
                detail: detail,
                onPlayAgain: {
                    isPresented = false
                    onPlayAgain()
                },
                onNext: { next in
                    isPresented = false
                    playNext(next)
                },
                onHome: {
                    isPresented = false
                    dismiss()
                })
        }
    }
}

/// Non-color cue for found/picked tiles: a solid checkmark in the game's ink, readable on any tint
/// (WCAG 1.4.1, conventions.md §4).
struct CheckBadge: View {
    var body: some View {
        Image(systemName: "checkmark.circle.fill")
            .font(.title2)
            // The game's ink behind a background-coloured tick: 3:1+ in both modes.
            .foregroundStyle(Color(.systemBackground), .tint)
            .padding(6)
            .accessibilityHidden(true)
    }
}

#Preview {
    CelebrationView(game: .memoryMatch, detail: "You found all 8 pairs!", onPlayAgain: {}, onNext: { _ in }, onHome: {})
        .modelContainer(for: GameSession.self, inMemory: true)
}
