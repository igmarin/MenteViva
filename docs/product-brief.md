# Product Brief — Mente Viva

Current truth as of 2026-09-29. History and reasons: `decisions.md`.

## What it is

Warm, bilingual (ES/EN) mental-exercise games for older adults. Fourteen short
games, big targets, no fail shame. Sold to families, played by a parent.

## Who it's for

**Player: older adults 60+, including people experiencing early cognitive changes.** Dad is the
design floor: errorless, familiar, calm. Mom and the owner are equal floors
(healthy 60+, healthy 40+); per-person game libraries are the north star,
per-device today (decisions 2026-09-20, 2026-09-22). Mental-health and general
wellness users are spillover of the same product, never a target.

**Buyer: the adult child.** They find the app, install it and pay. Store
listing and purchase flow speak to them ("for someone you love"); in-app copy
speaks to the player and never pitches (Jev 009).

**Not in v1:** clinical use, care facilities, kids, younger "brain training".

## Commercial intent

The goal is to reach families like ours. A stranger must be able to
install it with nobody explaining it: self-serve onboarding, in-app settings
(language, sound, bigger text), privacy policy, support contact, EN + ES store
assets. v1.0 is free, with support links only outside the app (decisions
2026-10-27, #228; the earlier one-time $12.99 lean was #21).
Publishing waits on the paid Developer Program (decisions 2026-09-20).

**Marketing ceiling: "Fun mental exercise".** Games exercise memory and attention;
never promise restored memory, clinical outcomes, treatment or screening
(research §1; `statistics-rationale.md` §4).

## Design pillars

1. **Easy above all** — one-tap start, large targets (≥60pt floor, 100pt aim),
   no fail shame. Words: "try again", never "wrong". Quick Eyes is player-paced
   (levels 1–5) and flashes its picture only from level 6 (#46).
2. **Bilingual from birth** — every string in `Localizable.xcstrings`, EN + ES.
3. **Games, grouped by what they exercise** (levels 1–10 in all but Remember Together):

   | Game | Domain | Mechanic |
   |---|---|---|
   | 🧩 Memory Lane | Episodic memory | Pair matching, illustrated cards or the family's photos |
   | 🎨 Color Clash | Attention / inhibition | Stroop: tap the ink colour |
   | 🐾 Name the Herd | Verbal fluency | Category recall from big tiles |
   | 🔢 Number Trail | Processing + numeracy | Easy sums in a row; the numbers grow with the level |
   | 👀 Quick Eyes | Processing speed | Look at a picture, then find it; player-paced, flash from level 6 |
   | 📷 Remember Together | Reminiscence | The family's photos, one at a time; nothing to get wrong |
   | ✏️ Sudoku | Planning | 4×4 up to 9×9, one solution each |
   | 🃏 Up or Down | Planning | Golf solitaire: play a card one higher or lower |
   | 💬 Finish the Saying | Verbal fluency | Pick the ending of a familiar saying |
   | 🔁 Repeat the Sequence | Working memory | Watch the lit tiles, repeat them in order |
   | 🔷 Tangram | Planning | Fill a silhouette with seven tiles |
   | 🀄 Tile Pairs | Attention | Find two free tiles that match |
   | 🧱 Sliding Blocks | Planning | Slide the blocks to free the big one |
   | 🖼️ Names and Faces | Names and faces | Match each family photo to its caption (needs four captioned photos) |

   Color Clash and Number Trail are hidden on dad's iPad (#47).
4. **Progress, not points** — every game ends on a warm celebration with a
   progress line; no scores are shown (#45).
5. **Visually warm** — big cards, soft colours. Never clinical: no brains,
   charts or medical iconography.
6. **Works offline, always** — no account, no forced login. Sync is a bonus.

## How today's plan is chosen (DailyPolicy, on the device)

- Games are deterministic and offline. Code judges right/wrong, never a model.
- `DailyPolicy` scores every game and deals the top three; each game's level follows a
  staircase, once a day and never mid-game. The family can hide a game or pin a level in
  Set up. Details: `how-it-works.md`.
- Nothing leaves the device: no model, no network, no key, no server (decisions.md
  2026-10-26). Jev is a dev-machine tool for validating product ideas; its integration is
  history: `jev-integration.md`.

## Data and sharing

- Default build is **local-only**: sessions live on the device, no CloudKit
  entitlement, works with a free Apple ID.
- CloudKit mirroring and real `CKShare` family sharing are **deferred**: they
  need the paid program (#11, v0.4.0). Family sharing today is the native text
  share of the week's games.

## Non-goals for v1

No accounts, leaderboards, clinical scores or medical claims. No caregiver
remote management or multi-profile households yet. No third language (#40),
Android or watch.
