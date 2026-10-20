# How Mente Viva works

A tour of the app for someone new to the code. Rules live in [conventions.md](conventions.md), reasons in
[decisions.md](decisions.md); this doc only says what happens, and where.

## One day in the app

```text
launch
  RootView (MenteVivaApp.swift)      first run → OnboardingView, otherwise HomeView
  HomeView.refreshPlan()             reads the last 14 days of sessions
    PlayerStateSummary.build         turns them into per-game numbers
    JevService.dailyPlan             today's three games + each game's level
  player taps "Play today's three"   games run back to back
  a game ends
    modelContext.record(GameSession) one row saved, then the celebration
    the card joins the week board    (no scores shown to the player)
```

## The pieces

| Piece | Where | What it does |
|---|---|---|
| App entry | `MenteViva/MenteVivaApp.swift` | Opens the SwiftData store. Local-only build by default (free Apple ID). If no store opens, an in-memory one is used so play still works. |
| Home | `HomeView.swift`, `GameCard.swift`, `Theme.swift` | Deals today's three as framed cards; each game has its own colour and an emblem drawn in SwiftUI shapes. |
| Games | `Games/` | One file per game, plus the shared celebration, miss cue and `fitOrScroll`. |
| Game list | `Models/GameID.swift` | The single list of games: stable ID, emoji, title key, whether it has levels. |
| Levels | `Models/Difficulty.swift` | easy / medium / hard. Each game turns a level into its own knobs with `pick(easy, medium, hard)`. |
| Saved play | `Models/GameSession.swift` | One row per finished game: rounds, attempts, correct, duration, level. No scores on screen. |
| Daily plan | `Services/DailyPolicy.swift` | Pure rules: which three games, and each game's level. No network. |
| Plan cache | `Services/PlanStore.swift`, `JevService.swift` | The plan is cached for the day. Jev can override it, but only when a proxy is configured. |
| Progress | `Services/WeeklySummary.swift`, `ProgressRates.swift` | Rates, never sums: accuracy per play, level reached, days played. Feeds My Week and My progress. |
| Family screens | `SetUpView.swift`, `MyProgressView.swift`, `Services/FamilySettings.swift` | Per device: hide a game, pin a level, choose Memory Lane photos. |
| Strings | `Localizable.xcstrings` | Every word, English and Spanish. |

## The games

Memory Lane, Name the Herd, Quick Eyes, Remember Together, Color Clash and Number Trail (the last two are
hidden on dad's iPad). Sudoku (#179) and Up or Down (#180) are new. Each game has the same shape:
a `View`, `@State` for the round, `Difficulty.stored(.game)` read once on open, and one
`modelContext.record(GameSession(...))` when it finishes. Games with real logic keep it in a separate pure
file (`SudokuPuzzle`, `UpOrDownDeal`, `NumberTrailQuestion`) so it is tested without a screen.

## How today's three are chosen

`DailyPolicy.plan` scores every game and takes the top three:

```text
score = value[game] × (0.5 + 0.5 × daysSinceLastPlayed / 7)     (days capped at 7)
```

- `value` is a fixed weight per game (Memory Lane 1.0 … Number Trail 0.3). A game not played for a week
  counts fully; one played today counts half.
- Hidden games are never picked.
- **Levels** move one step at a time and only with evidence: below 65% accuracy → easier; 90%+ over at
  least 3 sessions → harder; then the level holds for 7 days so it never shifts under the player. A pinned
  level (Set up) wins over the rules.

## Jev: optional, and never in the binary

Jev is a hosted judgment service. It is off unless `MenteViva/Config/Local.xcconfig` (git-ignored) sets a proxy
URL. When on, `JevService` sends only anonymous per-game numbers (play counts, accuracy, days since played)
to a Cloudflare Worker (`proxy/worker.js`), which holds the real API key. Any failure, or no proxy, falls
back to `DailyPolicy`: the app must always work offline. See [jev-integration.md](jev-integration.md).

## Adding a game

1. Logic file first, test-first (`MenteVivaTests/…`, Given/When/Then names, seeded random generator).
2. The view, copied from the shape above; targets ≥ 60pt (aim 100pt), VoiceOver labels, warm miss copy.
3. `GameID` case, ink colour in `Theme.swift`, emblem in `GameCard.swift`, route in `HomeView.destination`,
   weight in `DailyPolicy.value`.
4. Strings in `Localizable.xcstrings`, EN + ES, in the same commit.
5. Jev contract: add the ID to `GAMES` in `proxy/worker.js`, capture the app's new request in
   `docs/jev-json/`, point `JevServiceTests` and `worker.test.js` at it.
6. `swift tools/generate_project.swift`, then build, test and lint (AGENTS.md Workflow 5).

## What leaves the device

Nothing by default. No account, no ads, no tracking. Photos and their names never leave the device.
With a proxy configured, anonymous totals go to the Worker (see above).
