# Product Brief — Mente Viva

Current truth as of 2026-09-29. History and reasons: `decisions.md`.

## What it is

Warm, bilingual (ES/EN) mental-exercise games for older adults. Five short
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

The goal is to sell this to families like ours. A stranger must be able to
install it with nobody explaining it: self-serve onboarding, in-app settings
(language, sound, bigger text), privacy policy, support contact, EN + ES store
assets, one-time $12.99 with Family Sharing (decided for beta, #21).
Publishing waits on the paid Developer Program (decisions 2026-09-20).

**Marketing ceiling: "Fun mental exercise".** Games exercise memory and attention;
never promise restored memory, clinical outcomes, treatment or screening
(research §1; `statistics-rationale.md` §4).

## Design pillars

1. **Easy above all** — one-tap start, large targets (≥60pt floor, 100pt aim),
   no fail shame. Words: "try again", never "wrong". Quick Eyes has a short
   display time by design; the untimed redesign is #46.
2. **Bilingual from birth** — every string in `Localizable.xcstrings`, EN + ES.
3. **Games, one per cognitive domain:**

   | Game | Domain | Mechanic |
   |---|---|---|
   | 🧩 Memory Lane | Episodic memory | Emoji pair matching |
   | 🎨 Color Clash | Attention / inhibition | Stroop: tap the ink colour |
   | 🐾 Name the Herd | Verbal fluency | Category recall from big tiles |
   | 🔢 Number Trail | Processing + numeracy | Simple adaptive math streaks |
   | 👀 Quick Eyes | Processing speed | Shrinking display-time discrimination |

   Color Clash and Number Trail are under review (#47). A reminiscence game
   (family photos) is the next build candidate, gated on the playtest (#44).
4. **Progress, not points** — every game ends on a warm celebration with a
   progress line; no scores are shown (#45).
5. **Visually warm** — big cards, soft colours. Never clinical: no brains,
   charts or medical iconography.
6. **Works offline, always** — no account, no forced login. Sync is a bonus.

## Where Jev fits (decided: seasoning, not the meal)

- Games are deterministic and offline. Code judges right/wrong, never the model.
- Jev (online only) ranks today's mix and nudges per-game difficulty: one
  request a day, with a silent deterministic fallback. Design and status:
  `jev-integration.md`. **Runtime wiring is in progress**, not shipped.
- The API key never ships in the binary; `proxy/worker.js` holds it.

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
