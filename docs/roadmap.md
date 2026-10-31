# Roadmap

Ordered. Finish one before starting the next. Dates are added when work
starts, not before — no fantasy deadlines.

**Owner decision (2026-09-19): polish before distribution.** TestFlight
and any paid-developer-account work wait until the app feels right in dad's
hands. Beta is a *distribution* step, not a QA step.

## Now — v1.0 App Store and the contest submission (decided 2026-10-26)

The v0.3 plan shipped (epics #190–#193): Jev left the app, levels 1–10, onboarding with goals and the
warm-up, "Why these games", and four new games (Repeat the Sequence, Tangram, Tile Pairs, Sliding
Blocks). The owner pays the Apple Developer Program, and Claude agents build the tickets in parallel
(AGENTS.md "Several agents at once"). What is left, tracked as issues labelled `epic`:

1. **Contest submission by Nov 4, 9 PM ET** (epic #422): the Meta Global AI Developer Hackathon build,
   a public TestFlight link, the demo video and the write-up.
2. **Audit fixes before v1.0** (epic #423): the p1 issues from the 2026-10-29 audit.
3. **v1.0 on the App Store** (epic #194): IP review, copy audit, privacy and support URLs, native ES
   review, a TestFlight round on a real iPhone and iPad, store listing, submit for review.

## Before — v0.2.0 Polish + Speed (G1b, G2)

Shipped and off this list: app icon and launch screen, home screen (#27), sound
and haptics (#26), first-run onboarding (#31), Memory Lane warmth (#43),
progress instead of points (#45).

1. **Dad playtest #1 (#6)** — ran; findings on #6, decisions in `decisions.md` 2026-10-01
   (Jev 012). Color Clash / Number Trail retired from dad's library (#47, closed).
2. **Built from the playtest, in order (one PR each):** finished games always saved (#106),
   weekly progression for dad and the family (#107), Family settings — manual difficulty and
   hide games (#108), adult Memory Lane (#109), Memory Lane with his own photos (#110).
3. **Watch the daily picks** — decided on the device by `DailyPolicy` (#101). Re-tune the
   game weights once the family screen shows a few weeks.
4. **Done 2026-09-30:** VoiceOver and 100pt-target check on the iPad (#64),
   History/day-grouping tests and plumbing dedupe (#65, #57).

Quick Eyes became player-paced (#46, closed).

**Three new games (decided 2026-10-19), shipped one PR each:** Sudoku (#179), Up or Down
(#180), Finish the Saying (#181). Left: a native ES review of the refranes, and a week with dad.
Spec: `superpowers/specs/2026-10-19-three-new-games-design.md`.

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
- [ ] Privacy policy page (drafted, #34; the app makes no network calls).
- [ ] Age rating + positioning decision.
- [x] Business model: v1.0 is free; support links live outside the app (decisions.md 2026-10-27, #228).
- [ ] ES/EN native review sign-off.
- [ ] App Store screenshots + description in both languages.

## Superseded

- **Jev in the app (2026-10-26, #195):** the Jev proxy on Cloudflare (#63) and redeploying the Jev
  worker for new games are gone; `DailyPolicy` decides on the device and `proxy/` is deleted.
  History: `jev-integration.md`.

## Parking lot (deliberately not planned)

- ~~New user segments~~ — resolved 2026-09-22 (Jev 009): 60+ leads, mental-health
  and wellness users are spillover of the same product; no forks, copy ceiling holds.
- Android, watchOS, clinician dashboard, more games (blocked by #18 gate; reminiscence #44 is the first candidate).

