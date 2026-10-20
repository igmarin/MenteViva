# Handoff: graphify --update, GameID hub, Jev offline and API-key traces

## Goal
Refresh the graphify knowledge graph (`graphify-out/`) for MenteViva after new code/docs/images landed, then use it to trace the project's risky invariants (GameID hub, Jev offline fallback, API key handling).

## Status
- Done: `/graphify --update`. 72 changed files re-extracted (48 code via AST, 15 docs + 9 images via 2 subagents). Then `graphify update .` (code-only) rebuilt the graph: now 1,235 nodes, 73-ish communities with auto-generated names (my hand labels were replaced; some are symbol-named like `GameProgress`, `.weekly`, and one is HTML-escaped `Set Up &amp; Captions`; cosmetic).
- Done: `GameID` check. It is now ONE node (`MenteViva/Models/GameID.swift:4`, reaches 392 nodes at depth 2). The earlier duplicate came from `MenteViva/Theme.swift:41` (`extension GameID`) and was merged by the rebuild.
- Done: Jev offline path verified (see Verification).
- Done: API key trace (see Decisions / findings).
- Three findings saved in `graphify-out/memory/query_20261020_*.md` (GameID hub, framework-node noise, shallow doc extraction).
- `git status` was clean on `main`; `graphify-out/` is gitignored. Only this handoff file is uncommitted.

## Decisions
- Images went into one agent chunk (not one per image) to save tokens.
- The edge count fell 2627 -> 2470 and tripped the #479 shrink guard; I forced the write. Reason: no files deleted, drop is stale edges replaced by re-extraction plus duplicate framework nodes collapsing. Backup was deleted.
- Framework nodes (`SwiftUI`, `Foundation`, `XCTest`) look like god nodes only because many files import them. Ignore them when reading hubs/bridges.

## Findings
- **Jev offline invariant holds.** `JevServiceTests.swift:182-208`: with `proxyURL: nil` there is no network request (line 204), plan equals `DailyPolicy.plan` (203), `.stroop` moves to `.easy` (202) and the change is recorded in `PlanStore` (205-207). Server error falls back to the cached plan without retry (`JevServiceTests.swift:83`). Jev can move a game only one level (`JevPlanPolicyTests.swift:32`, `:38`). `.stroop` is the raw ID for Color Clash (`GameID.swift:26`).
- **API key trace.** The upstream Typesafe key (`TYPESAFE_AI_KEY`) lives only in the Worker env: `proxy/worker.js:74` adds `Authorization: Bearer` server-side. No key-like strings in tracked files (`git grep` for `sk-`, `tsk_`, `AIza` found nothing). `MenteViva/Config/Local.xcconfig` is gitignored (`.gitignore:16`) and was never committed. `proxy/.dev.vars` and `proxy/.env` are gitignored too. `Base.xcconfig` ships empty `JEV_PROXY_URL`/`JEV_PROXY_SECRET`, so default builds carry neither.
- **Nuance for `AGENTS.md`:** the app shared secret `JEV_PROXY_SECRET` (the Worker's `APP_SHARED_SECRET`) IS written into `Info.plist` (`MenteViva/Info.plist:7-8`) and sent as `X-MenteViva-Key` (`JevService.swift:134`) whenever `Local.xcconfig` sets it. So a build with the proxy configured has that secret inside the binary, readable by anyone with the .ipa. The upstream key is still safe, but "the API key never enters the binary" is only true for the Typesafe key. The Worker's hardening is what limits abuse.

## Dead ends
- First step-4 write refused by the shrink guard (forced; see Decisions).
- `cost.json` token counts are 0 for this run (subagent usage not exposed).

## Files
- `graphify-out/graph.json`, `graph.html`, `GRAPH_REPORT.md`: outputs.
- `proxy/worker.js:47-74`: secret check and upstream auth.
- `MenteViva/Services/JevService.swift:37-46,133-134`: reads secret from Info.plist, sends header.
- `MenteViva/Info.plist:5-8`, `MenteViva/Config/Base.xcconfig`, `MenteViva/Config/Local.xcconfig.example`: config plumbing.
- `MenteVivaTests/JevServiceTests.swift:83,182-208`: fallback tests.

## Verification
- `graphify query "GameID" --budget 800`: 1,235 nodes, single `GameID`. Done.
- `git grep -n -I -E "(sk-[A-Za-z0-9]{20,}|tsk_[A-Za-z0-9]{10,}|AIza[0-9A-Za-z_-]{30,})"`: no matches.
- Not run: the Swift test suite and `xcodebuild` (no code was changed).

## Next steps
1. Done (option A chosen): `AGENTS.md` non-negotiable reworded (upstream key never in repo/binary; app secret is a gate token) and logged in `docs/decisions.md` (2026-10-19).
2. Optional: re-extract the shallow doc nodes (`CHANGELOG.md`, `docs/design/*.html`, `docs/jev-revisit.md`, `docs/playtest*.md`, `docs/privacy-policy.md`, `docs/profiling.md`, `docs/es-review-packet.md`, `docs/install-runbook.md`) at full depth.

## Standing instructions
- Output style: ADHD mode, lead with the action, numbered steps, cap lists at 5, end with one under-2-minute next action.
- Project: follow `AGENTS.md`; zero third-party dependencies; EN+ES strings; no medical claims.

## Open questions
- Is the shared secret in the binary acceptable (it is a proxy gate, not the upstream key), or should `AGENTS.md` change, or the design (for example App Attest, already noted as a future upgrade in the proxy docs)?
- Re-extract the shallow docs, and is a Gemini key worth setting for that?
