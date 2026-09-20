# Changelog

Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/). Newest first.

## [Unreleased]

### Added
- First-run onboarding (#31): one screen — what this is, language choice,
  one big "Let's play" button. Written for a stranger, not for family.
- Settings (#32): language (Device/English/Español), bigger text, plain-language
  privacy summary, version. Reachable from home in one tap. Sound toggle
  deliberately deferred until sound exists (#26) — a control that does nothing
  is worse than no control.
- Home screen personality (#27): warm greeting, large emoji game tiles in a
  grid (>=140pt tall), and the My Week card. Replaces the bare list.
- App icon + launch screen: warm gradient with two memory cards, generated
  reproducibly by `tools/generate_icon.swift` (no design tools, no assets to
  lose). Deliberately not a brain glyph — research §1 caps our positioning at
  "fun mental exercise".
- Accessibility audit fixes (#5, docs/a11y-audit-2026-09.md): Color Clash
  buttons now carry a distinct shape (circle/triangle/square/diamond) so
  color never carries the answer alone; Name the Herd picked tiles get a
  visible checkmark; VoiceOver position/state hints in Memory Lane and Name
  the Herd ("Card 3 of 16", "Pair found", "Already picked") — all ES/EN.
  "My Week" now shows Quick Eyes sessions instead of "Unknown game".
- Quick Eyes: processing-speed game — a picture flashes for a shrinking
  display time (1.2 s → 0.35 s floor, relaxes after a miss), then the player
  picks it among four big buttons. 12 rounds, no countdown timer. ES/EN copy.
- Shared end-of-game celebration screen (#8): gentle pure-SwiftUI confetti,
  warm "Well done! 🎉" headline, big session score, and ≥100pt
  "Play again / Home" buttons. All four games present it on finish
  (fullScreenCover); Reduced Motion shows static confetti.
- "My Week" session history (#9): last 7 days grouped by day, big rows with
  game emoji + score, warm weekly summary line, gentle empty state.

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
