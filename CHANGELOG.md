# Changelog

Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/). Newest first.

## [Unreleased]

### Added
- **Weekly summary card (#71):** "My Week" shows days played, games played and
  day streak (no scores), and the existing share button sends that same warm
  text. Built locally from saved sessions; EN + ES.

### Accessibility
- **VoiceOver playability (#64):** Quick Eyes announces the flashed picture (and
  holds it 2.5s while VoiceOver is on); Color Clash reads the ink colour and
  shape, and draws the shape beside the word for colour-blind players; wrong
  picks in Name the Herd, Number Trail and Color Clash show a gentle amber
  outline (no text); gear, share and Done buttons have 100pt hit areas; the
  language-row hint is on each button. EN + ES.

### Fixed
- **Round-end bugs (#53, #54, #55):** an extra tap after the last round no longer
  records a second session (Color Clash, Quick Eyes, Number Trail); Color Clash
  now records whole-session time; Number Trail uses the shared round counter.
- **VoiceOver position hints (#56):** Memory Lane and Name the Herd position
  hints now resolve through the string catalog; orphan strings removed.
- **Launch crash on device (local-only builds):** the CloudKit on/off flag was
  passed as `INFOPLIST_KEY_CloudKitEnabled`, which Xcode does not inject (it
  only handles a known allowlist), so the app read `nil`, assumed CloudKit was
  on, and trapped inside CloudKit's mirroring setup with no iCloud entitlement —
  `EXC_BREAKPOINT` in `PFCloudKitContainerProvider`, uncatchable. The simulator
  tolerates the missing entitlement, which is why local testing missed it. Now a
  compile-time `LOCAL_ONLY` flag drives the choice.

### Changed
- **Memory Lane warmth pass (#43):** boards now draw from four themed emoji
  sets (garden, animals, fruit, vehicles) so repeat visits feel fresh; cards
  are larger with a softer warm palette, found pairs bloom gently and keep a
  visible checkmark instead of relying on color alone.
- **Scoring → progress (#45):** points no longer appear anywhere in the UI.
  Every game now ends with the shared celebration showing a warm progress line
  (pairs found, rounds finished, best streak, items spotted — EN + ES). Quick
  Eyes gains the celebration screen it never had. "My Week" rows and the family
  share text show the games played, without point totals. Scores are still
  stored on `GameSession` as anonymous telemetry for Jev; they are just never
  displayed.
- Review pass: game IDs now share one typed source of truth across Jev, Home,
  history, and saved sessions; delayed game tasks cancel when their round ends;
  interactive settings and language controls now use the app's 100pt target
  floor.
- Language selection now updates the visible app immediately, including settings
  labels and game names.
- Round bookkeeping extracted into a tested `RoundProgress` type (#30), used by
  Name the Herd, Color Clash and Quick Eyes. A counter can no longer run past the
  end of a game: advancing is idempotent, the displayed round is clamped, and 8
  boundary tests pin the behaviour (zero rounds, single round, over-advance,
  replay).

### Added
- Sound & haptics (#26): synthesized tones (no audio files, no fees) with a
  matching haptic — soft low-frequency success, a gentle three-note completion,
  a quiet low "miss", all behind one "Sound & haptics" Settings toggle, on by
  default. Design decisions (incl. overriding Jev on cue redundancy) recorded in
  `docs/jev-sounds.md`; Jev call archived as `jev-json/006-sounds`.
- First-run onboarding (#31): one screen — what this is, language choice,
  one big "Let's play" button. Written for a stranger, not for family.
- Settings (#32): language (Device/English/Español), bigger text, plain-language
  privacy summary, version. Reachable from home in one tap. The sound
  toggle followed with sound & haptics (#26).
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
  warm "Well done! 🎉" headline, a progress line (the score was replaced by
  progress in #45), and ≥100pt "Play again / Home" buttons. All games present it on finish
  (fullScreenCover); Reduced Motion shows static confetti.
- "My Week" session history (#9): last 7 days grouped by day, big rows with
  game emoji + score, warm weekly summary line, gentle empty state.

## [0.1.0] — 2026-09-19

First playable. Built in one session with agent teammates.

### Added
- Four games: Memory Lane (pairs), Color Clash (Stroop), Name the Herd
  (category fluency), Number Trail (adaptive math).
- ES/EN localization for every user-facing string (25 keys).
- Jev/TypeSafe client: daily game-mix ranking + difficulty nudge policy,
  once per day, silent deterministic fallback when offline. Not yet wired
  into the app's screens (tracked in #59). Key never on device — proxy
  contract documented.
- Docs system: product brief, conventions, decision log, cited research
  (audience evidence, domain ranking, licensing table, App Store pricing),
  roadmap.
- VoiceOver labels on all game elements; ≥100pt touch targets.

### Fixed
- JevService brace nesting (caught by first real build; parse ≠ compile).
- Missing ES translations for math format strings auto-extracted by Xcode.

[0.1.0]: https://github.com/igmarin/MenteViva/releases/tag/v0.1.0
