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

| Device | OS | Result |
|---|---|---|
| iPad (owner's, older model) | iOS 17+ | Installed via Xcode, playtested — the first real device the app ran on |
| iPhone 17 (simulator) | iOS 27.0 | Build + full 41-test suite green, 2026-09-22, after the #43/#45 UI changes |
| iPhone 18 Pro (simulator, iOS 27) | 27.0 | All screens exercised, screenshots reviewed |
| iPad Pro 13" (simulator, iOS 27) | 27.0 | Layout checked (4-across tile grid) |
| Mac Catalyst | — | Not supported, not planned |

## What we have NOT verified (open, tracked in #36)

- A **current physical iPhone** — only simulators so far. Owner task: any
  recent iPhone + free-account install (docs/install-runbook.md), one game of
  Memory Lane, landscape rotation check.
- The oldest OS exactly (17.0, not 17.x) — we don't own a device pinned there;
  the owner's iPad is our floor-proxy.
- Split-screen / Slide Over on iPad.
- VoiceOver with a real person (part of the a11y checklist on #5).

## Layout expectations

| Screen | iPhone | iPad |
|---|---|---|
| Home tiles | 2 across | 4 across (adaptive, min 150pt) |
| Memory Lane grid | adaptive, min 110pt (120pt cards) | more columns |
| Category Fluency grid | adaptive, min 100pt | more columns |
| Other games | fixed layouts, no grid | same, centered |
| My Week rows | full width, 72pt tall | full width |

## When someone reports a device-specific problem

1. Get model + exact OS version (`Settings → General → About`).
2. Ask for a screenshot and the approximate screen size in points.
3. Reproduce on the closest simulator before touching code — most "device bugs"
   in this app are Dynamic Type or rotation, both reproducible locally.
