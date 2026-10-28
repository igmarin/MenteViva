import SwiftUI

/// A game as a framed card (Card Table, docs/design/2026-10-12-card-table.html):
/// paper, a frame in the game's ink around its emblem, and the name on a band of
/// that ink. The band's text is the background colour, which ContrastTests
/// checks against every ink. Home's grid uses the full size; today's games on
/// the table use the hand size, with an amber check once played today.
struct GameCard: View {
    enum Size { case grid, hand }

    let game: GameID
    var size = Size.grid
    var playedToday = false

    private static let art = UnevenRoundedRectangle(
        topLeadingRadius: 13, bottomLeadingRadius: 4, bottomTrailingRadius: 4, topTrailingRadius: 13)
    private static let plate = UnevenRoundedRectangle(
        topLeadingRadius: 4, bottomLeadingRadius: 13, bottomTrailingRadius: 13, topTrailingRadius: 4)

    var body: some View {
        let title = AppLanguage.localized(game.title)
        let hand = size == .hand
        VStack(spacing: 5) {
            Emblem(game: game)
                .frame(width: hand ? 52 : 64, height: hand ? 52 : 64)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(hand ? 6 : 10)
                .background(game.ink.opacity(0.12), in: Self.art)
                .overlay(Self.art.strokeBorder(game.ink, lineWidth: 3))

            Text(title)
                .font((hand ? Font.headline : .title3).weight(.heavy))
                .fontDesign(.rounded)
                .foregroundStyle(Color.paper)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
                .padding(.horizontal, 6)
                .frame(maxWidth: .infinity, minHeight: hand ? 44 : 52)
                .background(game.ink, in: Self.plate)
        }
        .padding(6)
        .frame(width: hand ? 112 : nil, height: hand ? 164 : nil)
        .frame(minHeight: hand ? nil : 180)
        .background(Color.paper, in: .rect(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Color.espresso, lineWidth: 2))
        .overlay(alignment: .topTrailing) {
            if playedToday { PlayedCheck().offset(x: 10, y: -10) }
        }
        // A hard print shadow, not a soft blur: the retro card edge.
        .shadow(color: .black.opacity(0.25), radius: 0, x: 3, y: 3)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(title))
        .accessibilityValue(Text(playedToday ? AppLanguage.localized("home.today.played") : ""))
    }
}

/// Today's game as a full-width row, for the largest text sizes where three
/// cards side by side would squeeze the names (#117). The name sits under the
/// emblem so it gets the whole width and never breaks mid-word.
struct GameRow: View {
    let game: GameID
    var playedToday = false

    var body: some View {
        let title = AppLanguage.localized(game.title)
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Emblem(game: game)
                    .frame(width: 44, height: 44)
                    .padding(10)
                    .background(game.ink.opacity(0.12), in: .rect(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(game.ink, lineWidth: 3))
                Spacer(minLength: 0)
                if playedToday { PlayedCheck() }
            }
            Text(title)
                .font(.title2.weight(.heavy))
                .fontDesign(.rounded)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 100)
        .background(Color.paper, in: .rect(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(Color.espresso, lineWidth: 2))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(title))
        .accessibilityValue(Text(playedToday ? AppLanguage.localized("home.today.played") : ""))
    }
}

/// "Played today": a tick on an amber disc, a shape as well as a colour.
struct PlayedCheck: View {
    var body: some View {
        Image(systemName: "checkmark")
            .font(.system(size: 16, weight: .heavy))
            .foregroundStyle(Color.onAmber)
            .frame(width: 36, height: 36)
            .background(Color.amber, in: .circle)
            .overlay(Circle().strokeBorder(Color.paper, lineWidth: 3))
            .accessibilityHidden(true)
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
/// A game's emblem beside its name, for list rows and headers (Card Table:
/// emblems, not emoji). The caller sets the font.
struct GameName: View {
    let game: GameID
    @ScaledMetric(relativeTo: .title3) private var size: CGFloat = 28

    var body: some View {
        Label {
            Text(AppLanguage.localized(game.title))
        } icon: {
            Emblem(game: game).frame(width: size, height: size)
        }
    }
}

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
        case .sudoku:
            // A 2×2 board, one square filled in amber.
            for (index, origin) in [(10.0, 10.0), (34, 10), (10, 34), (34, 34)].enumerated() {
                let square = Path(roundedRect: CGRect(x: origin.0, y: origin.1, width: 20, height: 20), cornerRadius: 4)
                if index == 3 { context.fill(square, with: amber) } else { context.stroke(square, with: ink, style: line) }
            }
        case .upOrDown:
            // Two fanned cards and an amber "one up" chevron.
            context.fill(card(x: 8, y: 16, angle: -10), with: .color(game.ink.opacity(0.35)))
            context.fill(card(x: 22, y: 14, angle: 8), with: ink)
            var chevron = Path()
            chevron.addLines([CGPoint(x: 44, y: 16), CGPoint(x: 52, y: 7), CGPoint(x: 60, y: 16)])
            context.stroke(chevron, with: amber, style: StrokeStyle(lineWidth: 4.5, lineCap: .round, lineJoin: .round))
        case .sayings:
            // A speech bubble with three dots, the last one amber.
            var bubble = Path(roundedRect: CGRect(x: 8, y: 12, width: 48, height: 32), cornerRadius: 10)
            bubble.move(to: CGPoint(x: 18, y: 44))
            bubble.addLines([CGPoint(x: 14, y: 54), CGPoint(x: 28, y: 44)])
            context.stroke(bubble, with: ink, style: line)
            context.fill(circle(21, 28, 3.5), with: ink)
            context.fill(circle(32, 28, 3.5), with: ink)
            context.fill(circle(43, 28, 3.5), with: amber)
        case .repeatSequence:
            // A 2×2 grid with one amber tile lit.
            for (index, origin) in [(10.0, 10.0), (34, 10), (10, 34), (34, 34)].enumerated() {
                let square = Path(roundedRect: CGRect(x: origin.0, y: origin.1, width: 20, height: 20), cornerRadius: 4)
                if index == 1 { context.fill(square, with: amber) } else { context.stroke(square, with: ink, style: line) }
            }
        case .tangram:
            // A square split into triangles, one piece amber.
            let square = CGRect(x: 10, y: 10, width: 44, height: 44)
            var cuts = Path(roundedRect: square, cornerRadius: 4)
            cuts.move(to: CGPoint(x: 10, y: 10))
            cuts.addLine(to: CGPoint(x: 54, y: 54))
            cuts.move(to: CGPoint(x: 54, y: 10))
            cuts.addLine(to: CGPoint(x: 32, y: 32))
            context.stroke(cuts, with: ink, style: line)
            var piece = Path()
            piece.addLines([CGPoint(x: 54, y: 10), CGPoint(x: 54, y: 54), CGPoint(x: 32, y: 32)])
            piece.closeSubpath()
            context.fill(piece, with: amber)
        case .tilePairs:
            // Two stacked tiles and an amber dot.
            context.stroke(Path(roundedRect: CGRect(x: 12, y: 6, width: 40, height: 24), cornerRadius: 6), with: ink, style: line)
            context.stroke(
                Path(roundedRect: CGRect(x: 12, y: 34, width: 40, height: 24), cornerRadius: 6), with: ink, style: line)
            context.fill(circle(32, 46, 5), with: amber)
        case .slidingBlocks:
            // A frame with blocks and an amber block at the exit.
            var frame = Path()
            frame.addLines([CGPoint(x: 8, y: 36), CGPoint(x: 8, y: 8), CGPoint(x: 56, y: 8), CGPoint(x: 56, y: 22)])
            frame.move(to: CGPoint(x: 56, y: 40))
            frame.addLines([CGPoint(x: 56, y: 56), CGPoint(x: 8, y: 56), CGPoint(x: 8, y: 44)])
            context.stroke(frame, with: ink, style: line)
            context.fill(Path(roundedRect: CGRect(x: 14, y: 14, width: 16, height: 16), cornerRadius: 3), with: ink)
            context.fill(Path(roundedRect: CGRect(x: 14, y: 36, width: 28, height: 14), cornerRadius: 3), with: ink)
            context.fill(Path(roundedRect: CGRect(x: 36, y: 22, width: 16, height: 16), cornerRadius: 3), with: amber)
        case .photoCaptions:
            // A photo frame over a name line, with an amber sun in the frame.
            context.stroke(Path(roundedRect: CGRect(x: 10, y: 8, width: 44, height: 32), cornerRadius: 6), with: ink, style: line)
            context.fill(circle(24, 20, 5), with: amber)
            var hill = Path()
            hill.addLines([
                CGPoint(x: 14, y: 36), CGPoint(x: 28, y: 24), CGPoint(x: 38, y: 32), CGPoint(x: 46, y: 26), CGPoint(x: 50, y: 36),
            ])
            context.stroke(hill, with: ink, style: line)
            var name = Path()
            name.move(to: CGPoint(x: 16, y: 50))
            name.addLine(to: CGPoint(x: 48, y: 50))
            context.stroke(name, with: ink, style: line)
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

/// The week as seven dated slots (Card Table): each day shows up to three small
/// cards in the colours of the games played, the newest on top. Empty days are a
/// dashed outline, never a red mark; today has an amber ring. Decorative for
/// VoiceOver: whatever contains it gives the summary.
struct WeekBoard: View {
    let days: [(day: Date, games: [GameID])]
    var calendar = Calendar.current

    var body: some View {
        HStack(spacing: 4) {
            ForEach(days, id: \.day) { entry in
                VStack(spacing: 6) {
                    slot(entry.games)
                        .frame(width: 38, height: 50)
                        .overlay {
                            if calendar.isDateInToday(entry.day) {
                                RoundedRectangle(cornerRadius: 12).strokeBorder(Color.amber, lineWidth: 3).padding(-5)
                            }
                        }
                    Text(entry.day, format: .dateTime.weekday(.abbreviated))
                        .font(.subheadline.weight(.bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private func slot(_ games: [GameID]) -> some View {
        if games.isEmpty {
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(.secondary, style: StrokeStyle(lineWidth: 2, dash: [4, 4]))
        } else {
            let shown = Array(games.suffix(3))
            ZStack {
                ForEach(Array(shown.enumerated()), id: \.offset) { index, game in
                    let fromTop = shown.count - 1 - index
                    RoundedRectangle(cornerRadius: 6)
                        .fill(game.ink)
                        .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(Color.paper, lineWidth: 2))
                        .frame(width: 26, height: 36)
                        .rotationEffect(.degrees(fromTop == 0 ? 0 : (fromTop == 1 ? -11 : 10)))
                        .offset(x: fromTop == 0 ? 0 : (fromTop == 1 ? -4 : 4))
                }
            }
        }
    }
}
