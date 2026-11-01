import Foundation

/// The warm question under each revealed card in Photo Stories (#379), so
/// two people playing side by side get a conversation, not just a name. The
/// questions invite a story and have no right answer; they never ask who is in
/// the photo. Which one goes with which card is seeded and never repeats in a
/// session.
nonisolated enum ConversationPrompts {
    /// `reminiscence.ask.01` to `.16`: for the family's photos.
    static let photoKeys = (1...16).map { String(format: "reminiscence.ask.%02d", $0) }

    /// `reminiscence.askobject.01` to `.08`: for everyday objects, which are
    /// not a memory of anyone's, so they ask about the thing itself.
    static let objectKeys = (1...8).map { String(format: "reminiscence.askobject.%02d", $0) }

    /// Distinct prompt keys for one session, in card order. A session shows at
    /// most five cards, well inside each pool, so the cap on `count` only
    /// protects a caller that asks for more than the pool holds.
    static func deal<G: RandomNumberGenerator>(
        count: Int, photos: Bool, using generator: inout G
    ) -> [String] {
        let pool = photos ? photoKeys : objectKeys
        return Array(pool.shuffled(using: &generator).prefix(max(count, 0)))
    }
}
