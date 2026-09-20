# Roadmap

Ordered. Finish one before starting the next. Dates are added when work
starts, not before — no fantasy deadlines.

**Owner decision (2026-09-19): polish before distribution.** TestFlight (#10)
and any paid-developer-account work wait until the app feels right in dad's
hands. Beta is a *distribution* step, not a QA step.

## Now — make it feel finished (G1)

The app works; it doesn't yet feel like a finished product. Polish list:

1. **App icon + launch screen** — currently the default placeholder. A real
   icon is the single biggest "is this a real app?" signal.
2. **Home screen personality** — warm greeting, big tiles with per-game emoji,
   "Play again" affordance instead of a plain List.
3. **Dad playtest #1** (#6) — the gate Jev insists on (P=0.99). Watch, note
   3 friction points, fix them.
4. **Sound + haptics** — gentle success chime, soft tap feedback (optional,
   off by default if he finds them noisy).
5. **Empty/first-run state** — does a brand-new user know what to tap?

Exit criteria: dad picks it up unprompted, twice in one week (docs/mvp.md G1).

## Next — polish pass 2

- Session history richness (streaks, "you improved"), portrait/landscape check.
- Quick Eyes feel check with dad (is the 1.2s → 0.35s shrink curve right?).
- ES copy pass with a native speaker for warmth, not just correctness (#12).
- Device a11y checklist from the audit (issue #5 comments) on real hardware.

## Then — distribution (only when the above feels done)

- Apple Developer Program enrolment → CloudKit container provisioning.
- Real `CKShare` family sharing (#11) — now verifiable with 2 Apple IDs.
- Jev proxy deployed to Cloudflare → live daily mix/difficulty (#13 deploy step).
- TestFlight family beta (#10, 5–10 people, 2 weeks).

## Later — public release gate

- [ ] Medical-claims review: copy stays "games for an active mind",
      never "prevents/treats dementia" (research §1, App Store 1.4.1).
- [ ] Privacy policy page (what leaves the device: jev-integration.md §privacy).
- [ ] Age rating + positioning decision.
- [ ] Business model final call with beta data (one-time $12.99 lean).
- [ ] ES/EN native review sign-off.
- [ ] App Store screenshots + description in both languages.

## Parking lot (deliberately not planned)

- New user segments (Jev segment-expansion study → v0.4.0 research).
- Android, watchOS, clinician dashboard, more games (blocked by #18 gate).

