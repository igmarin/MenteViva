# Conventions

Lazy-senior rules. Read before writing code.

1. **Zero third-party dependencies.** SwiftUI/SwiftData/Foundation only. If you think you need a package, you're wrong or we discuss it first.
2. **One file per game** in `Games/`, following `MemoryMatchView.swift`: a `View`, `@State` game state, `modelContext.insert(GameSession(...))` on finish. No game engine, no base classes, no protocol ceremony until the 3rd game proves a pattern.
3. **Localization is not optional.** Every user-facing string goes in `Localizable.xcstrings` with EN + ES in the same commit. Hardcoded strings = rejected PR.
4. **Accessibility floor:** touch targets ≥ 60pt (we aim for 100pt), VoiceOver labels on every interactive element, Dynamic Type friendly fonts (`.title2` minimum for instructions).
5. **Tone of failure:** the app never says "wrong/error/failed". Copy is warm: "Almost — try again" / "Casi — inténtalo de nuevo".
6. **After adding a `.swift` file**, run `swift tools/generate_project.swift` and commit the regenerated pbxproj.
7. **Jev key hygiene:** never commit keys. Key lives in an untracked local config during beta; server-side proxy before public release.
8. **Review flow:** PRs to `main`, review checklist in `docs/review-checklist.md` (write it when the first PR exists — YAGNI).
