# Roadmap

Ordered. Finish one before starting the next. Dates are added when work
starts, not before — no fantasy deadlines.

**Owner decision (2026-09-19): polish before distribution.** TestFlight
and any paid-developer-account work wait until the app feels right in dad's
hands. Beta is a *distribution* step, not a QA step.

## Now — v0.3 More games, more range, then v1.0 App Store (decided 2026-10-26)

Supersedes the order below: the owner pays the Apple Developer Program, and several agents build in
parallel (AGENTS.md "Several agents at once"). Four epics, tracked as issues labelled `epic`:

1. **Simpler core:** Jev leaves the app; nothing leaves the device.
2. **Levels 1–10:** a staircase for every kind of player, explained to them, offered after a perfect game.
3. **Onboarding with goals:** who, what to exercise, minutes a day, how to start; optional warm-up;
   "Why these games".
4. **Four new games:** Repeat the Sequence, Tangram, Tile Pairs, Sliding Blocks.

Then **v1.0 App Store:** IP review, copy audit, price and purchase, TestFlight, playtests, listing.

## Before — v0.2.0 Polish + Speed (G1b, G2)

Shipped and off this list: app icon and launch screen, home screen (#27), sound
and haptics (#26), first-run onboarding (#31), Memory Lane warmth (#43),
progress instead of points (#45).

1. **Dad playtest #1 (#6)** — ran; findings on #6, decisions in `decisions.md` 2026-10-01
   (Jev 012). Color Clash / Number Trail retired from dad's library (#47, closed).
2. **Built from the playtest, in order (one PR each):** finished games always saved (#106),
   weekly progression for dad and the family (#107), Family settings — manual difficulty and
   hide games (#108), adult Memory Lane (#109), Memory Lane with his own photos (#110).
3. **Watch the daily picks** — decided on the device by `DailyPolicy` (#101); Jev is an
   optional override. Re-tune the game weights once the family screen shows a few weeks.
4. **Done 2026-09-30:** VoiceOver and 100pt-target check on the iPad (#64),
   History/day-grouping tests and plumbing dedupe (#65, #57).

Still open, waiting for evidence: Quick Eyes untimed redesign (#46).

**Three new games (decided 2026-10-19), shipped one PR each:** Sudoku (#179), Up or Down
(#180), Finish the Saying (#181). Left: redeploy the Jev worker for nine games, a native ES
review of the refranes, and a week with dad. Spec: `superpowers/specs/2026-10-19-three-new-games-design.md`.

Exit criteria: dad picks it up unprompted, twice in one week (docs/mvp.md G1b).

## Next — polish pass 2

- Session history richness (streaks, "you improved"), portrait/landscape check.
- ES copy pass with a native speaker for warmth, not just correctness (#12).
- Device a11y checklist from the audit (`a11y-audit-2026-09.md`) on real hardware.

## Then — distribution, in two tiers

**Tier 1 — free path (now, no paid account):**

- Device installs: `swift tools/generate_project.swift` → Xcode → ⌘R (local-only is the default).
  Builds expire after 7 days; re-sign from Xcode to renew (#38 runbook).
- Family + in-person testing on whatever devices we can lay hands on.
- Jev proxy on Cloudflare's free tier → live daily mix/difficulty (deployed and verified 2026-09-30, #63).
- Privacy policy + support page hosted free (#34).
- Store listing copy and screenshots written now so publishing is a copy-paste
  later (#35).

**Tier 2 — blocked on the paid Developer Program ($99/yr, deliberately
postponed until the trigger in decisions.md 2026-09-20):**

- TestFlight beta — external testers with no expiry (the device-based beta, #10, comes first).
- CloudKit sync + real `CKShare` family sharing (#11, v0.4.0).
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
- Android, watchOS, clinician dashboard, more games (blocked by #18 gate; reminiscence #44 is the first candidate).

