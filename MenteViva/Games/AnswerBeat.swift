import SwiftUI

/// What a tile shows during the answer beat (#235).
nonisolated enum AnswerMark: Equatable {
    case plain, check, missed
}

/// The moment after an answer (#235): the tapped choice and the right one, shown for a beat before
/// the next round. Without it a right answer was only a tone (nothing with sound off), and the miss
/// cue landed on the next question. A miss also shows where the answer was, warmly, with a check.
nonisolated struct AnswerBeat<Choice: Hashable>: Equatable {
    let tapped: Choice
    let right: Choice

    var isRight: Bool { tapped == right }

    /// Tapped and right → check; tapped and not right → the amber miss cue; the right tile on a
    /// miss → check, so the answer is always shown. Every other tile shows nothing.
    func mark(for choice: Choice) -> AnswerMark {
        if choice == right { return .check }
        if choice == tapped { return .missed }
        return .plain
    }

    /// Long enough to see the answer; longer under VoiceOver, which reads it out first.
    func duration(voiceOver: Bool) -> Double {
        voiceOver ? 1.2 : 0.7
    }

    /// Gives the same warm sound and announcement in each game.
    @MainActor
    func play(rightName: String) {
        Feedback.play(isRight ? .success : .miss)
        let line =
            isRight
            ? AppLanguage.localized("game.answer.right")
            : String(format: AppLanguage.localized("game.answer.was %@"), rightName)
        AccessibilityNotification.Announcement(line).post()
    }

    /// Runs the next round only after the visible beat, unless the game has gone away.
    @MainActor
    func after(_ action: @escaping @MainActor () -> Void) -> Task<Void, Never> {
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(duration(voiceOver: UIAccessibility.isVoiceOverRunning)))
            guard !Task.isCancelled else { return }
            action()
        }
    }
}

extension View {
    /// Draws a tile's beat mark: a check badge in the corner, or `MissCue`'s amber outline on a
    /// dimmed tile. The dimming is the cue that never depends on colour: on an orange or yellow ink
    /// tile the outline alone would vanish. Reduce Motion is handled by `MissCue` (no shrink).
    func answerMark(_ mark: AnswerMark) -> some View {
        self
            .opacity(mark == .missed ? 0.6 : 1)
            .overlay(alignment: .topTrailing) {
                if mark == .check {
                    CheckBadge()
                }
            }
            .modifier(MissCue(active: .constant(mark == .missed)))
    }
}
