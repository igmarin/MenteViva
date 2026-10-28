import Foundation

/// Quick Eyes' deal (#244): the picture that flashes and the four pictures to
/// choose among. Pure, with the generator passed in, so a test can seed a
/// round; the view keeps the flash timing, the rounds and the answer beat.
nonisolated enum QuickEyesDeal {
    /// The pictures the game draws from: familiar everyday things, bold enough
    /// to read in a short flash.
    static let pictures = GamePictures.named([
        "sunflower", "turtle", "apple", "guitar", "moon", "coffee", "butterfly", "orange", "car", "star", "bee", "cactus",
    ])
    /// The most pictures a round offers, the target among them.
    static let optionsPerRound = 4

    /// Pictures offered per level 1...10 (#46): two to start, four from level 5.
    static let optionCountTable = [2, 2, 3, 3, 4, 4, 4, 4, 4, 4]

    static func optionCount(for difficulty: Difficulty) -> Int {
        difficulty.values(optionCountTable)
    }

    /// Levels 1...5 let the player decide when to hide the picture; 6...10 flash it (#46).
    static func isPaced(_ difficulty: Difficulty) -> Bool {
        difficulty.level <= 5
    }

    /// One round: the picture to flash, and the pictures offered afterwards.
    nonisolated struct Round: Equatable {
        let target: GamePicture
        let options: [GamePicture]
    }

    /// Deals one round: a target, the other pictures, and all of them shuffled.
    static func make(optionCount: Int = optionsPerRound, using generator: inout some RandomNumberGenerator) -> Round {
        let target = pictures[Int.random(in: pictures.indices, using: &generator)]
        let others = pictures.filter { $0 != target }.shuffled(using: &generator)
        let options = ([target] + others.prefix(optionCount - 1)).shuffled(using: &generator)
        return Round(target: target, options: options)
    }
}

/// When to offer a faster round (#46): after three right-first-try rounds in a row, each looked at for
/// under a second, once per game. The player decides; nothing changes unless they say yes.
nonisolated struct FasterInvite {
    static let streakNeeded = 3
    static let quickLook: Double = 1.0

    private var streak = 0
    private var offered = false

    /// Records a finished round; true when the invite should show now.
    mutating func record(rightFirstTry: Bool, look: Double) -> Bool {
        streak = rightFirstTry && look < Self.quickLook ? streak + 1 : 0
        guard streak >= Self.streakNeeded, !offered else { return false }
        offered = true
        return true
    }
}
