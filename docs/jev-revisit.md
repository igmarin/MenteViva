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
