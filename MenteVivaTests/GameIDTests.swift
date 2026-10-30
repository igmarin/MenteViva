import XCTest

@testable import MenteViva

/// Games registered ahead of their views (#215) stay invisible until each ships.
final class GameIDTests: XCTestCase {

    func testGivenAllGameIDsWhenRawValuesThenUniqueAndExistingUnchanged() {
        let raw = GameID.allCases.map(\.rawValue)
        XCTAssertEqual(Set(raw).count, raw.count)
        let existing = [
            "memory_match", "stroop", "category_fluency", "math_streaks", "quick_eyes",
            "reminiscence", "sudoku", "up_or_down", "sayings",
        ]
        XCTAssertEqual(Array(raw.prefix(existing.count)), existing)
        XCTAssertEqual(
            Set(raw).subtracting(existing), ["repeat_sequence", "tangram", "tile_pairs", "sliding_blocks", "photo_captions"])
    }

    func testGivenUnreleasedGamesWhenReleasedThenTheyAreLeftOut() {
        XCTAssertEqual(GameID.unreleased.count, 0)
        XCTAssertTrue(Set(GameID.released).isDisjoint(with: GameID.unreleased))
        XCTAssertEqual(GameID.released.count, GameID.allCases.count)
        XCTAssertTrue(GameID.released.contains(.slidingBlocks))
        XCTAssertTrue(GameID.released.contains(.tilePairs))
        XCTAssertTrue(GameID.released.contains(.photoCaptions))
        XCTAssertTrue(GameID.released.contains(.tangram))
        XCTAssertTrue(GameID.released.contains(.repeatSequence))
    }

    /// Home and the celebration card show a retro illustration per game (#373).
    private var gamesWithHero: [GameID] { GameID.allCases.filter { $0.heroPicture != nil } }

    func testGivenEveryGameWhenHeroPictureThenSlugExistsInCatalogue() {
        // GamePictures.named traps on a missing slug, so a bad slug crashes here
        // before the assert runs. The emblem-only set below is the real pin.
        let slugs = Set(GamePictures.all.map(\.slug))
        for game in GameID.allCases {
            guard let hero = game.heroPicture else { continue }
            XCTAssertTrue(slugs.contains(hero.slug), "\(game) hero slug \(hero.slug)")
        }
        // Colour Clash, Sudoku, Up or Down and Tile Pairs keep their emblem.
        let emblemOnly = GameID.allCases.filter { $0.heroPicture == nil }
        XCTAssertEqual(Set(emblemOnly), [.stroop, .sudoku, .upOrDown, .tilePairs])
    }

    func testGivenGamesWithHeroThenPicturesAreDistinct() {
        let slugs = gamesWithHero.compactMap { $0.heroPicture?.slug }
        XCTAssertEqual(slugs.count, 10)
        XCTAssertEqual(Set(slugs).count, slugs.count)
    }

    func testGivenHeroPictureThenAssetExistsInBundle() {
        for game in gamesWithHero {
            let hero = game.heroPicture
            let look = hero.map { $0.look(hasAsset: PictureView.bundleHasAsset) }
            XCTAssertEqual(look, hero.map { .asset($0.assetName) }, "\(game)")
        }
    }
}
