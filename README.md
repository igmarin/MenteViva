# Mente Viva 🧠

Warm, bilingual (ES/EN) cognitive games for older adults — built for one dad
first, designed for every family like his.

Four mini-games, one per cognitive domain. Big buttons, no timers pressuring
anyone, no fail shame — "Almost, try again", never "wrong".

## Status

**v0.1.0 shipped** — four playable games, offline-first, ES/EN complete.
See [CHANGELOG.md](CHANGELOG.md). What's next: [docs/roadmap.md](docs/roadmap.md)
and [GitHub milestones](../../milestones).

## The games

| Game | Domain | Mechanic |
|---|---|---|
| 🧠 Memory Lane | Episodic memory | Emoji pair matching |
| 🎨 Color Clash | Attention / inhibition | Stroop — tap the ink, not the word |
| 🐾 Name the Herd | Verbal fluency | Tap everything that belongs to the category |
| 🔢 Number Trail | Processing + numeracy | Adaptive math streaks |

Jev ([TypeSafe](https://typesafe.ai)) ranks the daily mix and nudges
difficulty — seasoning, not the meal. Everything works offline without it.
Design: [docs/jev-integration.md](docs/jev-integration.md).

## Build

Requires Xcode 16+, iOS 17+ target, zero third-party dependencies.

```sh
open MenteViva.xcodeproj   # pick a simulator, press ▶︎
```

After adding a `.swift` file: `swift tools/generate_project.swift` and commit
the regenerated `project.pbxproj` (see docs/conventions.md §6).

## Structure

```
MenteViva/
  MenteVivaApp.swift      # app entry
  HomeView.swift          # game picker
  Models/                 # SwiftData: GameSession
  Games/                  # one file per game; MemoryMatchView is the reference
  Services/               # JevService (TypeSafe client, offline-fallback)
docs/                     # product & design docs — start at docs/README.md
tools/generate_project.swift
```

## Docs

Start at [docs/README.md](docs/README.md) — product brief, decision log,
research (audience evidence, licensing, pricing), roadmap.

## Honest scope

This is **not** a medical app. The science (see docs/research-2026-09.md):
brain games alone show weak transfer to daily life; they work best as one
ingredient of an engaged, active life. Our copy says "fun mental exercise" —
never "prevents decline". That's the honest position and the legally safe one.
