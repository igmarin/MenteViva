# Question audit

The single most expensive failure mode of this project is a **well-answered
wrong question**: a model (or a human) confidently answers what was asked, while
the real question sits unasked. This file exists to force the question to the
surface before the answer.

Rule: **for each decision, name the question, check whether it is the *real*
question, then say how we'll answer it — research, Jev, or owner.** A Jev call
whose `state` is wrong is wrong no matter how confident the output.

## 1. Audience

- ❌ Wrong version: "which population — healthy preventive 60+ vs MCI vs
  dementia?" — answered Jev 001 against a state that said *healthy preventive*.
- ✅ Real version: **the player is an older adult with a diagnosis of early
  dementia.** This changes both the evidence and the design bar.
- How answered: Jev 007 (re-run with the corrected state) + research §1.
- Consequence: the *evidence* does not improve: MCI is the best-supported
  population for cognitive training, established dementia shows no reliable
  benefit and early-stage dementia is unclear (research §1). The *design* bar
  changes: errorless, familiarity-based, reminiscence mechanics; speed drills
  and adaptive difficulty matter less; low-failure and familiar content matter
  more. The five games may need to shift. **Marketing ceiling is unchanged**: still "fun
  mental exercise", never treatment/prevention/diagnosis.

## 2. Devices / OS

- ❌ Wrong version: "what iOS does dad's iPad run?"
- ✅ Real version: "which iOS should we support for iPhone and iPad, measured by
  market share?" — i.e. who do we exclude by requiring iOS 17?
- How answered: research (iOS/iPadOS adoption share by region), not Jev.
- Constraint that overrides the answer: **SwiftData is iOS 17+**, so a lower
  floor means replacing persistence. We support iOS 17+ because the store layer
  demands it, not because we chose it — the market-share cost is unquantified.
  Action: quantify it before launch.

## 3. Languages

- ❌ Wrong version: "should we add languages?"
- ✅ Real version: two coupled questions — (a) which languages have the market
  reach worth the cost, and (b) **which can we actually validate**?
- Constraint: a translation we can't verify (no native speaker) is a liability,
  not a feature. EN + ES are validated by the owner; every other language needs
  a named validator before it's added.
- How answered: Jev scores language candidates by reach/effort; the *owner*
  gates on validator availability. German is not added until someone we know
  can review it.

## 4. Games

- ❌ Wrong version: "is MoCA copyrighted?" — that's a legal fact, already
  answered (yes, research §3).
- ✅ Real version: "which **non-copyrighted** games matter most for people with
  cognitive issues including early dementia?" — the licensing table (research
  §3) is the floor, not the answer.
- How answered: research §2 (domains) + Jev 008 (games re-scored for early
  dementia) + the licensing table §3.
- Consequence: paradigms are free (memory, attention, fluency, numeracy,
  speed); *clinical tests* (MoCA, UFOV) are not. The open question is not legal,
  it's which free mechanics best serve an early-dementia player — and that may
  shift the current five-game lineup.

## Review results — 2026-09-20 (owner walk-through)

The owner re-examined every question against the reality that this is a
**family**, not one person: dad (early dementia), mom (healthy 60+), owner
(healthy 40+). Answers:

| # | Question | Answer |
|---|---|---|
| 1 | Design floor (who must never be frustrated) | **All three equal** |
| 2 | Games: same library or per person | **Per-person libraries (C)** — the north star, reached in slices |
| 3 | How the app knows who's playing | **Per-device for now** (dad's iPad = dad, my phone = me); named profiles later |
| 4 | Jev mix/difficulty | **Per-device** — already true, no change |
| 5 | Family sharing vs profiles | **Profiles later**; per-device now; text-share already shipped |
| 6 | Devices/sync | Per-device assumption makes sync non-blocking; CloudKit still blocked (paid account) |
| 7 | Languages (market) | **ES + EN for v1** (owner-validated); more languages = #40, gated on a named validator |
| 8 | Pricing | Unchanged: one-time, adult-child-buys |

**Consequences of C (per-person libraries):** it needs profiles, per-person Jev,
and *more games* — none of which exist yet. So C is the destination; the path
starts per-device (already true) and only adds profiles + new games once dad's
own playtest (#6) says what *his* library should be. No three-libraries build
until the warm games are validated as loved.

## Still open (and where they live)

- **Dad's actual game library** → gated on playtest (#6) + Jev 008 (#42).
- **Market languages** → #40 (validator-gated).
- **"Which person is this device" at first run** → implementation detail of the
  per-device model; decide when the first new game ships (not now).

## Open re-asks (queued)

- [ ] Jev 007 — audience with corrected state (done, archived)
- [ ] Jev 008 — games re-scored for early dementia
- [ ] Research — iOS/iPadOS adoption share (device floor cost)
- [ ] Research/owner — language shortlist + validator availability
