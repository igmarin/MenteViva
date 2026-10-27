import SwiftUI
import UIKit

/// Where the guide's demonstrated move happens (#243): a game marks one element with
/// `guideTarget()` and the overlay draws the ring and arrow over it.
private struct GuideTargetKey: PreferenceKey {
    nonisolated static var defaultValue: Anchor<CGRect>? { nil }

    nonisolated static func reduce(value: inout Anchor<CGRect>?, nextValue: () -> Anchor<CGRect>?) {
        value = value ?? nextValue()
    }
}

extension View {
    /// Marks the element the first-play guide should point at. Costs nothing when no guide shows.
    func guideTarget(_ isTarget: Bool = true) -> some View {
        anchorPreference(key: GuideTargetKey.self, value: .bounds) { isTarget ? $0 : nil }
    }

    /// A calm "Let me show you" overlay on a game's first open (#243). The game supplies the
    /// one line and a spoken description of the example; the overlay is the same everywhere.
    /// Adopting it in another game is this modifier plus a `guideTarget()` on the example.
    func firstPlayGuide(
        _ game: GameID, line: String, example: String, defaults: UserDefaults = .standard
    ) -> some View {
        modifier(FirstPlayGuide(game: game, line: line, example: example, defaults: defaults))
    }
}

/// The shared first-play guide: instruction in `.title2` read aloud, one highlighted move
/// (soft pulse and an arrow; Reduce Motion keeps the highlight only), "Got it" and
/// "Show me again" at 100pt. A VoiceOver modal, so the game behind is hidden while it shows.
private struct FirstPlayGuide: ViewModifier {
    let game: GameID
    let line: String
    let example: String
    let defaults: UserDefaults

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showing = false
    @State private var replay = 0

    func body(content: Content) -> some View {
        content
            .accessibilityHidden(showing)
            .overlayPreferenceValue(GuideTargetKey.self) { anchor in
                GeometryReader { proxy in
                    if showing {
                        overlay(target: anchor.map { proxy[$0] }, size: proxy.size)
                    }
                }
            }
            .onAppear {
                guard FirstPlayGuideStore.shouldShow(game, defaults: defaults) else { return }
                showing = true
                read()
            }
    }

    private func overlay(target: CGRect?, size: CGSize) -> some View {
        let cardAtTop = (target?.midY ?? 0) > size.height / 2
        return ZStack {
            Color.black.opacity(0.3).ignoresSafeArea()
            if let target {
                GuideRing(frame: target, reduceMotion: reduceMotion).id(replay)
            }
            VStack {
                if !cardAtTop { Spacer() }
                card
                if cardAtTop { Spacer() }
            }
            .padding()
        }
        .accessibilityAddTraits(.isModal)
    }

    private var card: some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                Text(line)
                    .font(.title2.weight(.semibold))
                Text(example)
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            .multilineTextAlignment(.center)
            .accessibilityElement(children: .combine)
            Button {
                FirstPlayGuideStore.markSeen(game, defaults: defaults)
                CaptionSpeaker.stop()
                showing = false
            } label: {
                Text(AppLanguage.localized("guide.gotit")).font(.title2.weight(.semibold))
            }
            .buttonStyle(AnswerTileStyle(minHeight: 100))
            Button {
                replay += 1
                read()
            } label: {
                Text(AppLanguage.localized("guide.again")).font(.title2.weight(.semibold))
            }
            .buttonStyle(AnswerTileStyle(strength: 0.08, minHeight: 100))
        }
        .padding(20)
        .background(Color(.systemBackground), in: .rect(cornerRadius: 20))
    }

    /// Reads the line aloud, unless VoiceOver is on: it reads the card itself, and two voices clash.
    private func read() {
        guard !UIAccessibility.isVoiceOverRunning else { return }
        CaptionSpeaker.speak(line)
    }
}

/// The ring and arrow over the example. The arrow is decoration (the example is also
/// written out in words), and the ring is never the only cue.
private struct GuideRing: View {
    let frame: CGRect
    let reduceMotion: Bool
    @State private var pulse = false

    var body: some View {
        let below = frame.minY < 70
        ZStack {
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color.amber, lineWidth: 6)
                .frame(width: frame.width + 12, height: frame.height + 12)
                .scaleEffect(pulse && !reduceMotion ? 1.08 : 1)
                .position(x: frame.midX, y: frame.midY)
            Image(systemName: below ? "arrow.up" : "arrow.down")
                .font(.system(size: 40, weight: .bold))
                .foregroundStyle(Color.amber)
                .position(x: frame.midX, y: below ? frame.maxY + 40 : frame.minY - 40)
        }
        .accessibilityHidden(true)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) { pulse = true }
        }
    }
}
