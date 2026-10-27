import Foundation

/// Quick Eyes' deal (#244): the picture that flashes and the four pictures to
/// choose among. Pure, with the generator passed in, so a test can seed a
/// round; the view keeps the flash timing, the rounds and the answer beat.
nonisolated enum QuickEyesDeal {
    /// The pictures the game draws from: familiar everyday things. Emoji carry
    /// their own VoiceOver names, so they need no extra strings.
    static let pictures = ["🌻", "🐢", "🍎", "🎸", "🌙", "☕️", "🦋", "🍊", "🚗", "⭐", "🐝", "🌵"]
    /// How many pictures a round offers, the target among them.
    static let optionsPerRound = 4

    /// One round: the picture to flash, and the pictures offered afterwards.
    nonisolated struct Round: Equatable {
        let target: String
        let options: [String]
    }

    /// Deals one round: a target, three other pictures, and the four shuffled.
    static func make(using generator: inout some RandomNumberGenerator) -> Round {
        let target = pictures[Int.random(in: pictures.indices, using: &generator)]
        let others = pictures.filter { $0 != target }.shuffled(using: &generator)
        let options = ([target] + others.prefix(optionsPerRound - 1)).shuffled(using: &generator)
        return Round(target: target, options: options)
    }
}
