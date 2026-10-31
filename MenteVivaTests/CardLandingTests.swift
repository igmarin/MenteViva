import XCTest

@testable import MenteViva

/// The finished card landing on today's slot of the week board (#421): the flight is only a
/// vector and a few durations, so the vector is tested here and the view just plays it.
final class CardLandingTests: XCTestCase {

    private let card = CGRect(x: 100, y: 40, width: 190, height: 260)
    private let slot = CGRect(x: 250, y: 600, width: 38, height: 50)

    func testGivenAnUntiltedCardWhenOffsetThenItsCentreMovesOntoTheSlotCentre() {
        let offset = CardLanding.offset(from: card, to: slot, tiltedBy: 0)

        XCTAssertEqual(card.midX + offset.width, slot.midX, accuracy: 0.001)
        XCTAssertEqual(card.midY + offset.height, slot.midY, accuracy: 0.001)
    }

    func testGivenATiltedCardWhenOffsetThenTheTiltedOffsetStillEndsOnTheSlotCentre() {
        let tilt = -4.0

        let offset = CardLanding.offset(from: card, to: slot, tiltedBy: tilt)

        // The view applies the offset inside the tilt, so the tilt turns the vector the player sees.
        let radians = tilt * .pi / 180
        let seenX = offset.width * cos(radians) - offset.height * sin(radians)
        let seenY = offset.width * sin(radians) + offset.height * cos(radians)
        XCTAssertEqual(card.midX + seenX, slot.midX, accuracy: 0.001)
        XCTAssertEqual(card.midY + seenY, slot.midY, accuracy: 0.001)
    }
}
