# AGENTS.md

Instructions for AI agents (and humans in a hurry) working on MenteViva.

## Read first, in order

1. `docs/conventions.md` — the 9 rules. Violating one = rejected PR.
2. `docs/decisions.md` — what's decided and why. Don't re-litigate; append.
3. `docs/roadmap.md` — what phase we're in. Work outside "Now" needs a reason.

## Non-negotiables
- **Zero third-party dependencies.** SwiftUI/SwiftData/Foundation only.
- **Every user-facing string** goes in `Localizable.xcstrings` with EN + ES
  in the same commit. Hardcoded strings = rejected.
- **Accessibility floor:** touch targets ≥60pt, aim 100pt (conventions §4;
  game controls ship at ≥100pt), VoiceOver labels on every interactive
  element, no color-only information, `.title2` minimum for instructions.
- **Tone:** warm failure copy only. Never "wrong/error/failed" — the player is
  someone's dad you will never meet, installing this without anyone to explain
  it to them.
- **No medical claims** in any copy, code comment, or doc. "Fun mental
  exercise" is the ceiling. See docs/research-2026-09.md §1.
- **The app makes no network calls.** Today's plan is decided on the device (`DailyPolicy`);
  the app has no service client, key or server (decisions.md 2026-10-26). No keys in the repo,
  plist or binary.

## Where things are

```
MenteViva/            app (SwiftUI + SwiftData)
  MenteVivaApp.swift  entry; LOCAL_ONLY picks the store
  HomeView, OnboardingView, SettingsView, HistoryView,
  MyProgressView (rates, #141), SetUpView (hide/pin/photos)
  Games/              one file per game (9) + CelebrationView, MissCue, FitOrScroll
  Models/             GameSession, GameID, Difficulty, RoundProgress
  Services/           DailyPolicy (on-device plan), PlanStore (saved plan + levels),
                      FamilySettings, PlayerProfile (onboarding answers), MemoryPhotos,
                      PlayerStateSummary, WeeklySummary, ProgressRates, AppLanguage, SoundPlayer, HotPath (signposts),
                      CaptionSpeaker, EverydayObjects, GamePictures (one catalogue of game pictures)
  Localizable.xcstrings  every string, EN + ES
MenteVivaTests/       unit tests (Given/When/Then names)
tools/                generate_project.swift (the only way to edit the Xcode project)
docs/                 start at docs/README.md
.github/workflows/    checks.yml (Linux) + swift.yml (macOS): CI on PRs to main (Workflow 5)
```

## Current status

- 9 games shipped (Memory Lane, Color Clash, Name the Herd, Number Trail, Remember Together,
  Quick Eyes, Sudoku, Up or Down, Finish the Saying); ES/EN complete; local-only build is the default.
- **Daily picks and difficulty are decided on the device** (`DailyPolicy`, #101): no model,
  no network, no cost. The app no longer calls Jev (#195); `docs/jev-json/` stays as the
  evidence archive and `docs/jev-integration.md` as history.
- Dad playtest #6 ran (findings on #6); its follow-ups #106–#110 and Remember Together (#139)
  shipped. Three new games followed from the owner's playtests (decisions.md 2026-10-19):
  Sudoku (#179), Up or Down (#180), Finish the Saying (#181).
- **Card Table redesign shipped** (#154–#159, decisions.md 2026-10-12, Jev 015): each game is a
  framed card in its own colour (`GameCard.swift`, palette in `Theme.swift`), Home deals today's
  three, every game shares one header, and the end of a game adds its card to the week board.
  Spec: `docs/design/2026-10-12-card-table.html`.
- **Next: v0.3 then v1.0 on the App Store** (decisions.md 2026-10-26): Jev out of the app, levels
  1–10, onboarding with goals, four new games, then release work. Built by several agents in
  parallel; see "Several agents at once" below. The epics are the open issues labelled `epic`.
- Live state is in the [issues](https://github.com/igmarin/menteviva/issues), not here.

## Signing

- The generator pre-fills `DEVELOPMENT_TEAM` (Ismael Marin Cabrera, Personal
  Team, `VB42T7NYX2`), so device builds never stop to ask. Change the constant
  in `tools/generate_project.swift` when the paid team replaces it.
- Free provisioning means every device install **expires 7 days after signing**;
  re-sign by running ⌘R (or the equivalent `xcodebuild` device build) with the
  device connected. Never assume an installed build is still valid; see
  docs/install-runbook.md.
- Device builds use the default local-only mode (no CloudKit entitlement); see Workflow
  step 3 for why a CloudKit build without the entitlement traps at launch.

## Workflow

1. Branch from `main`, PR back to `main`.
2. After adding/removing a `.swift` file: `swift tools/generate_project.swift`
   and commit the regenerated `project.pbxproj`.
3. **Two build modes.** **Default = local-only** (`swift tools/generate_project.swift`):
   no CloudKit entitlement, `LOCAL_ONLY` defined — required for a free Apple ID
   and safe for the simulator. `--cloudkit` opts back in, but only with the paid
   Developer Program and a provisioned container.
   **Never run a CloudKit-enabled build without its entitlement**: it traps at
   launch inside CloudKit (`EXC_BREAKPOINT`), and the simulator does not
   reproduce it because it tolerates the missing entitlement. Test the mode you
   ship, on a device.
4. **Close Xcode before regenerating the project.** The generator rewrites
   `project.pbxproj` and clears cached `xcuserdata`; Xcode holding the old
   object graph open is what produces "the project has a file format integrity
   issue". Close → regenerate → reopen.
5. Verify before committing: build must pass —
   `xcodebuild -project MenteViva.xcodeproj -scheme MenteViva -destination 'generic/platform=iOS Simulator' build`
   and tests must pass (conventions §9), and lint must be clean:
   `xcrun swift-format lint --strict -r MenteViva MenteVivaTests tools`
   (Apple's formatter, ships with Xcode; config in `.swift-format`, #123).
   `xcrun swift-format format -i -r MenteViva MenteVivaTests tools` fixes most of it.
   Syntax checks (`swiftc -parse`) are
   NOT verification. **A pre-push hook runs all of this for you** — install it
   once with `git config core.hooksPath .githooks`; `git push --no-verify`
   skips it. It tests on the first booted simulator; when several agents work
   in parallel, each pushes with its own: `MENTEVIVA_SIMULATOR=<udid> git push`.
   It also runs the signpost and project-file checks.
   **CI runs the same checks on every PR to `main`**, split by cost (macOS
   minutes bill at 10× Linux; decisions.md 2026-10-20): `checks.yml` on Linux
   always runs signposts and the project-file check (~1 billed min);
   `swift.yml` on macOS runs generator drift, lint and `xcodebuild test` only
   when a non-draft PR touches `MenteViva/`, `MenteVivaTests/`, the project,
   `tools/` or `.swift-format` (~20 billed min). Open PRs as drafts while
   iterating; marking ready runs the macOS job. Pushes cancel the run they
   supersede. A check added to the hook goes into one of the workflows too.
   The same `core.hooksPath` also enables a
   **pre-commit hook** that runs `ocr review` on the staged changes and blocks
   the commit on critical/high findings (needs `OPENAI_API_KEY` in your shell and
   `npm i -g @alibaba-group/open-code-review`; without them it warns and skips;
   `git commit --no-verify` skips it too).
6. Track work in GitHub issues with the current milestone (see
   [milestones](https://github.com/igmarin/menteviva/milestones)). Closed-issue labels mark the release
   (e.g. `v0.1.0`).
7. Update `CHANGELOG.md` under `[Unreleased]` with any user-visible change.

## Agent workflow (always on)

1. **Classify before coding.** Run
   `python3 ~/.agents/skills/task-complexity-classifier/classifier.py "<one-line summary>"`
   (needs `TYPESAFE_API_KEY`; on failure it falls back to "complex"; never
   block on it). `routine` → cheapest/fastest model; `standard` → default;
   `complex` → strongest model and plan before editing. Switch models only if
   your agent supports it; otherwise state the class and adjust effort.
2. **Ponytail, full intensity.** Apply the `ponytail` skill: question the task,
   prefer stdlib/native, shortest working solution, no speculative abstraction.
3. **Product decisions get a Jev judgment first.** Archive request + response in
   `docs/jev-json/` (next number, never reused), then log in
   `docs/decisions.md`. Jev is evidence; the owner decides.
4. **Keys.** `TYPESAFE_API_KEY` = dev-machine classifier only. It never enters the
   repo, plist, or binary.
5. **Code questions:** if `.codegraph/` exists use `codegraph explore "<query>"`;
   if `graphify-out/` exists query it (`/graphify`). Both are gitignored and
   regenerable; fall back to grep when absent.
6. **Reference coding (optional, XERJ).** Before writing a new game or a tricky
   algorithm, search how others solved it. Needs a local node
   (`xerj --insecure --data-dir ~/xerj-data`, data dir outside the repo) and
   `export PATH="$HOME/.local/bin:$PATH"`. Prefixes: `menteviva` (this repo; re-run
   `xerj autoindex . --prefix menteviva` after big changes; `.githooks/post-merge`
   does it after a `git pull` on main), plus one per clone in
   `~/refs/` (`mysudoku` MIT, `imoofs-sudoku` Apache-2.0). Search is lexical, so use
   the identifiers the code uses: `xerj search --prefix <name> "<words>"`.
   Clone references **outside** the repo (`~/refs/<name>`), index each under its own
   prefix, and check the licence first: unlicensed code is read-only reference, never
   copied. Zero-dependency still applies. Set `XERJ_DISABLE_FEEDBACK=true`; never send
   field reports or `rerank`/`--embed-mode proxy` (they send text off the machine).

## Several agents at once (decisions.md 2026-10-26)

Muse Code, Cline and Claude work tickets in parallel. The owner decides and merges; Claude is the
lead and reviews every PR; no agent merges.

1. **Take only an issue labelled `ready` whose "Depends on" issues are all closed.** One issue, one
   agent, one branch (`agent/<issue>-<slug>`), one PR with `Closes #<issue>`. Label the issue
   `review` when the PR is up.
2. **The issue is the brief.** Do what it asks, nothing else. If it is unclear or wrong, comment on
   the issue and stop; don't guess.
3. **Hot files** (several tickets touch them): `Localizable.xcstrings`, `GameID.swift`, `Theme.swift`,
   `HomeView.swift`, `DailyPolicy.swift`. Merge `main` into your branch right before opening the PR.
   Never hand-merge `project.pbxproj`: take `main`'s and run `swift tools/generate_project.swift`.
4. **Never copy code, puzzles, art, sounds or text from another project, site or repo**, whatever
   its license. Read for ideas, then write your own from the issue's spec. Any asset needs its source
   and license recorded in `docs/ip-clearance.md`.
5. **Labels.** Type: `game`, `feature`, `design`, `research`, `infra`, `docs`, `decision`.
   Priority: `p0` (blocks the App Store), `p1`, `p2`. Size: `size:S` (<2 h), `size:M` (half a day),
   `size:L` (split before taking). Who: `agent:muse`, `agent:cline`, `agent:claude`, `owner`.
   State: `ready`, `review`, `blocked`. Epics are parent issues; tickets are their sub-issues.
6. **One worktree per ticket**, never the main checkout:
   `git worktree add ../mv-<issue> -b agent/<issue>-<slug> origin/main`. Remove it after the merge
   (`git worktree remove ../mv-<issue>`). Agents that don't do this on their own (Muse) are told to.
7. **Split tickets stack with `gh stack`.** A "(2/2)" screen ticket builds on its "(1/2)" logic
   ticket: its branch starts from the logic branch and its PR targets that branch, not `main`. Let
   `gh stack` keep the stack in order; never rebase or force-push a branch someone else pushed to.
8. **Green locally before every push.** On a Mac with Xcode, run lint
   (`xcrun swift-format lint --strict -r MenteViva MenteVivaTests tools`) and the tests on your own
   simulator (`MENTEVIVA_SIMULATOR=<udid> git push` runs both through the pre-push hook), and use the
   `menteviva-checks` skill. Never `--no-verify`. An agent that can't run them (no Xcode) says so in
   the PR and opens it ready, so CI runs them.

## Definition of done (every PR)

Speed without quality is not progress. A PR is done when:

- **Logic lives outside views.** Rules, scoring, generation and policy are small pure types (a
  "service object": one job, plain inputs, no UI), in `Services/` or next to the game as
  `<Game>Deal.swift` / `<Game>Puzzle.swift` (see `SudokuPuzzle`, `UpOrDownDeal`). Views show state
  and forward taps. Dependencies (`UserDefaults`, today's date, the random generator) come in as
  parameters, so tests control them; generated content takes a seed. Still no base classes or
  protocols until a third use proves the pattern (conventions §2).
- **Tests come first for logic** (conventions §9, Given/When/Then names). A bug fix starts with a
  failing test. Generated puzzles are tested for solvability and for difficulty rising with the level.
- **Every type and every non-obvious function has a `///` comment** saying why it exists or why it
  works this way, not what the next line does.
- **The checks pass:** build, tests and lint (Workflow 5); strings EN + ES (§3); accessibility floor
  (§4); warm copy (§5); `CHANGELOG.md` for anything a player can see; no keys; no medical claims.
- **Small:** one issue per PR; past ~400 changed lines (strings and pbxproj aside), split it.

## Patterns

- One file per game in `MenteViva/Games/`; copy `MemoryMatchView.swift`'s
  shape (View + @State + `modelContext.record(GameSession(...))` on finish, #106).
  No game engine, no base classes, no protocol ceremony.
- The daily plan is `Services/DailyPolicy.swift` (pure, tested). Policy stays in code,
  never in a model. Past Jev judgments are history: docs/jev-integration.md.

## When unsure

Smallest thing that works, warm tone, offline-safe. If a choice could land
in a doc, it lands in `docs/decisions.md`.
