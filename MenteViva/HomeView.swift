import SwiftUI

/// Home: the one screen dad lands on. Big warm tiles, one per game, no
/// navigation puzzles. Tiles carry the game emoji so the screen is readable
/// even when the text is too small for him to bother with.
struct HomeView: View {
    /// Emoji per game, matching HistoryView and the tile grid.
    private static let games: [(id: String, emoji: String, titleKey: String)] = [
        ("memory", "🧩", "game.memory.title"),
        ("colorclash", "🎨", "game.colorclash.title"),
        ("herd", "🐾", "game.category.title"),
        ("math", "🔢", "game.math.title"),
        ("quickeyes", "👀", "game.quickeyes.title"),
    ]

    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 16)]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(String(localized: "home.greeting"))
                        .font(.title2)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 4)

                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(Self.games, id: \.id) { game in
                            NavigationLink {
                                destination(for: game.id)
                            } label: {
                                GameTile(emoji: game.emoji,
                                         title: String(localized: String.LocalizationValue(game.titleKey)))
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    NavigationLink {
                        HistoryView()
                    } label: {
                        Label(String(localized: "history.title"), systemImage: "calendar")
                            .font(.title3.weight(.semibold))
                            .frame(maxWidth: .infinity, minHeight: 72)
                            .background(.blue.opacity(0.12), in: .rect(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint(String(localized: "home.week.hint"))
                }
                .padding()
            }
            .navigationTitle(String(localized: "app.title"))
        }
    }

    @ViewBuilder
    private func destination(for id: String) -> some View {
        switch id {
        case "memory": MemoryMatchView()
        case "colorclash": ColorClashView()
        case "herd": CategoryFluencyView()
        case "math": MathStreakView()
        case "quickeyes": QuickEyesView()
        default: EmptyView()
        }
    }
}

/// One game tile: big emoji over the localized name. Deliberately large
/// (>=150pt wide, 140pt tall) — conventions.md §4 wants >=100pt targets.
private struct GameTile: View {
    let emoji: String
    let title: String

    var body: some View {
        VStack(spacing: 12) {
            Text(emoji)
                .font(.system(size: 56))
                .accessibilityHidden(true)
            Text(title)
                .font(.title3.weight(.semibold))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, minHeight: 140)
        .padding(12)
        .background(.blue.opacity(0.12), in: .rect(cornerRadius: 20))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(title))
    }
}

#Preview {
    HomeView()
}
