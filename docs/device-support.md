# Device support

## What we claim

**iPhone and iPad running iOS 17.0 or later.** `TARGETED_DEVICE_FAMILY = "1,2"`,
`IPHONEOS_DEPLOYMENT_TARGET = 17.0`.

The floor is not arbitrary: **SwiftData is iOS 17+**, and it stores every
session. Lowering the floor means replacing persistence (Core Data or files) —
that is the whole cost of supporting older devices, and it is why we don't.

## Hardware the claim covers

The iOS 17 floor translates to 2018-or-newer hardware
([Apple's iOS 17 page, archived](https://web.archive.org/web/20240618002010/https://www.apple.com/ios/ios-17/),
[MacRumors roundup](https://www.macrumors.com/roundup/ios-17/)):

| Line | Oldest model that runs iOS 17 |
|---|---|
| iPhone | XR / XS (2018, A12) |
| iPad | 6th generation (2018) |
| iPad Air | 3rd generation (2019) |
| iPad mini | 5th generation (2019) |
| iPad Pro | 10.5″ / 12.9″ 2nd gen (2017) |

Anything older (iPhone X, iPad 5th gen, iPad Pro 1st gen) cannot install the
app — the App Store enforces this for us; no code check needed.

## What we've verified

Refreshed 2026-10-28 on `main` (445 tests). Only the iOS 27.0 simulator
runtime is installed on the dev Mac (`xcrun simctl list runtimes`), so
iOS 17 is verified on physical hardware, never on a simulator.

| Device | OS | Result |
|---|---|---|
| iPad Viejita — iPad Pro 10.5" (2017, the oldest iPad Pro that runs iOS 17) | iOS 17.7.11 (21H461, `xcrun devicectl` 2026-10-28) | Physical. Playtests run on it (`playtest-session-2/3/4.md`); it caught an iOS-17-only freeze in My progress that the iOS 27 simulators missed (#172, fixed). This is our floor device: if it runs here, the claim holds |
| iPhone 17 (simulator) | iOS 27.0 | Build + full test suite green, 2026-10-28: 445 tests, 0 failures |
| iPad Pro 13" (simulator) | iOS 27.0 | Full test suite green, 2026-10-28: 445 tests, 0 failures; layout checked (4-across tile grid) |
| iPhone 18 Pro (simulator) | iOS 27.0 | All screens exercised, screenshots reviewed (2026-09) |
| Mac Catalyst | — | Not supported, not planned |

## What we have NOT verified (open, tracked in #36)

- A **current physical iPhone** — only simulators so far. This is the last
  box for #36, and only the owner can tick it:
  1. Install on any recent iPhone with the free-account path in
     [install-runbook.md](install-runbook.md) (Cmd+R from Xcode; re-trust under
     Settings > General > VPN & Device Management on first install).
  2. Play one full game of Memory Lane to the celebration screen.
  3. Rotate to landscape mid-game and back; nothing should clip or scroll
     the board away.
  4. Comment on #36 with the iPhone model + exact iOS version
     (Settings > General > About). Then this row moves up to the table.
- The oldest OS exactly (17.0, not 17.x) — no device we own is pinned there;
  iPad Viejita on 17.7.11 is the floor-proxy.
- Split-screen / Slide Over on iPad.
- VoiceOver with a real person (part of the a11y checklist on #5).

Re-run this matrix when the deployment target changes, a new iOS major
lands, or a game adds a board that must fit without scrolling.

## Layout expectations

| Screen | iPhone | iPad |
|---|---|---|
| Home tiles | 2 across (1 at accessibility text sizes: 300pt minimum) | 4 across (adaptive, min 150pt) |
| Memory Lane board | every card visible, no scroll: `gridFit` picks the columns that make cards largest (4/6/8 pairs; cards stay ≥60pt, tested) | same, larger cards |
| Category Fluency grid | adaptive, min 100pt | more columns |
| Other games | fixed layouts, no grid | same, centered |
| My Week rows | full width, 100pt minimum height | full width |

## When someone reports a device-specific problem

1. Get model + exact OS version (`Settings → General → About`).
2. Ask for a screenshot and the approximate screen size in points.
3. Reproduce on the closest simulator before touching code — most "device bugs"
   in this app are Dynamic Type or rotation, both reproducible locally.
