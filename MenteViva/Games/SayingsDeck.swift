import Foundation

/// One saying slot (#181). Its text lives in `Localizable.xcstrings` under
/// `saying.NN.start` / `saying.NN.end`: the English value is an English saying and
/// the Spanish value a refrán on the same theme, written separately, not translated.
nonisolated struct Saying: Hashable {
    enum Theme: CaseIterable {
        case animals, money, time, food, work, weather, friends, home
    }

    let id: Int  // 1...120
    let theme: Theme

    var startKey: String { String(format: "saying.%02d.start", id) }
    var endKey: String { String(format: "saying.%02d.end", id) }

    /// What the screen shows and VoiceOver reads for the unfinished saying: its start and "…".
    func opening(localize: (String) -> String) -> String {
        localize(startKey) + "…"
    }
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

    /// Choices per level: 2 at 1, 3 at 2-3, 4 at 4-6, 5 at 7-10.
    /// Levels 2/4/6 are 3/4/4 to match old easy/medium/hard.
    static let choicesByLevel: [Int] = [2, 3, 3, 4, 4, 4, 5, 5, 5, 5]
    /// Whether distractors prefer the same theme. False at 1-5, true at 6-10
    /// so level 6 is exactly the old hard.
    static let sameThemeByLevel: [Bool] = [false, false, false, false, false, true, true, true, true, true]

    static func choiceCount(for difficulty: Difficulty) -> Int {
        difficulty.values(choicesByLevel)
    }

    /// The endings a round shows on a phone with room for only `count` (#415): his own ending and the
    /// first `count - 1` others, in the order dealt, so trimming never moves a button. Never fewer than
    /// two (one is no choice), never more than were dealt.
    static func shown(_ round: SayingRound, count: Int) -> [Saying] {
        var others = max(count, 2) - 1
        return round.choices.filter { choice in
            if choice == round.saying { return true }
            others -= 1
            return others >= 0
        }
    }

    /// How many of a round's endings fit in `room` points (#415), from each ending button's measured
    /// height (a long or localized ending, or big text, wraps to more than 100pt) and the `gap` between
    /// buttons: the most whose buttons, as `shown` picks them, stack within the room, never under 2. An
    /// ending not measured yet counts as 0, so the first layout shows them all until it is.
    static func fittingCount(_ round: SayingRound, heights: [Saying: Double], gap: Double, room: Double) -> Int {
        for count in stride(from: round.choices.count, to: 2, by: -1) {
            let endings = shown(round, count: count)
            let needed = endings.reduce(0) { $0 + (heights[$1] ?? 0) } + gap * Double(endings.count - 1)
            if needed <= room { return count }
        }
        return 2
    }

    /// Whether this level prefers same-theme distractors first.
    static func prefersSameTheme(for difficulty: Difficulty) -> Bool {
        difficulty.values(sameThemeByLevel)
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
                prefersSameTheme(for: difficulty)
                ? rest.filter { $0.theme == saying.theme } + rest.filter { $0.theme != saying.theme }
                : rest
            return SayingRound(
                saying: saying,
                choices: ([saying] + distractors.prefix(others)).shuffled(using: &generator))
        }
    }
}
