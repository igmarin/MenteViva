# MVP — definition of done

MVP = **exit of v0.3.0**: the app a family can install from TestFlight, play
daily, share progress on, and pay for — with Jev live and every claim defensible.

Sequencing rule (from Jev 005, P=0.99): **playtest evidence gates content.**
No game #6 before playtest findings (#18).

## Phase gates

| Gate | Criteria | Proof |
|---|---|---|
| G0 — Playable ✅ | 5 games build + playable, ES/EN | v0.2.0 code on main |
| **G1a — Stable ✅** | Runs reliably on a real device; no crashes in normal play | owner-verified 2026-09-20 |
| G1b — Loved | Played unprompted twice in one week; top-3 friction fixed | #6 (engagement not yet measured) |
| **G2 — Verified** (was misnamed "Sound") | Tests green + accessibility done + build/warning clean | 33 tests ✓, #5 code ✓, device a11y checklist pending |
| G3 — Connected | Jev live via proxy (daily mix + difficulty) | #13 |
| G4 — Shippable (free path) | Disclaimer copy, ES native review, **device-based beta** ≥5 people, in-person | #12, #10, #38 |
| G5 — Sellable (free path) | Works for strangers: onboarding, settings, privacy policy + support, listing assets, device support matrix | #31–#36 |
| G6 — Publishable | **Blocked: Apple Developer Program.** Store listing live, price, StoreKit, CloudKit/`CKShare` | decisions.md 2026-09-20 |

**G1 was split on 2026-09-20:** the owner reported the app "performing great" for
stability, which is what G1a measures. G1b (does he come back without being
asked?) needs a week of observation and is not yet measured — that's the part
that tells us whether the games are worth keeping.

MVP = G1b + G2 + G4. Sellable = G5. **Publishing (G6) waits on the account
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
