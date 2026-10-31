# How Mente Viva works

A tour of the app for someone new to the code. Rules live in [conventions.md](conventions.md), reasons in
[decisions.md](decisions.md); this doc only says what happens, and where.

## One day in the app

```text
launch
  RootView (MenteVivaApp.swift)      first run → OnboardingView, otherwise HomeView
  HomeView.refreshPlan()             reads the last 14 days of sessions
    PlayerStateSummary.build         turns them into per-game numbers
    PlanStore.todaysPlan             today's three games + each game's level (DailyPolicy)
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
| Levels | `Models/Difficulty.swift` | Levels 1–10 (#197). A game turns its level into its own knobs with `values(_:)`, a ten-row table. |
| Saved play | `Models/GameSession.swift` | One row per finished game: rounds, attempts, correct, duration, level. No scores on screen. |
| Daily plan | `Services/DailyPolicy.swift` | Pure rules: which three games, and each game's level. No network. |
| Plan cache | `Services/PlanStore.swift` | The plan is saved for the day, with each game's level and when it last changed. |
| Progress | `Services/WeeklySummary.swift`, `ProgressRates.swift` | Rates, never sums: accuracy per play, level reached, days played. Feeds My Week and My progress. |
| Family screens | `SetUpView.swift`, `MyProgressView.swift`, `Services/FamilySettings.swift` | Per device: hide a game, pin a level, choose Memory Lane photos. |
| Strings | `Localizable.xcstrings` | Every word, English and Spanish. |

## The games

Memory Lane, Name the Herd, Quick Eyes, Remember Together, Color Clash and Number Trail (the last two are
hidden on dad's iPad). Sudoku (#179), Up or Down (#180) and Finish the Saying (#181) are new. Each game has the same shape:
a `View`, `@State` for the round, `Difficulty.stored(.game)` read once on open, and one
`modelContext.record(GameSession(...))` when it finishes. Games with real logic keep it in a separate pure
file (`SudokuPuzzle`, `UpOrDownDeal`, `SayingsDeck`, `NumberTrailQuestion`) so it is tested without a screen.

Names and Faces (#142) is Memory Lane's board with each family photo paired to its caption
(`MemoryMatchView(variant: .captions)`, deal in `PhotoCaptionDeal`). It needs four photos with different
captions; until then `GameAvailability` keeps it off Home, out of the daily plan and out of the family's
"last game visible" count.

## How today's three are chosen

`DailyPolicy.plan` scores every game and takes the top three:

```text
score = value[game] × (0.5 + 0.5 × daysSinceLastPlayed / 7)     (days capped at 7)
```

- `value` is a fixed weight per game (Memory Lane 1.0 … Number Trail 0.3). A game not played for a week
  counts fully; one played today counts half.
- Hidden games are never picked.
- **Levels** follow a staircase, once a day and never mid-game (#198): the newest session strong (90%+) → up
  one; the two newest strong → up two; the newest hard going (under 65%) → down one, never more. Only
  sessions at the current level since it last changed count, so that window is the hold. Memory Lane uses
  0.65 / 0.45, because its accuracy counts moves. After a strong game the player can also choose to go up
  one (#207). A pinned level (Set up) wins over the rules.

## Saved data

- **One SwiftData model, `GameSession`.** No relationships and no unique constraints, and every field has a
  default, so it would also work with CloudKit later. Fields: game ID, score (kept for old rows; new rows store 0, #416), rounds, attempts,
  correct, duration, played-at, level (-1 for old rows).
- **Rounds / attempts / correct mean the same in every game** (#58): `rounds` is what the session was made of,
  `attempts` is the picks the player made, `correct` is how many were right. `accuracy` is `correct / attempts`,
  or nil when there were no attempts (Remember Together records none).
- **Small settings live in `UserDefaults`:** the cached daily plan and levels (`PlanStore`), hidden games and
  pinned levels (`FamilySettings`), language, bigger text, sound, "Read names aloud", and which sayings have been
  seen (`sayings.seen`).
- **Photos and their names are files** in the app's private folder (`Services/MemoryPhotos.swift`): a `.jpg` with
  a `.txt` next to it for the name.
- Everything is per device. A free Apple ID has no iCloud sync, so the iPad and the iPhone each keep their own.

## Progress and the family screens

The player never sees numbers. The family does.

| Screen | For | Shows | Built from |
|---|---|---|---|
| Home week ring / board | player | Seven day slots; each finished game adds a small card in its colour. An empty day is a dashed outline, never a red mark. | `WeeklySummary`, `DayGrouping` |
| My Week | player | Per day, which cards were played. No scores. | `GameSession` rows |
| My progress | family | Per game, last 7 days: days played out of 7, mean accuracy per play, level reached, share of the week's plays. | `ProgressRates.week` |
| Set up | family | Hide a game, pin a level (Auto, or a 1–10 stepper), Memory Lane photos and their names. | `FamilySettings`, `MemoryPhotos` |
| History share | family | A plain-text card: days played and games played this week. Sent only when the player taps share. | `WeeklySummary.text` |

How the numbers are kept honest:

- **Rates, never sums.** A busy week doesn't look better than a calm one.
- **Level reached is the progress signal**, accuracy the second one. Accuracy alone drops whenever the rules
  raise the level, which would read as decline exactly when he improves.
- **A trend needs 3 or more plays this week**, and compares only with the player's own 4 earlier weeks of the
  same game. Accuracy changes under 5 points read as "about the same". An easier week is worded gently and
  never drawn as a down arrow.
- **No streaks, no leaderboards, no pressure timers, no reminders** (decisions 2026-10-03).

## Accessibility and language

- **Targets:** at least 60pt everywhere, 100pt for game controls. Games that lay out a board (Sudoku, Up or
  Down) count the gaps and deal a smaller layout where a target would fall under 60pt, such as hard Sudoku on an
  iPhone SE.
- **VoiceOver:** every interactive element has a label; state is spoken, not only shown (for example "row 2,
  column 3, empty"). Colour is never the only signal: playing cards show the suit symbol as well as red or black.
- **Text size:** Dynamic Type everywhere, `.title2` at minimum for instructions, and a "bigger text" switch in
  Settings. `fitOrScroll` lets a screen scroll only when it no longer fits.
- **Motion:** the miss cue (`MissCue`) skips its shrink under Reduce Motion; the outline alone carries it.
- **Tone:** failure copy is warm: "Almost — try again". Never "wrong", "error" or "failed". No medical claims
  anywhere ("fun mental exercise" is the ceiling).
- **Language:** English and Spanish, chosen in Settings or following the device. Strings come from the chosen
  language's own bundle (`AppLanguage.localized`), because `locale:` alone only formats. Every string is in
  `Localizable.xcstrings` in both languages in the same commit, and `ContrastTests` checks every game colour
  against the background in light and dark.
- **Sayings** are one key per half, `saying.NN.start` and `saying.NN.end`. The English value is an English
  saying and the Spanish value a refrán, written separately, not translated.

## Build, test and CI

- **The Xcode project is generated.** After adding or removing a `.swift` file, run
  `swift tools/generate_project.swift` and commit the project file. Close Xcode first.
- **Two build modes.** The default is local-only (no CloudKit), which a free Apple ID needs. A CloudKit build
  without its entitlement crashes at launch, and the simulator doesn't show it, so test the mode you ship, on a
  device.
- **Tests** are in `MenteVivaTests/`, named Given/When/Then. Pure logic is written test-first; SwiftUI layout is
  not tested. Tests never touch `UserDefaults.standard`; they use their own suite.
- **Before every push**, `.githooks/pre-push` runs lint (`swift-format --strict`), the signpost and project-file
  checks, and `xcodebuild test`. Install it once with `git config core.hooksPath .githooks`.
- **CI on pull requests to `main`**, split by cost (macOS minutes bill at 10 times Linux):
  - `checks.yml` on Linux, always: signposts match `docs/profiling.md`, the project file lists every `.swift`
    file. About 1 billed minute.
  - `swift.yml` on macOS, only for a non-draft PR that touches the app, tests, project or tools: regenerate the
    project, lint, `xcodebuild test`. About 20 billed minutes. Open a PR as a draft while iterating.
  - `ocr-review.yml` posts an automated code review on the PR.
- **Installing on a device** with a free Apple ID expires after 7 days; see [install-runbook.md](install-runbook.md).

## Adding a game

1. Logic file first, test-first (`MenteVivaTests/…`, Given/When/Then names, seeded random generator).
2. The view, copied from the shape above; targets ≥ 60pt (aim 100pt), VoiceOver labels, warm miss copy.
3. `GameID` case, ink colour in `Theme.swift`, emblem in `GameCard.swift`, route in `HomeView.destination`,
   weight in `DailyPolicy.value`.
4. Strings in `Localizable.xcstrings`, EN + ES, in the same commit.
5. When the game is playable, remove its ID from `GameID.unreleased`.
6. `swift tools/generate_project.swift`, then build, test and lint (AGENTS.md Workflow 5).

## What leaves the device

Nothing by default. No account, no ads, no tracking. Photos and their names never leave the device.
