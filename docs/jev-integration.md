# Jev integration — MenteViva

Jev is **seasoning, not the meal**. All four games are 100% deterministic and work offline.
Jev answers two narrow questions per day; code stays in control of everything else.

Source of truth: https://docs.typesafe.ai/llms.txt (fetched 2025; append `.md` to doc paths).
Verified against live API 2026-09-19 (model served: `jev-1.13.0`; raw pairs in `jev-json/000`–`005`).

## The daily judgment at a glance

One lazy request per local day; every failure path lands silently on the
deterministic fallback. The UI never waits on the network.

```mermaid
flowchart TD
    A["Game list appears, first time today"] --> B{"Cached plan for today?"}
    B -->|yes| R["Render plan instantly"]
    B -->|no| S["Build state: aggregated stats only, composed in English"]
    S --> E["POST to JEV_PROXY_URL"]
    E --> P["Cloudflare Worker: adds Bearer key server-side, forwards verbatim"]
    P --> J["api.typesafe.ai/v1/systemone"]
    J --> V{"2xx and answers parse?"}
    V -->|yes| C["Cache by local day — rank in code — difficulty only if confidence ≥ 0.6"]
    V -->|no| F["Fallback: day-of-year rotation, keep yesterday's difficulty"]
    U["No proxy URL configured"] --> F
    C --> R
    F --> R
```

## API contract used

- `POST https://api.typesafe.ai/v1/systemone`
- Header: `Authorization: Bearer <TYPESAFE_AI_KEY>`
- Body: `{ "state": <string|object>, "model": "jev-latest", "questions": { "<key>": {...} } }`
- One request can mix Choice / Score / Noul questions; all see the same state and are
  evaluated independently. We send **one request per day** with 8 questions.
- Answers (verified live): `choice` → `{type, choice, probabilities, confidence}`;
  `score` → `{type, score (float, e.g. 1.93), legend (object keyed by level),
  probabilities (object keyed by level), confidence}`;
  `noul` → `{type, noul (P(yes), 0..1)}` — **no confidence field on Noul**.
- Real observed values: score float `1.7`–`1.93`, legend echoing our criteria verbatim,
  probabilities summing to ~1.0, `usage: {input_tokens, output_tokens}` on every response
  (001: 890 in / 95 out). Client ignores `usage` today.
- `confidence` (0..1) is derived from the probability distribution's shape; it's a
  separate axis from the answer itself. Gate actions on it.

## Judgment 1 — daily game mix (4 × Noul)

- **Primitive:** four Noul questions, one per game
  (`include_memory_match`, `include_stroop`, `include_category_fluency`, `include_math_streaks`).
- **Instructions:** "Should <game> be included in today's recommended mix for this player?"
  with `criteria.true/false` pinning what "should" means (variety, recency, engagement).
- **State:** compact JSON object: per game → sessions in last 14 days, mean accuracy,
  mean rounds completed, days since last played. No dates, no names, no identifiers.
- **Why Noul and not Choice:** the mix is multi-select (2–3 of 4 games). A single Choice
  forces one winner; independent Nouls give a per-game probability we rank in code.
- **Policy in code:** sort games by `noul` descending, take top 3. This guarantees a
  non-empty mix even if every probability is low — the model ranks, code decides.
- **Fallback:** deterministic rotation — day-of-year offset over the game list, top 3.

## Judgment 2 — per-game difficulty (4 × Score)

- **Primitive:** four Score questions, one per game, three levels.
- **Levels (criteria, ordered):**
  0 = "Easy — player is struggling or accuracy dropped recently; reduce cognitive load"
  1 = "Medium — player is steady; maintain current challenge"
  2 = "Hard — player consistently succeeds quickly; increase challenge"
- **State:** same session summary object, restricted to that game's last 10 sessions
  (accuracy trend + duration per round). Reused from the same daily request state.
- **Mapping:** `score` is a float; code rounds to the nearest level (0.49 → easy,
  1.5 → hard). `score` outside [0, 2] is clamped.
- **Confidence gate:** apply the new difficulty only when `confidence ≥ 0.6`.
  Wrong difficulty is the high-stakes error for this audience (frustration → abandonment),
  so the threshold sits above the docs' 0.5 "genuinely unsure" floor. Below threshold:
  keep yesterday's difficulty. Initial difficulty for a new player is always **medium**.
- **Fallback:** keep current stored difficulty.

## Timing — when judgments fire

Once per local day, lazily, on first appearance of the game list. Both judgments ride in
**one HTTP request** (4 Nouls + 4 Scores against one state object). The result is cached
in `UserDefaults` with the local day stamp; a cached plan for today is reused without a
network call. Nothing blocks the UI — the home screen renders the cached/default plan
immediately and updates in place if Jev answers.

Not after each session: difficulty that shifts mid-day feels erratic to older adults,
and per-session calls multiply cost 4–6× for no benefit at this granularity.

## Offline / failure behavior

Every failure path degrades to the deterministic fallback, silently (convention 5 —
no error copy, ever):

1. No network / timeout (10 s) → fallback plan.
2. Proxy or API error (non-2xx) → fallback plan.
3. Malformed response / missing answers → per-question fallback (a half-good response
   still contributes its good answers).
4. Low confidence on a difficulty Score → keep current difficulty.
5. No proxy URL configured → service is inert; fallback plan always.

## Cost / latency

- 1 request/day/user, ~8 questions, state ≈ 300–500 input tokens, answers ≈ 50–100
  output tokens. Negligible cost; Jev is a small fast model, typical latency < 1 s,
  off the critical path anyway (cached plan renders first).
- ES/EN note: state is always composed in English (Jev's primary training language;
  docs note lower accuracy for other languages). Locale never reaches the request.

## Privacy — what leaves the device

The state object contains only **aggregated gameplay statistics**: game IDs, session
counts, accuracy ratios, round counts, "days since played". No name, age, exact dates,
device identifiers, free text, or health claims. The proxy adds the API key server-side;
the device never holds it. If we later add CloudKit sync, this state shape stays the
same — sync changes storage, not what Jev sees.

## Server-side proxy requirement

An iOS app cannot hold `TYPESAFE_AI_KEY` safely (extractable from the binary —
convention 7: server-side proxy before public release). `JevService` therefore posts the
identical request body to a **configurable proxy URL** (`JEV_PROXY_URL` in Info.plist /
xcconfig; unset → offline fallback). Reference implementation: `proxy/worker.js`
(~20-line Cloudflare Worker; deploy guide in `proxy/README.md`):

```
POST /jev  →  forward body to https://api.typesafe.ai/v1/systemone
              with header Authorization: Bearer $TYPESAFE_AI_KEY
              return response verbatim
```

No request rewriting, no logging of bodies, rejects anything but `POST /jev`. The app
code does not change when the proxy goes live — only the config value does. During
local beta, run the same worker locally (`npx wrangler dev`, key from the environment).
