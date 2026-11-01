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
    /// The hand card's width, narrowed by Home so a row fits the table (#365); nil keeps the full size.
    var handWidth: CGFloat?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private static let art = UnevenRoundedRectangle(
        topLeadingRadius: 13, bottomLeadingRadius: 4, bottomTrailingRadius: 4, topTrailingRadius: 13)
    private static let plate = UnevenRoundedRectangle(
        topLeadingRadius: 4, bottomLeadingRadius: 13, bottomTrailingRadius: 13, topTrailingRadius: 4)

    var body: some View {
        let title = AppLanguage.localized(game.title)
        let hand = size == .hand
        let width = handWidth ?? HandLayout.fullWidth
        // The hero picture is bigger than the emblem; both shrink with a narrowed hand card.
        let scale = hand ? width / HandLayout.fullWidth : 1
        let emblem = hand ? 52 * scale : 64
        VStack(spacing: 5) {
            illustration(emblem: emblem, picture: (hand ? 72 : 96) * scale)
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
        .frame(width: hand ? width : nil, height: hand ? 164 : nil)
        .frame(minHeight: hand ? nil : 180)
        .background(Color.paper, in: .rect(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Color.espresso, lineWidth: 2))
        .overlay(alignment: .topTrailing) {
            Group {
                if playedToday {
                    PlayedCheck().offset(x: 10, y: -10).transition(PlayedCheck.transition(reduceMotion: reduceMotion))
                }
            }
            .animation(PlayedCheck.animation(reduceMotion: reduceMotion), value: playedToday)
        }
        // A hard print shadow, not a soft blur: the retro card edge.
        // compositingGroup first, so the shadow follows the card outline, not each glyph (#366).
        .compositingGroup()
        .shadow(color: .black.opacity(0.25), radius: 0, x: 3, y: 3)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(title))
        .accessibilityValue(Text(playedToday ? AppLanguage.localized("home.today.played") : ""))
    }

    /// The game's retro illustration (#373), or its emblem for the games that have
    /// no picture yet. Decorative: the card's combined label already names the game.
    @ViewBuilder
    private func illustration(emblem: CGFloat, picture: CGFloat) -> some View {
        if let hero = game.heroPicture {
            PictureView(picture: hero, size: picture)
                .accessibilityHidden(true)
        } else {
            let side = Emblem.boards.contains(game) ? picture : emblem
            Emblem(game: game)
                .frame(width: side, height: side)
        }
    }
}

/// Today's game as a full-width row, for the largest text sizes where three
/// cards side by side would squeeze the names (#117). The name sits under the
/// emblem so it gets the whole width and never breaks mid-word.
struct GameRow: View {
    let game: GameID
    var playedToday = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

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
                Group {
                    if playedToday { PlayedCheck().transition(PlayedCheck.transition(reduceMotion: reduceMotion)) }
                }
                .animation(PlayedCheck.animation(reduceMotion: reduceMotion), value: playedToday)
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

/// Three paper cards fanned out, each holding one of our own pictures. It gives
/// the welcome screen and other first-sight moments the card look instead of a
/// system emoji. Decorative, so VoiceOver skips it. The cards deal in once with a
/// spring; under Reduce Motion they are simply there. Designed for exactly three
/// cards: the angles and the centre card assume it.
struct CardFan: View {
    let slugs: [String]

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// False until the cards have dealt out; Reduce Motion sets it true on appear.
    @State private var dealt = false

    private static let cardWidth: CGFloat = 112
    private static let overlap: CGFloat = 24
    private static let angles: [Double] = [-9, 0, 9]

    var body: some View {
        let spread = dealt ? 1.0 : 0.0
        HStack(spacing: -Self.overlap) {
            ForEach(Array(slugs.enumerated()), id: \.offset) { index, slug in
                let angle = Self.angles[index % Self.angles.count]
                let fromMiddle = Double(index - slugs.count / 2)
                card(slug)
                    .rotationEffect(.degrees(angle * spread))
                    // Stacked on the middle card until dealt.
                    .offset(x: -fromMiddle * (Self.cardWidth - Self.overlap) * (1 - spread))
                    // The centre card sits on top, like a hand of cards.
                    .zIndex(index == slugs.count / 2 ? 1 : 0)
            }
        }
        .onAppear {
            if reduceMotion {
                dealt = true
            } else {
                withAnimation(.spring(duration: 0.55, bounce: 0.3).delay(0.1)) { dealt = true }
            }
        }
        .accessibilityHidden(true)
    }

    private func card(_ slug: String) -> some View {
        PictureView(picture: GamePictures.named(slug), size: 84)
            .frame(width: Self.cardWidth, height: 156)
            .background(Color.paper, in: .rect(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Color.espresso, lineWidth: 2))
            // The same hard print shadow as GameCard.
            .shadow(color: .black.opacity(0.25), radius: 0, x: 3, y: 3)
    }
}

/// "Played today": a tick on an amber disc, a shape as well as a colour.
struct PlayedCheck: View {
    /// The tick pops in when a card becomes played while Home is on screen (#383); under Reduce
    /// Motion it fades instead of growing.
    static func transition(reduceMotion: Bool) -> AnyTransition { reduceMotion ? .opacity : .scale }

    static func animation(reduceMotion: Bool) -> Animation {
        reduceMotion ? .easeOut(duration: 0.2) : .spring(duration: 0.4, bounce: 0.4)
    }

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

    /// The games whose emblem is a mini board of the game itself (#512). They replaced an
    /// unrelated hero picture, so Home and the celebration draw them at the picture's size.
    static let boards: Set<GameID> = [.tangram, .slidingBlocks, .mathStreaks, .quickEyes, .reminiscence]

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
            // Number Trail: a dotted trail through stones numbered 1, 2, 3, the last one amber.
            var trail = Path()
            trail.move(to: CGPoint(x: 13, y: 50))
            trail.addCurve(to: CGPoint(x: 32, y: 32), control1: CGPoint(x: 25, y: 50), control2: CGPoint(x: 22, y: 32))
            trail.addCurve(to: CGPoint(x: 51, y: 14), control1: CGPoint(x: 42, y: 32), control2: CGPoint(x: 43, y: 14))
            context.stroke(trail, with: ink, style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [1, 6]))
            for (index, (x, y)) in [(13.0, 50.0), (32, 32), (51, 14)].enumerated() {
                let last = index == 2
                context.fill(circle(x, y, 10), with: last ? amber : ink)
                digit(index + 1, at: CGPoint(x: x, y: y), color: last ? .onAmber : .paper, in: &context)
            }
        case .quickEyes:
            // Quick Eyes: an eye over a picture card that flashes past, its flash in amber.
            var eye = Path()
            eye.move(to: CGPoint(x: 8, y: 20))
            eye.addQuadCurve(to: CGPoint(x: 56, y: 20), control: CGPoint(x: 32, y: 2))
            eye.addQuadCurve(to: CGPoint(x: 8, y: 20), control: CGPoint(x: 32, y: 38))
            context.stroke(eye, with: ink, style: line)
            context.fill(circle(32, 20, 7), with: ink)
            let glimpse = Path(roundedRect: CGRect(x: 21, y: 37, width: 22, height: 24), cornerRadius: 4)
            context.stroke(glimpse, with: ink, style: line)
            context.fill(circle(32, 49, 5), with: amber)
            var flash = Path()
            let rays = [((16.0, 42.0), (10.0, 39.0)), ((16, 55), (10, 58)), ((48, 42), (54, 39)), ((48, 55), (54, 58))]
            for (from, to) in rays {
                flash.move(to: CGPoint(x: from.0, y: from.1))
                flash.addLine(to: CGPoint(x: to.0, y: to.1))
            }
            context.stroke(flash, with: amber, style: line)
        case .reminiscence:
            // Photo Stories: a framed photo (hills, amber sun) and a speech bubble telling its story.
            context.stroke(
                Path(roundedRect: CGRect(x: 6, y: 22, width: 40, height: 34), cornerRadius: 5), with: ink, style: line)
            var hills = Path()
            hills.addLines([
                CGPoint(x: 10, y: 52), CGPoint(x: 21, y: 39), CGPoint(x: 28, y: 46), CGPoint(x: 33, y: 41),
                CGPoint(x: 42, y: 52),
            ])
            hills.closeSubpath()
            context.fill(hills, with: ink)
            context.fill(circle(16, 31, 4), with: amber)
            var bubble = Path(roundedRect: CGRect(x: 32, y: 6, width: 28, height: 20), cornerRadius: 7)
            bubble.move(to: CGPoint(x: 38, y: 26))
            bubble.addLines([CGPoint(x: 34, y: 33), CGPoint(x: 45, y: 26)])
            context.fill(bubble, with: .color(.paper))
            context.stroke(bubble, with: ink, style: line)
            for x in [40.0, 46, 52] { context.fill(circle(x, 16, 2.5), with: ink) }
        case .sudoku:
            // A 3×3 board with a heavy frame and thin dividers, one square filled in amber. Three
            // columns, not Repeat the Sequence's two, so the pair differs in grayscale at 52pt.
            var board = Path()
            for step in [26.0, 38] {
                board.move(to: CGPoint(x: step, y: 12))
                board.addLine(to: CGPoint(x: step, y: 52))
                board.move(to: CGPoint(x: 12, y: step))
                board.addLine(to: CGPoint(x: 52, y: step))
            }
            context.stroke(board, with: ink, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
            context.stroke(
                Path(roundedRect: CGRect(x: 12, y: 12, width: 40, height: 40), cornerRadius: 4), with: ink, style: line)
            context.fill(Path(roundedRect: CGRect(x: 27.5, y: 27.5, width: 9, height: 9), cornerRadius: 2), with: amber)
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
            // Tangram: the classic seven pieces in their square (two large triangles, a medium one,
            // two small ones, the square and the parallelogram), the square in amber, paper seams.
            let pieces: [[(Double, Double)]] = [
                [(0, 0), (4, 0), (2, 2)], [(0, 0), (2, 2), (0, 4)], [(4, 2), (4, 4), (2, 4)],
                [(4, 0), (4, 2), (3, 1)], [(2, 2), (3, 3), (1, 3)], [(0, 4), (1, 3), (3, 3), (2, 4)],
                [(3, 1), (4, 2), (3, 3), (2, 2)],
            ]
            for (index, corners) in pieces.enumerated() {
                var piece = Path()
                piece.addLines(corners.map { CGPoint(x: 8 + $0.0 * 12, y: 8 + $0.1 * 12) })
                piece.closeSubpath()
                context.fill(piece, with: index == 6 ? amber : ink)
                context.stroke(piece, with: .color(.paper), style: StrokeStyle(lineWidth: 2.5, lineJoin: .round))
            }
        case .tilePairs:
            // Two stacked tiles and an amber dot.
            context.stroke(Path(roundedRect: CGRect(x: 12, y: 6, width: 40, height: 24), cornerRadius: 6), with: ink, style: line)
            context.stroke(
                Path(roundedRect: CGRect(x: 12, y: 34, width: 40, height: 24), cornerRadius: 6), with: ink, style: line)
            context.fill(circle(32, 46, 5), with: amber)
        case .slidingBlocks:
            // Sliding Blocks: a board with an exit in the middle of the bottom wall, the big amber
            // block above it with a chevron pointing out, and three small blocks around it.
            var frame = Path()
            frame.addLines([CGPoint(x: 22, y: 56), CGPoint(x: 8, y: 56), CGPoint(x: 8, y: 8), CGPoint(x: 56, y: 8)])
            frame.addLines([CGPoint(x: 56, y: 8), CGPoint(x: 56, y: 56), CGPoint(x: 42, y: 56)])
            context.stroke(frame, with: ink, style: line)
            for (x, y) in [(12.0, 12.0), (42, 12), (43, 36)] {
                context.fill(Path(roundedRect: CGRect(x: x, y: y, width: 10, height: 10), cornerRadius: 2.5), with: ink)
            }
            context.fill(Path(roundedRect: CGRect(x: 22, y: 23, width: 20, height: 20), cornerRadius: 3), with: amber)
            var arrow = Path()
            arrow.addLines([CGPoint(x: 27, y: 47), CGPoint(x: 32, y: 52), CGPoint(x: 37, y: 47)])
            context.stroke(arrow, with: amber, style: line)
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

    /// A number in the round print face, centred on `point`; the emblem's only text, so
    /// verbatim (digits read the same in EN and ES).
    private func digit(_ number: Int, at point: CGPoint, color: Color, in context: inout GraphicsContext) {
        let text = Text(verbatim: "\(number)").font(.system(size: 13, weight: .heavy, design: .rounded)).foregroundStyle(color)
        context.draw(text, at: point)
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
    /// True while today's slot should show that a card just landed on it (#421): a short swell, or,
    /// under Reduce Motion, a steady stronger ring and wash. Nothing else changes.
    var landed = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 4) {
            ForEach(days, id: \.day) { entry in
                VStack(spacing: 6) {
                    let isToday = calendar.isDateInToday(entry.day)
                    slot(entry.games)
                        .frame(width: 38, height: 50)
                        .overlay {
                            if isToday {
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(Color.amber, lineWidth: landed && reduceMotion ? 6 : 3)
                                    .background(
                                        Color.amber.opacity(landed && reduceMotion ? 0.3 : 0), in: .rect(cornerRadius: 12)
                                    )
                                    .padding(-5)
                            }
                        }
                        // Where the finished card lands: only today's slot says where it is.
                        .anchorPreference(key: LandingTargets.self, value: .bounds) {
                            isToday ? LandingTargets(slot: $0) : LandingTargets()
                        }
                        .scaleEffect(isToday && landed && !reduceMotion ? CardLanding.pulse : 1)
                        .animation(.spring(duration: 0.3, bounce: 0.5), value: landed)
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

/// The two frames the celebration's landing needs, reported up as anchors so each is read in the
/// same coordinate space: the finished card and today's slot on the week board (#421).
struct LandingTargets: PreferenceKey {
    var card: Anchor<CGRect>?
    var slot: Anchor<CGRect>?

    init(card: Anchor<CGRect>? = nil, slot: Anchor<CGRect>? = nil) {
        self.card = card
        self.slot = slot
    }

    static var defaultValue: LandingTargets { LandingTargets() }

    static func reduce(value: inout LandingTargets, nextValue: () -> LandingTargets) {
        let next = nextValue()
        value.card = value.card ?? next.card
        value.slot = value.slot ?? next.slot
    }
}
