# Device support

## What we claim

**iPhone and iPad running iOS 17.0 or later.** `TARGETED_DEVICE_FAMILY = "1,2"`,
`IPHONEOS_DEPLOYMENT_TARGET = 17.0`.

The floor is not arbitrary: **SwiftData is iOS 17+**, and it stores every
session. Lowering the floor means replacing persistence (Core Data or files) —
that is the whole cost of supporting older devices, and it is why we don't.

## What we've verified

| Device | OS | Result |
|---|---|---|
| iPad (owner's, older model) | iOS 17+ | Installed via Xcode, playtested — the first real device the app ran on |
| iPhone 18 Pro (simulator, iOS 27) | 27.0 | All screens exercised, screenshots reviewed |
| iPad Pro 13" (simulator, iOS 27) | 27.0 | Layout checked (4-across tile grid) |
| Mac Catalyst | — | Not supported, not planned |

## What we have NOT verified (open, tracked in #36)

- The **oldest** device we claim to support (an iOS 17.0 device specifically,
  not 17.x) — we don't own one.
- A current physical iPhone (only simulators so far).
- Split-screen / Slide Over on iPad.
- Landscape rotation on a physical device.
- VoiceOver with a real person (part of the a11y checklist on #5).

## Layout expectations

| Screen | iPhone | iPad |
|---|---|---|
| Home tiles | 2 across | 4 across (adaptive, min 150pt) |
| Game grids | adaptive, min 100pt | more columns |
| My Week rows | full width, 72pt tall | full width |

## When someone reports a device-specific problem

1. Get model + exact OS version (`Settings → General → About`).
2. Ask for a screenshot and the approximate screen size in points.
3. Reproduce on the closest simulator before touching code — most "device bugs"
   in this app are Dynamic Type or rotation, both reproducible locally.
