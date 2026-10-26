import Foundation

/// The warm line at the top of the end-of-game card (#242). Five headlines rotate so the end of a
/// game never feels identical twice in a row. The choice is pure given its generator; the only thing
/// stored is the index shown last, so the no-repeat rule also holds across games and launches.
/// Headlines never mention accuracy, speed or a score (#45).
enum CelebrationHeadline {
    /// How many headlines the catalog holds (`game.celebration.headline.1` … `.5`).
    static let count = 5

    /// UserDefaults key of the zero-based index shown last.
    static let lastIndexKey = "celebration.lastHeadlineIndex"

    /// The catalog key of a zero-based headline index. Catalog keys are numbered from 1 to read naturally.
    static func key(for index: Int) -> String {
        "game.celebration.headline.\(index + 1)"
    }

    /// The next zero-based index, never equal to `last`. It draws from the other `count - 1` indices
    /// and shifts past `last`, so a repeat is impossible rather than merely unlikely. With no previous
    /// index (the first celebration) every index is equally likely.
    static func next(after last: Int?, using generator: inout some RandomNumberGenerator) -> Int {
        guard let last else { return Int.random(in: 0..<count, using: &generator) }
        let draw = Int.random(in: 0..<(count - 1), using: &generator)
        return draw >= last ? draw + 1 : draw
    }

    /// Picks the next headline, remembers its index in `defaults`, and returns its text in the app's
    /// language. Only `lastIndexKey` is read and written.
    static func pick(
        defaults: UserDefaults = .standard,
        using generator: inout some RandomNumberGenerator
    ) -> String {
        let last = defaults.object(forKey: lastIndexKey) as? Int
        let index = next(after: last, using: &generator)
        defaults.set(index, forKey: lastIndexKey)
        return AppLanguage.localized(key(for: index), defaults: defaults)
    }
}
