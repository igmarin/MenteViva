# MVP — definition of done

MVP = **exit of v0.3.0** (G1b + G2 + G4): a family can install the app on their own
devices, play daily, and understand it without us, with every claim defensible.
Selling (G5) and publishing (G6) follow.

Sequencing rule (from Jev 005, P=0.99): **playtest evidence gates content.**
No game #6 before playtest findings (#18).

## Phase gates

| Gate | Criteria | Proof |
|---|---|---|
| G0 — Playable ✅ | 5 games build + playable, ES/EN | on main |
| **G1a — Stable ✅** | Runs reliably on a real device; no crashes in normal play | owner-verified 2026-09-20 |
| G1b — Loved | Played unprompted twice in one week; top-3 friction fixed | #6 (engagement not yet measured) |
| **G2 — Verified** (was misnamed "Sound") | Tests green + accessibility done + build/warning clean | 41 test methods (counted 2026-09-29), #5 code ✓, device a11y checklist pending, VoiceOver gaps #64 |
| G3 — Connected | Jev live via a hardened proxy: client wired into Home, difficulty applied, real payload archived | #59, #60, #62, #63 (#13 closed = worker file only) |
| G4 — Shippable (free path) | Disclaimer copy, ES native review, **device-based beta** ≥5 people, in-person | #12, #10, #38 |
| G5 — Sellable (free path) | Works for strangers: onboarding, settings, privacy policy + support, listing assets, device support matrix | #31–#36 |
| G6 — Publishable | **Blocked: Apple Developer Program.** Store listing live, price, StoreKit, CloudKit/`CKShare` | decisions.md 2026-09-20 |

**G1 was split on 2026-09-20:** the owner reported the app "performing great" for
stability, which is what G1a measures. G1b (does he come back without being
asked?) needs a week of observation and is not yet measured — that's the part
that tells us whether the games are worth keeping.

MVP = G1b + G2 + G4 (above). Sellable = G5. **Publishing (G6) waits on the account
decision, and nothing before G5 needs it.**

## Checklist (owner → evidence)

- [ ] 5 games playtested on real iPad → #6 notes
- [ ] Playtest friction top-3 fixed → linked PRs
- [ ] Accessibility audit vs conventions §4 → #5 report
- [ ] Test backfill + TDD/BDD rule → #20, green `xcodebuild test`
- [ ] Jev proxy live, key server-side → #63, first real dashboard traffic
- [ ] Family share + preset cheers → #11 (v0.4.0, needs the paid account; not MVP), tested with 2 Apple IDs
- [ ] Medical-disclaimer copy in-app + store listing → research §5.1 wording
- [ ] ES review by native speaker 65+ → #12 sign-off (packet: es-review-packet.md)
- [ ] Device-based family beta (no TestFlight) → #10, feedback log
- [ ] Price tier set in App Store Connect → #21 (G6, needs the paid account)

### G5 — Sellable (commercial intent, 2026-09-20)

- [ ] First-run onboarding a stranger can follow with no help → #31
- [ ] In-app settings an older adult can reach alone (language, sound, text size) → #32
- [ ] Playtest with non-family seniors (≥3 people) → #33
- [ ] Privacy policy + support contact page → #34
- [ ] App Store listing: description + screenshots in EN **and** ES → #35
- [ ] Price + refund/purchase path verified in sandbox → #21
- [ ] Device support matrix documented (which iPads/iPhones we claim) → #36

## Explicitly NOT in MVP

- New user segments (decided 2026-09-22, Jev 009: 60+ leads, others are spillover)
- Game #6+, caregiver remote management, Android, watchOS, accounts/leaderboards
- Clinical framing of any kind (research §1 ceiling: "fun mental exercise")

## After MVP

- Pricing revisit with beta conversion data; game #6 decision from playtest
  (reminiscence, #44, is the first candidate).
