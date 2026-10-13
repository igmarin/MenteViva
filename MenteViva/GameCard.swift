import SwiftUI

/// A game as a framed card (Card Table, docs/design/2026-10-12-card-table.html):
/// paper, a frame in the game's ink around its emblem, and the name on a band of
/// that ink. The band's text is the background colour, which ContrastTests
/// checks against every ink. Home's tiles are these cards.
struct GameCard: View {
    let game: GameID
    var isTodaysPick = false

    private static let art = UnevenRoundedRectangle(
        topLeadingRadius: 13, bottomLeadingRadius: 4, bottomTrailingRadius: 4, topTrailingRadius: 13)
    private static let plate = UnevenRoundedRectangle(
        topLeadingRadius: 4, bottomLeadingRadius: 13, bottomTrailingRadius: 13, topTrailingRadius: 4)

    var body: some View {
        let title = AppLanguage.localized(game.title)
        VStack(spacing: 5) {
            VStack(spacing: 8) {
                Emblem(game: game)
                    .frame(width: 64, height: 64)
                // Text + star, not color alone (conventions §4).
                if isTodaysPick {
                    Label(AppLanguage.localized("home.today.badge"), systemImage: "star.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.todaysPick)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(10)
            .background(game.ink.opacity(isTodaysPick ? 0.22 : 0.12), in: Self.art)
            .overlay(Self.art.strokeBorder(game.ink, lineWidth: 3))

            Text(title)
                .font(.title3.weight(.heavy))
                .fontDesign(.rounded)
                .foregroundStyle(Color(.systemBackground))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
                .padding(.horizontal, 6)
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(game.ink, in: Self.plate)
        }
        .padding(6)
        .frame(minHeight: 180)
        .background(Color(.systemBackground), in: .rect(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(.primary.opacity(0.08)))
        .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(title))
        .accessibilityValue(Text(isTodaysPick ? AppLanguage.localized("home.today.badge") : ""))
    }
}

/// A card that sinks a little while pressed, so the tap is felt before the
/// game opens. Under Reduce Motion it dims instead of moving.
struct CardPressStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.96 : 1)
            .opacity(configuration.isPressed && reduceMotion ? 0.8 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

/// Each game's emblem: plain geometry in the game's ink with one amber accent,
/// drawn on a 64-point grid and scaled to fit. Decorative; the card's name
/// carries the meaning for VoiceOver.
struct Emblem: View {
    let game: GameID

    var body: some View {
        Canvas { context, size in
            let scale = min(size.width, size.height) / 64
            context.translateBy(x: (size.width - 64 * scale) / 2, y: (size.height - 64 * scale) / 2)
            context.scaleBy(x: scale, y: scale)
            draw(in: &context)
        }
        .accessibilityHidden(true)
    }

    private func draw(in context: inout GraphicsContext) {
        let ink = GraphicsContext.Shading.color(game.ink)
        let amber = GraphicsContext.Shading.color(.amber)
        let line = StrokeStyle(lineWidth: 3.5, lineCap: .round, lineJoin: .round)
        switch game {
        case .memoryMatch:
            // Two cards, one face up with the icon's amber dot.
            context.fill(card(x: 9, y: 12, angle: -12), with: .color(game.ink.opacity(0.35)))
            context.fill(card(x: 25, y: 13, angle: 9), with: ink)
            context.fill(circle(39, 32, 5.5), with: amber)
        case .stroop:
            // Three overlapping inks.
            context.fill(circle(24, 25, 13), with: .color(Color(UIColor(rgb: 0xC8372D)).opacity(0.92)))
            context.fill(circle(40, 25, 13), with: .color(Color.amber.opacity(0.92)))
            context.fill(circle(32, 40, 13), with: .color(Color(UIColor(rgb: 0x2F62B5)).opacity(0.88)))
        case .categoryFluency:
            // Three in the pen, one left out.
            var pen = Path()
            pen.addLines([CGPoint(x: 7, y: 20), CGPoint(x: 7, y: 51), CGPoint(x: 43, y: 51), CGPoint(x: 43, y: 20)])
            context.stroke(pen, with: ink, style: line)
            for (x, y) in [(16.0, 41.0), (31, 41), (23.5, 29)] { context.fill(circle(x, y, 6), with: ink) }
            context.fill(circle(54, 22, 6), with: amber)
        case .mathStreaks:
            // Stepping stones along a dotted trail.
            var trail = Path()
            trail.move(to: CGPoint(x: 14, y: 50))
            trail.addCurve(to: CGPoint(x: 33, y: 32), control1: CGPoint(x: 26, y: 50), control2: CGPoint(x: 23, y: 32))
            trail.addCurve(to: CGPoint(x: 52, y: 14), control1: CGPoint(x: 43, y: 32), control2: CGPoint(x: 44, y: 14))
            context.stroke(trail, with: ink, style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [1, 6]))
            context.fill(circle(14, 50, 7.5), with: ink)
            context.fill(circle(33, 32, 7.5), with: ink)
            context.fill(circle(52, 14, 7.5), with: amber)
        case .quickEyes:
            // An eye, with an amber glint.
            var eye = Path()
            eye.move(to: CGPoint(x: 6, y: 32))
            eye.addQuadCurve(to: CGPoint(x: 58, y: 32), control: CGPoint(x: 32, y: 8))
            eye.addQuadCurve(to: CGPoint(x: 6, y: 32), control: CGPoint(x: 32, y: 56))
            context.stroke(eye, with: ink, style: line)
            context.fill(circle(32, 32, 10), with: ink)
            context.fill(circle(36, 28, 3), with: amber)
        case .reminiscence:
            // A framed photo: hills and an amber sun.
            context.stroke(
                Path(roundedRect: CGRect(x: 10, y: 12, width: 44, height: 40), cornerRadius: 5), with: ink, style: line)
            var hills = Path()
            hills.addLines([
                CGPoint(x: 14, y: 48), CGPoint(x: 27, y: 33), CGPoint(x: 35, y: 41), CGPoint(x: 41, y: 35),
                CGPoint(x: 50, y: 48),
            ])
            hills.closeSubpath()
            context.fill(hills, with: ink)
            context.fill(circle(44, 22, 4.5), with: amber)
        }
    }

    private func circle(_ x: Double, _ y: Double, _ r: Double) -> Path {
        Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2))
    }

    /// A 28 × 38 card turned by `angle` degrees around its centre.
    private func card(x: Double, y: Double, angle: Double) -> Path {
        let rect = CGRect(x: x, y: y, width: 28, height: 38)
        let turn = CGAffineTransform(translationX: rect.midX, y: rect.midY)
            .rotated(by: angle * .pi / 180)
            .translatedBy(x: -rect.midX, y: -rect.midY)
        return Path(roundedRect: rect, cornerRadius: 5).applying(turn)
    }
}
