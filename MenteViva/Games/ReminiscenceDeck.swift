import Foundation

/// One card of Photo Stories (#139): a picture and, if there is one, the
/// name that helps remember it, and the warm question (#379) that invites a story.
nonisolated struct ReminiscenceCard: Equatable, Identifiable {
    enum Picture: Equatable {
        case photo(URL)
        case object(EverydayObject)
    }

    let id: Int
    let picture: Picture
    let caption: String?
    /// Localization key of the question shown under the name once revealed;
    /// `dealSession` sets it, so a hand-built card has none.
    var question: String?

    /// Localization key of the prompt shown before the name is revealed; the screen, the
    /// header and the VoiceOver announcement of the next card all read this one key. A photo
    /// invites a story whether or not it has a name (#513); "Who is this?" now only names a photo.
    var promptKey: String {
        if case .photo = picture { return "game.reminiscence.prompt.story" }
        return "game.reminiscence.prompt.object"
    }
}

/// Which cards a session shows: the family's photos, in the order given (the view shuffles).
/// Everyday objects only when there are no photos at all, which the game is not dealt for (#513).
enum ReminiscenceDeck {
    static let cardsPerSession = 5

    /// One session: photos and objects in random order, so a player without
    /// photos does not see the same five objects every time. Each card gets its
    /// own conversation prompt (#379), from the photo or the object pool.
    static func dealSession<G: RandomNumberGenerator>(
        photos: [URL], captions: [URL: String], using generator: inout G
    ) -> [ReminiscenceCard] {
        let cards = deal(
            photos: photos.shuffled(using: &generator), captions: captions,
            objects: EverydayObjects.all.shuffled(using: &generator))
        let questions = ConversationPrompts.deal(count: cards.count, photos: !photos.isEmpty, using: &generator)
        return zip(cards, questions).map { card, question in
            ReminiscenceCard(id: card.id, picture: card.picture, caption: card.caption, question: question)
        }
    }

    static func deal(
        photos: [URL], captions: [URL: String],
        objects: [EverydayObject] = EverydayObjects.all,
        limit: Int = cardsPerSession,
        localize: (String) -> String = { AppLanguage.localized($0) }
    ) -> [ReminiscenceCard] {
        if photos.isEmpty {
            return objects.prefix(limit).enumerated().map { index, object in
                ReminiscenceCard(id: index, picture: .object(object), caption: localize(object.nameKey))
            }
        }
        return photos.prefix(limit).enumerated().map { index, url in
            ReminiscenceCard(id: index, picture: .photo(url), caption: captions[url])
        }
    }
}
