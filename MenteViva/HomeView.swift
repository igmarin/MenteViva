import SwiftData
import SwiftUI

/// Home (Card Table, step 4): a greeting, today's games dealt on a table with
/// one button that always names the next game, the week board, and every game
/// below. Dad never has to choose where to start; he can still pick any game.
struct HomeView: View {
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.modelContext) private var modelContext
    /// This week's sessions, so the table and week board update the moment a game
    /// is saved without loading years of history. The week is fixed when Home is
    /// made; everything below also filters by day, so a stale week stays correct.
    @Query(GameSession.thisWeek()) private var sessions: [GameSession]
    @State private var showSettings = false
    /// The games opened from Home, so "Next" can swap the finished game for the next one.
    @State private var path = GamePath()
    /// Today's picks in plan order. Empty until the on-device policy has run (a
    /// local fetch, so effectively instant); nothing here waits on the network.
    @State private var plan: [GameID] = []
    /// The day `plan` was made for; a new day (seen when the app comes back) re-plans.
    @State private var planDay = PlanStore.dayStamp()
    @Environment(\.scenePhase) private var scenePhase
    /// Games the family hid on this device (#108).
    @AppStorage(FamilySettings.hiddenKey) private var hiddenGames = ""
    /// Only read to re-key the screen: a language change must redraw every name.
    @AppStorage(AppLanguage.storageKey) private var appLanguage = AppLanguage.system.rawValue

    private var hidden: Set<GameID> { FamilySettings.hidden(from: hiddenGames) }
    private var today: TodayRun { TodayRun(plan: plan, hidden: hidden, sessions: sessions) }
    private var week: [(day: Date, games: [GameID])] {
        DayGrouping.thisWeek(sessions, date: \.playedAt).map { (day: $0.day, games: $0.items.compactMap(\.game)) }
    }

    /// Wider cards at accessibility text sizes (#117) so names never break
    /// mid-word: one column on iPhone, two on iPad.
    private var columns: [GridItem] {
        [GridItem(.adaptive(minimum: typeSize.isAccessibilitySize ? 300 : 150), spacing: 16)]
    }

    var body: some View {
        NavigationStack(path: $path.games) {
            ScrollView {
                if sizeClass == .regular {
                    // iPad: today on the left, everything else on the right.
                    HStack(alignment: .top, spacing: 32) {
                        todayColumn.frame(maxWidth: 560)
                        VStack(alignment: .leading, spacing: 20) {
                            allGames
                            if !today.isFinished { weekCard }
                        }
                    }
                    .padding()
                } else {
                    VStack(alignment: .leading, spacing: 20) {
                        todayColumn
                        if !today.isFinished { weekCard }
                        allGames
                    }
                    .padding()
                }
            }
            .pageBackground()
            // Cards take their name from a function, not the environment, so without
            // a new identity they keep the old language until the app restarts.
            .id(appLanguage)
            .navigationTitle(AppLanguage.localized("app.title"))
            .navigationBarTitleDisplayMode(.inline)
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
            .navigationDestination(for: GameID.self) { destination(for: $0) }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
        }
        // On the stack, not its root: the root disappears on every push, which
        // restarted the plan (a fetch) on every Back.
        // Keyed by day, it runs at launch and again when the day rolls over.
        .task(id: planDay) { refreshPlan() }
        // Settings -> My plan can start the warm-up (#213), which replaces today's plan.
        .onChange(of: showSettings) { _, shown in
            if !shown { refreshPlan() }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { planDay = PlanStore.dayStamp() }
        }
        .environment(path)
    }

    // MARK: - Today

    private var todayColumn: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(Date.now, format: .dateTime.weekday(.wide).day().month(.wide))
                .font(.title3.weight(.semibold))
            Text(AppLanguage.localized(Greeting.key(hour: Calendar.current.component(.hour, from: .now))))
                .font(.largeTitle.bold())
                .fontDesign(.serif)
                .accessibilityAddTraits(.isHeader)
            Text(statusLine)
                .font(.title2.weight(.semibold))
            if !today.games.isEmpty {
                table.padding(.top, 10)
            }
        }
    }

    private var statusLine: String {
        if today.isFinished { return AppLanguage.localized("home.today.done") }
        if today.done.isEmpty { return AppLanguage.localized("home.greeting") }
        return AppLanguage.localized("home.today.togo \(today.remaining)" as String.LocalizationValue)
    }

    /// The icon's gradient with today's games on it: the hand and the button
    /// while there is something left, a tidy pile and the week once done.
    private var table: some View {
        VStack(spacing: 16) {
            if today.isFinished {
                pile
                weekLink { weekBoardCard }
            } else {
                hand
                nextButton
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .background(.table, in: .rect(cornerRadius: 30))
    }

    @ViewBuilder
    private var hand: some View {
        let games = today.games
        if typeSize.isAccessibilitySize {
            VStack(spacing: 10) {
                ForEach(games, id: \.self) { game in
                    NavigationLink(value: game) {
                        GameRow(game: game, playedToday: today.done.contains(game))
                    }
                    .buttonStyle(CardPressStyle())
                }
            }
        } else {
            HStack(spacing: -6) {
                ForEach(Array(games.enumerated()), id: \.element) { index, game in
                    let tilt = (Double(index) - Double(games.count - 1) / 2) * 7
                    NavigationLink(value: game) {
                        GameCard(game: game, size: .hand, playedToday: today.done.contains(game))
                    }
                    .buttonStyle(CardPressStyle())
                    .rotationEffect(.degrees(tilt))
                    .offset(y: tilt == 0 ? 0 : 8)
                }
            }
            .padding(.vertical, 8)
            .accessibilityElement(children: .contain)
            .accessibilityLabel(AppLanguage.localized("home.today.label"))
        }
    }

    /// Always names what comes next, so there is nothing to decide.
    @ViewBuilder
    private var nextButton: some View {
        if let next = today.next {
            NavigationLink(value: next) {
                HStack(spacing: 14) {
                    Image(systemName: "play.fill")
                        .font(.title3)
                        .foregroundStyle(Color.paper)
                        .frame(width: 46, height: 46)
                        .background(Color.brand, in: .circle)
                        .accessibilityHidden(true)
                    Text(
                        today.done.isEmpty
                            ? AppLanguage.localized("home.today.play")
                            : String(
                                format: AppLanguage.localized("home.today.continue %@"),
                                AppLanguage.localized(next.title))
                    )
                    .font(.title2.weight(.heavy))
                    .fontDesign(.rounded)
                    .foregroundStyle(Color.brand)
                    .multilineTextAlignment(.leading)
                }
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity, minHeight: 100)
                .background(Color.paper, in: .rect(cornerRadius: 26))
                .overlay(RoundedRectangle(cornerRadius: 26).strokeBorder(Color.espresso, lineWidth: 2))
            }
            .buttonStyle(CardPressStyle())
        }
    }

    /// Today's games once all are played: a tidy pile, the last one ticked.
    private var pile: some View {
        let games = today.games
        return ZStack {
            ForEach(Array(games.enumerated()), id: \.element) { index, game in
                let last = index == games.count - 1
                GameCard(game: game, size: .hand, playedToday: last)
                    .rotationEffect(.degrees(last ? 0 : (index.isMultiple(of: 2) ? -9 : 6)))
            }
        }
        .padding(.vertical, 10)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(AppLanguage.localized("home.today.done"))
    }

    // MARK: - Week and all games

    private var weekCard: some View {
        weekLink {
            weekBoardCard
                .shadow(color: .black.opacity(0.25), radius: 0, x: 3, y: 3)
        }
    }

    private var weekBoardCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(AppLanguage.localized("home.week.title"))
                    .font(.title3.weight(.heavy))
                Spacer()
                Image(systemName: "chevron.forward")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
            WeekBoard(days: week)
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 100)
        .background(Color.paper, in: .rect(cornerRadius: 24))
        .overlay(RoundedRectangle(cornerRadius: 24).strokeBorder(Color.espresso, lineWidth: 2))
    }

    /// My Week's door: the board itself, read by VoiceOver as "My Week".
    private func weekLink(@ViewBuilder _ label: () -> some View) -> some View {
        NavigationLink {
            HistoryView()
        } label: {
            label()
        }
        .buttonStyle(CardPressStyle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(AppLanguage.localized("history.title"))
        .accessibilityHint(AppLanguage.localized("home.week.hint"))
        .accessibilityAddTraits(.isButton)
    }

    private var allGames: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(AppLanguage.localized("home.allgames"))
                .font(.title3.weight(.heavy))
                .accessibilityAddTraits(.isHeader)
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(GameID.released.filter { !hidden.contains($0) }, id: \.self) { game in
                    NavigationLink(value: game) {
                        GameCard(game: game)
                    }
                    .buttonStyle(CardPressStyle())
                }
            }
        }
    }

    // MARK: - Plan

    /// Everything Home waits on before it can deal today's games: a 14-day
    /// SwiftData fetch, the summary, and the plan.
    private func refreshPlan() {
        HotPath.measure("plan.today") {
            let since = Calendar.current.date(byAdding: .day, value: -14, to: .now) ?? .distantPast
            let recent =
                (try? modelContext.fetch(
                    FetchDescriptor<GameSession>(
                        predicate: #Predicate { $0.playedAt >= since }))) ?? []
            let difficulty = PlanStore.storedDifficulty()
            let state = PlayerStateSummary.build(
                from: recent, difficulty: difficulty,
                lastChange: PlanStore.lastDifficultyChange())
            let plan = PlanStore.todaysPlan(state: state)
            self.plan = plan.games
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
        case .sudoku: SudokuView()
        case .upOrDown: UpOrDownView()
        case .sayings: SayingsView()
        case .repeatSequence: RepeatSequenceView()
        case .tangram: TangramView()
        case .tilePairs: TilePairsView()
        case .slidingBlocks: SlidingBlocksView()
        }
    }
}

extension Color {
    /// Warm text: dark tomato (#336). Was the "Today's pick" badge (#118: plain
    /// orange was 1.65:1 in light mode); now the text of the soft mustard "Almost"
    /// notes. ContrastTests checks it.
    static let todaysPick = Color.tomato
}

#Preview {
    HomeView()
}
