import CoreGraphics
import Foundation

/// How the celebration's card lands on today's slot of the week board (#421): it waits, shrinks
/// onto the slot, and the slot pulses. Only the numbers and the one vector live here, so the view
/// does no arithmetic and a test can check where the card ends up.
nonisolated enum CardLanding {
    /// Seconds the card rests after it has arrived, so the caption can be read first.
    static let hold = 1.2
    /// Seconds the card takes to shrink onto the slot.
    static let flight = 0.9
    /// The card's scale when it reaches the slot: 190pt wide becomes about 42pt, a little over a slot.
    static let shrink: CGFloat = 0.22
    /// How much the slot swells when the card arrives.
    static let pulse: CGFloat = 1.12

    /// The offset that carries the centre of `card` onto the centre of `slot`. The view applies it
    /// inside the card's own tilt (`tiltedBy`, in degrees), which turns the offset with it, so the
    /// vector is turned back by the same angle and the card still lands on the slot.
    static func offset(from card: CGRect, to slot: CGRect, tiltedBy degrees: Double) -> CGSize {
        let dx = Double(slot.midX - card.midX)
        let dy = Double(slot.midY - card.midY)
        let radians = -degrees * .pi / 180
        return CGSize(
            width: dx * cos(radians) - dy * sin(radians),
            height: dx * sin(radians) + dy * cos(radians))
    }
}
