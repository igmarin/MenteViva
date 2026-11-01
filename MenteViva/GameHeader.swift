import SwiftUI

extension View {
    /// The shared game header (Card Table, step 3): the game's name small and
    /// centred instead of a large title, the game's ink as the tint, cream paper
    /// behind the page (dark surround in dark mode), and a
    /// speaker that reads the instruction aloud. Tapping it is asking to hear
    /// it, so it speaks even with "Read names aloud" off, like the photo
    /// speaker (#139). The page fills the screen, so the paper reaches every edge (#528), and
    /// the back button is the same 100pt chevron in every game; `inProgress` and `celebrating`
    /// only matter to the puzzle games that ask before leaving (`LeaveGuard`, #404).
    func gameHeader(
        _ game: GameID, instruction: String, inProgress: Bool = false, celebrating: Bool = false
    ) -> some View {
        frame(maxWidth: .infinity, maxHeight: .infinity)
            // Inside the tint, so the leave prompt wears the game's ink.
            .modifier(LeaveGuardModifier(game: game, inProgress: inProgress, celebrating: celebrating))
            .navigationTitle(AppLanguage.localized(game.title))
            .navigationBarTitleDisplayMode(.inline)
            .tint(game.ink)
            // Cream paper behind every game, and its bar once content scrolls under it (#336).
            .background(Color.paper.ignoresSafeArea())
            .toolbarBackground(Color.paper, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        CaptionSpeaker.speak(instruction)
                    } label: {
                        Label(AppLanguage.localized("game.readaloud"), systemImage: "speaker.wave.2.fill")
                            .font(.title3)
                            .labelStyle(.iconOnly)
                            .bigTapTarget()
                    }
                    .accessibilityHint(AppLanguage.localized("game.readaloud.hint"))
                }
            }
            .onAppear { SoundPlayer.warmUp() }
            .onDisappear { CaptionSpeaker.stop() }
    }
}

/// Progress as a row of small cards in the game's ink, with the same count in
/// words at full contrast underneath. Shape carries the state as well as
/// colour: done cards are filled, the current one has a thick outline.
/// VoiceOver hears only the words.
struct ProgressCards: View {
    let done: Int
    let total: Int
    let words: String

    var body: some View {
        VStack(spacing: 8) {
            // A long session would overflow the row; the words alone still say it.
            if total <= 12 {
                HStack(spacing: 6) {
                    ForEach(0..<total, id: \.self) { index in
                        let card = RoundedRectangle(cornerRadius: 5)
                        card.fill(index < done ? AnyShapeStyle(.tint) : AnyShapeStyle(Color.clear))
                            .overlay(
                                card.strokeBorder(
                                    .tint.opacity(index == done ? 1 : 0.4), lineWidth: index == done ? 3 : 2)
                            )
                            .frame(width: 16, height: 22)
                    }
                }
            }
            Text(words)
                .font(.title3.weight(.semibold))
                .multilineTextAlignment(.center)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(words)
    }
}
