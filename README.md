# Mente Viva 🧠

Warm, bilingual (ES/EN) cognitive games for older adults — built for one dad
first, designed for every family like his.

Nine mini-games today, with four more on the way. Big buttons, no countdown clocks
pressuring anyone, no fail shame — "Almost, try again", never "wrong".

## Status

**v0.1.0 shipped**; nine playable games now, offline-first, ES/EN complete.
See [CHANGELOG.md](CHANGELOG.md). What's next: [docs/roadmap.md](docs/roadmap.md)
and [GitHub issues](https://github.com/igmarin/menteviva/issues).

## The games

| Game | Domain | Mechanic |
|---|---|---|
| 🧩 Memory Lane | Episodic memory | Emoji pair matching |
| 🎨 Color Clash | Attention / inhibition | Stroop — tap the ink, not the word |
| 🐾 Name the Herd | Verbal fluency | Tap everything that belongs to the category |
| 🔢 Number Trail | Processing + numeracy | Adaptive math streaks |
| 👀 Quick Eyes | Processing speed | Shrinking display-time discrimination |
| 📷 Remember Together | Reminiscence | The family's own photos and names; nothing to get wrong |
| ✏️ Sudoku | Logic | 4×4 and 6×6 boards, generated with one solution |
| 🃏 Up or Down | Planning | Golf solitaire: one higher or one lower |
| 💬 Finish the Saying | Language | Pick the ending of a familiar saying |

Coming next (#193): Repeat the Sequence, Tangram, Tile Pairs, Sliding Blocks.

Home marks today's picks and each game reads the daily difficulty. Both are
decided by a small rule policy on the device (no network, no cost).
Design history: [docs/jev-integration.md](docs/jev-integration.md).

## Build

Requires Xcode 16+, iOS 17+ target, zero third-party dependencies.

```sh
swift tools/generate_project.swift   # regenerate project (local-only, the default)
open MenteViva.xcodeproj             # pick a simulator, press ▶︎
```

Two build modes, chosen at generation time:

| Mode | Command | Use when |
|---|---|---|
| **Local-only** (default) | `swift tools/generate_project.swift` | Everything for now — free Apple ID, simulator, any device. Store is on-device. |
| **CloudKit** | `swift tools/generate_project.swift --cloudkit` | Later, with the paid Developer account + provisioned container (iCloud sync/`CKShare`) |

Local-only defines `LOCAL_ONLY` at compile time and drops the entitlements file,
so the store is on-device only and a free Apple ID can provision it. CloudKit
mode traps on launch if built without the entitlement — that is why it is not
the default (see `AGENTS.md`).

After adding a `.swift` file: regenerate and commit the updated
`project.pbxproj` (see docs/conventions.md §6).

## Structure

```
MenteViva/
  MenteVivaApp.swift      # app entry
  HomeView.swift          # game picker
  Models/                 # SwiftData: GameSession, RoundProgress
  Games/                  # one file per game; MemoryMatchView is the reference
  Services/               # DailyPolicy (on-device plan), SoundPlayer
docs/                     # product & design docs — start at docs/README.md
tools/generate_project.swift
```

## Docs

Start at [docs/README.md](docs/README.md) — product brief, decision log,
research (audience evidence, licensing, pricing), roadmap.

## Honest scope

This is **not** a medical app. The science (see docs/research-2026-09.md):
brain games alone show weak transfer to daily life; they work best as one
ingredient of an engaged, active life. Our copy says "fun mental exercise" and
never promises cognitive outcomes. That's the honest position and the legally safe one.

## License

The code and docs are licensed under the [Apache License 2.0](LICENSE); see [NOTICE](NOTICE).
You may use, change and redistribute them, keeping the copyright and licence notices.

The name **MenteViva** and the app icon are not covered by that licence (Apache-2.0 §6 grants
no trademark rights). If you ship your own build, give it a different name and icon.

Contributions are accepted under the same licence (Apache-2.0 §5).
