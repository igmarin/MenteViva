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
- **The API key never enters the repo or the binary.** Jev goes through the
  proxy; unset proxy URL = offline fallback, which must always work.

## Where things are

```
MenteViva/            app (SwiftUI + SwiftData)
  MenteVivaApp.swift  entry; LOCAL_ONLY picks the store
  HomeView, OnboardingView, SettingsView, HistoryView
  Games/              one file per game (6) + CelebrationView, MissCue, FitOrScroll
  Models/             GameSession, GameID, Difficulty, RoundProgress
  Services/           DailyPolicy (on-device plan), PlanStore (saved plan + levels),
                      JevService (optional Jev client), FamilySettings, MemoryPhotos,
                      PlayerStateSummary, WeeklySummary, AppLanguage, SoundPlayer, HotPath (signposts),
                      CaptionSpeaker, EverydayObjects
  Localizable.xcstrings  every string, EN + ES
MenteVivaTests/       unit tests (Given/When/Then names)
proxy/worker.js       Cloudflare Worker that holds the Jev key
tools/                generate_project.swift (the only way to edit the Xcode project)
docs/                 start at docs/README.md
.github/workflows/    swift.yml: build + test on PRs, push to main, manual
```

## Current status

- 6 games shipped (Memory Lane, Color Clash, Name the Herd, Number Trail, Remember Together,
  Quick Eyes); ES/EN complete; local-only build is the default.
- **Daily picks and difficulty are decided on the device** (`DailyPolicy`, #101): no model,
  no network, no cost. Jev is an optional override, wired and verified live (proxy deployed #63,
  payload archived `docs/jev-json/011`), used only when `MenteViva/Config/Local.xcconfig`
  (git-ignored; copy the `.example`) sets the proxy URL and secret (#91). Open-model
  alternatives were tested and rejected for the app: `docs/decision-model-spike-2026-09-30.md`.
- Dad playtest #6 ran (findings on #6). Work from it, in order: #106 save fix, #107 weekly
  progression, #108 Family settings, #109 adult Memory Lane, #110 photo cards
  (docs/decisions.md 2026-10-01, Jev 012). New games stay deferred (#18).
- Live state is in the [milestones](https://github.com/igmarin/MenteViva/milestones), not here.

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
   skips it. `.github/workflows/swift.yml` holds the same checks but is
   manual-dispatch only while the Actions minutes are out, so the hook is the
   thing that actually runs.
6. Track work in GitHub issues with the current milestone (see
   [milestones](https://github.com/igmarin/MenteViva/milestones)). Closed-issue labels mark the release
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
4. **Two different keys.** `TYPESAFE_API_KEY` = dev-machine classifier.
   `TYPESAFE_AI_KEY` = the proxy's secret (`wrangler secret put`). Neither ever
   enters the repo, plist, or binary.
5. **Code questions:** if `.codegraph/` exists use `codegraph explore "<query>"`;
   if `graphify-out/` exists query it (`/graphify`). Both are gitignored and
   regenerable; fall back to grep when absent.

## Patterns

- One file per game in `MenteViva/Games/`; copy `MemoryMatchView.swift`'s
  shape (View + @State + `modelContext.record(GameSession(...))` on finish, #106).
  No game engine, no base classes, no protocol ceremony.
- The daily plan is `Services/DailyPolicy.swift` (pure, tested). Jev judgments, when enabled, live
  in `Services/JevService.swift`; policy stays in code, never in the model. See docs/jev-integration.md.

## When unsure

Smallest thing that works, warm tone, offline-safe. If a choice could land
in a doc, it lands in `docs/decisions.md`.
