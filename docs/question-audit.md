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
- Consequence: the *evidence* actually improves — MCI/early dementia is the
  best-supported population for cognitive training, and early-stage dementia
  benefits from cognitive *stimulation* (not training) with errorless,
  familiarity-based, reminiscence mechanics. Speed drills and adaptive
  difficulty matter less; low-failure and familiar content matter more. The
  five games may need to shift. **Marketing ceiling is unchanged**: still "fun
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

## Open re-asks (queued)

- [ ] Jev 007 — audience with corrected state (done, archived)
- [ ] Jev 008 — games re-scored for early dementia
- [ ] Research — iOS/iPadOS adoption share (device floor cost)
- [ ] Research/owner — language shortlist + validator availability
