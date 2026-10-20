# Three new games: Sudoku, Up or Down, Finish the Saying — design

Evidence: owner playtests with dad (2026-10, informal), Jev 012 ranking (sayings 1.83), Jev 016
(asked in step 0 of the plan). Lineup and build shape chosen by the owner on 2026-10-19.

## Intent

Dad likes the app but gets bored: "few games, very repetitive". His iPad shows 4 games (Color
Clash and Number Trail are hidden, #47) and Home deals 3 of those 4 every day. He used to enjoy
newspaper puzzles, card and table games, and sayings. The owner wants **more variety and a
higher ceiling**. One new game per hobby takes his library from 4 to 7, and every game below
deals fresh content each time, so no session looks like the last.

The design floor does not move: errorless, familiar, calm (product brief; early-stage dementia).
"Harder" means a bigger puzzle, never a timer, a lost game or a score on screen.

## Shared rules (all three)

- **One file per game** plus one pure logic file, written test-first (conventions §2, §9). No base
  class, no shared game protocol.
- **Fresh every time:** Sudoku and Up or Down generate on the device; Finish the Saying never
  repeats a saying until all have been seen.
- **Misses are warm:** `MissCue` on the tapped thing plus a hint line ("Almost — try another
  number."). The player always continues; nothing ends a game early.
- **Narrow screens:** each game computes its cell or card width from the available width. Where the
  level's layout would put a target under 60pt (iPhone SE, 375pt wide), it uses the next smaller
  layout named below. iPad targets aim for 100pt.
- **Session:** `modelContext.record(GameSession(...))` on finish with `correct` = right on the
  first tap, `attempts` = all taps that count, `difficulty` = the level read on open
  (`Difficulty.stored`). Score stays hidden (#45).
- **Plan:** each game is a normal game: Home card, daily-pick candidate, hideable, pinnable.
  `DailyPolicy.value` starts at 0.8 for each (Jev 016 may move it).

## 1. Sudoku (`sudoku`)

Title EN "Sudoku", ES "Sudoku" (the word he knows from the newspaper). Emoji ✏️.

- **Board:** easy 4×4 with 4 blanks; medium 4×4 with 8 blanks; hard 6×6 (2×3 boxes) with 18
  blanks. Narrow-screen hard: 4×4 with 10 blanks. Givens in ink, his numbers in the game colour.
- **Play:** the first blank starts selected (thick frame). He taps a big number button (1–4 or
  1–6) to fill it. Right → placed, success haptic, the next blank in reading order becomes
  selected. Not right → `MissCue` on the square, "Almost — try another number." Tapping any blank
  selects it.
- **"Show me one":** fills the selected blank with its answer in a softer colour. Counts as an
  attempt, not as correct.
- **End:** all squares filled. Celebration detail "You filled N squares".
- **Logic (`SudokuPuzzle`):** a solved grid from the base pattern, then shuffled digits, rows
  inside bands, bands, columns inside stacks, stacks. Blanks are removed in random order, keeping
  only removals that leave exactly one solution (a backtracking count that stops at 2). If the
  target count is not reached, start again from a new grid (up to 20 tries), then accept the
  closest. Takes any `RandomNumberGenerator`, so tests are deterministic.
- **VoiceOver:** "Row 2, column 3, 4" / "Row 2, column 3, empty"; buttons "Put 3".

## 2. Up or Down (`up_or_down`)

Title EN "Up or Down", ES "Sube o baja". Emoji 🃏. Golf solitaire.

- **Table:** a row of piles, 3 cards each, only the top card readable (the rest show as edges):
  easy 4 piles, medium 5, hard 6. Narrow screens drop to the widest row that keeps 60pt cards.
  Below them: the open card and the deck (the rest of a shuffled 52-card deck).
- **Card faces:** drawn in SwiftUI, big rank (A, 2…10, J, Q, K) and suit symbol (♠♥♦♣); red or
  black plus the symbol, never colour alone.
- **Play:** tap a top card one higher or one lower than the open card; it becomes the open card.
  Suit does not matter. Easy and medium wrap King↔Ace; hard does not. Tap the deck to turn a new
  open card at any time.
- **Help:** easy lifts the playable top cards. On every level, when no table card fits, the deck
  pulses and the line reads "No card fits — turn a new one." A card that does not fit gets
  `MissCue` and "Almost — it needs one more or one less than 7."
- **End:** table cleared ("You cleared the table!") or the deck is empty with no move left
  ("You cleared N cards"). Never "you lost".
- **Logic (`UpOrDownDeal`):** deal, `canPlay(card, on: open, wraps:)`, and `greedyClears(deal)`,
  a simple simulation (play the first legal top card, else turn the deck). Easy deals are redealt
  until greedy clears them (up to 50 tries). `correct` = cards played, `attempts` = taps on table
  cards, `rounds` = table cards.
- **VoiceOver:** "7 of hearts, fits" / "Queen of spades"; "Open card: 8 of clubs"; "Turn a new
  card, 12 left".

## 3. Finish the Saying (`sayings`)

Title EN "Finish the Saying", ES "Termina el refrán". Emoji 💬.

- **Round:** the start of a saying in large serif type with "…" ("Más vale pájaro en mano…"). He
  picks the ending: easy 3 choices, medium 4, hard 4 drawn from the same theme first (closer).
  Buttons are full width, text `.title2`, multiline.
- **Right:** the full saying shows, success haptic, a speaker button reads it aloud
  (`CaptionSpeaker`; speech only on tap), then "Next". **Not right:** `MissCue`, that button dims,
  "Almost — try again." He keeps choosing until right. 8 sayings per game.
- **Content:** 60 slots. Each slot has `saying.NN.start` / `saying.NN.end` keys in
  `Localizable.xcstrings`; the EN value is an English saying and the ES value a Spanish refrán on
  the same theme. They are **not translations**, and that keeps conventions §3 (every key EN +
  ES). The theme tag (animals, money, time, food, work, weather, friends, home) lives per slot in
  `Sayings.swift`. Content rule: nothing about age, memory, illness or death; no "old dog, new
  tricks". The ES list is checked by a native speaker before merge (the #12 process).
- **Logic (`SayingsDeck`):** deal 8 unseen slots, distractors from other slots (same theme first
  on hard), choices shuffled. Seen slot IDs persist in `UserDefaults` ("sayings.seen"); when fewer
  than 8 are unseen, the seen list resets. Tests use `UserDefaults(suiteName:)`.
- **End:** celebration detail "You finished N sayings".

## Files (per game, one PR each, in this order)

New: `Games/SudokuView.swift` + `Games/SudokuPuzzle.swift`; `Games/UpOrDownView.swift` +
`Games/UpOrDownDeal.swift`; `Games/SayingsView.swift` + `Games/SayingsDeck.swift` +
`Games/Sayings.swift`; tests `SudokuPuzzleTests`, `UpOrDownDealTests`, `SayingsDeckTests`.

Changed by every game: `Models/GameID.swift` (case, emoji, title), `Theme.swift` (ink colour),
`GameCard.swift` (emblem in shapes), `HomeView.swift` (route), `Services/DailyPolicy.swift`
(value), `Localizable.xcstrings`, `proxy/worker.js` (`GAMES`), `proxy/worker.test.js` and
`JevServiceTests` (new request capture), `project.pbxproj` (generator), `CHANGELOG.md`.

Starting ink colours (light / dark), checked against the six on Home and adjusted if two read
alike: Sudoku petrol `0x1F5F7A` / `0x86C5DE`; Up or Down wood `0x6B4F2A` / `0xD2B48C`; Finish the
Saying violet `0x5B3F8C` / `0xC3A8F0`. Emblems: a 2×2 grid with one amber square; two fanned
cards with an amber up-chevron; a speech bubble with three dots, one amber.

## Jev wire contract

A new `GameID` adds `include_` and `difficulty_` keys, so `JevServiceTests` (pinned to 014's 11
keys) and the proxy allow-list break on purpose. Each game PR: adds the ID to `GAMES` in
`proxy/worker.js`, captures the app's request through the stubbed `URLSession` as the next
`docs/jev-json` number (request only: 017, 018, 019), and points both tests at it (13, 15, 17
keys). After the third PR the owner redeploys the worker (`wrangler deploy`) and saves the live
response as `019-daily-plan.response.json`. Dad's build is local-only, so this never blocks him.

## Out of scope

A higher ceiling for the six existing games (the "Challenge level" tracked 2026-10-03; follow-up),
Sudoku pencil marks, word search, dominoes, decade trivia, timers, visible scores.

## Done when

Each game: tests green, lint clean, built on an iPhone SE and an iPad simulator, played once on
dad's iPad. Overall: dad plays a new game unprompted twice in one week (mvp G1b).
