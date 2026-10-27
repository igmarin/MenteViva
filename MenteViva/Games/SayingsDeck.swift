import Foundation

/// One saying slot (#181). Its text lives in `Localizable.xcstrings` under
/// `saying.NN.start` / `saying.NN.end`: the English value is an English saying and
/// the Spanish value a refrán on the same theme, written separately, not translated.
nonisolated struct Saying: Hashable {
    enum Theme: CaseIterable {
        case animals, money, time, food, work, weather, friends, home
    }

    let id: Int  // 1...60
    let theme: Theme

    var startKey: String { String(format: "saying.%02d.start", id) }
    var endKey: String { String(format: "saying.%02d.end", id) }
}

/// One round: the saying to finish and the endings offered, his own among them once.
nonisolated struct SayingRound: Equatable {
    let saying: Saying
    let choices: [Saying]  // each choice's `endKey` is a button
}

/// Which sayings a game shows: 8 he hasn't seen yet, so none repeats until all have
/// been seen. Hard draws the other endings from the same theme first, so they're closer.
enum SayingsDeck {
    static let roundsPerGame = 8
    static let seenKey = "sayings.seen"

    /// Marks a saying seen once its round is completed, so a game left early doesn't
    /// use up the sayings he never reached.
    static func markSeen(_ saying: Saying, defaults: UserDefaults) {
        var seen = defaults.array(forKey: seenKey) as? [Int] ?? []
        if !seen.contains(saying.id) { seen.append(saying.id) }
        defaults.set(seen, forKey: seenKey)
    }

    static func choiceCount(for difficulty: Difficulty) -> Int {
        difficulty.pick(3, 4, 4)
    }

    static func deal<G: RandomNumberGenerator>(
        difficulty: Difficulty, from pool: [Saying] = Sayings.all, defaults: UserDefaults,
        using generator: inout G
    ) -> [SayingRound] {
        var seen = Set(defaults.array(forKey: seenKey) as? [Int] ?? [])
        if pool.filter({ !seen.contains($0.id) }).count < roundsPerGame {
            seen = []
            defaults.set([Int](), forKey: seenKey)
        }
        let picked = pool.filter { !seen.contains($0.id) }.shuffled(using: &generator).prefix(roundsPerGame)

        let others = choiceCount(for: difficulty) - 1
        return picked.map { saying in
            let rest = pool.filter { $0 != saying }.shuffled(using: &generator)
            let distractors =
                difficulty.pick(false, false, true)
                ? rest.filter { $0.theme == saying.theme } + rest.filter { $0.theme != saying.theme }
                : rest
            return SayingRound(
                saying: saying,
                choices: ([saying] + distractors.prefix(others)).shuffled(using: &generator))
        }
    }
}
