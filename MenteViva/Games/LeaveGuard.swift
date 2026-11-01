import SwiftUI

/// The one rule behind the leave prompt (#404), kept out of the view so a test can reach it: a
/// puzzle game asks before closing only when the player has moved and the game is not already over.
enum LeaveGuard {
    /// The games whose half-played board is worth a question (#404). Round games lose a few
    /// one-tap rounds at most, so they close at once even with rounds played (#528).
    private static let asksFirst: Set<GameID> = [
        .sudoku, .tangram, .slidingBlocks, .tilePairs, .upOrDown, .memoryMatch, .photoCaptions,
    ]

    /// `inProgress` is each game's own "has moved" (a placed digit, a move, a tap). Once the
    /// celebration is up the session is recorded, so nothing is lost by leaving, even though the
    /// counters are still above zero.
    static func needsConfirmation(game: GameID, inProgress: Bool, celebrating: Bool) -> Bool {
        asksFirst.contains(game) && inProgress && !celebrating
    }
}

/// Every game's back button (#528), put on by `gameHeader`, and its prompt (#404). One stray tap
/// or edge swipe used to throw away minutes of play: nothing is saved until a game finishes.
/// Hiding the system button also turns off the edge swipe, so this 100pt chevron is the one way
/// out, in the same place in all 14 games. The prompt is a card over the game, not a
/// `confirmationDialog` or alert: the system draws those buttons (under 100pt) and on iPad turns
/// a dialog into a popover without its cancel action.
struct LeaveGuardModifier: ViewModifier {
    let game: GameID
    let inProgress: Bool
    let celebrating: Bool

    @Environment(\.dismiss) private var dismiss
    @State private var asking = false

    func body(content: Content) -> some View {
        content
            // Hidden from VoiceOver while the card shows, like the first-play guide: the card is modal.
            .accessibilityHidden(asking)
            .overlay {
                if asking {
                    LeavePrompt(
                        keepPlaying: { asking = false },
                        leave: {
                            asking = false
                            dismiss()
                        })
                }
            }
            .navigationBarBackButtonHidden(true)
            // The bar's speaker would read the game's rules over the modal card, so the bar goes while it shows.
            .toolbar(asking ? .hidden : .visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        if LeaveGuard.needsConfirmation(game: game, inProgress: inProgress, celebrating: celebrating) {
                            asking = true
                        } else {
                            dismiss()
                        }
                    } label: {
                        Label(AppLanguage.localized("game.celebration.home"), systemImage: "chevron.backward")
                            .font(.title3.weight(.semibold))
                            .labelStyle(.iconOnly)
                            .bigTapTarget()
                    }
                }
            }
    }
}

/// "Leave this game?": a dimmed screen and a card with two full-width 100pt buttons. "Keep playing"
/// comes first and is the strong one, since it is the safe answer. VoiceOver lands on the title,
/// and the escape gesture (two-finger scrub) keeps playing. The card scrolls at the biggest
/// text sizes. No animation, so Reduce Motion has nothing to skip.
private struct LeavePrompt: View {
    let keepPlaying: () -> Void
    let leave: () -> Void

    @AccessibilityFocusState private var titleFocused: Bool

    var body: some View {
        ZStack {
            Color.black.opacity(0.3).ignoresSafeArea()
            GeometryReader { proxy in
                ScrollView {
                    card
                        .padding()
                        // Centred when it fits, scrolling from the top when it does not.
                        .frame(maxWidth: .infinity, minHeight: proxy.size.height)
                }
                .scrollBounceBehavior(.basedOnSize)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
        .accessibilityAction(.escape, keepPlaying)
        .task {
            // The card is not in the accessibility tree on the first frame, so focus a beat later.
            try? await Task.sleep(for: .milliseconds(100))
            titleFocused = true
        }
    }

    private var card: some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                Text(AppLanguage.localized("game.leave.title"))
                    .font(.title.weight(.semibold))
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityFocused($titleFocused)
                Text(AppLanguage.localized("game.leave.note"))
                    .font(.title3)
            }
            .multilineTextAlignment(.center)
            Button(action: keepPlaying) {
                Text(AppLanguage.localized("game.leave.stay"))
            }
            .buttonStyle(RetroButtonStyle())
            Button(action: leave) {
                Text(AppLanguage.localized("game.leave.go")).font(.title2.weight(.semibold))
            }
            .buttonStyle(AnswerTileStyle(strength: 0.08, minHeight: 100))
        }
        .padding(20)
        .frame(maxWidth: 520)
        .background(Color.paper, in: .rect(cornerRadius: 20))
    }
}
