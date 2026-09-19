# Changelog

Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/). Newest first.

## [Unreleased]

### Added
- Quick Eyes: processing-speed game — a picture flashes for a shrinking
  display time (1.2 s → 0.35 s floor, relaxes after a miss), then the player
  picks it among four big buttons. 12 rounds, no countdown timer. ES/EN copy.
- Shared end-of-game celebration screen (#8): gentle pure-SwiftUI confetti,
  warm "Well done! 🎉" headline, big session score, and ≥100pt
  "Play again / Home" buttons. All four games present it on finish
  (fullScreenCover); Reduced Motion shows static confetti.

## [0.1.0] — 2026-09-19

First playable. Built in one session with agent teammates.

### Added
- Four games: Memory Lane (pairs), Color Clash (Stroop), Name the Herd
  (category fluency), Number Trail (adaptive math).
- ES/EN localization for every user-facing string (25 keys).
- Jev/TypeSafe service: daily game-mix ranking + difficulty nudge,
  once per day, silent deterministic fallback when offline.
  Key never on device — proxy contract documented.
- Docs system: product brief, conventions, decision log, cited research
  (audience evidence, domain ranking, licensing table, App Store pricing),
  roadmap.
- VoiceOver labels on all game elements; ≥100pt touch targets.

### Fixed
- JevService brace nesting (caught by first real build; parse ≠ compile).
- Missing ES translations for math format strings auto-extracted by Xcode.

[0.1.0]: https://github.com/igmarin/MenteViva/releases/tag/v0.1.0
