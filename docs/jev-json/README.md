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
