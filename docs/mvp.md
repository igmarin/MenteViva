# MVP — definition of done

MVP = **exit of v0.3.0**: the app a family can install from TestFlight, play
daily, share progress on, and pay for — with Jev live and every claim defensible.

Sequencing rule (from Jev 005, P=0.99): **playtest evidence gates content.**
No game #6 before playtest findings (#18).

## Phase gates

| Gate | Criteria | Proof |
|---|---|---|
| G0 — Playable ✅ | 5 games build + playable, ES/EN | v0.2.0 code on main |
| G1 — Loved | Dad playtested; top-3 friction fixed; voluntary repeat play ×2/wk | issue #6 notes |
| G2 — Sound | A11y audit passed; tests green; TDD/BDD rule live | #5, #20 |
| G3 — Connected | Jev live via proxy (daily mix + difficulty) | #13 |
| G4 — Shippable (free path) | Disclaimer copy, ES native review, **device-based beta** ≥5 people, in-person | #12, #10, #38 |
| G5 — Sellable (free path) | Works for strangers: onboarding, settings, privacy policy + support, listing assets, device support matrix | #31–#36 |
| G6 — Publishable | **Blocked: Apple Developer Program.** Store listing live, price, StoreKit, CloudKit/`CKShare` | decisions.md 2026-09-20 |

MVP = G4 passed. Sellable = G5. **Publishing (G6) waits on the account
decision, and nothing before G5 needs it.**

## Checklist (owner → evidence)

- [ ] 5 games playtested on real iPad → #6 notes
- [ ] Playtest friction top-3 fixed → linked PRs
- [ ] Accessibility audit vs conventions §4 → #5 report
- [ ] Test backfill + TDD/BDD rule → #20, green `xcodebuild test`
- [ ] Jev proxy live, key server-side → #13, first real dashboard traffic
- [ ] Family share + preset cheers → #11, tested with 2 Apple IDs
- [ ] Medical-disclaimer copy in-app + store listing → research §5.1 wording
- [ ] ES review by native speaker 65+ → #12 sign-off
- [ ] TestFlight family beta → #10, feedback log
- [ ] Price tier set in App Store Connect → #21

### G5 — Sellable (commercial intent, 2026-09-20)

- [ ] First-run onboarding a stranger can follow with no help → #31
- [ ] In-app settings an older adult can reach alone (language, sound, text size) → #32
- [ ] Playtest with non-family seniors (≥3 people) → #33
- [ ] Privacy policy + support contact page → #34
- [ ] App Store listing: description + screenshots in EN **and** ES → #35
- [ ] Price + refund/purchase path verified in sandbox → #21
- [ ] Device support matrix documented (which iPads/iPhones we claim) → #36

## Explicitly NOT in MVP

- New user segments (Jev segment-expansion study → v0.4.0 research ticket)
- Game #6+, caregiver remote management, Android, watchOS, accounts/leaderboards
- Clinical framing of any kind (research §1 ceiling: "fun mental exercise")

## After MVP

- v0.4.0 research: Jev segment-expansion study (archived in jev-json/),
  pricing revisit with beta conversion data, game #6 decision from playtest.
