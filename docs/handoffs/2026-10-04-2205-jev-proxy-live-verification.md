# Handoff — close out #146 (Jev proxy live verification)

Written 2026-10-04 22:05. Branch `fix/146-live-proxy-verification`, working tree clean, 2 commits ahead of `main`, not pushed.

## Goal

Close GitHub issue **#146** ("Jev proxy rejects every request: GAMES missing reminiscence"). The code fix already shipped to `main`, but #146's own done-when goes further:

> A live request against the deployed proxy returns 200 and the payload is archived in `docs/jev-json/` (next number).

So the issue stays open until a real authenticated call to the deployed Cloudflare Worker returns 200 and both halves of the pair are archived as `014`.

Background on the bug: `proxy/worker.js` built its question-key allow-list from a five-game list while the app had grown to six (Remember Together / `reminiscence`, #139). The proxy answered **400 to every real request**, and `JevService` converts any non-2xx to `badResponse` and silently falls back to `DailyPolicy` — so the Jev override was dead in production with no visible symptom.

## Status

Four steps. **Three done, one blocked on a secret.**

1. **Done** — captured the exact six-game request body and archived it as `docs/jev-json/014-daily-plan.request.json` (11 question keys).
2. **Done** — pinned both sides to that file; red→green proven; lint clean.
3. **Done** — worker deployed to Cloudflare by the user.
4. **Blocked** — the live authenticated 200 + archived response + closing #146. Needs `APP_SHARED_SECRET`, which is not on this machine.

Earlier, already merged to `main` (not part of this branch):

- `a7f0a10` / PR #147 — the actual `worker.js` fix (#146).
- `e840be0` / PR #149 — narrowed `.github/workflows/claude-code-review.yml` to `types: [opened, ready_for_review]`.

## Deployment facts (from the wrangler log, not guessed)

- URL: **`https://menteviva-jev-proxy.ismael-marin.workers.dev`** — the endpoint is `/jev`.
- Version ID: `d020a68b-e4ad-4e2f-8c2b-9f40d45e0dba`.
- `Total Upload: 3.23 KiB / gzip: 1.41 KiB`; `Uploaded menteviva-jev-proxy (3.13 sec)`.
- Deploy log: `~/Library/Preferences/.wrangler/logs/wrangler-2026-10-05_03-08-58_779.log`. Login succeeded in the prior log, `...03-08-27_755.log`.
- Credentials live at `~/Library/Preferences/.wrangler/config/default.toml`, **not** `~/.wrangler` (which does not exist on this machine — checking only there gives a false "not logged in").

## Decisions

- **`014` replaces `011` as the current wire contract.** `011` was captured before #139 and asks about five games. `014` asks about six: `include_` for every game, `difficulty_` only for the five with levels (`GameID.hasLevels` is false for `reminiscence`). `011` stays in the repo because its *response* is still the fixture the plan-ranking test replays.
- **Captured from code, never retyped.** Precedent set by `011` and recorded in `docs/jev-json/README.md`. Done by temporarily patching the existing body-capture test in `MenteVivaTests/JevServiceTests.swift` to dump `httpBody` to a file, running that one test, then restoring the file from a scratchpad copy. Chosen over adding a new `.swift` file specifically to avoid `swift tools/generate_project.swift` + the close-Xcode dance (AGENTS.md workflow steps 2 and 4).
- **Archive the request *before* sending it, then POST that exact file** with `--data-binary @...`. Makes the archived bytes literally the bytes sent, satisfying the README's "exact body POSTed" rule.
- **Pin both sides to the one file**, so the app and the proxy cannot drift apart again unnoticed — that silent drift *was* the bug. `JevServiceTests` asserts the app's keys equal `014`'s; `proxy/worker.test.js` replays `014`'s exact bytes through the worker.
- **Dropped the `.union(["include_reminiscence"])` compensation** in `JevServiceTests` that `011`'s staleness had forced; it is now plain equality against `014`, and `archivedKeys.count` is 11 (was 10).
- **Did not re-run `wrangler secret put`.** Worker secrets persist across deploys from the #63 deploy; `wrangler deploy` replaces code only.
- **Earlier in the session, rejected `alibaba/open-code-review`** (the user asked whether it was a better review path). Reasons: its rulesets are Java/web-shaped (NPE, thread-safety, XSS, SQL injection) and MenteViva is SwiftUI + SwiftData with no server; Swift is not named as a supported language; it is an Actions-based bot and this repo's Actions minutes are out; and it would need a third LLM provider key against AGENTS.md's two-key rule. Its token-efficiency pitch optimizes cost-at-scale, which a solo repo opening one PR at a time does not have.

## Dead ends

- `-destination 'platform=iOS Simulator,name=iPhone 16'` — **no such simulator.** xcodebuild then falls back to "My Mac" and fails with `My Mac's macOS platform doesn't match MenteViva.app's supported platforms`. Use **`name=iPhone 17`** (available: iPhone 18 Pro, 18 Pro Max, 17e, Air, 17).
- Checking `~/.wrangler` for credentials — wrong path on macOS, see above.
- `TYPESAFE_API_KEY` is set in the shell but is **not** usable here. AGENTS.md: it is the dev-machine classifier key; `TYPESAFE_AI_KEY` is the proxy's, and neither is `APP_SHARED_SECRET`.
- `node --test proxy/` (the command that used to be in `worker.test.js` line 1) fails with `MODULE_NOT_FOUND` on Node 24.21.0. The working form, already in `proxy/README.md`, is `node --test 'proxy/*.test.js'`.
- `MenteViva/Config/Local.xcconfig` does not exist — git-ignored, so it did not survive. That is why the shared secret is unavailable locally.

## Files

- `docs/jev-json/014-daily-plan.request.json` — **new.** The 11-key body `JevService` builds today. Pretty-printed with `indent=2, sort_keys=True, ensure_ascii=True` to match `011`'s style.
- `docs/jev-json/014-daily-plan.response.json` — **does not exist yet.** Step 4 creates it.
- `proxy/worker.js` — holds the fix (`GAMES` includes `reminiscence`; `LEVELLESS` mirrors `GameID.hasLevels` so `difficulty_` is only derived for levelled games). Already on `main`.
- `proxy/worker.test.js` — new test `"archived 014 request body -> 200, forwarded verbatim"` reads the archive via `fileURLToPath(new URL("../docs/jev-json/...", import.meta.url))`.
- `MenteVivaTests/JevServiceTests.swift:133` points at `014-daily-plan.request.json`; `:156` asserts `archivedKeys.count == 11`.
- `docs/jev-json/README.md` — appended a `## 014 — the six-game daily request` section explaining why it supersedes `011`.
- `.gitignore:14` — added `proxy/.wrangler/` (wrangler build scratch; the dir existed untracked and unignored, silent only because it was empty).
- `proxy/README.md` — the deploy runbook; its secret-setup steps 2 and 3 are the rotation path if the secret is lost.
- `MenteViva/Services/JevService.swift:134–136` — the `guard ... (200..<300)` that turns any non-2xx into a silent fallback. Worth re-reading to understand why this bug was invisible.

## Verification

Last known results, all from this session:

```
node --test 'proxy/*.test.js'
# -> ℹ pass 15, ℹ fail 0

xcodebuild test -project MenteViva.xcodeproj -scheme MenteViva \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:MenteVivaTests/JevServiceTests
# -> 8/8 passed, ** TEST SUCCEEDED **

xcrun swift-format lint --strict -r MenteViva MenteVivaTests tools
# -> clean (no output)
```

Red→green was proven with the real archived payload, not just asserted: deleting `, "reminiscence"` from `GAMES` in `proxy/worker.js` makes exactly two tests fail — the `014` replay and the six-game payload test — both getting 400 where 200 was expected. Restored from a scratchpad copy afterwards.

Live probes against the deployed worker (unauthenticated, so they only reach the auth layer):

```
GET  /jev                    -> 405   (expected 405)
GET  /other                  -> 404   (expected 404)
POST /jev, no secret         -> 401   (expected 401)
POST /jev, wrong secret      -> 401   (expected 401)
```

**These four do not prove the fix is live.** The allow-list check runs after auth, so every probe stops at 401. Only an authenticated 200 distinguishes the fixed bundle from the old one.

## Next steps

1. **Get `APP_SHARED_SECRET` into `proxy/.dev.vars`** (git-ignored, `.gitignore:13`, and the location `proxy/README.md` already designates for local secrets). The user was asked to run:
   ```
   printf 'APP_SHARED_SECRET=PASTE_IT_HERE\n' > proxy/.dev.vars
   ```
   Read it from there; never echo it. If the secret is lost, rotate instead — `cd proxy && npx wrangler secret put APP_SHARED_SECRET` with a fresh `openssl rand -hex 32`. Rotation is safe: no shipped build depends on it yet.
2. **Make the live call**, POSTing the archive verbatim:
   ```
   curl -sS -D - -X POST \
     -H 'Content-Type: application/json' \
     -H "X-MenteViva-Key: $APP_SHARED_SECRET" \
     --data-binary @docs/jev-json/014-daily-plan.request.json \
     https://menteviva-jev-proxy.ismael-marin.workers.dev/jev
   ```
   Expect **200**. A 400 means the deployed bundle is still the five-game version — redeploy with `cd proxy && npx wrangler deploy`. A 502 means upstream Jev trouble, not a proxy bug.
3. **Archive the response verbatim** as `docs/jev-json/014-daily-plan.response.json`, pretty-printed the same way as the request (`indent=2, sort_keys=True, ensure_ascii=True`). Check it against the privacy rule in `docs/jev-json/README.md` before committing: anonymized aggregates only.
4. **Consider pinning the response too.** `JevServiceTests` currently replays `011`'s response for plan ranking; a `014` equivalent would cover the six-game path end to end. Optional, and it needs reading the real answers first.
5. **Commit, push, open a PR to `main`.** The pre-push hook (lint, signposts vs docs, project file, build + test) is what actually runs — `.github/workflows/swift.yml` is manual-dispatch only while Actions minutes are out.
6. **Close #146** with the live status code and the archive paths as evidence.
7. Update `CHANGELOG.md` only if something player-visible changed. The `aaa2c49`/#147 entry already covers the user-facing fix; archiving evidence and test pinning are not player-visible.

## Open questions

- **Does the user still have `APP_SHARED_SECRET`?** Only they can answer. Everything in step 4 waits on it.
- **Should `AGENTS.md`'s "Current status" line be updated?** It still cites "payload archived `docs/jev-json/011`" as the Jev verification. Once `014` lands it is the newer evidence.
- **Was the #146 regression ever visible to the player?** Almost certainly not — installs without a proxy URL were never affected, and installs with one degraded silently to `DailyPolicy`. Worth one sentence on the issue when closing it.
- The **graphify extractor bug** found earlier (Swift initializer calls and property access not followed; same-file JS const refs dropped) belongs upstream in the graphify repo, not MenteViva, and has not been filed anywhere.

## Standing instructions heard this session

From `AGENTS.md` and the user's global config — the next session will not have heard these:

- **Zero third-party dependencies** in the app: SwiftUI/SwiftData/Foundation only. (`npx wrangler` and `node --test` are dev tooling, not app deps, and `proxy/README.md` already prescribes `npx wrangler`.)
- **The API key never enters the repo or the binary.** Unset proxy URL = offline fallback, which must always work.
- **Two different keys:** `TYPESAFE_API_KEY` = dev-machine classifier, `TYPESAFE_AI_KEY` = the proxy's secret. Neither ever enters the repo, plist, or binary.
- **Every user-facing string** goes in `Localizable.xcstrings` with EN + ES in the same commit.
- **Warm failure copy only** — never "wrong/error/failed". **No medical claims**; "fun mental exercise" is the ceiling.
- Branch from `main`, PR back to `main`. Verify with build + tests + `swift-format lint --strict` before committing.
- Commit messages end with `Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>`; PR bodies end with `🤖 Generated with [Claude Code](https://claude.com/claude-code)`.
- **Output style is ADHD mode**, always on: lead with the next action, number multi-step work, cap lists at five, concrete time estimates, show what now works after a change, no preamble and no closers. One next action at the end, doable in under two minutes.
- Apply the `ponytail` skill (shortest thing that works, no speculative abstraction) and run the complexity classifier before coding tasks.
