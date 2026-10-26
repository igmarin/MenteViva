---
name: menteviva-checks
description: Run MenteViva's pre-push checks (lint, claims, signposts, project file, build and tests) before committing or pushing. Use before opening or updating a PR.
---

# MenteViva checks

Follow AGENTS.md, Workflow 5 and the Definition of done. This skill only lists the commands.

Run from the repo root. Each one must pass before a commit is pushed:

1. Lint (Apple's formatter, config in `.swift-format`):
   `xcrun swift-format lint --strict -r MenteViva MenteVivaTests tools`
   Fix most findings with `xcrun swift-format format -i -r MenteViva MenteVivaTests tools`.
2. Copy makes no prohibited claims: `./tools/check_claims.sh`
3. Signposts match docs/profiling.md: `./tools/check_signposts.sh`
4. Project file lists every .swift file: `./tools/check_project_files.sh`
5. Build and tests (macOS with Xcode only):
   `xcodebuild -project MenteViva.xcodeproj -scheme MenteViva -destination 'generic/platform=iOS Simulator' build`
   `xcodebuild test -project MenteViva.xcodeproj -scheme MenteViva -destination "id=<simulator-udid>"`

On Linux, steps 2 to 4 run; steps 1 and 5 need macOS. Say which ones you could not run.

Never regenerate `MenteViva.xcodeproj/project.pbxproj` by hand. After adding or removing a .swift file, run `swift tools/generate_project.swift` with Xcode closed (AGENTS.md, Workflow 4).
