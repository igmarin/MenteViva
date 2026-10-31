import Foundation

/// The beat between the last move and the celebration (#415). Without it the cover rose in the same
/// frame as the last pair or tile, so the finished board was never seen. The session is recorded
/// before the beat and the VoiceOver line is posted then too; only the cover waits.
enum FinishBeat {
    /// Long enough to see the board whole and the last card's bloom settle.
    static let seconds = 0.9

    /// Runs `action` after the beat, unless the task is cancelled first: the game went away, or a
    /// new board was dealt. Held in the game's one task slot, so cancelling that slot stops it.
    static func after(seconds: Double = seconds, _ action: @escaping @MainActor () -> Void) -> Task<Void, Never> {
        Task { @MainActor in
            do {
                try await Task.sleep(for: .seconds(seconds))
            } catch {
                return
            }
            // A cancel can land after the sleep ends but before this resumes.
            guard !Task.isCancelled else { return }
            action()
        }
    }
}
