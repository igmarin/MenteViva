# Decisions

Newest first. Format: date — decision — why — what would make us revisit.

## 2026-09-19 — Primary audience: healthy-to-mild older adults, preventive focus

Decided with the grill interview: dad is "mostly fine, we want to slow decline
and keep him sharp." We are **not** building for diagnosed cognitive impairment
in v1 — that raises the design bar (simplification, caregiver supervision) and
the regulatory bar (closer to medical claims) at the same time.

Revisit when: real users with MCI/early dementia show up, or a clinician
partner wants in.

## 2026-09-19 — Four games, one per cognitive domain

Memory (pair matching), attention/inhibition (Stroop), verbal fluency
(category recall), numeracy/processing (adaptive math). Small and polished
beats broad and shallow. Evidence basis: see research-2026-09.md §2.

Revisit when: playtest data shows one game dominates or gets abandoned.

## 2026-09-19 — Offline-first; Jev is seasoning

Games are 100% deterministic and playable without network. Jev ranks the
daily mix and nudges difficulty, once per day, with silent fallback to
deterministic rotation. Full design: jev-integration.md.

Revisit when: we have enough play data to evaluate whether Jev's rankings
beat the rotation.

## 2026-09-19 — Family visibility via CloudKit share, zero backend

Family circle sees progress and can send preset cheers. CloudKit `CKShare`
means no server to build or breach. Jev's API key still needs a tiny proxy
(jev-integration.md §proxy) — that's a config item, not a backend.

Revisit when: we outgrow per-record sharing or need cross-platform family
members (Android in the family → real backend).

## 2026-09-19 — Stack: SwiftUI + SwiftData, zero third-party dependencies

Native everything. No packages. Convention 1 in conventions.md.

Revisit when: a concrete need fails twice against stdlib/native.

## 2026-09-19 — Decision revisit with Jev (jev-revisit.md)

All five early decisions re-asked as real Jev judgments against an
evidence/constraints state; raw JSON archived in docs/jev-json/000–005.
Result: audience, monetization lean, and offline-first/once-daily architecture
confirmed (0.72–0.95). Two tensions became tickets: #18 (playtest-before-content
gate — Jev 005 at P=0.99 said polish-first; Quick Eyes had already shipped, so
the gate applies from game #6 onward) and #17 (numeracy scored 0.62, weakest
domain — Number Trail must justify itself via playtest).

Rule adopted: significant product decisions get a Jev judgment archived in
docs/jev-json/ before being logged here. Jev is evidence, not truth — the
human decides, and disagreements get recorded, not silently resolved.

## 2026-09-19 — Confirmed by owner (via discussion + Jev evidence)

- **Pricing:** one-time $12.99 + Family Sharing is *decided for beta* (#21);
  freemium-annual (Jev minority 0.28) revisited only with beta conversion data.
- **Audience:** v1 stays healthy preventive 60+ (Jev 001, P=0.95). Segment
  expansion becomes a Jev research study in v0.4.0 — not v1 scope.
- **Testing:** TDD for logic, BDD (Given/When/Then) for user flows, backfill
  for shipped code (#20). No tests for layout trivia or wire models.
- **MVP:** gates G0–G4 in docs/mvp.md adopted as the definition of done (#19).

## 2026-09-19 — Number Trail role defined (#17 closed)

Jev 002 scored numeracy 0.62 (weakest domain, P(skip)=0.39). Resolution:
Number Trail stays as **engagement variety, not an evidence pillar** —
math is familiar, low-friction, and confidence-building for the target
audience; the evidence pillars are speed (Quick Eyes) and memory (Memory
Lane). Playtest data (#6) confirms engagement or we cut it at MVP review.

## 2026-09-19 — Family sharing: mirroring + native share now, CKShare deferred (#11)

Shipped: SwiftData model made CloudKit-mirroring-safe (defaults on every
property), ModelContainer on `iCloud.com.igmarin.MenteViva` private database
with local-only fallback if iCloud is unavailable, and a native `ShareLink`
in HistoryView that sends the week's games as plain text — works over any
channel, no account, no network, no share acceptance flow.

Deferred: true `CKShare` (invite family, they see live progress in-app, send
cheers). Reasons: SwiftData in iOS 17 exposes no CKShare API (it would need
Core Data interop or a parallel CloudKit record zone), and it cannot be
honestly verified without an Apple Developer Program container and two Apple
IDs on real devices. Revisit when the developer account is set up and the
TestFlight beta (#10) is running.

## 2026-09-20 — Commercial intent: ship for strangers, not just for dad

Owner direction: the app is for dad first, but is meant to be **sold** to
families like ours. What this changes — and deliberately does not:

**Changes.** v1 must work without us in the room: self-serve first-run
onboarding, in-app settings (language, sound, larger text) reachable by an
older adult alone, privacy policy + support contact, App Store listing assets
in EN/ES, price, refunds. Playtesting must include people who are not family
(#33).

**Does not change.** The target segment. Jev 001 (P=0.95) put v1 on healthy
preventive 60+ and that is also the viable market: broad "brain training for
everyone" competes with Lumosity/Elevate on their terms; "warm, bilingual,
senior-first, no dark patterns" is a position we can actually own. Marketing
ceiling stays "fun mental exercise".

**Consequence for prior decisions.** The family-only framing in
`product-brief.md`, `AGENTS.md` tone rules and the MVP gates is superseded;
segment, pricing lean (one-time $12.99 + Family Sharing, #21) and the
Jev-as-seasoning architecture all stand.

## 2026-09-20 — No paid Apple Developer Program for now (bootstrapping)

Owner constraint: independent developer, no income from this yet. The $99/year
Developer Program is postponed deliberately until there's evidence it's worth
it. Testing happens by connecting devices to Xcode and installing directly.

**What this costs us (hard blocks, no workaround):**

| Capability | Needs paid account |
|---|---|
| TestFlight (any external tester) | yes |
| App Store listing, price, StoreKit | yes |
| CloudKit sync, `CKShare` family sharing, push | yes (iCloud entitlement) |
| Non-expiring installs | yes — free-account builds stop launching after 7 days |

**What stays free and is enough for now:**

- Device installs via a free Apple ID (`--local-only` builds; re-sign weekly)
- Real playtests — as long as the tester is physically with us and the session
  fits inside the 7-day window (see playtest.md)
- Cloudflare Workers free tier for the Jev proxy (#13)
- Privacy policy page (#34) — the repo is private, and GitHub Pages on private
  repos needs a paid plan, so: tiny public policy repo or Cloudflare Pages
- Store listing **assets** (#35) — writing copy and screenshots costs nothing;
  only publishing needs the account

**Buy trigger (write it down so it isn't a feeling):** buy when *either* is true
— (a) five or more people outside the family have asked for the app and cannot
be served by in-person installs, or (b) the app is ready to publish and the only
remaining step is distribution. Not before: no feature we've deferred is worth
$99 to a pre-revenue project.

**Consequence:** TestFlight and App Store work move to a new milestone that is
explicitly blocked on this purchase, and the beta plan becomes device-based.

## 2026-09-20 — G1a (stability) verified by owner; G1b (engagement) still open

Owner ran the app on the real iPad and reports it "performing great" for
stability. Recorded as **G1a passed**. Deliberately not recorded as G1 passed:
the original criterion ("picks it up unprompted, twice in one week") measures
*whether the games are worth keeping*, and one session cannot show that.

Also split the confusing gate name: G2 was called "Sound" and read as audio
(#26 is the audio ticket). It is now **G2 — Verified**: tests + accessibility +
clean build.

Consequence: content work (#18's gate) stays gated on playtest *findings*, not
on stability, because there are still no findings to act on.

## Open questions (not yet decided)

- Business model: research leans **one-time $12.99 + Family Sharing**
  (research-2026-09.md §4) — confirm after family beta.
- Age-rating and medical-disclaimer wording for App Store submission
  (research-2026-09.md §5 items 1–3).
- Whether "Name the Herd" needs voice input (motor-friendly) — needs playtest.
- Processing-speed game is the strongest-evidence domain we don't cover yet
  (research-2026-09.md §2) — candidate for the fifth game. Must be a generic
  speed task, NOT a UFOV® clone (licensed, §3).

