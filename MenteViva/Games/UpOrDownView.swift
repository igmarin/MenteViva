import SwiftData
import SwiftUI
import UIKit

/// Up or Down (#180): a golf solitaire with big cards drawn in SwiftUI (`UpOrDownDeal`).
/// Tap a top card one higher or one lower than the open card; turn the deck when none
/// fits. A new deal every time. The game ends on cards cleared, never on a loss.
struct UpOrDownView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @ScaledMetric(relativeTo: .largeTitle) private var rankSize: CGFloat = 34

    @State private var difficulty = Difficulty.stored(.upOrDown)
    @State private var deal: UpOrDownDeal?
    @State private var rowWidth = 0.0
    @State private var played = 0
    @State private var taps = 0
    @State private var startedAt = Date.now
    @State private var missed = false
    @State private var missedPile: Int?
    @State private var showAlmost = false
    @State private var pulse = false
    @State private var showCelebration = false
    @State private var finalDetail = ""

    var body: some View {
        VStack(spacing: 24) {
            LevelExplainBanner(
                change: PlanStore.cachedPlan()?.changes[GameID.upOrDown], game: GameID.upOrDown,
                hasStarted: played > 0 || taps > 0)
            Text(AppLanguage.localized("game.upordown.instruction"))
                .font(.title2)
                .multilineTextAlignment(.center)

            if let deal {
                note(for: deal)
                piles(deal)
                HStack(alignment: .bottom, spacing: 32) {
                    face(deal.open, width: cardWidth(deal) * 1.15)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(
                            String(format: AppLanguage.localized("game.upordown.a11y.open %@"), name(deal.open)))
                    deckButton(deal)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .onGeometryChange(for: Double.self) {
            $0.size.width
        } action: { width in
            guard width > 0 else { return }
            rowWidth = width
            // A six-pile row that no longer fits (turned to portrait on a small iPhone)
            // is dealt again with fewer piles: cards never drop under 60pt.
            if let deal, deal.fits(width: width) { return }
            restart()
        }
        .padding()
        .fitOrScroll()
        .gameHeader(.upOrDown, instruction: AppLanguage.localized("game.upordown.instruction"))
        .celebration(isPresented: $showCelebration, game: .upOrDown, detail: finalDetail, onPlayAgain: restart)
    }

    // MARK: - Table

    private func cardWidth(_ deal: UpOrDownDeal) -> Double {
        let count = Double(deal.piles.count)
        return min(120, (rowWidth - UpOrDownDeal.gap * (count - 1)) / count)
    }

    /// The soft amber note: a near miss, or no card fits and the deck can help.
    @ViewBuilder
    private func note(for deal: UpOrDownDeal) -> some View {
        let stuck = deal.playablePiles.isEmpty && !deal.deck.isEmpty
        if showAlmost || stuck {
            Text(
                stuck
                    ? AppLanguage.localized("game.upordown.stuck")
                    : String(format: AppLanguage.localized("game.upordown.miss %@"), rankName(deal.open))
            )
            .font(.title2.weight(.semibold))
            .foregroundStyle(Color.todaysPick)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color.amber.opacity(0.24), in: .rect(cornerRadius: 14))
        }
    }

    private func piles(_ deal: UpOrDownDeal) -> some View {
        let width = cardWidth(deal)
        let lift = UpOrDownDeal.liftsPlayableCards(at: difficulty)
        return HStack(alignment: .top, spacing: UpOrDownDeal.gap) {
            ForEach(deal.piles.indices, id: \.self) { index in
                let pile = deal.piles[index]
                let fits = deal.playablePiles.contains(index)
                ZStack(alignment: .top) {
                    // The cards underneath show as edges, so he can see what's left.
                    ForEach(0..<max(pile.count - 1, 0), id: \.self) { depth in
                        RoundedRectangle(cornerRadius: 10)
                            .fill(GameID.upOrDown.ink.opacity(0.25))
                            .frame(width: width, height: width * 1.4)
                            .offset(y: Double(depth) * 12)
                    }
                    if let top = pile.last {
                        Button {
                            tap(index)
                        } label: {
                            face(top, width: width)
                        }
                        .buttonStyle(.plain)
                        .offset(y: Double(pile.count - 1) * 12 - (lift && fits ? 14 : 0))
                        .shadow(color: .black.opacity(lift && fits ? 0.25 : 0), radius: 6, y: 4)
                        .modifier(MissCue(active: missedPile == index ? $missed : .constant(false)))
                        .accessibilityLabel(name(top))
                        .accessibilityValue(fits ? AppLanguage.localized("game.upordown.a11y.fits") : "")
                    } else {
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(.secondary, style: StrokeStyle(lineWidth: 2, dash: [6, 6]))
                            .frame(width: width, height: width * 1.4)
                            .accessibilityLabel(AppLanguage.localized("game.upordown.a11y.empty"))
                    }
                }
                .frame(height: width * 1.4 + 24, alignment: .top)
            }
        }
        .animation(reduceMotion ? nil : .easeOut(duration: 0.2), value: deal)
    }

    private func face(_ card: PlayingCard, width: Double) -> some View {
        // Red or black plus the suit symbol: never colour alone.
        let ink = card.suit.isRed ? Color(light: 0xB3261E, dark: 0xFF8A80) : Color.primary
        return VStack(spacing: 2) {
            Text(verbatim: card.rankText)
                .font(.system(size: rankSize, weight: .bold, design: .rounded))
            Text(verbatim: card.suit.symbol)
                .font(.system(size: rankSize * 0.8))
        }
        .foregroundStyle(ink)
        .minimumScaleFactor(0.5)
        .frame(width: width, height: width * 1.4)
        .background(Color(.systemBackground), in: .rect(cornerRadius: 10))
        .overlay { RoundedRectangle(cornerRadius: 10).strokeBorder(GameID.upOrDown.ink, lineWidth: 2) }
    }

    private func deckButton(_ deal: UpOrDownDeal) -> some View {
        let width = cardWidth(deal) * 1.15
        let nudge = deal.playablePiles.isEmpty && !deal.deck.isEmpty
        return Button(action: turn) {
            RoundedRectangle(cornerRadius: 10)
                .fill(GameID.upOrDown.ink)
                .overlay {
                    RoundedRectangle(cornerRadius: 6).strokeBorder(Color.amber, lineWidth: 3).padding(8)
                }
                .overlay { if nudge { RoundedRectangle(cornerRadius: 10).stroke(Color.amber, lineWidth: 6) } }
                .frame(width: width, height: width * 1.4)
                .opacity(deal.deck.isEmpty ? 0.3 : 1)
        }
        .buttonStyle(.plain)
        .scaleEffect(nudge && pulse && !reduceMotion ? 1.06 : 1)
        .animation(
            nudge && !reduceMotion ? .easeInOut(duration: 0.8).repeatForever(autoreverses: true) : .default,
            value: pulse
        )
        .onChange(of: nudge) { _, stuck in
            if stuck {
                if !reduceMotion { pulse.toggle() }
                UIAccessibility.post(notification: .announcement, argument: AppLanguage.localized("game.upordown.stuck"))
            } else {
                pulse = false
            }
        }
        .onAppear {
            // Seed the pulse only when already stuck at appear; the stuck transition
            // drives it afterwards so the deck doesn't jump and stay at 1.06.
            if nudge, !reduceMotion { pulse = true }
        }
        .disabled(deal.deck.isEmpty)
        .accessibilityLabel(String(format: AppLanguage.localized("game.upordown.a11y.deck %lld"), deal.deck.count))
    }

    private func rankName(_ card: PlayingCard) -> String { AppLanguage.localized(card.rankKey) }

    private func name(_ card: PlayingCard) -> String {
        String(
            format: AppLanguage.localized("game.upordown.a11y.card %@ %@"), rankName(card),
            AppLanguage.localized(card.suit.nameKey))
    }

    // MARK: - Play

    private func restart() {
        var generator = SystemRandomNumberGenerator()
        deal = UpOrDownDeal.make(difficulty: difficulty, width: rowWidth, using: &generator)
        played = 0
        taps = 0
        showAlmost = false
        startedAt = .now
    }

    private func tap(_ pile: Int) {
        guard var current = deal else { return }
        taps += 1
        if current.play(pile: pile) {
            played += 1
            showAlmost = false
            Feedback.play(.success)
        } else {
            missedPile = pile
            missed = true
            showAlmost = true
            Feedback.play(.miss)
        }
        deal = current
        finishIfDone()
    }

    private func turn() {
        guard var current = deal, current.turn() else { return }
        showAlmost = false
        deal = current
        finishIfDone()
    }

    private func finishIfDone() {
        guard let deal, deal.isCleared || deal.isStuck else { return }
        modelContext.record(
            GameSession(
                gameID: .upOrDown, score: played * 10,
                rounds: deal.tableCards, durationSeconds: Int(Date.now.timeIntervalSince(startedAt)),
                correct: played, attempts: taps,
                difficulty: difficulty))
        finalDetail =
            deal.isCleared
            ? AppLanguage.localized("game.celebration.table")
            : String(format: AppLanguage.localized("game.celebration.cards %lld"), played)
        showCelebration = true
    }
}

#Preview {
    UpOrDownView()
}
