import SwiftUI

/// Home: the one screen dad lands on. Big warm tiles, one per game, no
/// navigation puzzles. Tiles carry the game emoji so the screen is readable
/// even when the text is too small for him to bother with.
struct HomeView: View {
    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 16)]
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(AppLanguage.localized( "home.greeting"))
                        .font(.title2)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 4)

                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(GameID.allCases, id: \.self) { game in
                            NavigationLink {
                                destination(for: game)
                            } label: {
                                GameTile(emoji: game.emoji, title: AppLanguage.localized( game.title))
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    NavigationLink {
                        HistoryView()
                    } label: {
                        Label(AppLanguage.localized( "history.title"), systemImage: "calendar")
                            .font(.title3.weight(.semibold))
                            .frame(maxWidth: .infinity, minHeight: 100)
                            .background(.blue.opacity(0.12), in: .rect(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint(AppLanguage.localized( "home.week.hint"))
                }
                .padding()
            }
            .navigationTitle(AppLanguage.localized( "app.title"))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Label(AppLanguage.localized( "settings.title"), systemImage: "gearshape")
                            .font(.title3)
                    }
                    .accessibilityHint(AppLanguage.localized( "settings.open.hint"))
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
        }
    }

    @ViewBuilder
    private func destination(for game: GameID) -> some View {
        switch game {
        case .memoryMatch: MemoryMatchView()
        case .stroop: ColorClashView()
        case .categoryFluency: CategoryFluencyView()
        case .mathStreaks: MathStreakView()
        case .quickEyes: QuickEyesView()
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
