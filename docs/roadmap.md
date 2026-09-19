# Roadmap

Ordered. Finish one before starting the next. Dates are added when work
starts, not before — no fantasy deadlines.

## Now — playtest loop (the only thing that matters)

1. Dad plays all four games on a real iPad, unsupervised.
2. Watch, don't help. Note: where he hesitates, what he mis-taps, what he
   skips, whether he smiles.
3. Fix the top 3 friction points. Repeat weekly.

Exit criteria: he picks up the app without being asked, twice in one week.

## Next — v0.2 "warmth"

- End-of-game celebration screen (confetti + warm copy, ES/EN).
- Session history view for dad ("what I played this week") — big, simple.
- App icon + launch screen with personality.
- Voice input spike for Name the Herd (motor-friendly alternative to taps).

## Then — v0.3 "family"

- CloudKit `CKShare` on progress → family read-only view + preset cheers.
- Jev proxy (20-line Cloudflare Worker or similar) → daily mix/difficulty live.
- Accessibility audit against conventions.md §4 (VoiceOver walkthrough of
  every screen, Dynamic Type at max).

## Later — public release gate (each item must be checked, not assumed)

- [ ] Medical-claims review: copy stays "games for an active mind",
      never "prevents/treats dementia" (research doc §1, App Store 1.4.1).
- [ ] Privacy policy page (what leaves the device: jev-integration.md §privacy).
- [ ] Age rating + "Made for Seniors" positioning decision.
- [ ] Business model decision (free / one-time / subscription) — research §4.
- [ ] ES/EN review by a native speaker who isn't us.
- [ ] TestFlight family beta (5–10 people, 2 weeks minimum).

## Parking lot (deliberately not planned)

- Android version — until family demand proves it.
- Clinician dashboard — until a clinician asks.
- More games — until the four we have are measurably loved.
- Apple Watch companion — no.
