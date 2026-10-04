import Foundation

/// One card of Remember Together (#139): a picture and, if there is one, the
/// name that helps remember it.
struct ReminiscenceCard: Equatable, Identifiable {
    enum Picture: Equatable {
        case photo(URL)
        case symbol(String)
    }

    let id: Int
    let picture: Picture
    let caption: String?
}

/// Which cards a session shows: the family's photos first, in the order given
/// (the view shuffles); everyday objects only when there are no photos at all.
enum ReminiscenceDeck {
    static let cardsPerSession = 5

    /// One session: photos and objects in random order, so a player without
    /// photos does not see the same five objects every time.
    static func dealSession<G: RandomNumberGenerator>(
        photos: [URL], captions: [URL: String], using generator: inout G
    ) -> [ReminiscenceCard] {
        deal(
            photos: photos.shuffled(using: &generator), captions: captions,
            objects: EverydayObjects.all.shuffled(using: &generator))
    }

    static func deal(
        photos: [URL], captions: [URL: String],
        objects: [EverydayObject] = EverydayObjects.all,
        limit: Int = cardsPerSession,
        localize: (String) -> String = { AppLanguage.localized($0) }
    ) -> [ReminiscenceCard] {
        if photos.isEmpty {
            return objects.prefix(limit).enumerated().map { index, object in
                ReminiscenceCard(id: index, picture: .symbol(object.symbol), caption: localize(object.nameKey))
            }
        }
        return photos.prefix(limit).enumerated().map { index, url in
            ReminiscenceCard(id: index, picture: .photo(url), caption: captions[url])
        }
    }
}
