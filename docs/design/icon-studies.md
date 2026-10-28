# App icon studies (#337)

**Status: the owner selected study A on 2026-10-28. Studies B and C were not selected.** The shipped icon is a native redraw of A (below). Studies and sheet below are kept as the record.

Sheet: [`art-samples/icon/icon-studies.png`](art-samples/icon/icon-studies.png) (each study and the current icon at 1024, 180, 60, 40 px on light and dark home-screen backgrounds). Masters: `art-samples/icon/study-{a,b,c}.png`, 1024×1024, opaque, square. Prompts and tool disclosure: [art-prompts.md](../art-prompts.md#icon-studies-337). Direction: [art-style.md](art-style.md).

## Brand placements today (none changed here)

1. **App icon**: `MenteViva/Assets.xcassets/AppIcon.appiconset/icon-1024.png`, rendered by `tools/generate_icon.swift` (tilted white card, jade frame, two cards, amber dot, teal-to-amber gradient).
2. **Home-screen name**: `INFOPLIST_KEY_CFBundleDisplayName = "Mente Viva"` (via `tools/generate_project.swift`).
3. **In-app wordmark**: system-typography text from `app.title` ("Mente Viva"): `HomeView` navigation title, `OnboardingView` heading. No drawn logo.
4. **README**: title `# Mente Viva 🧠` (emoji) and the trademark note on the name and icon. No image.
5. **Support site**: `site/index.html` `<h1>`, nav text and `<title>` in `site/en`, `site/es`. Text only; no favicon or image.
6. **Docs**: `docs/ip-clearance.md` names `icon-1024.png` as the only bundled image.

So a selected icon changes only (1) and its provenance entry; the wordmark stays system typography everywhere. (The 🧠 in the README title is outside this ticket; it sits oddly with the "no brain glyph" icon rule, so flag it to the owner.)

## The studies

Common ground: cream card, espresso ink, jade identity, one mustard accent, flat fills, no lettering, no gradient or shadow.

- **A: "The dealt card".** Closest evolution. Keeps the single tilted card and framed panel; swaps white/teal-amber gradient for a cream card with an espresso outline, a jade panel, one big mustard disc, on dark jade. Drops the second card and the tiny dot for one bold disc.
- **B: "The pair".** Keeps the memory-pair idea of the current two cards but makes it the whole icon: a cream back card and a jade front card with mustard disc, on cream. Lightest, most "Memory Lane"; names the game, not the app.
- **C: "The friendly card".** Upright cream card with a simple smile and mustard cheeks on jade. Furthest from today's mark, warmest, ties to the "selective friendly faces" direction.

## Review at 40px

All three read at 40px: A as a framed card with a gold disc, B as two cards, C as a smiling card. Notes (independent subagent review agreed): B is weakest at 40px: cream on a pale home screen has little edge contrast, and the back card's thin jade ring is the only cue for a "pair", so it can read as one green card. C's face survives (eyes, smile; eye highlights vanish, harmless). A has the strongest silhouette on both backgrounds; its inner frame lines are the finest detail and are not essential.

Palette drift (image model output, not exact tokens): A's ground is darker than `#246456` (about `#0F4A44`); B's jade is lighter; C's card is warmer tan than `#FFF1D0` and its ground is a teal near the token; the mustard in A and C is more orange than `#E7AC45`. The selected study would be redrawn in `tools/generate_icon.swift` with exact tokens.

## Recommendation: A

1. Clearest at 40px and on both backgrounds; one shape, one accent.
2. Most recognizable evolution of today's card (single tilted framed card), so existing users still find it.
3. No face or character: stays inside "no dense character illustration" and the no-medical-glyph rule.
4. Easy to redraw natively with exact tokens (rounded rects and a circle), keeping `generate_icon.swift` reproducible with no AI asset to clear in #226.

B is the runner-up. C is charming but the least like today's mark and the least robust when small.

## Final icon (selected 2026-10-28)

Drawn by `tools/generate_icon.swift` (`swift tools/generate_icon.swift` regenerates `AppIcon.appiconset/icon-1024.png` byte-for-byte; checked twice). Sheet: [`art-samples/icon/icon-final.png`](art-samples/icon/icon-final.png), the installed icon beside the previous one at 1024/180/60/40 px on light and dark; read at 40px, the card, the jade panel and the gold disc all stay distinct.

Exact tokens: cream `#FFF1D0` card, espresso `#2B2118` outlines (card and disc), muted jade `#246456` panel, honey mustard `#E7AC45` disc, ground `#143F36` (jade darkened so the cream card stands off it). Flat fills, no gradient, no shadow, opaque 1024×1024 RGB PNG (no alpha), square corners (iOS rounds them). The study's inner frame line around the jade panel is dropped: jade on cream already separates and the line blurred at 40px. The wordmark stays system typography; README and site are unchanged.
