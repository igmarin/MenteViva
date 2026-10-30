# Mente Viva

Warm, bilingual (EN/ES) fun mental exercise for older adults, built for one family first.

Add your family's photos in Set up, and Memory Lane and Names and Faces play with them.
Fourteen calm games, levels 1–10, offline and private. Big buttons, no countdown clocks,
no fail shame: "Almost, try again", never "wrong".

## Status

**14 games playable**, offline-first, EN and ES complete. See [CHANGELOG.md](CHANGELOG.md)
for what changed, [docs/roadmap.md](docs/roadmap.md) for what's next, and
[GitHub issues](https://github.com/igmarin/menteviva/issues) for live work.

## The games

| Game | What you do |
|---|---|
| Memory Lane | Find the matching pairs of illustrated cards, or of your family's photos |
| Color Clash | Tap the colour of the ink, not the word |
| Name the Herd | Tap everything that belongs to the category |
| Number Trail | Quick sums in a row; the operations and numbers grow with the level |
| Quick Eyes | Look at a picture, then find it among the choices. Paced at levels 1–5; a quick flash at levels 6–10 |
| Remember Together | Look at your family's photos and familiar objects together. Nothing to get wrong |
| Sudoku | Fill the board, from 4×4 up to 9×9, each with one solution |
| Up or Down | Golf solitaire: play a card one higher or one lower |
| Finish the Saying | Pick the ending of a familiar saying |
| Repeat the Sequence | Watch the lit tiles, then repeat them in order |
| Tangram | Fill the silhouette with seven tiles |
| Tile Pairs | Find two free tiles that match |
| Sliding Blocks | Slide the blocks to free the big one |
| Names and Faces | Match each family photo to its caption |

Home marks today's picks and each game reads the daily difficulty. Both are
decided by a small rule policy on the device (no network, no cost).

## How it is built

- Zero third-party dependencies: SwiftUI, SwiftData and Foundation only.
- Most games have levels 1–10. The level moves between sessions, never in the middle of a game.
  Remember Together has no levels.
- Deals are small pure types that take the random generator as a parameter, so tests can
  replay them. Sudoku boards are generated with exactly one solution.
- Every string is in one catalogue, `MenteViva/Localizable.xcstrings`, in English and Spanish.
- No network calls, no accounts and no analytics. Photos stay on the device.

## Built with AI

Several AI coding assistants (Claude, Muse Code and Cline) have worked on tickets, and the owner
merges every pull request. Some game pictures were made with AI image tools, then cut out, cropped
and resized; each prompt is logged in [docs/art-prompts.md](docs/art-prompts.md). The app itself
uses no AI at runtime.

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
  Models/                 # SwiftData: GameSession, RoundProgress, GameID
  Games/                  # one file per game; MemoryMatchView is the reference
  Services/               # DailyPolicy (on-device plan), LevelPolicy, MemoryPhotos, SoundPlayer, ...
docs/                     # product & design docs — start at docs/README.md
tools/generate_project.swift
```

## Docs

Start at [docs/README.md](docs/README.md) — product brief, decision log,
research (audience evidence, licensing, pricing), roadmap.

## Honest scope

This is **not** a medical app. The games exercise memory and attention. They do not diagnose,
treat or cure any condition, and nothing in the app promises a change in daily life. The research
behind the games is in [docs/research-2026-09.md](docs/research-2026-09.md).

## License

The code and docs are licensed under the [Apache License 2.0](LICENSE); see [NOTICE](NOTICE).
You may use, change and redistribute them, keeping the copyright and licence notices.

The name **MenteViva** and the app icon are not covered by that licence (Apache-2.0 §6 grants
no trademark rights). If you ship your own build, give it a different name and icon.

Contributions are accepted under the same licence (Apache-2.0 §5).
