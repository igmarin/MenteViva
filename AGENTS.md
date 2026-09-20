# AGENTS.md

Instructions for AI agents (and humans in a hurry) working on MenteViva.

## Read first, in order

1. `docs/conventions.md` — the 8 rules. Violating one = rejected PR.
2. `docs/decisions.md` — what's decided and why. Don't re-litigate; append.
3. `docs/roadmap.md` — what phase we're in. Work outside "Now" needs a reason.

## Non-negotiables

- **Zero third-party dependencies.** SwiftUI/SwiftData/Foundation only.
- **Every user-facing string** goes in `Localizable.xcstrings` with EN + ES
  in the same commit. Hardcoded strings = rejected.
- **Accessibility floor:** ≥100pt touch targets, VoiceOver labels on every
  interactive element, no color-only information, `.title2` minimum for
  instructions.
- **Warm failure copy only.** Never "wrong/error/failed" — the player is
  someone's dad. "Almost — try again."
- **No medical claims** in any copy, code comment, or doc. "Fun mental
  exercise" is the ceiling. See docs/research-2026-09.md §1.
- **The API key never enters the repo or the binary.** Jev goes through the
  proxy; unset proxy URL = offline fallback, which must always work.

## Workflow

1. Branch from `main`, PR back to `main`.
2. After adding/removing a `.swift` file: `swift tools/generate_project.swift`
   and commit the regenerated `project.pbxproj`.
3. **Two build modes.** Default = CloudKit entitlements (simulator, or a device
   signed with the paid Developer Program). `--local-only` = no entitlements and
   `CloudKitEnabled = NO`, required to install on a real device with a free
   Apple ID. Regenerate before switching modes; never commit a local-only
   `project.pbxproj`.
4. **Close Xcode before regenerating the project.** The generator rewrites
   `project.pbxproj` and clears cached `xcuserdata`; Xcode holding the old
   object graph open is what produces "the project has a file format integrity
   issue". Close → regenerate → reopen.
3. Verify before committing: build must pass —
   `xcodebuild -project MenteViva.xcodeproj -scheme MenteViva -destination 'generic/platform=iOS Simulator' build`
   Syntax checks (`swiftc -parse`) are NOT verification.
4. Track work in GitHub issues with the current milestone (see
   [milestones](../../milestones)). Closed-issue labels mark the release
   (e.g. `v0.1.0`).
5. Update `CHANGELOG.md` under `[Unreleased]` with any user-visible change.

## Patterns

- One file per game in `MenteViva/Games/`; copy `MemoryMatchView.swift`'s
  shape (View + @State + `modelContext.insert(GameSession(...))` on finish).
  No game engine, no base classes, no protocol ceremony.
- Jev judgments live in `Services/JevService.swift`; policy stays in code,
  never in the model. See docs/jev-integration.md.

## When unsure

Smallest thing that works, warm tone, offline-safe. If a choice could land
in a doc, it lands in `docs/decisions.md`.
