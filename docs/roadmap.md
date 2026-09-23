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
- Scoring → progress redesign (Jev 010 noul 0.79: points confused, progress motivates).
- Memory Lane engagement + visual warmth (Jev 010: dad's anchor, engagement 0.50).
- Quick Eyes: untimed errorless redesign replaces the shrink-curve feel check (Jev 010).
- ES copy pass with a native speaker for warmth, not just correctness (#12).
- Device a11y checklist from the audit (issue #5 comments) on real hardware.

## Then — distribution, in two tiers

**Tier 1 — free path (now, no paid account):**

- Device installs: `swift tools/generate_project.swift` → Xcode → ⌘R (local-only is the default).
  Builds expire after 7 days; re-sign from Xcode to renew (#38 runbook).
- Family + in-person testing on whatever devices we can lay hands on.
- Jev proxy on Cloudflare's free tier → live daily mix/difficulty (#13 deploy).
- Privacy policy + support page hosted free (#34).
- Store listing copy and screenshots written now so publishing is a copy-paste
  later (#35).

**Tier 2 — blocked on the paid Developer Program ($99/yr, deliberately
postponed until the trigger in decisions.md 2026-09-20):**

- TestFlight beta (#10) — external testers with no expiry.
- CloudKit sync + real `CKShare` family sharing (#11).
- App Store submission, price, StoreKit purchase (#21).
- Non-expiring installs, more than 3 simultaneous test devices.

## Later — public release gate

- [ ] Medical-claims review: copy stays "games for an active mind",
      never "prevents/treats dementia" (research §1, App Store 1.4.1).
- [ ] Privacy policy page (what leaves the device: jev-integration.md §privacy).
- [ ] Age rating + positioning decision.
- [ ] Business model final call with beta data (one-time $12.99 lean).
- [ ] ES/EN native review sign-off.
- [ ] App Store screenshots + description in both languages.

## Parking lot (deliberately not planned)

- ~~New user segments~~ — resolved 2026-09-22 (Jev 009): 60+ leads, mental-health
  and wellness users are spillover of the same product; no forks, copy ceiling holds.
- Android, watchOS, clinician dashboard, more games (blocked by #18 gate).

