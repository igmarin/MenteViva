# Handoff: retro app icon (#337)

## Goal
Issue igmarin/MenteViva#337: evolve the card app icon to the approved retro direction. Owner picks the icon before it replaces anything. Worktree `/tmp/mv-337`, branch `agent/337-retro-icon`. Only this issue/PR is in scope; leave the PR open for human merge, never merge.

## Status
- Done: three studies (A/B/C), contact sheet, prompts, `docs/design/icon-studies.md` (inventory + recommendation), `docs/art-prompts.md` rows, subagent review findings folded into the doc.
- Owner chose **A** (the dealt card). Logged in `docs/decisions.md` (2026-10-28).
- Done: icon redrawn natively in `tools/generate_icon.swift` (exact tokens, opaque RGB, square, no shadow), `icon-1024.png` regenerated, `docs/ip-clearance.md` and `CHANGELOG.md` updated.
- Pushed through commit 6a3bd95; pre-push hook passed. Working tree clean.
- **Not done:** PR #346 (https://github.com/igmarin/MenteViva/pull/346) is still a draft with the old title "Icon studies for owner selection (#337)" and a "Refs #337" body. `gh pr edit` / `gh pr ready` was denied by the permission classifier.

## Decisions
- Studies are generated with OpenAI Images API `gpt-image-1.5` (not Muse's built-in generator; disclosed in `docs/art-prompts.md` and the PR).
- The AI study master is reference only; the shipped icon is drawn in Swift, so no AI asset enters the bundle (final IP review stays with #226).
- Icon PNG written through an alpha-less sRGB CGContext because the App Store rejects alpha icons.
- Wordmark, README and site are text only (no image), so nothing else changes. README title still has a 🧠 emoji; flagged in the doc, not changed.
- Added the icon commit to the same PR rather than a second PR.

## Dead ends
- `NSBitmapImageRep` with `hasAlpha: false`: "could not create bitmap context". Used the flatten step instead.
- `gh pr create` failed against `nebulaideas/MenteViva` (repo moved); worked with `--repo igmarin/MenteViva --head agent/337-retro-icon`.
- One pre-push attempt failed only on simulator test-runner launch (Mach error -308); rerun passed. Never needed `--no-verify`.

## Files
- `tools/generate_icon.swift`: icon generator (run `swiftc -O tools/generate_icon.swift -o /tmp/genicon && /tmp/genicon` from repo root).
- `MenteViva/Assets.xcassets/AppIcon.appiconset/icon-1024.png`: shipped icon.
- `docs/design/icon-studies.md`, `docs/design/art-samples/icon/` (study-a/b/c.png, icon-studies.png, prompts/).
- `docs/decisions.md`, `docs/ip-clearance.md`, `docs/art-prompts.md`, `CHANGELOG.md`.

## Verification
- `./tools/check_claims.sh ./tools/check_signposts.sh ./tools/check_project_files.sh`: passed.
- `xcrun swift-format lint --strict tools/generate_icon.swift`: clean.
- Pre-push hook (build + tests): passed on last push.
- Icon pixel check: ground (20,63,54), panel (36,100,86) = #246456, disc (231,172,69) = #E7AC45.

## Next steps
1. Update PR #346: `gh pr edit 346 --repo igmarin/MenteViva --title "Retro app icon: study A (#337)"` with body "Closes #337" summarising the above, then `gh pr ready 346 --repo igmarin/MenteViva`. Needs the user to approve or run it.
2. Optional: rebuild the contact sheet with the real shipped icon at 40/60/180 px beside the current one (the sheet still shows the study master, not the Swift redraw).
3. Do not merge; the owner merges.

## Open questions
- Should the README 🧠 emoji be removed (out of scope here)?
- Does the owner want the sheet refreshed with the shipped redraw before merging?
