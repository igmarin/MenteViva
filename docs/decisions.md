# Decisions

Newest first. Format: date — decision — why — what would make us revisit.

## 2026-10-27 — Open source under Apache-2.0; the name and icon stay ours

**Question:** the repo moved to `igmarin/menteviva` to be open source. Under which licence, given
the app will also be sold on the App Store?

**Decision (owner, from Apache-2.0 / MIT / GPL-3.0 / source-available):** **Apache-2.0** — `LICENSE`
(the canonical text) and `NOTICE` at the root.

- Permissive, so the owner and anyone else may sell builds; the owner holds the copyright, so the
  App Store release is unaffected.
- Explicit patent grant, and contributions arrive under the same terms (§5).
- GPL-3.0 set aside: its terms are widely read as incompatible with App Store distribution, which
  would tangle outside contributions. Source-available set aside: not open source.
- §6 grants no trademark rights: the name "MenteViva" and the icon are not licensed (README).

**Before the repo goes public:** the docs and history describe the reference player's diagnosis;
the owner decides whether to anonymize first (not part of this decision).

Revisit when: someone ships a copy that confuses players (register the name), or the lawyer review
(#226) advises otherwise.

## 2026-10-26 — Direction to v1.0: an App Store game worth buying, built by several agents

**Question:** what does MenteViva need to be a paid App Store app, and how do we build it fast
without losing quality? Asked while entering the Meta Global AI Developer Hackathon (Indie track,
accepted with this project; its Meta Model API credit pays for Muse Code as one more coding agent).
The hackathon is fuel, not the goal. Owner decisions, made in one planning session; Jev 020
(`jev-json/020-v03-direction.request.json`) is written and asked from the dev machine with
`tools/ask_jev.sh`. Jev is evidence; if it disagrees, we revisit here.

**Decision:**

1. **Jev leaves the app.** On-device `DailyPolicy` already returned the same top 3 as Jev on the
   real payload, so Jev cost a proxy, a secret and 265 lines for no change. `JevService`, its tests,
   the plist keys, the xcconfig and `proxy/` are removed; git history keeps them. Jev stays a
   **dev-machine tool for validating product ideas** (`TYPESAFE_API_KEY`, `tools/ask_jev.sh`).
   Nothing leaves the device any more.
2. **Audience: anyone who wants an active mind**, with the reference player still the owner's
   father. The design stays dementia-friendly (it helps everyone). Copy: "Ejercicio mental
   divertido / Fun mental exercise". **A game *exercises* memory or attention; copy never says it
   *improves* them.** No medical claims, unchanged.
3. **Levels 1–10 per game**, replacing easy/medium/hard (migrated easy→2, medium→4, hard→6). A
   staircase between sessions, never mid-game: a perfect session +1, two in a row +2, accuracy
   under 65% −1 (never more). A perfect session ends with "Shall we try the next level?"
   (Yes / Keep it as it is). Every change is explained in one warm line. The family can pin a level.
   One rule for both kinds of player: it follows how someone plays, never a health question.
4. **Onboarding asks at most four things**, all skippable: who it is for, what to exercise, minutes a
   day (2/3/5 games), how to start (calm/normal/challenge = level 2/4/6). **No age.** An optional
   warm-up sets starting levels quietly and **never shows a score, result or "brain age"**
   (research §1: that is diagnosis territory).
5. **A "Why these games" section**: balanced and sourced (including the 2014 Stanford consensus),
   no promise per game, "educational information, not medical advice".
6. **Four new games, public-domain mechanics, own names and art:** Repeat the Sequence (Corsi,
   working memory: the domain no game covers), Tangram, Tile Pairs (mahjong-solitaire style),
   Sliding Blocks (Huarong Dao style). Avoided names: Simon, Shanghai, Klotski, KenKen, Picross,
   Wordle, 24 Game. Every game passes `docs/ip-clearance.md`; a one-hour IP lawyer review happens
   before the paid release.
7. **Apple Developer Program gets paid (owner, 2026-10-27).** Revisits 2026-09-20: TestFlight,
   CloudKit and the App Store are no longer blocked on money.
8. **Many agents, one bar.** Muse Code, Cline and Claude take tickets in parallel; Claude reviews
   every PR; the owner merges. Tickets are self-contained briefs; quality rules live in AGENTS.md
   "Definition of done". Agents never copy code from other projects.

Revisit when: Jev 020 disagrees on levels, onboarding or the warm-up; a playtest shows the staircase
moving too fast for dad; or the lawyer flags a game or name.

## 2026-10-20 — CI on PRs to main, split by cost: Linux always, macOS only for Swift

**Found:** `swift.yml` was manual-only after the minutes ran out (early October); until billing was
fixed on 2026-10-20 every job, Linux included, was refused ("spending limit needs to be increased"). The workflow also had no timeout (a hung simulator could bill 6 h at 10×), no
cancel of superseded runs, built twice (`build` then `test`), and used `macos-latest`'s Xcode (26.6)
while the hook runs 27.1, so `swift-format --strict` could disagree. The hook never ran the proxy tests.

**Decision (owner, from three options):** hosted runners, path-filtered.

- `checks.yml` (Linux, every PR to main): signposts, project file, `node --test proxy/*.test.js`.
- `swift.yml` (macOS 26, newest Xcode on the image; 26.6 on 2026-10-20, lint still agreed with
  local 27.1): generator drift, lint, `xcodebuild test` — only
  when a non-draft PR touches the app, tests, project, `tools/` or `.swift-format`. 20-minute timeout,
  concurrency cancel. No caching: zero dependencies, nothing worth restoring.
- No run on push to `main`: the PR already ran it. `workflow_dispatch` stays for a manual run.
- The pre-push hook stays the local twin and now runs the proxy tests too; the project-file check moved
  to `tools/check_project_files.sh` so both share it.

The first green run (#177) took 1 min 44 s on macOS (2 billed min × 10 = 20); the Team plan's 3,000 included minutes cover ~150
of them a month. Set aside: macOS only on label / ready-for-review (cheaper, but later pushes go
untested), and a self-hosted runner on the owner's Mac (no minutes, but the Mac must be on).

Revisit when: billed minutes pass ~2,000 in a month (move macOS to label-only or self-hosted), or lint
disagrees between the runner's Xcode and the local one.

## 2026-10-23 — Privacy and support pages: static files in `site/`, hosted on a free public host (#34)

**Question:** how do we host the privacy policy and support page for free? GitHub Pages on this private
repo needs a paid plan (decisions 2026-09-20).

**Decision:** the pages live in the repo as plain static HTML, English and Spanish (`site/en`, `site/es`),
no JavaScript, large text, light and dark. `tools/build_site.sh <email>` fills in the support address
and writes `site-out/`, which any free static host can serve. The address is never committed, and the
script refuses to build without one, so a placeholder can't be published. The host itself (a small public
repo's GitHub Pages, or Cloudflare Pages) and the address are the owner's choice.

**Not done by this change:** the in-app link in Settings and the App Store Connect URLs (both need the
final URL, #34), and a native-speaker pass over the Spanish pages (the #12 process).

Revisit when: the paid Developer Program arrives and the repo can go public, or the policy text changes.

## 2026-10-19 — Three new games: Sudoku, Up or Down, Finish the Saying

**Question:** dad likes the app but gets bored: "few games, very repetitive". He sees 4 games
(Color Clash and Number Trail hidden) and Home deals 3 of them every day. What do we add?
Decided by the owner from the hobbies dad had (newspaper puzzles, cards, sayings) and the wish for
more variety and a higher ceiling. Jev 016 was written (`jev-json/016-new-games.request.json`) but
not asked: the session had no Jev key. Owner decision; ask it when a key is at hand.

**Decision:** one game per hobby, one PR each, in this order:

- **Sudoku (#179):** 4×4 easy/medium, 6×6 hard, generated with exactly one solution.
- **Up or Down (#180):** golf solitaire with big drawn cards; easy deals always clear.
- **Finish the Saying (#181):** 60 sayings per language, written separately in EN and ES, no repeats.

Each deals fresh content every session; misses stay warm; no timer, no visible score. Word search
(letters under 60pt on iPhone), dominoes (twice the build) and decade trivia (facts vary by country)
were set aside. This reopens 2026-10-01 "no new games yet", whose revisit trigger was the owner's
own game ideas. Spec: `superpowers/specs/2026-10-19-three-new-games-design.md`.

Revisit when: one of the three is unplayed for two weeks on dad's iPad.

## 2026-10-19 — "No key in the binary" means the upstream key; the app secret is a gate token

**Found by:** a graph trace of the key path (graphify, 2026-10-19). The Typesafe key lives only in the
Worker env (`proxy/worker.js`). `JEV_PROXY_SECRET` is copied into `Info.plist` and sent as
`X-MenteViva-Key` when `Local.xcconfig` configures the proxy, so it can be read from such a build.

**Decision:** AGENTS.md now says the upstream key never enters the repo or the binary; the app shared
secret is a proxy gate token that may sit in a configured build, never in the repo. No code change.

Revisit when: a build with the proxy configured is shared beyond the owner's devices, or the Worker sees
abuse. App Attest is the noted upgrade.

## 2026-10-13 — Privacy as three lines; the icon becomes a framed card

**Question:** Settings' privacy paragraph was hard to read and mentioned daily suggestions, which are
off in his build; the app icon (blank cream cards) no longer matched the Card Table's framed cards.
Decided by the owner from `design/2026-10-13-privacy-and-icon.html`. No Jev judgment: a visual call
inside the already-judged Card Table direction (Jev 015).

**Decision:**

- Privacy stays at the bottom of Settings, as three short lines with icons ("Your games stay on this
  iPad.", "No account, no ads, no tracking.", "Your photos and their names never leave it.") and the
  backup note in smaller type. The anonymous-totals line shows only when a Jev proxy is configured.
  The promise card at the top of Settings was considered and not chosen.
- Icon option A: one game card as Home deals it (white paper, Memory Lane's ink frame and emblem) on
  the table gradient. The hand (B) and recoloured old cards (C) were set aside.

**Still open:** the small icon mark beside "Mente Viva" at the top of Home; the welcome-screen line
"No account. Everything stays on this iPad."

Revisit when: the playtest shows he never scrolls to the privacy lines, or the icon is hard to spot on his home screen.

## 2026-10-13 — My progress: what "this week" and "earlier weeks" mean (#141)

Details the 2026-10-03 "Progress measures" row; the owner confirms on the PR.

- **This week** is the last 7 calendar days, today included, so "days played" reads "3 of the last 7".
- **Earlier weeks** are the 4 weeks before that, same game only. A trend compares this week's mean
  accuracy per play and latest level with those weeks; under 3 plays this week, or nothing earlier,
  it says why there is no trend instead.
- **An easier week** is named in words ("A few fewer right answers…", "An easier level…") with the
  same right-pointing arrow as "about the same". Never a down arrow, never colour alone.
- **Set up** stays open, no lock (2026-10-01). Memory Lane photos and their names move there too: they
  are a choice, not a measure.
- **Not tracked yet** (seconds per round, milestones, personal bests, a Challenge level) is not shown on screen.

Revisit when: the father finds a line on My progress confusing, or 4 weeks proves too short or long a memory.

## 2026-10-12 — Visual direction: the Card Table

**Question:** the app is easy to use but looks generic (pale system blue on white everywhere,
game icons in five emoji styles, the same reward every time). What visual identity do we build?
Decided by the owner after a design review that used Apple Design Award winners 2024–2026 as
reference ([2024](https://www.apple.com/newsroom/2024/06/apple-announces-winners-of-the-2024-apple-design-awards/),
[2025](https://www.apple.com/newsroom/2025/06/apple-unveils-winners-and-finalists-of-the-2025-apple-design-awards/),
[2026](https://www.apple.com/newsroom/2026/06/apple-reveals-winners-of-the-2026-apple-design-awards/)).
Jev 015 was asked after the build to put it on record (`jev-json/015-*`, analysis in
`jev-revisit.md` §015): card_table 1.00, framed 1.00, fit 1.84 of 2. The state described the
built direction, so the result confirms it rather than testing it blind.

**Decision:** Direction A, "Card Table". Garden and Calm Glass were considered and set aside.

- Each game is a framed card in its own colour, with an emblem drawn in SwiftUI shapes (no image assets).
- Home deals today's three with one "Play today's three" button; they run back to back, with "Back to the table" one tap away.
- Each finished game adds its card to the week; My Week shows the week as a board of cards. Still no scores (#45).
- Palette comes from the app icon; fonts are system only (New York for greetings and titles, SF Pro Rounded for the rest). Zero dependencies.

**Why:** it grows out of the icon and Memory Lane's cards, cards are a familiar adult object
(#109 "he's not a child"), Home stops asking dad to choose, and progress becomes visible without numbers.

**Still open:** greeting by name (Jev 015 leans yes, 0.73; owner to decide). Resolved since:
card face is Framed (Jev 015 1.00); the Card Table Spanish strings were signed off on #12 (#160, #161).

Review: `design/2026-10-12-review.html`. Spec and build order: `design/2026-10-12-card-table.html`.

Revisit when: dad reaches for a different Home mock when shown the three on a phone, or the theme step ships and the app reads worse.

## 2026-10-03 — Captions, per-device My progress, week ring; reminiscence game next

**Question:** after the photo playtest, what do we build next and how do we show progress?
Grilled with the owner; evidence: Jev 013 (`jev-json/013-*`, analysis in `jev-revisit.md` §013).

| Topic | Decision | Jev 013 |
|---|---|---|
| Next game | Reminiscence ("Who is this?"): photo, tap "Show me" to reveal and hear the caption, no wrong answer; bundled everyday objects when there are no photos | 0.95 |
| Captions | One optional short caption per photo (name, nickname, place, event), on this device only, never in a share text or sent to Jev. Built inside the reminiscence PR | foundation first 0.46 |
| Speech | The name is spoken on its own only if "Read names aloud" (Settings) is on, off by default; the speaker button always works | owner |
| Privacy | A line where the caption is typed, plus its own section in the policy | owner |
| Progress measures | Rates, never sums: mean accuracy per play, level reached, days played per week; trend only after 3+ plays, only against the player's own weeks. Reminiscence records no accuracy | owner |
| Progress screen | "For family" becomes a per-device "My progress"; hide games and pin difficulty move to "Set up" | 1.00 |
| Consistency | Week ring of 7 dots. No streaks, no leaderboards, no pressure timers, no reminders | 0.84 |
| My Week | One row per day with a count per game, no scores | 0.71 |
| Game mix | Share of plays per game, labeled "played this week" | 0.54 |
| Number Trail | − then × and exact ÷ as difficulty steps, lowest priority; tracked: how to measure when to step up (auto or manual) is decided later | 0.77 / fit 0.79 |
| Challenge level | Tracked, not decided | 0.69 |
| Quick Eyes | A "find the face for this name" variant is noted on #46, deferred | fit 1.48, conf .23 |

## 2026-10-01 — Playtest #6 outcome: progress first, Family settings, adult Memory Lane, no new games yet

**Question:** after the structured playtest, what do we build next, and how is progress tracked?
Grilled with the owner; evidence: Jev 012 (`jev-json/012-*`, analysis in `jev-revisit.md` §012).

| Topic | Decision | Jev 012 |
|---|---|---|
| Order | Save fix → progress → Family settings → adult Memory Lane → photo Memory Lane, one PR each | progress first 0.80 |
| Progression signal | Difficulty level reached; accuracy secondary | level 0.79 |
| Player view | Warm words + icon in My Week; no numbers, never a down arrow | owner |
| Caregiver view | Open "For family" screen in Settings (no lock) with real numbers and a share button | show declines 0.70 |
| Manual difficulty | Per game: Auto (default) / Easy / Medium / Hard; a pin freezes that game, Auto resumes from the pinned level | owner |
| #47 | Hide/show per game on the device, code kept; Color Clash and Number Trail hidden on dad's iPad | owner |
| Memory Lane | 4/6/8 pairs on a board that fits the screen, adult restyle, emoji as fallback | emoji 0.68 (conf .52) |
| Photos | His own photos become Memory Lane cards (system photo picker, stays on device) | 0.80 |
| Auto pace | Unchanged: one step per 7 days | owner |
| New games | Not yet; ranking kept: reminiscence 1.87 › sayings 1.83 › sequencing 1.80 › spot-the-difference 1.37 | add now 0.26 |
| Quick Eyes | Ships as is; #46 stays open | 0.40 |

He plays on both an iPad and an iPhone. History and Family settings stay **per device** (free
account, no iCloud sync; owner, 2026-10-01): the For family screen says so, and the caregiver
sets difficulty / hidden games on each. Revisit with the paid account (#37, #11). Every layout
change is checked on an iPhone and an iPad simulator.

The #18 gate's data has landed; new games stay deferred by this decision, not by the gate.
Points stay hidden from the player (#45); the caregiver screen is where numbers live.

Revisit when: the caregiver numbers show a game abandoned for two weeks, or the owner's own game ideas are scored (Jev 013).

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
