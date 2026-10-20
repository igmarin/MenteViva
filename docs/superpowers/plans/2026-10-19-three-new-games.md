# Three New Games Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Three new games, Sudoku, Up or Down and Finish the Saying, so dad's library grows from 4 to 7 and every session deals fresh content.

**Architecture:** Each game is one pure logic file (written test-first, generic over `RandomNumberGenerator`) plus one view file in the `MathStreakView` / `MemoryMatchView` shape. Each game ships as its own PR, in order, because all three edit the same shared files (`GameID`, `Theme`, `GameCard`, `HomeView`, `DailyPolicy`, strings, Jev contract).

**Tech Stack:** SwiftUI, SwiftData, AVFoundation (existing `CaptionSpeaker`). No new dependencies.

**Spec:** `docs/superpowers/specs/2026-10-19-three-new-games-design.md`

## Global Constraints

- Zero third-party dependencies; SwiftUI/SwiftData/Foundation only.
- Every user-facing string in `MenteViva/Localizable.xcstrings` with EN + ES in the same commit; look up with `AppLanguage.localized(_:)`, counts with `String(format:)` like `MathStreakView`.
- Targets ≥ 60pt everywhere (iPhone SE, 375pt wide, included), game controls aim 100pt on iPad; VoiceOver label on every interactive element; `.title2` minimum for instructions; never colour alone.
- Warm copy only: never "wrong", "error", "failed", "lost". No medical claims.
- Misses use `MissCue` and a hint line; nothing ends a game early; score never shown (#45).
- On finish: `modelContext.record(GameSession(gameID:score:rounds:durationSeconds:correct:attempts:difficulty:))`; difficulty read once on open with `Difficulty.stored(_:)`.
- New `DailyPolicy.value` entries: `0.8` each (unless Jev 016 in Task 0 says otherwise and the owner agrees).
- Tests: Given/When/Then names; `UserDefaults(suiteName:)`, never `.standard`; seeded RNG (copy the `SeededGenerator` from `NumberTrailQuestionTests`).
- After adding a `.swift` file: close Xcode, `swift tools/generate_project.swift`, commit `project.pbxproj`.
- Verify before each commit that touches Swift: `xcodebuild -project MenteViva.xcodeproj -scheme MenteViva -destination 'generic/platform=iOS Simulator' build`, the test suite (`xcodebuild test -scheme MenteViva -destination 'platform=iOS Simulator,id=<UDID>'`), and `xcrun swift-format lint --strict -r MenteViva MenteVivaTests tools`.
- One branch and PR per game, from `main`, PR back to `main`; next game branches from `main` after the previous PR merges. Commit trailer `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.

## Review Focus

- iPhone SE width: hard Sudoku drops to 4×4/10 blanks and Up or Down to the widest row that keeps 60pt cards (Task 1 and Task 4 width tests).
- A 4×4 puzzle whose blanks leave two solutions: the "right number" check would reject a number that also fits. Every made puzzle must have exactly one solution (Task 1 test over 50 seeds).
- An easy Up or Down deal that cannot be cleared reads as failure to dad: easy deals must pass `greedyClears` (Task 4 test over 50 seeds).
- Finish the Saying repeating a saying inside one game, or across games before all 60 are seen (Task 7 tests).
- A saying key with an empty or missing ES or EN value shows a raw key on screen (Task 8 strings test).

---

### Task 0: Jev judgment, decision and issues (docs only, no PR of its own)

**Files:**
- Create: `docs/jev-json/016-new-games.request.json`, `docs/jev-json/016-new-games.response.json`
- Modify: `docs/jev-revisit.md` (new §016), `docs/decisions.md` (new top entry), `docs/roadmap.md` ("New games stay deferred" line → Now)

- [ ] **Step 1:** Build the 016 request from the shape of `012-progress-and-library.request.json`: state = playtest finding ("4 visible games, 3 dealt daily, he is bored; likes newspaper puzzles, cards, sayings"), candidates = the three games as one line each from the spec, questions = `fit_sudoku`, `fit_up_or_down`, `fit_sayings` (score 0–2) and `daily_value_*` (score 0–1). No names, ages, dates or health terms (jev-json README §Privacy). Save it before sending.
- [ ] **Step 2:** POST it if `TYPESAFE_AI_KEY` is available in the shell; save the response verbatim. If no key: skip the response, and the decision entry says "Jev 016 not asked: no key in session; owner decision".
- [ ] **Step 3:** Add the `decisions.md` entry "2026-10-19 — Three new games: Sudoku, Up or Down, Finish the Saying". It reopens 2026-10-01 "no new games yet" (its revisit trigger: the owner's game ideas are scored), cites the spec, and ends with "Revisit when: one of the three is unplayed for two weeks on dad's iPad".
- [ ] **Step 4:** Create three GitHub issues (`gh issue create`, current milestone), one per game, body = that game's spec section link. Note the numbers; PRs and CHANGELOG lines cite them.
- [ ] **Step 5:** Commit on the Sudoku branch (Task 1's branch) as its first commit: `docs: Jev 016 and the three-new-games decision`.

---

## PR 1 — Sudoku

### Task 1: `SudokuPuzzle` (pure logic)

**Files:**
- Create: `MenteViva/Games/SudokuPuzzle.swift`
- Test: `MenteVivaTests/SudokuPuzzleTests.swift`

**Interfaces:**
- Produces:
  ```swift
  nonisolated struct SudokuPuzzle: Equatable {
      let size: Int          // 4 or 6
      let boxRows: Int       // 2
      let boxColumns: Int    // 2 (4×4) or 3 (6×6)
      let solution: [Int]    // row-major, size*size values in 1...size
      let givens: Set<Int>   // indices shown at start
      static func layout(for difficulty: Difficulty, width: Double) -> (size: Int, blanks: Int)
      static func make<G: RandomNumberGenerator>(difficulty: Difficulty, width: Double, using generator: inout G) -> SudokuPuzzle
      static func solutionCount(_ grid: [Int?], size: Int, boxRows: Int, boxColumns: Int, limit: Int) -> Int
  }
  ```

- [ ] **Step 1: Write the failing tests**

```swift
func testGivenEachLevelOnAWideScreenWhenLayoutThenSizeAndBlanksMatchSpec() {
    XCTAssertEqual(SudokuPuzzle.layout(for: .easy, width: 700).size, 4)
    XCTAssertEqual(SudokuPuzzle.layout(for: .easy, width: 700).blanks, 4)
    XCTAssertEqual(SudokuPuzzle.layout(for: .medium, width: 700).blanks, 8)
    XCTAssertEqual(SudokuPuzzle.layout(for: .hard, width: 700).size, 6)
    XCTAssertEqual(SudokuPuzzle.layout(for: .hard, width: 700).blanks, 18)
}
func testGivenHardOnAnIPhoneSEWidthWhenLayoutThenItFallsBackToFourByFourWithTenBlanks() {
    // 343pt of board / 6 = 57pt < 60pt floor
    XCTAssertEqual(SudokuPuzzle.layout(for: .hard, width: 343).size, 4)
    XCTAssertEqual(SudokuPuzzle.layout(for: .hard, width: 343).blanks, 10)
}
func testGivenFiftySeedsWhenMakeThenEverySolutionIsAValidGrid()        // each row, column, box holds 1...size once
func testGivenFiftySeedsWhenMakeThenGivensHaveExactlyOneSolution()     // solutionCount(givens grid, limit: 2) == 1
func testGivenFiftySeedsWhenMakeThenBlankCountEqualsLayout()           // size*size - givens.count == layout.blanks, all four layouts
func testGivenTheSameSeedWhenMakeTwiceThenPuzzlesAreEqual()
func testGivenAnEmptyFourByFourWhenCountingWithLimitTwoThenItStopsAtTwo() // == 2
```

- [ ] **Step 2:** Run `SudokuPuzzleTests`; expected FAIL: `SudokuPuzzle` not defined.
- [ ] **Step 3:** Implement. Board fits when `width / Double(size) >= 60`. Solved grid from the base pattern, then shuffle:

```swift
// value at (r, c), n = size, before shuffling
(boxColumns * (r % boxRows) + r / boxRows + c) % n + 1
```

Then permute digits, rows inside each band, bands, columns inside each stack, stacks. Remove cells in shuffled order, keeping a removal only if `solutionCount(..., limit: 2) == 1`, until the layout's blank count; if not reached, retry with a new grid up to 20 times, then return the closest.
- [ ] **Step 4:** Run `SudokuPuzzleTests`; expected PASS (all 7).
- [ ] **Step 5:** `swift tools/generate_project.swift`; commit `feat(sudoku): puzzle generator with one solution per board (#<issue>)`.

### Task 2: `SudokuView` and wiring

**Files:**
- Create: `MenteViva/Games/SudokuView.swift`
- Modify: `MenteViva/Models/GameID.swift`, `MenteViva/Theme.swift:46-51`, `MenteViva/GameCard.swift:152-200`, `MenteViva/HomeView.swift:288-293`, `MenteViva/Services/DailyPolicy.swift:22-25`, `MenteViva/Localizable.xcstrings`, `proxy/worker.js:12`, `proxy/worker.test.js:74-78`, `MenteVivaTests/JevServiceTests.swift:152-176`, `MenteVivaTests/DailyPolicyTests.swift` (if it counts games)
- Create: `docs/jev-json/017-daily-plan.request.json`

**Interfaces:**
- Consumes: `SudokuPuzzle.make(difficulty:width:using:)`, `.solution`, `.givens`, `.size`.
- Produces: `GameID.sudoku` (raw `"sudoku"`, emoji `"✏️"`, title key `"game.sudoku.title"`, `hasLevels == true`).

- [ ] **Step 1:** Add `GameID.sudoku`; ink `Color(light: 0x1F5F7A, dark: 0x86C5DE)`; emblem: 2×2 grid of rounded squares in ink, one square amber; route `case .sudoku: SudokuView()`; `DailyPolicy.value[.sudoku] = 0.8`.
- [ ] **Step 2:** Strings (EN / ES): `game.sudoku.title` "Sudoku" / "Sudoku"; `game.sudoku.instruction` "Tap a square, then a number." / "Toca un cuadro y luego un número."; `game.sudoku.miss` "Almost — try another number." / "Casi — prueba otro número."; `game.sudoku.showme` "Show me one" / "Muéstrame uno"; `game.sudoku.a11y.cell %lld %lld %lld` "Row %1$lld, column %2$lld, %3$lld" / "Fila %1$lld, columna %2$lld, %3$lld"; `game.sudoku.a11y.empty %lld %lld` "Row %1$lld, column %2$lld, empty" / "Fila %1$lld, columna %2$lld, vacío"; `game.sudoku.a11y.put %lld` "Put %lld" / "Poner %lld"; `game.celebration.squares %lld` "You filled %lld squares" / "Llenaste %lld cuadros".
- [ ] **Step 3:** Build `SudokuView` per spec §1: deal once the board width is known (`GeometryReader`); givens in ink, his numbers in the game colour; first blank selected; number pad `1...size` with `AnswerTileStyle`; right → place, `Feedback.play(.success)`, select next blank in reading order; not right → `MissCue` on the square and the miss line; "Show me one" fills the selected blank in a softer colour (attempt, not correct). Finish when no blank is left: `GameSession(gameID: .sudoku, score: correct * 10, rounds: blanks, durationSeconds:, correct:, attempts:, difficulty:)`, celebration detail `game.celebration.squares %lld`. Use `.gameHeader(.sudoku, instruction:)`, `.fitOrScroll()`, `.celebration(...)` like `MathStreakView`.
- [ ] **Step 4:** Jev contract: add `"sudoku"` to `GAMES` in `proxy/worker.js`. Capture the app's request into `docs/jev-json/017-daily-plan.request.json` with a temporary test that runs `JevService.dailyPlan` against `StubURLProtocol` and writes the body (delete the temporary test after). Point `JevServiceTests.testGivenAppRequestWhenSentThenQuestionKeysMatchArchivedLiveRequest` and `worker.test.js` at 017; expected key count `13`. Add a line to `docs/jev-json/README.md` ("017: request only, seven games; live response after the third game").
- [ ] **Step 5:** `swift tools/generate_project.swift`; run build, all tests (`ContrastTests` now covers the new ink), lint, `node --test proxy/`; expected all PASS.
- [ ] **Step 6:** Run on an iPhone SE (3rd gen) and an iPad simulator, each level pinned in Set up: board fits, no target under 60pt, VoiceOver reads cells. Commit `feat(sudoku): Sudoku game (#<issue>)`.

### Task 3: Sudoku PR

- [ ] **Step 1:** `CHANGELOG.md` `[Unreleased] → Added`: "**Sudoku (#<issue>):** a 4×4 or 6×6 number square, new every time. A number that doesn't fit gets a gentle 'try another'; 'Show me one' helps when stuck."
- [ ] **Step 2:** Push (pre-push hook runs build + tests + lint), open the PR with the `pr` skill, ask the owner to merge and to hand dad the iPad for one game.

---

## PR 2 — Up or Down (branch from `main` after PR 1 merges)

### Task 4: `UpOrDownDeal` (pure logic)

**Files:**
- Create: `MenteViva/Games/UpOrDownDeal.swift`
- Test: `MenteVivaTests/UpOrDownDealTests.swift`

**Interfaces:**
- Produces:
  ```swift
  nonisolated struct PlayingCard: Hashable {
      enum Suit: CaseIterable { case spades, hearts, diamonds, clubs; var isRed: Bool; var symbol: String }
      let rank: Int   // 1 (A) ... 13 (K)
      let suit: Suit
  }
  nonisolated struct UpOrDownDeal: Equatable {
      private(set) var piles: [[PlayingCard]]  // last element = top card
      private(set) var open: PlayingCard
      private(set) var deck: [PlayingCard]     // last element = next to turn
      let wraps: Bool
      static func pileCount(for difficulty: Difficulty, width: Double) -> Int
      static func make<G: RandomNumberGenerator>(difficulty: Difficulty, width: Double, using generator: inout G) -> UpOrDownDeal
      static func canPlay(_ card: PlayingCard, on open: PlayingCard, wraps: Bool) -> Bool
      static func greedyClears(_ deal: UpOrDownDeal) -> Bool
      var playablePiles: [Int] { get }
      var isCleared: Bool { get }
      var isStuck: Bool { get }                // deck empty and no playable pile
      mutating func play(pile: Int) -> Bool    // false and no change if it doesn't fit
      mutating func turn() -> Bool             // false if the deck is empty
  }
  ```

- [ ] **Step 1: Write the failing tests**

```swift
func testGivenAnOpenSevenWhenCheckingThenSixAndEightFitAndNineDoesNot() // canPlay rank 6, 8 true; 9 false; suit ignored
func testGivenAnOpenKingWhenWrapsThenAceFitsAndWithoutWrapItDoesNot()
func testGivenEachLevelOnAWideScreenWhenPileCountThenFourFiveSix()      // width 700
func testGivenHardOnAnIPhoneSEWidthWhenPileCountThenFive()              // width 343: 343/6 < 60, 343/5 >= 60
func testGivenAMadeDealThenEachPileHasThreeAndAll52CardsAreUsedOnce()   // piles*3 + 1 + deck.count == 52, Set count 52
func testGivenFiftySeedsWhenMakeEasyThenEveryDealGreedyClears()
func testGivenAFittingTopWhenPlayThenItBecomesTheOpenCardAndLeavesThePile()
func testGivenANonFittingTopWhenPlayThenFalseAndNothingChanges()
func testGivenAnEmptyDeckWhenTurnThenFalse()
func testGivenEmptyDeckAndNoFitWhenAskedThenIsStuck()
func testGivenHardWhenMakeThenItDoesNotWrap()                           // wraps == (difficulty != .hard)
```

- [ ] **Step 2:** Run `UpOrDownDealTests`; expected FAIL: types not defined.
- [ ] **Step 3:** Implement. Piles easy 4 / medium 5 / hard 6, reduced while `width / Double(piles) < 60`. Easy: redeal until `greedyClears` (≤ 50 tries). `greedyClears` plays the first playable pile, else turns, until cleared or stuck.
- [ ] **Step 4:** Run `UpOrDownDealTests`; expected PASS (all 11).
- [ ] **Step 5:** `swift tools/generate_project.swift`; commit `feat(cards): Up or Down deal and rules (#<issue>)`.

### Task 5: `UpOrDownView` and wiring

**Files:** as Task 2, with `MenteViva/Games/UpOrDownView.swift` and `docs/jev-json/018-daily-plan.request.json`.

**Interfaces:**
- Consumes: Task 4's `UpOrDownDeal` API.
- Produces: `GameID.upOrDown` (raw `"up_or_down"`, emoji `"🃏"`, title key `"game.upordown.title"`, `hasLevels == true`).

- [ ] **Step 1:** Wiring as Task 2 Step 1: ink `Color(light: 0x6B4F2A, dark: 0xD2B48C)`; emblem: two fanned cards in ink with an amber up-chevron; route; value `0.8`.
- [ ] **Step 2:** Strings (EN / ES): `game.upordown.title` "Up or Down" / "Sube o baja"; `game.upordown.instruction` "Tap a card one higher or one lower." / "Toca una carta con uno más o uno menos."; `game.upordown.stuck` "No card fits — turn a new one." / "Ninguna carta sirve — voltea una nueva."; `game.upordown.miss %@` "Almost — it needs one more or one less than %@." / "Casi — necesita uno más o uno menos que %@."; `game.upordown.a11y.card %@ %@` "%1$@ of %2$@" / "%1$@ de %2$@"; `game.upordown.a11y.fits` "fits" / "sirve"; `game.upordown.a11y.open %@` "Open card: %@" / "Carta abierta: %@"; `game.upordown.a11y.deck %lld` "Turn a new card, %lld left" / "Voltear una carta nueva, quedan %lld"; rank names (Ace…King / As…Rey) and suit names (spades, hearts, diamonds, clubs / picas, corazones, diamantes, tréboles); `game.celebration.table` "You cleared the table!" / "¡Limpiaste la mesa!"; `game.celebration.cards %lld` "You cleared %lld cards" / "Quitaste %lld cartas".
- [ ] **Step 3:** Build `UpOrDownView` per spec §2: faces drawn in SwiftUI (rank + suit symbol, red/black); only top cards tappable, lower cards as edges; easy lifts `playablePiles`; deck pulses with the stuck line when no pile fits; non-fitting tap → `MissCue` + miss line. `correct` = cards played, `attempts` = taps on table cards, `rounds` = table cards, `score = correct * 10`. Finish on `isCleared` or `isStuck`.
- [ ] **Step 4:** Jev contract as Task 2 Step 4 with `"up_or_down"`, capture 018, expected key count `15`.
- [ ] **Step 5:** Regenerate, build, test, lint, `node --test proxy/`; SE + iPad check at each level. Commit `feat(cards): Up or Down game (#<issue>)`.

### Task 6: Up or Down PR

- [ ] **Step 1:** CHANGELOG: "**Up or Down (#<issue>):** a solitaire with big cards: tap a card one higher or one lower. A new deal every time; the easy level always clears."
- [ ] **Step 2:** Push, open the PR, owner merges after one game on dad's iPad.

---

## PR 3 — Finish the Saying (branch from `main` after PR 2 merges)

### Task 7: `SayingsDeck` (pure logic)

**Files:**
- Create: `MenteViva/Games/SayingsDeck.swift`, `MenteViva/Games/Sayings.swift`
- Test: `MenteVivaTests/SayingsDeckTests.swift`

**Interfaces:**
- Produces:
  ```swift
  nonisolated struct Saying: Hashable {
      enum Theme: CaseIterable { case animals, money, time, food, work, weather, friends, home }
      let id: Int            // 1...60
      let theme: Theme
      var startKey: String   // "saying.07.start"
      var endKey: String     // "saying.07.end"
  }
  enum Sayings { static let all: [Saying] }   // 60 slots, ids 1...60
  nonisolated struct SayingRound: Equatable { let saying: Saying; let choices: [Saying] } // choices' endKeys are the buttons
  enum SayingsDeck {
      static let roundsPerGame = 8
      static let seenKey = "sayings.seen"
      static func choiceCount(for difficulty: Difficulty) -> Int   // 3, 4, 4
      static func deal<G: RandomNumberGenerator>(difficulty: Difficulty, from pool: [Saying] = Sayings.all, defaults: UserDefaults, using generator: inout G) -> [SayingRound]
  }
  ```

- [ ] **Step 1: Write the failing tests**

```swift
func testGivenEachLevelWhenChoiceCountThenThreeFourFour()
func testGivenADealThenEightRoundsWithEightDifferentSayings()
func testGivenADealThenEachRoundHoldsItsSayingOnceAmongDistinctChoices()
func testGivenSevenGamesWhenDealingThen56DifferentSayingsAndNoRepeat()   // pool of 60
func testGivenOnlyFourUnseenWhenDealingThenSeenResetsAndEightAreDealt()
func testGivenHardWhenThreeSameThemeSayingsExistThenDistractorsShareTheTheme()
func testGivenADealThenSeenIDsArePersistedUnderSeenKey()                 // suite defaults
func testGivenTheContentListThenSixtyUniqueIDsOneToSixty()
```

- [ ] **Step 2:** Run `SayingsDeckTests`; expected FAIL: types not defined.
- [ ] **Step 3:** Implement. `Sayings.all` lists 60 slots with themes (≥ 4 slots per theme so hard always has 3 same-theme distractors). Deal: unseen first; if fewer than 8 unseen, clear seen then deal; distractors from other slots, same theme first on hard; shuffle choices; append dealt IDs to seen.
- [ ] **Step 4:** Run `SayingsDeckTests`; expected PASS (all 8).
- [ ] **Step 5:** `swift tools/generate_project.swift`; commit `feat(sayings): saying deck with no repeats (#<issue>)`.

### Task 8: Saying content (EN + ES)

**Files:**
- Modify: `MenteViva/Localizable.xcstrings` (120 keys: `saying.01.start` … `saying.60.end`)
- Test: `MenteVivaTests/SayingsStringsTests.swift`

- [ ] **Step 1: Write the failing test**

```swift
// Reads Localizable.xcstrings via #filePath (as JevServiceTests reads docs/jev-json).
func testGivenEverySayingSlotWhenLookingUpStartAndEndThenEnAndEsAreBothPresentAndNotEmpty()
```

- [ ] **Step 2:** Run it; expected FAIL: keys missing.
- [ ] **Step 3:** Write 60 slots. ES: well-known refranes split at the natural pause ("Más vale pájaro en mano" / "que ciento volando"). EN: a well-known English saying on the slot's theme, not a translation. Endings short (≤ 6 words). Excluded: age, memory, illness, death, "old dog, new tricks".
- [ ] **Step 4:** Run it; expected PASS. Commit `content(sayings): 60 sayings in EN and ES (#<issue>)`.
- [ ] **Step 5:** Ask the owner to send the ES list to the native reviewer (#12 process). Merge waits for that sign-off; continue Task 9 meanwhile.

### Task 9: `SayingsView` and wiring

**Files:** as Task 2, with `MenteViva/Games/SayingsView.swift` and `docs/jev-json/019-daily-plan.request.json`.

**Interfaces:**
- Consumes: `SayingsDeck.deal(difficulty:defaults:using:)`, `SayingRound`, `CaptionSpeaker` (speak on tap only).
- Produces: `GameID.sayings` (raw `"sayings"`, emoji `"💬"`, title key `"game.sayings.title"`, `hasLevels == true`).

- [ ] **Step 1:** Wiring as Task 2 Step 1: ink `Color(light: 0x5B3F8C, dark: 0xC3A8F0)`; emblem: speech bubble in ink with three dots, one amber; route; value `0.8`.
- [ ] **Step 2:** Strings (EN / ES): `game.sayings.title` "Finish the Saying" / "Termina el refrán"; `game.sayings.instruction` "How does this saying end?" / "¿Cómo termina este refrán?"; `game.sayings.miss` "Almost — try again." / "Casi — inténtalo de nuevo."; `game.sayings.next` "Next" / "Siguiente"; `game.sayings.a11y.listen` "Hear the saying" / "Escuchar el refrán"; `game.celebration.sayings %lld` "You finished %lld sayings" / "Terminaste %lld refranes".
- [ ] **Step 3:** Build `SayingsView` per spec §3: start in large serif with "…"; full-width choice buttons, `.title2`, multiline; right → full saying, success, speaker button, "Next"; not right → `MissCue`, that button dims, miss line, keep choosing. `correct` = right on first tap, `attempts` = all taps, `rounds = 8`, `score = correct * 10`.
- [ ] **Step 4:** Jev contract as Task 2 Step 4 with `"sayings"`, capture 019, expected key count `17`.
- [ ] **Step 5:** Regenerate, build, test, lint, `node --test proxy/`; SE + iPad check, long ES endings wrap without truncation. Commit `feat(sayings): Finish the Saying game (#<issue>)`.

### Task 10: Sayings PR and the release wrap-up

- [ ] **Step 1:** CHANGELOG: "**Finish the Saying (#<issue>):** the start of a familiar saying, pick the ending from big buttons, hear it read aloud. Sixty sayings in each language, none repeated until all have been seen."
- [ ] **Step 2:** `AGENTS.md` Current status and file map: "9 games"; `docs/roadmap.md`: the three games under Now as shipped.
- [ ] **Step 3:** Push, open the PR; merge after the ES sign-off (Task 8 Step 5).
- [ ] **Step 4 (owner):** `wrangler deploy` the worker; save the live 9-game answer as `docs/jev-json/019-daily-plan.response.json` and note HTTP status and model in the jev-json README.
- [ ] **Step 5:** Owner plays one week with dad; record in the #6 / playtest-session-2 notes whether he picked a new game unprompted twice (mvp G1b).
