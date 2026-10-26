# Game-feel and UX review — 2026-10-26 (#230)

What makes the nine shipped games feel worth buying, checked against the engine-neutral skills of
`gamedev-skills/awesome-gamedev-agent-skills` (Apache-2.0): `game-feel`, `game-ui-ux`, `puzzle`,
`card-game`, `level-design`, `procedural-gen`, `audio-design`.

**Method.** A code read of every game, the shared feedback pieces (`Feedback`/`SoundPlayer`,
`MissCue`, `CelebrationView`, `RoundCounter`, `AnswerTileStyle`) and the a11y audit. Not yet walked on a
device: this session has no simulator. Items marked *verify* need a look on the iPhone SE simulator
first; the rest are read straight from the code.

**Filter.** Every skill suggestion passed MenteViva's rules first: no timers, no visible score, no
screen shake, no freeze frames, no flashing, warm misses, 100pt game controls, nothing colour-only,
Reduce Motion honoured. "Juice" here means soft, clear, consistent feedback, not intensity.

## What already works

- **Feedback tiers exist and are shared** (`Feedback.Event`: tap, success, complete, miss, each a tone
  plus a matching haptic). The skill's "importance tiers" rule is already the design.
- **Misses are warm and return to rest** (`MissCue`: amber outline, small shrink, gone in 0.7 s,
  motion dropped under Reduce Motion).
- **Never a loss, never a dead end:** Up or Down ends on cards cleared; easy deals always clear;
  Sudoku boards have exactly one solution; "Show me one" exists where a player can get stuck.
- **State is never colour-only** (check badges, suit symbols, shapes on Color Clash inks).
- **The celebration lands** (card arrives with a spring, stamped "Added to your week", complete chord).
- **Logic is already out of views** for the newer games (`SudokuPuzzle`, `UpOrDownDeal`, `SayingsDeck`,
  `NumberTrailQuestion`), with injected random generators.

## Findings

### Must

1. **Quick Eyes, Color Clash and Number Trail never show the answer.** On any tap the next round is
   dealt in the same instant. A right answer has no visual confirmation, only a tone and a haptic, and
   with the one Settings toggle off there is no feedback at all. On a miss in Color Clash and Number
   Trail, `missed = true` animates `MissCue` on the **next** question, because `deal()` already
   replaced it; the player never sees which answer was right. (`QuickEyesView.choose`,
   `ColorClashView.tap`, `MathStreakView.tap`.) Fix: one shared "answer beat" (~0.7 s, input locked):
   a check badge on the tapped tile when right; when missed, the amber cue on the tapped tile and a
   check on the right one; then the next round. → ticket.
2. **Two newer games regressed below the 100pt floor for game controls** (a11y audit; AGENTS.md):
   Sudoku's number pad is 80pt and "Show me one" is 70pt (`SudokuView.swift:136`, `:51`); Finish the
   Saying's answers are 80pt (`SayingsView.swift:81`). → ticket.

### Should

3. **Memory Lane cards don't flip, they swap** (`isFaceUp` changes with no animation; only the match
   bloom animates). The flip is the game's core moment. A 0.25 s turn (cross-fade under Reduce
   Motion). Also, after a miss, a third tap leaves up to four cards face up for 1.2 s; flip the missed
   pair back as soon as a new card is tapped. → ticket.
4. **Name the Herd jumps to the next category on the last right tap**: the last check badge is never
   seen, and VoiceOver isn't told the category changed (`CategoryFluencyView.tap` → `dealRound`). A
   short "all found" beat, then the new category with an announcement. → ticket.
5. **Sudoku gives no mid-board reward.** Finishing a row, column or box is a natural medium-tier
   moment (skill: scale feedback to importance). A soft wash over the finished line plus the success
   tone; a small pop on each placed digit. → ticket.
6. **The tones are thin and the miss tone may be inaudible on an iPhone speaker.** Each note's
   envelope reaches zero at 25% of its length (`decayEnv`), so notes are ~25–45 ms blips; the miss tone
   is 180 Hz, below what small phone speakers reproduce well. A gentler decay and a soft second harmonic;
   miss around 260–300 Hz. → ticket.
7. **Up or Down's "turn the deck" nudge probably doesn't pulse** *(verify)*. The repeating animation is
   keyed to `pulse`, which only changes once on appear; when the player gets stuck later, the deck jumps
   to 1.06× and stays (`UpOrDownView.deckButton`). → ticket.
8. **Every celebration says the same headline** (`game.common.welldone`). Dad's main complaint is
   repetition (decisions 2026-10-19); a small pool of warm headlines, never the same twice in a row.
   → ticket.
9. **No game teaches before it tests** (skill `level-design`: introduce safely, practise, then test).
   A stranger gets one instruction line. A one-time, skippable "Let me show you" for the games whose
   rules aren't obvious (Sudoku, Up or Down, Color Clash first), and for the four new games. → ticket.
10. **The older games deal with the global random generator inside the view** (Memory Lane, Quick Eyes,
    Color Clash, Name the Herd), so their deals are untested and not reproducible (skills `puzzle`,
    `procedural-gen`; AGENTS.md "Definition of done"). Move each deal into a small pure type with an
    injected generator and tests, like `SayingsDeck`. → ticket, after the levels epic (same files).

### Could (no ticket yet)

- A success tone that climbs one step per right answer in a row and settles after a miss (calm "streak"
  feedback) in Number Trail and Quick Eyes.
- An "Undo last card" in Up or Down (skill `puzzle`: undo for thinking puzzles).
- A soft cross-fade between photos in Remember Together.
- Separate toggles for sound and for vibration (one toggle today, by design in `docs/jev-sounds.md`).
- ~~Finish the Saying: read the whole saying aloud on a right answer when "Read names aloud" is on, and
  announce it to VoiceOver.~~ Moved to a ticket (#245): the VoiceOver part is an accessibility gap, not polish.

The rest wait for the playtest with dad (#231): what he misses or what bothers him becomes a ticket
with evidence.

## Not adopted from the skills

Screen shake, hit-stop, flashes, number pop-ups, score and move counters, time limits, adaptive music:
each fights the warm, no-pressure design or the older player's comfort. Gamepad focus and TV safe areas
don't apply to an iPhone/iPad touch app.
