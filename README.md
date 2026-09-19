# Mente Viva 🧠

Cognitive exercise app for older adults. iPad + iPhone, English & Spanish.
Built for my dad — preventive brain training that's easy, warm, and playful.

## Stack

- **SwiftUI + SwiftData** — native, zero third-party deps
- **iOS 17+**, universal (TARGETED_DEVICE_FAMILY = 1,2)
- **Localization**: `Localizable.xcstrings` (en + es from day one)
- **TypeSafe Jev** (planned): daily game mix + difficulty tuning, online-only; games work 100% offline
- **CloudKit** (planned): family progress sharing, no server to run

## Build

```bash
# One-time: accept Xcode license, then:
swift tools/generate_project.swift   # regenerate .xcodeproj after adding files
open MenteViva.xcodeproj             # or: xcodebuild -scheme MenteViva build
```

## Structure

```
MenteViva/
  MenteVivaApp.swift      # app entry
  HomeView.swift          # game picker
  Models/GameSession.swift
  Games/                  # one file per game; Memory Lane is the reference
  Services/               # Jev client goes here
docs/                     # product & design docs
tools/generate_project.swift
```

## Status

- [x] Project scaffold, builds with zero deps
- [x] Game 1: Memory Lane (pair matching)
- [ ] Game 2: Color Clash (Stroop) · Game 3: Name the Herd (fluency) · Game 4: Number Trail (math)
- [ ] Jev daily-mix service
- [ ] CloudKit family sharing

**Not a medical app.** Wellness-positioned; no diagnostic claims.
