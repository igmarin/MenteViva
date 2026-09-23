# Jev decision revisit — 2026-09-19

The 5 product decisions from the human interview (decisions.md) re-asked as real
Jev judgments against a compact evidence/constraints state. Raw request/response
pairs: `jev-json/001`–`005`. Smoke test: `jev-json/000`. Model served: jev-1.13.0.
Jev output is evidence, not truth — policy stays with us.

## 001 — Audience (`jev-json/001-audience.*`)

| | |
|---|---|
| Our call | Healthy-to-mild older adults, preventive focus; not diagnosed MCI in v1 |
| Jev | **Choice:** `healthy_preventive_60plus` — P=0.95, confidence 0.94 (MCI 0.05, dementia 0.0, general 0.0). **Noul** "dementia claims evidence-unsupported + regulatorily risky": **0.98** |
| Verdict | **Agree** — full alignment |
| Read | The evidence+regulatory framing makes this a near-consensus call; MCI stays a revisit trigger, not a v1 target. |

## 002 — Game domains (`jev-json/002-game-domains.*`)

| Domain | Score (0=skip, 1=variety, 2=pillar) | Confidence | Verdict vs our 4 games |
|---|---|---|---|
| processing_speed | **1.93** | 0.89 | **Tension** — we don't cover it |
| working_memory | 1.79 | 0.69 | Agree (covered by Memory Lane) |
| episodic_memory | 1.70 | 0.54 | Agree (covered by Memory Lane) |
| executive_inhibition | 1.34 | 0.43 | Agree-ish (Color Clash = variety-plus) |
| verbal_fluency | 0.81 | 0.67 | Agree (Name the Herd = variety) |
| numeracy | **0.62** (P(skip)=0.39) | 0.41 | **Notable** — weakest domain; Jev leans skip/variety |

- Read: Jev ranks processing speed the only slam-dunk pillar and treats numeracy
  as the most dispensable — our lineup is defensible but inverted on the
  strongest evidence. The speed gap is already a known open question
  (decisions.md); Jev strengthens it.

## 003 — Monetization (`jev-json/003-monetization.*`)

| | |
|---|---|
| Our lean | One-time $12.99 + Family Sharing (open question, not yet decided) |
| Jev | **Choice:** `one_time_1299_family_sharing` — P=0.72, confidence **0.62**; freemium_annual_2499 P=0.28 |
| Verdict | **Agree, low conviction** |
| Read | Right answer, but 0.28 on freemium-annual is a real minority report — keep the "revisit after family beta" trigger exactly as written. |

## 004 — Jev role (`jev-json/004-jev-role.*`)

| | |
|---|---|
| Our call | Offline-first; Jev once daily; never per-session |
| Jev | **Noul** offline-first + once-daily is right: **0.90**. **Noul** per-session worth cost + mid-day shifts: **0.17** |
| Verdict | **Agree** — both directions |
| Read | The architecture decision is validated on the exact axis we cared about (facility wifi, erratic feel, 4–6× cost). |

## 005 — v0.2.0 priority (`jev-json/005-v2-priority.*`)

| | |
|---|---|
| Our lean | None recorded; open question listed speed game as "candidate for fifth game" |
| Jev | **Choice:** `polish_existing_from_playtest` — P=0.99, confidence **0.98** (speed game 0.01, family 0.0, breadth 0.0) |
| Verdict | **Notable** — strongest signal of the whole batch |
| Read | Given "no playtest data exists," Jev says the speed game waits: playtest first, then decide. This reorders my intuition (evidence-first → speed game next). |

## Candidate tickets (genuine tensions only)

1. **Playtest before fifth game.** Jev 005 (P=0.99) says v0.2.0 = playtest-driven
   polish. Action: schedule 3–5 sessions with ES/EN seniors 65+ before scoping
   any new game. The processing-speed game becomes the default *next* candidate,
   gated on playtest outcome — consistent with 002's 1.93 pillar score.
2. **Numeracy justification check.** Jev 002 scores numeracy 0.62 with P(skip)=0.39.
   Cheap ticket: define what Number Trail is *for* (engagement variety vs
   evidence domain) and let playtest data (ticket 1) confirm or cut it.

No ticket for monetization: Jev agrees with our lean; the 0.28 freemium
minority is already covered by the existing "revisit after family beta" trigger.

## 007 — Audience re-asked (corrected state) — 2026-09-20

The original 001 call assumed "healthy preventive 60+". The owner later stated
the real player has early-stage dementia. Same model, same question shape,
corrected state — and the answer flips (raw pair: `jev-json/007-audience-dementia.*`).

| Judgment | 001 | 007 |
|---|---|---|
| Primary audience | healthy_preventive_60plus | **mci_early_dementia** (0.95, conf 0.94) |
| Design | — | errorless/familiarity over speed (0.93) |
| Content | — | familiar/personalized matters (0.88) |

Lesson recorded as a rule in docs/question-audit.md: the question and its
implicit state are the decision; a confident answer to the wrong premise is the
most expensive failure mode we have.

## 008 — Games re-scored for early dementia — 2026-09-20

Same five games, re-scored against the corrected audience (early dementia,
errorless/familiarity priority). Raw pair: `jev-json/008-games-dementia.*`.
Score legend: 0 = deprioritize, 1 = keep, 2 = core.

| Game | Score | Confidence | Verdict |
|---|---|---|---|
| Memory Lane (pairs) | 1.76 | .64 | keep, leaning core |
| Name the Herd (category) | 1.27 | .16 | keep — Jev genuinely unsure (14/44/42) |
| Color Clash (Stroop) | 0.24 | .65 | deprioritize — error-*inducing* by design |
| Number Trail (math) | 0.12 | .83 | deprioritize |
| Quick Eyes (speed) | 0.01 | .98 | deprioritize — timed pressure, worst fit |
| Next game = reminiscence/familiarity | 0.92 (Noul) | — | strongly indicated |

**Key reconciliation:** the three games Jev deprioritizes for *dad* are exactly
what a healthy 40-something wants — speed, logic, attention. So nothing is
deleted: the five games get **allocated to the right person**, which is the
per-person library (Q2 answer C) made concrete. Dad's library = Memory Lane +
Name the Herd + a new reminiscence game; the speed/logic/attention games serve
mom and the owner.

Still gated: any *rebuild* or *new game* waits on dad's playtest (#6, gate #18).
This is a candidate list, not a work order.

## 009 — Segment prioritization — 2026-09-22

Owner opened the design to 3 segments (60+, mental-health, wellness) — question
from question-audit re-litigated with cited market state from
`docs/research-2026-09-22.md`. Raw pair: `jev-json/009-segment-priority.*`.
Real question asked: where does *design and copy focus* go (one binary, no code
forks) — not "which market is biggest."

| Judgment | Result | Verdict |
|---|---|---|
| Primary design/copy focus | **older_adults_60plus** — P=1.00, confidence 1.00 (mental-health 0.0, wellness 0.0) | **Agree** — maximal signal, matches dad-first product truth |
| Sell to the caregiver buyer | **Noul 0.77** | **Agree** — marketing/payflow addresses the adult child; player never sees a pitch |
| Copy ceiling unchanged under expansion | **Noul 0.86** | **Agree** — wider audience *raises* the value of the wellness line |

Read: the 3-segment expansion resolves to "S1 focus, S2/S3 served as spillover
of the same product" — exactly what the research said (S2 = regulatory gravity
+ no design freedom; S3 = no edge). Expansion changes the *store listing and
welcome copy* (who it's for), not the app. Action feeding Track C/D: App Store
copy and onboarding speak to the adult child ("for someone you love"); in-app
copy speaks to the player, warm and claim-free. No decision changes; this
locks the audience question for good — question-audit closeout in Track B
records it in decisions.md.
