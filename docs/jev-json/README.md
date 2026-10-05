# jev-json — Jev call archive

## Purpose

Audit trail of **real Jev API calls** that drive product decisions for MenteViva.
Every request body is saved verbatim **before** sending; every response body is
saved verbatim as returned. Analysis lives in `docs/jev-revisit.md`; this
directory holds only raw evidence.

## File naming

- `NNN-slug.request.json` — exact body POSTed to `https://api.typesafe.ai/v1/systemone`
- `NNN-slug.response.json` — exact JSON response received

Numbering starts at `001`. `000` is reserved for the connectivity smoke test.
Numbers are never reused; a re-asked question gets a new number.

## Privacy

Saved state must stay **anonymized aggregates** per `docs/jev-integration.md`
§Privacy: game IDs, session counts, accuracy ratios, round counts, "days since
played". No names, ages, exact dates, device identifiers, free text, or health
claims — in request files or anywhere else in this archive.

## 011 — the app's real daily request

`011-daily-plan.request.json` is the exact body `JevService` builds (captured
from the code through a stubbed `URLSession`, not retyped). Its `state` is a
**sample fixture** with made-up numbers, not a real player. The response is the
live answer via the deployed proxy. `JevServiceTests` replays the pair.

## 014 — the six-game daily request

`014-daily-plan.request.json` replaces 011 as the current wire contract. 011 was
captured before Remember Together (#139) and asks about five games; 014 asks about
six — `include_` for every game, `difficulty_` only for the five that have levels.
Captured the same way (from `JevService` through a stubbed `URLSession`, not retyped),
with the same anonymized sample state plus a `reminiscence` entry.

It exists because the proxy's question-key allow-list had been left at five games
and rejected every real request with 400 (#146). `JevServiceTests` pins the app's
keys to this file and `proxy/worker.test.js` replays the exact bytes through the
worker, so the two sides cannot drift apart again unnoticed. 011 stays: its
response is still the fixture the plan-ranking test replays.

`014-daily-plan.response.json` is the live answer through the deployed proxy on
2026-10-04: HTTP 200, model `jev-1.13.0`, 11 answers for 11 questions. Jev put
Remember Together second in the mix (`include_reminiscence` 0.75), which is the
pick the 400s had been suppressing.
