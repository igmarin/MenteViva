import SwiftData
import SwiftUI

/// Home: the one screen dad lands on. Big warm tiles, one per game, no
/// navigation puzzles. Tiles carry the game emoji so the screen is readable
/// even when the text is too small for him to bother with.
struct HomeView: View {
    @Environment(\.dynamicTypeSize) private var typeSize
    /// Wider tiles at accessibility text sizes (#117) so names never break
    /// mid-word: one column on iPhone, two on iPad.
    private var columns: [GridItem] {
        [GridItem(.adaptive(minimum: typeSize.isAccessibilitySize ? 300 : 150), spacing: 16)]
    }
    @State private var showSettings = false
    @Environment(\.modelContext) private var modelContext
    /// Today's picks. Empty until the on-device policy has run (a local
    /// fetch, so effectively instant); nothing on this screen waits on the network.
    @State private var todaysMix: Set<GameID> = []
    /// Games the family hid on this device (#108).
    @AppStorage(FamilySettings.hiddenKey) private var hiddenGames = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(AppLanguage.localized("home.greeting"))
                        .font(.title2)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 4)

                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(GameID.allCases.filter { !FamilySettings.hidden(from: hiddenGames).contains($0) }, id: \.self) {
                            game in
                            NavigationLink {
                                destination(for: game)
                            } label: {
                                GameTile(
                                    emoji: game.emoji, title: AppLanguage.localized(game.title), ink: game.ink,
                                    isTodaysPick: todaysMix.contains(game))
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    NavigationLink {
                        HistoryView()
                    } label: {
                        Label(AppLanguage.localized("history.title"), systemImage: "calendar")
                            .font(.title3.weight(.semibold))
                            .frame(maxWidth: .infinity, minHeight: 100)
                            .background(.tint.opacity(0.12), in: .rect(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint(AppLanguage.localized("home.week.hint"))
                }
                .padding()
            }
            .navigationTitle(AppLanguage.localized("app.title"))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Label(AppLanguage.localized("settings.title"), systemImage: "gearshape")
                            .font(.title3)
                            .labelStyle(.iconOnly)
                            .bigTapTarget()
                    }
                    .accessibilityHint(AppLanguage.localized("settings.open.hint"))
                }
            }
            .task { await refreshPlan() }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
        }
    }

    /// Everything Home waits on before it can star today's games: a 14-day
    /// SwiftData fetch, the summary, and the plan — which, with a Jev proxy
    /// configured, includes a network call with a 10 s timeout.
    private func refreshPlan() async {
        await HotPath.measure("plan.today") {
            let since = Calendar.current.date(byAdding: .day, value: -14, to: .now) ?? .distantPast
            let recent =
                (try? modelContext.fetch(
                    FetchDescriptor<GameSession>(
                        predicate: #Predicate { $0.playedAt >= since }))) ?? []
            let difficulty = PlanStore.storedDifficulty()
            let state = PlayerStateSummary.build(from: recent, difficulty: difficulty)
            let plan = await JevService.shared.dailyPlan(state: state, currentDifficulty: difficulty)
            todaysMix = Set(plan.games)
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
        case .reminiscence: ReminiscenceView()
        }
    }
}

/// One game tile: big emoji over the localized name. Deliberately large
/// (>=150pt wide, 140pt tall) — conventions.md §4 wants >=100pt targets.
private struct GameTile: View {
    let emoji: String
    let title: String
    /// The game's own colour (Card Table theme); ContrastTests checks the badge on it.
    let ink: Color
    let isTodaysPick: Bool

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
            // Text + star, not color alone (conventions §4).
            if isTodaysPick {
                Label(AppLanguage.localized("home.today.badge"), systemImage: "star.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.todaysPick)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 140)
        .padding(12)
        .background(ink.opacity(isTodaysPick ? 0.22 : 0.12), in: .rect(cornerRadius: 20))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(title))
        .accessibilityValue(Text(isTodaysPick ? AppLanguage.localized("home.today.badge") : ""))
    }
}

extension Color {
    /// "Today's pick" badge: a deep orange in light mode, system orange in
    /// dark mode, so the text stays readable on its tile (#118, WCAG AA 4.5:1;
    /// plain orange was 1.65:1 in light mode). ContrastTests checks both.
    static let todaysPick = Color(
        UIColor { traits in
            traits.userInterfaceStyle == .dark ? .systemOrange : UIColor(red: 0.55, green: 0.27, blue: 0, alpha: 1)
        })
}

#Preview {
    HomeView()
}
