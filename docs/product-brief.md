# Product Brief — Mente Viva

## What it is

Warm, bilingual (ES/EN) cognitive mini-games for older adults. Four-to-five
short games, one per cognitive domain, big targets, no fail shame.

## Who it's for

**Primary: older adults, 60+, preventive / mild cognitive stage.** Motivated
people who want to stay sharp, or whose family wants to help them do it.
Deliberately *not* diagnosed cognitive impairment: that population has the best
evidence for cognitive training but raises the design and regulatory bar at the
same time (research §1).

**Secondary: the family buyer.** Adult children who find the app, decide it's
good, and set it up for a parent. They hold the wallet and the patience for
onboarding — the *player* holds neither.

**Not in v1** (see docs/mvp.md): general-public/younger "brain training"
audience, clinical populations, care facilities, kids.

## The two modes we must design for

This started as an app for one dad. It is now an app **strangers will install
without us in the room** — the difference drives real requirements:

| Family mode (v0: how it began) | Stranger mode (v1: what we ship) |
|---|---|
| We explain it to dad in person | First run must explain itself; no tutorial by phone |
| We fix things when they break | Settings dad can reach himself; nothing needs our intervention |
| We know his language and pace | Language auto-detected, both shipped equally, neither an afterthought |
| Scores stay in the family | Privacy policy, no tracking, no ads — trust is the product |
| Free, built out of love | A price, an App Store listing, refunds, support contact |

## Design pillars

1. **Easy above all** — one-tap start, huge touch targets (≥100pt), no
   pressure timers, no fail shame. Words: "try again", never "wrong".
2. **Bilingual from birth** — every string in `Localizable.xcstrings`, EN + ES,
   shipped equally. Spanish is a market advantage, not a translation.
3. **Evidence-informed games** — one game per cognitive domain:
   | Game | Domain | Mechanic |
   |---|---|---|
   | 🧩 Memory Lane | Episodic memory | Emoji pair matching |
   | 🎨 Color Clash | Attention / inhibition | Stroop: tap the ink colour |
   | 🐾 Name the Herd | Verbal fluency | Category recall from big tiles |
   | 🔢 Number Trail | Processing + numeracy | Simple adaptive math streaks |
   | 👀 Quick Eyes | Processing speed | Shrinking display-time discrimination |
4. **Visually warm** — big cards, soft colours, celebration on completion.
   Never clinical: no brains, no charts, no medical iconography.
5. **Works offline, always** — solo devices, bad facility wifi, no forced
   login, no account. Sync is a bonus, never a requirement.

## Where Jev fits (decided: seasoning, not the meal)

- Games are deterministic and fully offline. Code judges right/wrong, never the
  model.
- Jev (online only): (a) ranks today's game mix from recent play history,
  (b) nudges per-game difficulty. Once per day, one request, archived in
  `docs/jev-json/`.
- The API key never ships in the binary: `proxy/worker.js` holds it server-side.
- Fallback: deterministic rotation when Jev is unreachable. **The app must
  never degrade without network.**

## Commercial intent (why the requirements got stricter)

The goal is to sell this — to families like ours, not to a mass market. That
means v1 needs the boring parts: self-serve onboarding, a privacy policy, a
support contact, App Store listing assets in both languages, honest marketing
copy, and a price.

**Marketing ceiling: "fun mental exercise".** Never memory-loss reversal,
dementia prevention, MCI treatment, or clinical screening — FTC precedent
(Lumosity, $2M) and FDA general-wellness rules both bite here (research §1).

## Non-goals for v1

- No accounts, no leaderboards, no clinical scores, no medical claims.
- No caregiver remote management, no multi-profile households.
- No third language, no Android, no watch.

## Sharing

Phase 1 (shipped): on-device CloudKit mirroring + a native text share of the
week's games. Phase 2 (post-launch): real `CKShare` invite/accept with preset
cheers — blocked on SwiftData's missing CKShare API and on paid-account
provisioning (issue #11).

