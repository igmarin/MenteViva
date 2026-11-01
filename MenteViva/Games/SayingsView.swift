import SwiftData
import SwiftUI

/// Finish the Saying (#181): the start of a familiar saying, and he picks the ending
/// from big buttons. A near miss dims that button and he keeps choosing; once right,
/// the whole saying shows and the speaker button reads it aloud. 8 sayings, no timer.
struct SayingsView: View {
    @Environment(\.modelContext) private var modelContext

    @Environment(\.horizontalSizeClass) private var sizeClass

    /// The screen's edge padding, named so the height measured outside it can take it off (#415).
    private static let edgePadding: CGFloat = 16

    /// Space between the column's blocks and between the ending buttons.
    private static let blockGap: CGFloat = 24
    private static let endingGap: CGFloat = 12

    @ScaledMetric(relativeTo: .largeTitle) private var sayingSize: CGFloat = 34

    @State private var difficulty = Difficulty.stored(.sayings)
    @State private var rounds: [SayingRound] = []
    @State private var progress = RoundProgress(totalRounds: SayingsDeck.roundsPerGame)
    @State private var dimmed: Set<Saying> = []
    @State private var solved = false
    @State private var correct = 0
    @State private var taps = 0
    @State private var startedAt = Date.now
    @State private var missed = false
    @State private var missedChoice: Saying?
    @State private var showAlmost = false
    @State private var showCelebration = false
    @State private var finalDetail = ""
    /// Measured heights (#415): the play area outside the padding, then everything in it but the endings
    /// (the banner with the instruction row, the saying, the round counter), each opening and each ending
    /// button. None of them depends on how many endings show, so trimming never feeds back into them.
    @State private var areaHeight: CGFloat = 0
    @State private var topHeight: CGFloat = 0
    @State private var sayingHeight: CGFloat = 0
    @State private var counterHeight: CGFloat = 0
    @State private var openingHeights: [Saying: Double] = [:]
    @State private var endingHeights: [Saying: Double] = [:]
    /// How many endings this round showed when he first tapped: kept until the next round, so a dimmed
    /// near miss never disappears and no button moves under his finger.
    @State private var frozenCount: Int?

    private var round: SayingRound? {
        rounds.indices.contains(progress.completedRounds) ? rounds[progress.completedRounds] : nil
    }

    /// How many of the round's endings fit (#415): every one dealt on an iPad, where there is room, and
    /// on a phone as many as fit under the saying, so the last one is never below the fold. The amber
    /// note takes the instruction's place (#494), so it costs no ending. The next round's opening and
    /// endings are measured before Next (#494), so a new round is fitted right on its first pass and the
    /// page never flips to scrolling and back. Re-fitted until his first tap in the round, then frozen.
    private func fittedCount(_ round: SayingRound) -> Int {
        if let frozenCount { return frozenCount }
        guard !GameColumn.usesPadLayout(sizeClass), areaHeight > 0 else { return round.choices.count }
        // The column's four blocks have three gaps between them. A fresh deal's first pass has no
        // opening measured yet and falls back on the last saying shown.
        let opening = openingHeights[round.saying] ?? sayingHeight
        let room = areaHeight - topHeight - opening - counterHeight - 3 * Self.blockGap
        return SayingsDeck.fittingCount(round, heights: endingHeights, gap: Self.endingGap, room: room)
    }

    var body: some View {
        VStack(spacing: Self.blockGap) {
            VStack(spacing: Self.blockGap) {
                LevelExplainBanner(
                    game: GameID.sayings, hasStarted: taps > 0 || progress.completedRounds > 0)
                instructionRow
            }
            .onGeometryChange(for: CGFloat.self) {
                $0.size.height
            } action: { height in
                topHeight = height
            }

            if let round {
                sayingText(solved ? whole(round.saying) : opening(round))
                    .onGeometryChange(for: CGFloat.self) {
                        $0.size.height
                    } action: {
                        sayingHeight = $0
                    }

                if solved {
                    HStack(spacing: 12) {
                        Button {
                            CaptionSpeaker.speak(whole(round.saying))
                        } label: {
                            Image(systemName: "speaker.wave.2.fill")
                                .font(.title)
                                .frame(minWidth: 100, minHeight: 100)
                        }
                        .buttonStyle(AnswerTileStyle(minHeight: 100))
                        .fixedSize(horizontal: true, vertical: false)
                        .accessibilityLabel(AppLanguage.localized("game.sayings.a11y.listen"))

                        Button(action: next) {
                            Text(AppLanguage.localized("game.sayings.next")).font(.title2.weight(.semibold))
                        }
                        .buttonStyle(AnswerTileStyle(minHeight: 100))
                    }
                } else {
                    VStack(spacing: Self.endingGap) {
                        ForEach(SayingsDeck.shown(round, count: fittedCount(round)), id: \.self) { choice in
                            Button {
                                choose(choice, in: round)
                            } label: {
                                endingLabel(choice)
                            }
                            .buttonStyle(AnswerTileStyle(minHeight: 100))
                            .disabled(dimmed.contains(choice))
                            .opacity(dimmed.contains(choice) ? 0.4 : 1)
                            .modifier(MissCue(active: missedChoice == choice ? $missed : .constant(false)))
                        }
                    }
                }

                RoundCounter(progress: progress)
                    .onGeometryChange(for: CGFloat.self) {
                        $0.size.height
                    } action: {
                        counterHeight = $0
                    }
            }
        }
        .background(alignment: .top) { measuringCopy }
        .gameColumn()
        .padding(Self.edgePadding)
        .fitOrScroll()
        // Measured outside the padding and the fit-or-scroll, so it is the room the screen offers
        // and not the height of what is in it (as Sudoku does).
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onGeometryChange(for: CGFloat.self) {
            $0.size.height - 2 * Self.edgePadding
        } action: { height in
            areaHeight = height
        }
        .gameHeader(
            .sayings, instruction: AppLanguage.localized("game.sayings.instruction"),
            inProgress: progress.completedRounds > 0
        )
        .onAppear { if rounds.isEmpty { deal() } }
        .onDisappear { CaptionSpeaker.stop() }
        .celebration(isPresented: $showCelebration, game: .sayings, detail: finalDetail, onPlayAgain: restart)
    }

    private func whole(_ saying: Saying) -> String {
        AppLanguage.localized(saying.startKey) + " " + AppLanguage.localized(saying.endKey)
    }

    private func opening(_ round: SayingRound) -> String {
        round.saying.opening(localize: { AppLanguage.localized($0) })
    }

    private func sayingText(_ text: String) -> some View {
        Text(text)
            .font(.system(size: sayingSize, weight: .semibold, design: .serif))
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
    }

    /// The instruction and the amber note share one row as tall as the taller of the two, as in Tile
    /// Pairs (#482, #494): after a near miss the note stands where the instruction was, so it never
    /// pushes an ending down or costs one, and the instruction comes back with the next round. No
    /// animation, so the swap is still with Reduce Motion.
    private var instructionRow: some View {
        ZStack {
            Text(AppLanguage.localized("game.sayings.instruction"))
                .font(.title2)
                .multilineTextAlignment(.center)
                .opacity(showAlmost ? 0 : 1)
                .accessibilityHidden(showAlmost)
            almostNote.hidden()
            if showAlmost { almostNote }
        }
    }

    /// The soft amber note after a near miss, the same as Quick Eyes: kind and easy to read.
    private var almostNote: some View {
        AlmostNote(text: AppLanguage.localized("game.sayings.miss"))
    }

    private func endingLabel(_ choice: Saying) -> some View {
        Text(AppLanguage.localized(choice.endKey))
            .font(.title2)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 12)
    }

    /// This round's and the next one's opening and every ending dealt, laid out unseen at the column's
    /// width (#415), so their real heights are known before choosing how many show: a long Spanish ending
    /// or big text wraps a button past 100pt. A copy, because a trimmed ending is not on screen to be
    /// measured, and the next round is measured while he reads the whole saying, before Next (#494).
    private var measuringCopy: some View {
        VStack(spacing: Self.endingGap) {
            ForEach(rounds.dropFirst(progress.completedRounds).prefix(2), id: \.saying) { round in
                sayingText(opening(round))
                    .onGeometryChange(for: Double.self) {
                        $0.size.height
                    } action: {
                        openingHeights[round.saying] = $0
                    }
                ForEach(round.choices, id: \.self) { choice in
                    Button {
                    } label: {
                        endingLabel(choice)
                    }
                    .buttonStyle(AnswerTileStyle(minHeight: 100))
                    .onGeometryChange(for: Double.self) {
                        $0.size.height
                    } action: {
                        endingHeights[choice] = $0
                    }
                }
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .hidden()
        .accessibilityHidden(true)
    }

    private func deal() {
        var generator = SystemRandomNumberGenerator()
        rounds = SayingsDeck.deal(difficulty: difficulty, defaults: .standard, using: &generator)
    }

    private func restart() {
        difficulty = Difficulty.stored(.sayings)
        progress.reset()
        correct = 0
        taps = 0
        startedAt = .now
        resetRound()
        deal()
    }

    private func resetRound() {
        frozenCount = nil
        dimmed = []
        solved = false
        showAlmost = false
        missed = false
        missedChoice = nil
    }

    private func choose(_ choice: Saying, in round: SayingRound) {
        if frozenCount == nil { frozenCount = fittedCount(round) }
        taps += 1
        if choice == round.saying {
            if dimmed.isEmpty { correct += 1 }  // right on the first tap
            solved = true
            showAlmost = false
            Feedback.play(.success)
            if CaptionSpeaker.autoSpeaks() {
                CaptionSpeaker.speak(whole(round.saying))
            } else if UIAccessibility.isVoiceOverRunning {
                AccessibilityNotification.Announcement(whole(round.saying)).post()
            }
        } else {
            dimmed.insert(choice)
            missedChoice = choice
            missed = true
            showAlmost = true
            Feedback.play(.miss)
            // Posted here, not from a `.task(id:)`: two misses in a row keep the same text.
            AccessibilityNotification.Announcement(AppLanguage.localized("game.sayings.miss")).post()
        }
    }

    private func next() {
        CaptionSpeaker.stop()
        if let round { SayingsDeck.markSeen(round.saying, defaults: .standard) }
        resetRound()
        if progress.completeRound() {
            finish()
        } else if let round {
            // The Next button is replaced by the new answers, so VoiceOver focus jumps and the
            // new start would not be read (#391).
            AccessibilityNotification.Announcement(opening(round)).post()
        }
    }

    private func finish() {
        modelContext.record(
            GameSession(
                gameID: .sayings,
                rounds: SayingsDeck.roundsPerGame, durationSeconds: Int(Date.now.timeIntervalSince(startedAt)),
                correct: correct, attempts: taps,
                difficulty: difficulty))
        finalDetail = String(
            format: AppLanguage.localized("game.celebration.sayings %lld"), SayingsDeck.roundsPerGame)
        showCelebration = true
    }
}

#Preview {
    SayingsView()
}
