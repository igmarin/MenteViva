import Foundation

/// One card of a standard 52-card deck, drawn in SwiftUI (no image assets).
nonisolated struct PlayingCard: Hashable {
    enum Suit: CaseIterable {
        case spades, hearts, diamonds, clubs

        var isRed: Bool { self == .hearts || self == .diamonds }
        var symbol: String {
            switch self {
            case .spades: "♠"
            case .hearts: "♥"
            case .diamonds: "♦"
            case .clubs: "♣"
            }
        }
        var nameKey: String { "game.upordown.suit.\(self)" }
    }

    let rank: Int  // 1 (A) ... 13 (K)
    let suit: Suit

    /// What the card face shows: A, 2…10, J, Q, K.
    var rankText: String {
        switch rank {
        case 1: "A"
        case 11: "J"
        case 12: "Q"
        case 13: "K"
        default: "\(rank)"
        }
    }
    var rankKey: String { "game.upordown.rank.\(rank)" }
}

/// Up or Down (#180), a golf solitaire: a row of piles of three, an open card and the
/// deck. A pile's top card can be played when it is one higher or one lower than the
/// open card; suit never matters. Easy deals are checked so they can always be cleared.
nonisolated struct UpOrDownDeal: Equatable {
    private(set) var piles: [[PlayingCard]]  // last element = top card
    private(set) var open: PlayingCard
    private(set) var deck: [PlayingCard]  // last element = next to turn
    let wraps: Bool

    /// Narrowest card the player taps, in points (conventions §4), and the space between cards.
    static let minTarget = 60.0
    static let gap = 8.0
    static let cardsPerPile = 3
    private static let easyTries = 50

    /// One row per level 1...10 (#202): piles, whether King–Ace wraps, and
    /// whether the deal retries until it can always be cleared. Levels 2/4/6
    /// match old easy/medium/hard (4/5/6 piles, wrapping except hard, retries
    /// only where easy did) so migrated players notice nothing; piles never
    /// shrink, and wrapping and retries never come back once off.
    static let rulesPerLevel: [(piles: Int, wraps: Bool, clearable: Bool)] = [
        (3, true, true),
        (4, true, true),
        (4, true, true),
        (5, true, false),
        (5, true, false),
        (6, false, false),
        (6, false, false),
        (7, false, false),
        (7, false, false),
        (7, false, false),
    ]

    /// The table row for a level.
    static func rules(for difficulty: Difficulty) -> (piles: Int, wraps: Bool, clearable: Bool) {
        difficulty.values(rulesPerLevel)
    }

    /// Piles for a level, fewer where the row would put a card under 60pt.
    static func pileCount(for difficulty: Difficulty, width: Double) -> Int {
        var piles = rules(for: difficulty).piles
        while piles > 3 && !cardsFit(piles, in: width) { piles -= 1 }
        return piles
    }

    static func make<G: RandomNumberGenerator>(
        difficulty: Difficulty, width: Double, using generator: inout G
    ) -> UpOrDownDeal {
        let rules = rules(for: difficulty)
        let count = pileCount(for: difficulty, width: width)
        var made = deal(piles: count, wraps: rules.wraps, using: &generator)
        guard rules.clearable else { return made }
        // Every candidate is checked before it is returned.
        for _ in 0..<easyTries {
            if greedyClears(made) { return made }
            made = deal(piles: count, wraps: rules.wraps, using: &generator)
        }
        return made
    }

    /// Whether playable top cards are lifted as a hint: the first three levels
    /// only, where every deal is also checked clearable.
    static func liftsPlayableCards(at difficulty: Difficulty) -> Bool {
        difficulty.level <= 3
    }

    /// Stuck pulse and announcement rule (#265): announce only on the transition
    /// into stuck; pulse only while stuck with Reduce Motion off. The view feeds
    /// it `onChange` values, so a re-render never re-announces.
    static func stuckCue(wasStuck: Bool, isStuck: Bool, reduceMotion: Bool) -> (pulse: Bool, announce: Bool) {
        (isStuck && !reduceMotion, isStuck && !wasStuck)
    }

    static func canPlay(_ card: PlayingCard, on open: PlayingCard, wraps: Bool) -> Bool {
        let distance = abs(card.rank - open.rank)
        return distance == 1 || (wraps && distance == 12)
    }

    /// Plays the first card that fits, else turns the deck: can that clear the table?
    static func greedyClears(_ deal: UpOrDownDeal) -> Bool {
        var deal = deal
        while !deal.isCleared {
            if let pile = deal.playablePiles.first {
                deal.play(pile: pile)
            } else if !deal.turn() {
                return false
            }
        }
        return true
    }

    var playablePiles: [Int] {
        piles.indices.filter { piles[$0].last.map { Self.canPlay($0, on: open, wraps: wraps) } ?? false }
    }

    var isCleared: Bool { piles.allSatisfy(\.isEmpty) }
    var isStuck: Bool { !isCleared && deck.isEmpty && playablePiles.isEmpty }
    var tableCards: Int { piles.count * Self.cardsPerPile }
    var cardsLeftOnTable: Int { piles.reduce(0) { $0 + $1.count } }

    /// Whether this row of piles keeps 60pt cards at `width`. A six-pile row dealt in
    /// landscape on a small iPhone stops fitting when the phone turns to portrait.
    func fits(width: Double) -> Bool { Self.cardsFit(piles.count, in: width) }

    /// Plays the pile's top card; false, and nothing changes, if it doesn't fit.
    @discardableResult
    mutating func play(pile: Int) -> Bool {
        guard playablePiles.contains(pile), let card = piles[pile].popLast() else { return false }
        open = card
        return true
    }

    /// Turns a new open card from the deck; false if the deck is empty.
    @discardableResult
    mutating func turn() -> Bool {
        guard let card = deck.popLast() else { return false }
        open = card
        return true
    }

    private static func cardsFit(_ count: Int, in width: Double) -> Bool {
        (width - gap * Double(count - 1)) / Double(count) >= minTarget
    }

    private static func deal<G: RandomNumberGenerator>(
        piles count: Int, wraps: Bool, using generator: inout G
    ) -> UpOrDownDeal {
        var cards = PlayingCard.Suit.allCases.flatMap { suit in (1...13).map { PlayingCard(rank: $0, suit: suit) } }
            .shuffled(using: &generator)
        let piles = (0..<count).map { _ in (0..<cardsPerPile).map { _ in cards.removeLast() } }
        let open = cards.removeLast()
        return UpOrDownDeal(piles: piles, open: open, deck: cards, wraps: wraps)
    }
}
