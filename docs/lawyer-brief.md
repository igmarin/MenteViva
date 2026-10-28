# Lawyer brief — one-hour IP and claims review (#226)

Input pack for the owner's appointment, before the paid-release gate (decisions.md 2026-10-26 item 6).
Facts are as of 2026-10-28. This file links to the evidence; it does not copy it. Our own screening is
not legal advice, which is why the review exists.

**Suggested hour:** 5 min §1 · 15 min §2 · 15 min §3 · 10 min §4 · 5 min §5 · 10 min checklist (§6).
Priority if time runs short: §3 (generated pictures), then §1 (claims), then §2 (names).

## 1. What the app is, and is not

MenteViva is 13 calm puzzle and card games for iPhone and iPad, in English and Spanish, built by one
individual (owner: Ismael Marin Cabrera). Anyone who wants an active mind can play; the reference player
is an older family member. Store category: Games › Puzzle, secondary Family; age rating 4+.

- **Claim ceiling: "Fun mental exercise / Ejercicio mental divertido."** A game *exercises* memory or
  attention; copy never says it *improves*, *protects* or *delays* anything (decisions.md 2026-10-26
  item 2; `AGENTS.md` non-negotiables).
- **No diagnosis, treatment or outcome claims.** No scores, results or "brain age" shown to the player;
  the optional warm-up only sets starting levels quietly (decisions.md 2026-10-26 item 4). No clinical
  tests built (ip-clearance.md "The rules").
- **Not a medical device.** Store description ends with a "not a medical device, talk to a doctor"
  note, EN + ES ([store-listing.md](store-listing.md)).
- **"Why these games"** (Settings): balanced, sourced, "educational information, not medical advice",
  no promise per game. Source: [why-these-games.md](why-these-games.md); strings in `Localizable.xcstrings`.
- **Where claim discipline is enforced:** `tools/check_claims.sh` runs on every PR and in the pre-push
  hook. It greps `Localizable.xcstrings`, `docs/store-listing.md`, `docs/product-brief.md`, `site/en`,
  `site/es` and `README.md` for the words improve, boost, train your brain, sharpen, prevent, protect,
  delay, decline, dementia, Alzheimer, memory loss and their Spanish equivalents, and fails on any hit.
  It passes today. It is a word list, not a legal test: it does not read `why-these-games.md` or
  `privacy-policy.md`, and it does not catch phrasing outside the list. That gap is what we ask you
  to cover.
- **Copy to review:** [store-listing.md](store-listing.md) (subtitle, promo text, description, keywords,
  App Review notes), [why-these-games.md](why-these-games.md), the site pages.
- **Game rules, one page each:** [how-it-works.md](how-it-works.md).

## 2. The 14 names

Full table, with mechanic origin, live marks found and two fallback names each:
[ip-clearance.md "Status — name search 2026-10-27"](ip-clearance.md#status--name-search-2026-10-27).
Searched on 2026-10-27 in USPTO, EUIPO, IMPI (MARCANET/SIGA) and the US and MX App Stores, Nice classes
9 and 41, public web views, not a certified search. No live conflicting mark found for any name. Names
we avoided on purpose: Simon, Shanghai, Klotski, KenKen, Picross, Wordle, 24 Game, Lumosity and
BrainHQ game names.

| # | EN / ES | Our risk read |
|---|---|---|
| 0 | MenteViva (app) | low: near strings with a space ("Mente Viva") exist outside 9/41 or dead |
| 1 | Memory Lane / Camino de Memoria | low: descriptive, crowded in stores; "Memory Lane" live in unrelated classes |
| 2 | Color Clash / Choque de Colores | low: live in apparel (class 25) |
| 3 | Name the Herd / Nombra la Manada | none |
| 4 | Number Trail / Sendero de Números | none |
| 5 | Quick Eyes / Ojos Ágiles | none |
| 6 | Remember Together / Recordar juntos | none |
| 7 | Sudoku / Sudoku | none outside Japan (see below) |
| 8 | Up or Down / Sube o baja | none |
| 9 | Finish the Saying / Termina el refrán | none |
| 10 | Repeat the Sequence / Repite la secuencia | none |
| 11 | Tangram / Tangram | low: generic, crowded |
| 12 | Tile Pairs / Parejas de fichas | none (design doc proposed "Pares de fichas"; both searched) |
| 13 | Sliding Blocks / Bloques deslizantes | none |

**Questions to confirm:**

1. Is our search method enough for a "go", or do you want a professional search on any of the 14?
   Which, and in which classes and jurisdictions?
2. **Sudoku:** Nikoli holds "Sudoku" as a trademark in Japan only. We do not plan a Japan release. Is it
   safe to list Sudoku in the US, EU, Mexico and Spain, and what must we do to *exclude* Japan on the
   App Store? Is the word in the keywords field ("sudoku") a separate exposure?
3. **MenteViva** is the one name we cannot easily replace. Any concern about the "Mente Viva" near
   strings, or about the Spanish-language market (Spain, Mexico, other Spanish-speaking storefronts)?
4. **Memory Lane** and **Color Clash** are the only two with live marks in other classes. Keep, or swap
   to the fallback names in the table?
5. Mechanics (concentration, Stroop, Corsi, Tangram, mahjong-solitaire style matching, sliding block /
   Huarong Dao style, higher-or-lower, number place) are built from public rules (17 U.S.C. §102(b)).
   Is any one close enough to a protected product in look, feel or rules to worry you? We name none
   after a product and copy no art.

## 3. Asset provenance

Evidence: [ip-clearance.md "Third-party assets"](ip-clearance.md#third-party-assets--what-we-checked-on-2026-10-27)
and ["AI-generated pictures"](ip-clearance.md#ai-generated-pictures); per-picture prompt and tool log:
[art-prompts.md](art-prompts.md); prompts: `docs/design/art-samples/prompts/`; direction:
[design/art-style.md](design/art-style.md).

**Clean by construction (checked in the repo on 2026-10-27):** no bundled fonts (system San Francisco),
no sound files (tones synthesised in `SoundPlayer.swift`), no third-party code or packages, game marks
are Apple Color Emoji system glyphs, puzzles and texts are generated by our code or written by us. The
app icon is drawn in code by `tools/generate_icon.swift` (a redraw of study A; no generated raster ships).
Study A and the retro concept sheet are reference only, not bundled.

**Generated pictures: 69 in `Assets.xcassets/Pictures/`**, all text-prompt only, no reference image, no
artist, studio or brand named, white background removed locally. By tool:

| Tool, as logged | Pictures | Output-rights basis today |
|---|---|---|
| OpenAI Images API, model `gpt-image-1.5` (#326) | 11: guitar, coffee, star, bee, cactus, clock, house, chair, umbrella, book, lamp | OpenAI Terms of Use, "We hereby assign to you all our right, title, and interest, if any, in and to Output" (checked 2026-10-27) |
| OpenAI built-in image tool driven by `codex exec`, Codex CLI 0.165.0; image model/version **not exposed** (#325, #327, #328) | 50: 18 in #325, 17 in #327, 15 in #328 | Same OpenAI terms assumed, but the account terms for this route are not yet confirmed (ip-clearance.md says confirm in #226) |
| Muse built-in image tool, `muse.image_generation`; provider and model **not exposed** (#323 samples) | 8: dog, apple, sailboat, sunflower, moon, key, teapot, violin (reused unchanged in #325–#328) | **None asserted** |

**OPEN QUESTION (the main one for you).** Muse's image tool does not tell us which provider or model made
the output, so we cannot quote any terms that assign us the output of those 8 pictures. The Codex route
shows the vendor but not the image model. We need your route for the output-rights basis, one of:

- **(a) License:** a written answer from the tool vendor (or its terms, once the provider is known)
  that grants commercial use of output. Who asks, and what wording is enough?
- **(b) Originality:** is "original design from a text prompt, checked for resemblance to existing
  characters" a sufficient basis, given we never name a source? What would you want to see in the check?
- **(c) Redraw:** replace the 8 Muse pictures (and any others you flag) with art drawn in code or by
  hand. This is the fallback we can do without your blessing.

Related points to confirm:

6. **Copyright in the pixels.** AI-generated expression may not be protectable (US Copyright Office
   announcement 2025: prompts alone do not establish human authorship). We accept that others could
   reuse the pictures, and we promise no exclusivity. Anything to change in how we describe the art?
7. **Disclosure.** Do the App Store listing, the support page or the app need to say the pictures were
   AI-generated (App Store guidelines, EU AI Act, other)? Today they say nothing about it.
8. **Resemblance.** Each batch was checked by us for existing characters, distinctive accessories and
   branding, and nothing was traced. Is our own check enough, or do you want to look at the set
   (batch contact sheets: `docs/design/art-samples/batch*.png`)?
9. **Open source.** The repo is licensed Apache-2.0 and intended to go public (it is private today; decisions.md
   2026-10-27 and 2026-10-28). Does publishing the generated pictures under that licence create a problem,
   given point 6?

## 4. Privacy posture

Policy: [site/en/privacy.html](../site/en/privacy.html) and [site/es/privacy.html](../site/es/privacy.html)
(source text [privacy-policy.md](privacy-policy.md)); support:
[site/en/support.html](../site/en/support.html), [site/es/support.html](../site/es/support.html). Hosting is
not live yet (#34, #188).

- **Nothing leaves the device.** The app makes no network requests (no `URLSession`); the daily plan is
  computed on the device (`DailyPolicy`); no keys in the repo or binary (AGENTS.md; decisions.md 2026-10-26 item 1).
- No accounts, ads, analytics, tracking or third-party SDKs. App Store label: **Data Not Collected**
  ([store-listing.md "App Privacy"](store-listing.md#app-privacy)).
- **Photos** ("Memory Lane photos" in the policy's wording) come through the system photo picker, a copy is kept in the app's
  private storage, with an optional typed name. They are never uploaded. They may be in the user's own
  device backup; the policy says so.
- The only things that can leave are user-initiated: the iOS share sheet ("share your week") and the
  source links in "Why these games" (open in Safari).
- Contact address on the pages: hello@nebulaideas.com (EN), hola@nebulaideas.com (ES).

**Questions to confirm:**

10. Is "Data Not Collected" correct given the on-device photos, typed names and backups?
11. Does the privacy policy need anything more for the US, EU/GDPR, Mexico (LFPDPPP) or Spain, given we
    hold no data? Is a terms-of-use page needed (the issue asks)?
12. The policy says the app is "designed for older adults and is not directed at children", while the
    store copy and decisions.md 2026-10-26 item 2 say the audience is *anyone*, with age rating 4+. Do
    those two statements conflict (COPPA, App Store Kids rules)? Which should change?

## 5. Price, Family Sharing, seller and label consistency

- **Price.** The issue calls this the "paid release", but decisions.md 2026-10-27 (#228) made v1.0
  **free**, with no in-app purchase and no payment link inside the app (support link outside the app only;
  never the word "donation", guideline 3.2.2). The store listing says free. The paid Apple Developer
  Program ($99/yr) is the only cost. A price may return later.
- **Family Sharing:** a free app shares automatically; nothing to configure ([store-listing.md](store-listing.md)).
- **Seller name.** Today: an individual, "Ismael Marin Cabrera" (copyright line and signing team). The
  email domain is `nebulaideas.com`. The issue asks: individual or company? That choice sets what the App
  Store shows as seller, who holds liability, and who owns the copyright.
- **Consistency to check against the three public surfaces:** (1) store listing, (2) in-app strings,
  (3) site pages. Known differences: the site writes "Mente Viva" with a space, the app and store write
  "MenteViva"; the privacy policy says "older adults" and the App Review notes say "adults" (see point 12); the keywords field contains
  "seniors" and "brain games", which the claims script does not flag; the age rating answers "Medical
  or treatment information: None" and the lawyer review is named as the confirmation.

**Questions to confirm:**

13. Individual seller or a company, before a paid price ever appears? What does a company change for
    the name, the copyright line and the policy contact?
14. If we later charge: any extra duties (consumer-law information, refund terms, tax) we should plan for?
15. Do "seniors" and "brain games" in the keywords, or "Fun mental exercise" as the App Store subtitle,
    create a claims problem with Apple (guideline 1.4.1) or the FTC, even with the disclaimer?

## 6. Decision checklist (tick during the call)

Each item: the question, what we do today, and what changes in the repo if the answer is no. "Ticket"
means we open a GitHub issue for it (the done-when of #226 is the outcome in `docs/decisions.md`).

| ☐ | # | Question | Our position today | If the lawyer says no |
|---|---|---|---|---|
| ☐ | 1 | Is "Fun mental exercise" an acceptable ceiling for all copy? | Yes; script-enforced word list | Reword in `Localizable.xcstrings`, `store-listing.md`, site; extend the pattern in `tools/check_claims.sh` |
| ☐ | 2 | Is the "Why these games" section safe (sourced, no promise)? | Yes, disclaimer included | Cut it to a short note or remove it; update strings and the store notes |
| ☐ | 3 | Are the keywords "seniors" and "brain games" and the subtitle OK? | Yes | Replace keywords in `store-listing.md`; change subtitle EN + ES |
| ☐ | 4 | Are the 14 names cleared as searched? | Yes; no live marks found | Rename to the fallback in the table: strings, store listing, docs, `GameID`; regenerate the project |
| ☐ | 5 | Do we want a professional search on any name? | No | Ticket per name; hold the release for it |
| ☐ | 6 | Is Sudoku safe with Japan excluded? | Yes; no Japan release | Exclude Japan in App Store Connect, or use "Number Grid / Cuadrícula Numérica" |
| ☐ | 7 | Are all 8 mechanics free of protected-product closeness? | Yes; public rules, own art | Change the named game's rules or art; ticket per game |
| ☐ | 8 | Output-rights route for the 8 Muse-made pictures: license, originality or redraw? | Unasserted; not cleared | **Redraw** the 8 in code (dog, apple, sailboat, sunflower, moon, key, teapot, violin); ticket; update `art-prompts.md` |
| ☐ | 9 | Is the Codex-route set (50 pictures) cleared on OpenAI's terms? | Assumed yes; account terms unconfirmed | Redraw the set in batches; or regenerate through the API route in the table, log model |
| ☐ | 10 | Is the `gpt-image-1.5` set (11 pictures) cleared? | Yes, per OpenAI terms | Redraw the 11 |
| ☐ | 11 | Must we disclose AI-generated pictures (store, support, in app)? | No disclosure today | Add a line to `store-listing.md`, the site pages and the in-app Settings, EN + ES |
| ☐ | 12 | Is a resemblance check by us enough, or does the lawyer review the set? | Own check per batch | Lawyer reviews the contact sheet; flagged pictures get redrawn |
| ☐ | 13 | May the generated pictures sit in the Apache-2.0 repo once it is public? | Yes | Move them out of the public repo or relicense them; update `README` and `ip-clearance.md` |
| ☐ | 14 | Is "Data Not Collected" the correct label? | Yes | Change the App Privacy answers and the policy in `site/`, `privacy-policy.md` |
| ☐ | 15 | Is a terms-of-use page needed? | No | Write it (EN + ES) in `site/`, add to the store listing |
| ☐ | 16 | Do "older adults" and the audience "anyone / 4+" conflict? | Yes, a mismatch we know | Align the policy wording with the store copy, or the age rating with the policy |
| ☐ | 17 | Individual or company as seller? | Individual | Company set-up outside the repo; change the copyright line and the policy contact |

**Outcome:** record it in `docs/decisions.md` (new entry at the top of the current month, template there);
each change above becomes its own ticket. This brief is closed by the owner after the call.
