import XCTest

@testable import MenteViva

/// #376: the first finished game of a day turns over one of our illustrations for the player's
/// album. The same day always gives the same picture, a day turns over at most one, a missed day
/// costs nothing, and the album never runs dry.
final class DailyPictureTests: XCTestCase {
    private var defaults: UserDefaults!

    /// A fixed calendar so day boundaries do not depend on the runner's time zone.
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Madrid")!
        return calendar
    }

    /// Our illustrations, as the celebration passes them: every catalogue picture but the colours.
    private let pictures = DailyPicture.candidates(from: GamePictures.all, hasAsset: { _ in true })

    override func setUp() {
        defaults = UserDefaults(suiteName: "DailyPictureTests")!
        defaults.removePersistentDomain(forName: "DailyPictureTests")
    }

    private func date(_ day: Int, hour: Int = 12, minute: Int = 0) throws -> Date {
        try XCTUnwrap(
            calendar.date(from: DateComponents(year: 2026, month: 11, day: day, hour: hour, minute: minute)))
    }

    // MARK: - Pick

    func testGivenSameDayStampWhenPickingThenSamePictureEveryTime() {
        let first = DailyPicture.pick(dayStamp: "2026-11-04", from: pictures)
        for _ in 0..<20 {
            XCTAssertEqual(DailyPicture.pick(dayStamp: "2026-11-04", from: pictures), first)
        }
        // FNV-1a, not Swift's per-launch seeded hashValue: a known value pins it across launches.
        XCTAssertEqual(DailyPicture.fnv1a(""), 0xcbf2_9ce4_8422_2325)
        XCTAssertEqual(DailyPicture.fnv1a("a"), 0xaf63_dc4c_8601_ec8c)
    }

    func testGivenConsecutiveDaysWhenTurningOverEachDayThenEveryPictureArrivesBeforeAnyRepeats() throws {
        // The spread comes from turnOver's fresh-first pool, not from pick: collected pictures leave it.
        var turned: [String] = []
        for offset in 0..<pictures.count {
            let day = try XCTUnwrap(calendar.date(byAdding: .day, value: offset, to: try date(1)))
            let picture = try XCTUnwrap(
                PictureAlbum.turnOver(on: day, calendar: calendar, from: pictures, defaults: defaults))
            turned.append(picture.slug)
        }
        XCTAssertEqual(Set(turned).count, pictures.count)
        XCTAssertEqual(PictureAlbum.all(defaults: defaults), turned)
    }

    func testGivenColorSlugsWhenPickingThenTheyAreNeverChosen() {
        XCTAssertEqual(pictures.count, 69)
        XCTAssertFalse(pictures.contains { $0.slug.hasPrefix("color.") })
        for day in 1...28 {
            let stamp = String(format: "2026-02-%02d", day)
            XCTAssertFalse(DailyPicture.pick(dayStamp: stamp, from: pictures).slug.hasPrefix("color."))
        }
    }

    func testGivenPictureWithoutArtWhenListingCandidatesThenItIsLeftOut() {
        let candidates = DailyPicture.candidates(from: GamePictures.all, hasAsset: { $0 != "pic.dog" })
        XCTAssertFalse(candidates.contains { $0.slug == "dog" })
        XCTAssertEqual(candidates.count, 68)
    }

    // MARK: - Album

    func testGivenPictureCollectedWhenCollectingAgainThenAlbumHasItOnce() {
        PictureAlbum.collect("teapot", defaults: defaults)
        PictureAlbum.collect("rose", defaults: defaults)
        PictureAlbum.collect("teapot", defaults: defaults)
        XCTAssertEqual(PictureAlbum.all(defaults: defaults), ["teapot", "rose"])
    }

    func testGivenNoGameFinishedTodayWhenTheFirstEndsThenTodaysPictureJoinsTheAlbum() throws {
        let picture = try XCTUnwrap(
            PictureAlbum.turnOver(on: try date(4), calendar: calendar, from: pictures, defaults: defaults))
        XCTAssertEqual(picture, DailyPicture.pick(dayStamp: "2026-11-04", from: pictures))
        XCTAssertEqual(PictureAlbum.all(defaults: defaults), [picture.slug])
    }

    func testGivenTodaysPictureTurnedWhenAnotherGameEndsThenNothingTurnsAndAlbumIsUnchanged() throws {
        _ = PictureAlbum.turnOver(on: try date(4, hour: 0, minute: 1), calendar: calendar, from: pictures, defaults: defaults)
        let album = PictureAlbum.all(defaults: defaults)
        XCTAssertNil(
            PictureAlbum.turnOver(on: try date(4, hour: 23, minute: 59), calendar: calendar, from: pictures, defaults: defaults))
        XCTAssertEqual(PictureAlbum.all(defaults: defaults), album)
    }

    func testGivenLateEveningGameWhenTheNextGameIsJustAfterMidnightThenANewPictureTurns() throws {
        let evening = try XCTUnwrap(
            PictureAlbum.turnOver(on: try date(4, hour: 23, minute: 59), calendar: calendar, from: pictures, defaults: defaults))
        let morning = try XCTUnwrap(
            PictureAlbum.turnOver(on: try date(5, hour: 0, minute: 1), calendar: calendar, from: pictures, defaults: defaults))
        XCTAssertNotEqual(evening, morning)
        XCTAssertEqual(PictureAlbum.all(defaults: defaults), [evening.slug, morning.slug])
    }

    func testGivenAMissedDayWhenPlayingAgainThenOnePictureTurnsAndNothingIsLost() throws {
        let first = try XCTUnwrap(
            PictureAlbum.turnOver(on: try date(4), calendar: calendar, from: pictures, defaults: defaults))
        let afterGap = try XCTUnwrap(
            PictureAlbum.turnOver(on: try date(7), calendar: calendar, from: pictures, defaults: defaults))
        XCTAssertEqual(PictureAlbum.all(defaults: defaults), [first.slug, afterGap.slug])
    }

    func testGivenEveryPictureCollectedWhenANewDayStartsThenAFavouriteTurnsAgainAndTheAlbumKeepsEachOnce() throws {
        for picture in pictures { PictureAlbum.collect(picture.slug, defaults: defaults) }
        let album = PictureAlbum.all(defaults: defaults)
        let again = try XCTUnwrap(
            PictureAlbum.turnOver(on: try date(4), calendar: calendar, from: pictures, defaults: defaults))
        XCTAssertEqual(again, DailyPicture.pick(dayStamp: "2026-11-04", from: pictures))
        XCTAssertEqual(PictureAlbum.all(defaults: defaults), album)
    }

    func testGivenNoPicturesWhenAGameEndsThenNothingTurns() throws {
        XCTAssertNil(PictureAlbum.turnOver(on: try date(4), calendar: calendar, from: [], defaults: defaults))
        XCTAssertEqual(PictureAlbum.all(defaults: defaults), [])
    }
}
