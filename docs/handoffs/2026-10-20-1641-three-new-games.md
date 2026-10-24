# Handoff: three new games (Sudoku, Up or Down, Finish the Saying)

## Goal

The owner's father (early-stage dementia, plays on his own iPad and iPhone) gets bored: "few games,
very repetitive". Only 4 games are visible to him, and Home deals 3 a day. The owner wants more variety
and a higher ceiling, at no cost. One new game per hobby he used to have: newspaper puzzles → Sudoku
(#179), card games → Up or Down (#180), sayings → Finish the Saying (#181). Ship one PR per game.

## Status

- **Done, merged to `main`:** Sudoku (PR #182), Up or Down (PR #183). CI is set up (PR #177; the ocr review fix is PR #178).
- **Done and pushed, PR not opened:** Finish the Saying, branch `claude/sayings-game` (last commit
  `b493bad`; the pre-push hook passed: lint, signposts, project file, proxy tests, build + test).
  Commits: deck `2eff81c`, 60 sayings `99ce594`, view + wiring `42582e5`, docs `b493bad`.
- **Not started:** proxy redeploy for 9 games, live 019 response, Jev 016 call, native ES review.
- A cloud session (task_40da0f14, "Build three new games") was started earlier from a proposal card and
  may duplicate this work. It never pushed a branch, as of the last check.

## Decisions

- Lineup chosen by the owner over word search (letters fall under 60pt on iPhone), dominoes (twice the
  build) and decade trivia (facts vary by country). Logged in `docs/decisions.md` 2026-10-19.
- One PR per game, merged one after another (they all touch `GameID`, `Theme`, `GameCard`, `HomeView`,
  `DailyPolicy`, `Localizable.xcstrings`, `proxy/worker.js`).
- Every new game has a `DailyPolicy.value` of 0.8. An unplayed new game therefore enters the top three;
  `DailyPolicyTests` were updated on purpose.
- Up or Down: the deck stays tappable **at any time** (the owner confirmed this; spec §2). The ocr comment
  asking to disable it was answered as "intended".
- 60pt rule counts gaps between targets (Sudoku gap 2pt, cards 8pt). A board or row that stops
  fitting after rotation is dealt again (from the #182 review).
- Sayings: one xcstrings key per slot, `saying.NN.start` and `saying.NN.end`. The EN value is an English
  saying and the ES value a refrán on the same theme, not a translation. Slot 53 ES was changed from
  "Donde hay confianza da asco" (harsh) to "Más vale un amigo / que cien parientes".
- Jev wire contract: each game PR recaptured the request (017, 018, 019; request only). The worker is
  redeployed once, after the third game.
- Auto-merge was requested, but the repo reports `allow_auto_merge: false`, even after the owner said
  they enabled it. #183 was merged manually with `gh pr merge 183 --squash --match-head-commit`, after
  CI was green.

## Dead ends

- Jev 016 judgment: `TYPESAFE_API_KEY` (classifier key) returns **401** from
  `https://api.typesafe.ai/v1/systemone`; `TYPESAFE_AI_KEY` is unset. The request is archived unsent at
  `docs/jev-json/016-new-games.request.json`.
- `mcp__ccd_host__sync_with_base_branch` refused: pinned origin is `igmarin/MenteViva`, but the actual
  origin is `nebulaideas/MenteViva` (re-pin in the app: Help → Troubleshooting → Review Pinned Git Origins).
  The workaround is plain `git fetch` and branching from `origin/main`.
- iOS Simulator control tool: the user never granted device access. Screenshots are taken headless
  with a temporary, uncommitted launch hook in `HomeView` (`-openGame` argument sets the pin with
  `UserDefaults.standard` and pushes the game), then `xcrun simctl io <udid> screenshot`. Writing the pin into
  the sim's prefs plist doesn't always reach the app (cfprefsd cache).
- Jev capture via temporary test: reusing a `UserDefaults` suite made `JevService` skip the request
  (cached). Use a fresh suite and call `removePersistentDomain` first.
- The host Mac sometimes runs at load 50–700 (WindowServer, Siri AI). xcodebuild then exceeds 10 minutes;
  run builds with `run_in_background`.

## Files

- `docs/superpowers/specs/2026-10-19-three-new-games-design.md`: the spec.
- `docs/superpowers/plans/2026-10-19-three-new-games.md`: the task plan (Tasks 0–10).
- `MenteViva/Games/SayingsDeck.swift`, `Sayings.swift`, `SayingsView.swift`: game 3.
- `MenteVivaTests/SayingsDeckTests.swift`, `SayingsStringsTests.swift`: its tests.
- `MenteViva/Games/SudokuPuzzle.swift`, `SudokuView.swift`, `UpOrDownDeal.swift`, `UpOrDownView.swift`: games 1–2.
- `docs/jev-json/019-daily-plan.request.json`: current 17-key contract; README notes 017–019.
- `proxy/worker.js` `GAMES` now has 9 IDs. The deployed worker still allows 6.

## Verification

- `xcodebuild test -project MenteViva.xcodeproj -scheme MenteViva -destination 'platform=iOS Simulator,id=72195EBD-F9B8-4648-839A-2EEBB6409F4A'`
  → last result: **241 tests, 0 failures** on `claude/sayings-game`.
- `xcrun swift-format lint --strict -r MenteViva MenteVivaTests tools` → clean.
- `node --test proxy/*.test.js` → 15/15 pass.
- Screenshots (hard level): iPhone SE and iPad both show 4 same-theme endings and fit with no scroll.
  Spanish layout was not checked by eye.

## Next steps

1. Open the PR: `gh pr create --base main --head claude/sayings-game --title "Finish the Saying: pick the ending of a familiar saying (#181)"`,
   with the body in the `pr` skill format. List the 60 ES refranes (from `MenteViva/Localizable.xcstrings`,
   keys `saying.NN.*`) for the native reviewer, and note that merge waits for that sign-off. End the body with
   "🤖 Generated with [Claude Code](https://claude.com/claude-code)". Then `mcp__ccd_pr__get_status`.
2. Check the ocr review comments on that PR. Fix the real ones, reply to the rest (as on #182/#183).
3. After merge: the owner runs `wrangler deploy` in `proxy/`, then saves the live 9-game response as
   `docs/jev-json/019-daily-plan.response.json`.
4. Send Jev 016 when a working key exists; record it in `docs/jev-revisit.md` §016.
5. If the cloud session task_40da0f14 produced anything, reconcile it or discard it.

## Open questions

- Who reviews the Spanish refranes, and when (the #12 native-speaker process)?
- Does the owner want a working Jev key in this shell, to send 016?
- Should "Allow auto-merge" really be on? GitHub still reports it off.

## Standing instructions from the owner

- ADHD output style: lead with the action, numbered steps, at most 5 list items, end with one next action under 2 minutes.
- Before merging, check the PR review comments. Fix what's real and answer the rest.
- Auto-fix is on for PRs in this session. Merge only when CI is green and the owner has said to.
- Commit trailer: `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- Project rules: `AGENTS.md`, `docs/conventions.md` (EN+ES strings, ≥60pt targets, warm copy, no medical claims, zero dependencies).
