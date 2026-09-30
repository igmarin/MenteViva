# Decisions

Newest first. Format: date — decision — why — what would make us revisit.

## 2026-09-30 — Daily picks and difficulty are decided by rules on the device, not a hosted model

**Question:** how should the app choose today's games and difficulty without ongoing charges?
Checked with the owner (goal: avoid charges; the buyer and player never see a model).

**Decision:** `DailyPolicy` (#101) is the default: a pure function, no model, no network, no key.
Jev stays as an optional override behind the proxy; the classifier/decision tooling keeps using
TypeSafe Jev (#103, owner: keep).

**Evidence** (details: [decision-model-spike-2026-09-30.md](decision-model-spike-2026-09-30.md)):
- The questions have no ground truth, and on the one real payload a 25-line rule picked the same
  top-3 set as Jev and matched its difficulty on 4/5 games.
- Nimble 9B (free weights) needs ~9 GB RAM: the 16 GB dev Mac swapped heavily, cold start 15.5 s
  (app timeout 10 s), and its answers differed from Jev (1/5 difficulty decisions, 1/3 mix picks).
- Laya ~0.4B is fast (0.58 s) but did not react to the player's data (same picks for "struggling"
  and "thriving", difficulty confidence ≈ uniform).
- Hosting any of them for free means an always-on machine; hosted GPUs bring the charges back.

**Side effects:** the app makes no network request by default, so the App Privacy label stays
"Data Not Collected" without caveats; the Cloudflare/IP note in privacy-policy.md applies only if
the optional backend is ever enabled.

Revisit when: real play data shows a model's picks beat the rules, or a cheap always-on host exists
(then #102). The value weights are a judgment from Jev 008/010; re-tune after playtest #6 and #47.

## 2026-09-22 — Jev 010 game utility matrix: what it decided

Six games (5 shipped + reminiscence candidate) × evidence, errorless fit,
engagement, polish; raw pair `jev-json/010-*`, analysis in `jev-revisit.md` §010.
The owner adopted these outcomes (Jev is evidence, the owner decides):

- **Reminiscence (family photos) is the build candidate** — only game that wins
  all four axes; ships licensing-free (Noul 0.74). Still gated on playtest #6
  and the #18 gate. Ticket: #44.
- **Memory Lane is dad's anchor** but boring (engagement 0.50): fix variety and
  warmth, not mechanics (shipped as #43).
- **Quick Eyes:** best evidence (1.91), worst errorless fit (0.19). Redesign as
  untimed and errorless rather than polish the shrinking flash. Ticket: #46.
- **Color Clash and Number Trail** score lowest on errorless, engagement and
  (Number Trail) evidence. Rework, retire from dad's library, or cut: open
  decision, ticket #47.
- **Drop numeric scoring** for progress (Noul 0.79): see next entry.

Revisit when: dad's playtest (#6) contradicts a cell of the matrix.

## 2026-09-22 — Points removed; progress and celebration instead (#45)

Informal playtest feedback on #6 called the scoring confusing and meaningless;
Jev 010 agreed (drop numeric scoring for progress, Noul 0.79). Points no longer
appear in the UI, "My Week" or the share text. Every game ends on the shared
celebration with a warm progress line. Scores are still stored on
`GameSession` as anonymous telemetry for Jev, never displayed.

Revisit when: players ask to see a number, or Jev needs a different signal.

## 2026-09-22 — Audience locked: one segment leads, two are spillover

Owner opened the design to three segments (older adults 60+, mental-health,
general wellness). Researched with citations (`docs/research-2026-09-22.md`)
and judged by Jev 009 (`jev-json/009-*`, analysis in `jev-revisit.md`):

- **Design and copy optimize for older adults 60+ (incl. early cognitive
  decline)** — Jev Choice P=1.00, confidence 1.00. This is the dad-first
  product truth confirmed with market numbers, not a change.
- **Mental-health and wellness users are spillover, not targets.** They get
  the same warm, non-clinical product; we never design or market *to* the
  clinical need. Copy ceiling ("fun mental exercise", no claims) is confirmed
  unchanged (Noul 0.86) — expansion raises the ceiling's value.
- **The buyer is the adult child.** Marketing and purchase flow address the
  caregiver (63M in the US, AARP/NAC 2025); the player never sees a pitch
  (Noul 0.77). Store listing speaks to the family; in-app copy speaks to the
  player.
- **iOS 17 floor confirmed cheap** (research §7: iOS ≤16 = low single digits
  and shrinking; excluded hardware is 2017-era). Decision stands; #41 closed.

This closes the audience branch of the question audit. Re-litigation requires
new evidence, not a new mood.

## 2026-09-20 — Keep game identity typed and local to the domain

Game IDs are the single source of truth for Jev payloads, navigation, saved
sessions, history labels, and tile metadata. Views may choose a destination, but
they do not invent alternate string IDs. This prevents a saved session from
quietly becoming an unknown history row when two screens use different names.

Revisit when: games become independently installable modules or their metadata
comes from a server-owned catalog.

## 2026-09-20 — Cancel delayed round work with the view lifecycle

Memory matching and Quick Eyes cancel pending delays when a round restarts or a
view disappears. Delayed UI work must not mutate a later round or a screen that
is no longer visible. Audio graph changes likewise stay out of render-thread
completion callbacks.

Revisit when: a shared session coordinator owns round timing across screens.

## 2026-09-20 — Per-person libraries are the north star; per-device today

Owner walk-through of `question-audit.md`: dad (early dementia), mom (healthy
60+) and the owner (healthy 40+) are equal design floors. Each person
eventually gets their own game library (allocate, don't delete: Jev 008).
Today "who is playing" is the device (dad's iPad = dad) and Jev mix/difficulty
is per-device. Named profiles and new games come after dad's playtest (#6) says
what his library should be; per-device also makes sync non-blocking.

Revisit when: a second person shares one device, or the playtest reorders
dad's library.

## 2026-09-20 — Audience corrected: early dementia, not just "preventive"

> Corrects the 2026-09-19 "Primary audience" entry and Jev 001 (right answer to a wrong state). Locked on 2026-09-22.

The owner clarified the real player has a diagnosis of **early-stage dementia**
(mild). The earlier "healthy preventive 60+" framing was the *state* we fed the
model — not the truth — and it produced a confident-but-wrong answer (Jev 001).

Re-asked with the corrected state (Jev 007, archived): primary audience =
`mci_early_dementia` at 0.95; design should favor **errorless, low-failure,
familiarity/reminiscence** over speed drills (0.93); familiar/personalized
content meaningfully beats generic emoji (0.88).

Consequences:
- **Design target is now early dementia**, not generic prevention. The existing
  warm, no-fail, big-target design already leans this way — the shift is in
  *which* games and content matter, not in replacing the whole app.
- **Evidence is mixed, not better:** MCI is the best-supported population for
  cognitive training, but evidence for established dementia is weak and for
  early-stage dementia unclear (research §1). We design for this player as a
  kindness, not on an efficacy claim.
- **Marketing ceiling is unchanged** — and now more important, not less: "fun
  mental exercise", never treatment/prevention/diagnosis. Targeting an
  early-dementia audience raises App Store 1.4.1 scrutiny if we *market* to it;
  we don't. The design can be dementia-friendly without the copy saying so.
- **Content re-evaluation is queued, not rushed**: re-score the five games for
  this population (Jev 008) and reconsider personalized/familiar content, but
  hold *rebuilds* until dad's own playtest (#6) — the app is already warm and
  no-fail, and the biggest unknown is still what he actually engages with.

This is also the moment the **question audit** (`docs/question-audit.md`) was
created: every decision must state the question, confirm it's the real one, and
say how it's answered — because a well-answered wrong question is the most
expensive bug we have.

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

- Device installs via a free Apple ID (local-only builds are now the default; re-sign weekly)
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
the device-based beta (#10) is running (TestFlight follows the paid account).

## 2026-09-19 — Number Trail role defined (#17 closed)

> **Under review:** Jev 010 scores Number Trail evidence 0.02 and engagement 0.06. The "engagement variety" role is being re-decided in #47.

Jev 002 scored numeracy 0.62 (weakest domain, P(skip)=0.39). Resolution:
Number Trail stays as **engagement variety, not an evidence pillar** —
math is familiar, low-friction, and confidence-building for the target
audience; the evidence pillars are speed (Quick Eyes) and memory (Memory
Lane). Playtest data (#6) confirms engagement or we cut it at MVP review.

## 2026-09-19 — Confirmed by owner (via discussion + Jev evidence)

- **Pricing:** one-time $12.99 + Family Sharing is *decided for beta* (#21);
  freemium-annual (Jev minority 0.28) revisited only with beta conversion data.
- **Audience:** ~~v1 stays healthy preventive 60+~~ (Jev 001, P=0.95; superseded 2026-09-20/22). Segment
  expansion becomes a Jev research study in v0.4.0 — not v1 scope.
- **Testing:** TDD for logic, BDD (Given/When/Then) for user flows, backfill
  for shipped code (#20). No tests for layout trivia or wire models.
- **MVP:** gates G0–G4 in docs/mvp.md adopted as the definition of done (#19).

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

## 2026-09-19 — Stack: SwiftUI + SwiftData, zero third-party dependencies

Native everything. No packages. Convention 1 in conventions.md.

Revisit when: a concrete need fails twice against stdlib/native.

## 2026-09-19 — Family visibility via CloudKit share, zero backend

> **Superseded by** 2026-09-19 "Family sharing: mirroring + native share now" and 2026-09-20 "No paid Apple Developer Program": CloudKit is off by default (local-only build); true `CKShare` is deferred to v0.4.0 (#11). Family progress today is the native text share.

Family circle sees progress and can send preset cheers. CloudKit `CKShare`
means no server to build or breach. Jev's API key still needs a tiny proxy
(jev-integration.md §proxy) — that's a config item, not a backend.

Revisit when: we outgrow per-record sharing or need cross-platform family
members (Android in the family → real backend).

## 2026-09-19 — Offline-first; Jev is seasoning

> **Updated 2026-09-30:** the daily mix and difficulty are now decided by the on-device `DailyPolicy` (#101), not Jev with a rotation fallback; Jev is an optional override. See the 2026-09-30 entry.

Games are 100% deterministic and playable without network. Jev ranks the
daily mix and nudges difficulty, once per day, with silent fallback to
deterministic rotation. Full design: jev-integration.md.

Revisit when: we have enough play data to evaluate whether Jev's rankings
beat the rotation.

## 2026-09-19 — Four games, one per cognitive domain

> **Now five:** Quick Eyes (processing speed) shipped in #7 on Jev 002's evidence. Jev 010 reopens the lineup (#47).

Memory (pair matching), attention/inhibition (Stroop), verbal fluency
(category recall), numeracy/processing (adaptive math). Small and polished
beats broad and shallow. Evidence basis: see research-2026-09.md §2.

Revisit when: playtest data shows one game dominates or gets abandoned.

## 2026-09-19 — Primary audience: healthy-to-mild older adults, preventive focus

> **Superseded by** 2026-09-20 "Audience corrected: early dementia" and 2026-09-22 "Audience locked". Current audience: older adults 60+ including early cognitive decline; the adult child is the buyer. Kept for the record.

Decided with the grill interview: dad is "mostly fine, we want to keep him
engaged." We are **not** building for diagnosed cognitive impairment
in v1 — that raises the design bar (simplification, caregiver supervision) and
the regulatory bar (closer to medical claims) at the same time.

Revisit when: real users with MCI/early dementia show up, or a clinician
partner wants in.

## Open questions (not yet decided)

- Business model: one-time $12.99 + Family Sharing is decided for beta; confirm
  after the device-based beta (research-2026-09.md §4).
- Age-rating and medical-disclaimer wording for App Store submission
  (research-2026-09.md §5 items 1–3).
- Whether "Name the Herd" needs voice input (motor-friendly) — needs playtest.
- Color Clash and Number Trail: rework, retire from dad's library, or cut (#47).
