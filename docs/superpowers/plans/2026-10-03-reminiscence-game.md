# Reminiscence Game Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A sixth game, "Remember Together" (#139): his photos one at a time with "Who is this?", an optional per-photo caption revealed on tap, names spoken only if the player opts in.

**Architecture:** Captions live in `.txt` sidecars next to each photo in `MemoryPhotos`. A pure `ReminiscenceDeck` deals up to 5 cards (photos first, everyday objects only when the album is empty). `ReminiscenceView` follows the existing one-file-per-game shape and records a session with no accuracy, so the level and difficulty rules ignore it.

**Tech Stack:** SwiftUI, SwiftData, PhotosUI (existing), AVFoundation speech. No new dependencies.

**Spec:** `docs/superpowers/specs/2026-10-03-reminiscence-game-design.md`

## Global Constraints

- Zero third-party dependencies; SwiftUI/SwiftData/Foundation/AVFoundation only.
- Every user-facing string in `MenteViva/Localizable.xcstrings` with EN + ES in the same commit.
- Touch targets >= 100pt for game controls (>= 60pt floor); VoiceOver label on every interactive element; `.title2` minimum for instructions.
- Warm copy only: never "wrong", "error", "failed". No medical claims.
- Caption maximum 60 characters. Captions never enter a share text, `PlayerStateSummary`, or any Jev payload.
- Speech is off by default (`speakNames` setting), separate from `SoundPlayer.enabledKey`.
- Tests use `UserDefaults(suiteName:)`, never `.standard` (host app's real prefs).
- Lint clean: `xcrun swift-format lint --strict -r MenteViva MenteVivaTests tools`; after adding files run `swift tools/generate_project.swift` and commit `project.pbxproj`.
- Tests named Given/When/Then; commit trailer `Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>`.

## Review Focus

- A caption of only spaces or newlines: treated as no caption (Task 1 test).
- A pasted caption over 60 characters, and Spanish names with accents or ñ: truncated and round-tripped intact (Task 1 tests).
- Removing a photo leaves no orphan caption file behind (Task 1 test).
- Fewer than 5 photos (including exactly 1): the session uses just those, never padded with objects (Task 2 tests).
- Speech must never start unless the toggle is on or the speaker button is tapped (Task 3 test); the reveal on a photo with no caption does not show an empty name (Task 4 test).

---

### Task 1: Captions in `MemoryPhotos`

**Files:**
- Modify: `MenteViva/Services/MemoryPhotos.swift` (add caption API; `remove` deletes the sidecar)
- Test: `MenteVivaTests/MemoryPhotosTests.swift` (reuse its `folder` and `photoData` helpers)

**Interfaces:**
- Produces: `static let maxCaptionLength = 60`; `static func caption(for photo: URL) -> String?`; `static func setCaption(_ text: String, for photo: URL) throws`. Sidecar path = the photo URL with extension `txt`.

- [ ] **Step 1: Write failing tests** in `MemoryPhotosTests`: `testGivenCaptionWhenSetThenItReadsBack` ("Mamá, Ñandú 🙂" round-trips exactly); `testGivenWhitespaceOnlyWhenSetThenNoCaption` (`"  \n "` -> `caption(for:) == nil`); `testGivenCaptionOver60WhenSetThenTruncatedTo60`; `testGivenEmptyTextWhenSetThenExistingCaptionIsRemoved`; `testGivenCaptionWhenPhotoRemovedThenNoTxtFileRemains` (assert the folder contents have no `.txt`); `testGivenPhotoListingThenCaptionFilesAreNotListed` (`all(in:).count == 1` with one photo and a caption). Use `try MemoryPhotos.add(photoData(width: 100, height: 100), to: folder)` to create the photo.
- [ ] **Step 2:** Run `xcodebuild test -project MenteViva.xcodeproj -scheme MenteViva -destination 'platform=iOS Simulator,id=<UDID>' -only-testing:MenteVivaTests/MemoryPhotosTests`. Expected: FAIL (compile error, symbols missing).
- [ ] **Step 3:** Implement the three members. Trim with `.whitespacesAndNewlines`, cap with `String(prefix(60))`, UTF-8 file write, empty -> delete the sidecar. Make `remove(_:)` also delete the sidecar.
- [ ] **Step 4:** Re-run the same command. Expected: all `MemoryPhotosTests` pass.
- [ ] **Step 5:** Commit `feat: captions for Memory Lane photos (#139)`.

### Task 2: `ReminiscenceDeck` and everyday objects

**Files:**
- Create: `MenteViva/Games/ReminiscenceDeck.swift` (cards + deal), `MenteViva/Services/EverydayObjects.swift`
- Test: `MenteVivaTests/ReminiscenceDeckTests.swift`

**Interfaces:**
- Produces: `struct EverydayObject: Equatable { let symbol: String; let nameKey: String }`; `enum EverydayObjects { static let all: [EverydayObject] }` (8 items: cup.and.saucer, clock, key, house, chair, umbrella, book, lamp.desk; keys `object.cup`, `object.clock`, `object.key`, `object.house`, `object.chair`, `object.umbrella`, `object.book`, `object.lamp`).
- Produces: `struct ReminiscenceCard: Equatable, Identifiable { enum Picture: Equatable { case photo(URL), symbol(String) }; let id: Int; let picture: Picture; let caption: String? }` and `enum ReminiscenceDeck { static let cardsPerSession = 5; static func deal(photos: [URL], captions: [URL: String], objects: [EverydayObject] = EverydayObjects.all, limit: Int = cardsPerSession, localize: (String) -> String = { AppLanguage.localized($0) }) -> [ReminiscenceCard] }`. Photos are used in the order given (the view shuffles); ids are 0-based positions.

- [ ] **Step 1: Write failing tests:** `testGivenSevenPhotosWhenDealtThenFiveInGivenOrder`; `testGivenThreePhotosWhenDealtThenOnlyThoseThree`; `testGivenOnePhotoWhenDealtThenOneCardNoObjects`; `testGivenNoPhotosWhenDealtThenFiveObjectCardsCaptionedByLocalizedName` (pass `localize: { "L:" + $0 }`, expect caption `"L:object.cup"` first); `testGivenPhotoWithoutCaptionWhenDealtThenCaptionIsNil`; `testGivenEveryObjectSymbolThenItResolvesToAnImage` (`UIImage(systemName:)` non-nil for all 8).
- [ ] **Step 2:** Run `-only-testing:MenteVivaTests/ReminiscenceDeckTests`. Expected: FAIL (not defined).
- [ ] **Step 3:** Implement both files; no randomness inside `deal`. If a symbol fails the resolve test, swap it for a valid SF Symbol and keep the key.
- [ ] **Step 4:** Re-run. Expected: PASS.
- [ ] **Step 5:** Run `swift tools/generate_project.swift`; commit `feat: deal reminiscence cards (#139)`.

### Task 3: `CaptionSpeaker` and the opt-in setting

**Files:**
- Create: `MenteViva/Services/CaptionSpeaker.swift`
- Test: `MenteVivaTests/CaptionSpeakerTests.swift`

**Interfaces:**
- Produces: `@MainActor enum CaptionSpeaker { static let speakNamesKey = "speakNames"; nonisolated static func autoSpeaks(defaults: UserDefaults = .standard) -> Bool; nonisolated static func voiceLanguage(for language: AppLanguage) -> String; static func speak(_ text: String) }`. `autoSpeaks` is false when unset. `voiceLanguage`: `.spanish` -> `"es-MX"`, `.english` -> `"en-US"`, `.system` -> `Locale.current.identifier`. `speak` uses one retained `AVSpeechSynthesizer`, stops any current utterance first, and picks the voice from `AppLanguage.selected()`.

- [ ] **Step 1: Write failing tests** (own suite `CaptionSpeakerTests`): `testGivenNothingStoredWhenAutoSpeaksThenFalse`; `testGivenToggleOnWhenAutoSpeaksThenTrue`; `testGivenLanguageWhenVoiceLanguageThenRegionalCode` (es -> "es-MX", en -> "en-US").
- [ ] **Step 2:** Run `-only-testing:MenteVivaTests/CaptionSpeakerTests`. Expected: FAIL.
- [ ] **Step 3:** Implement as specified.
- [ ] **Step 4:** Re-run. Expected: PASS.
- [ ] **Step 5:** Commit `feat: opt-in caption speech (#139)` (with the regenerated project).

### Task 4: `GameID.reminiscence`, the game view, and the session rule

**Files:**
- Create: `MenteViva/Games/ReminiscenceView.swift`
- Modify: `MenteViva/Models/GameID.swift` (case, emoji "📷", title key `game.reminiscence.title`, `var hasLevels: Bool` false only for it); `MenteViva/HomeView.swift` (`destination(for:)`); `MenteViva/Services/DailyPolicy.swift` (`value[.reminiscence] = 0.7`); `MenteViva/Localizable.xcstrings`
- Test: `MenteVivaTests/ReminiscenceSessionTests.swift`; fix any existing test that hardcodes five games

**Interfaces:**
- Consumes: `ReminiscenceDeck.deal`, `MemoryPhotos.all()/caption(for:)`, `CaptionSpeaker.autoSpeaks/speak`, `modelContext.record`, `.celebration(isPresented:detail:onPlayAgain:)`, `Feedback.play`.
- Produces: `ReminiscenceView.makeSession(cards: Int, seconds: Int) -> GameSession` (static): `gameID .reminiscence`, `score 0`, `rounds cards`, `correct 0`, `attempts 0`, no difficulty.

- [ ] **Step 1: Write failing tests:** `testGivenReminiscenceSessionWhenAccuracyThenNil`; `testGivenOnlyReminiscenceSessionsWhenSummaryThenMeanAccuracyIsNil` (via `PlayerStateSummary.build`); `testGivenReminiscenceSessionsWhenPlanThenItsDifficultyStaysMedium` (with `DailyPolicy.plan`, 10 sessions); `testGivenAllGamesWhenPlanThenReminiscenceCanBePicked` (with the rest hidden; `plan.games == [.reminiscence]`); `testGivenReminiscenceWhenHasLevelsThenFalseAndOthersTrue`.
- [ ] **Step 2:** Run `-only-testing:MenteVivaTests/ReminiscenceSessionTests`. Expected: FAIL.
- [ ] **Step 3:** Add the `GameID` and `DailyPolicy` changes and `makeSession`. Build the view: `@State` for `cards`, `index`, `revealed`, `startedAt`, `showCelebration`. Card = large photo (`.scaledToFit`, `fitOrScroll()` for large type) or the SF Symbol at ~120pt; `RoundCounter` for "n / total"; prompt "Who is this?" (photo) or "What is this?" (object); no caption -> "Let's look together" and only "Next". "Show me" (>= 64pt, `AnswerTileStyle` or `bigTapTarget()` like other games) sets `revealed` and, only if `CaptionSpeaker.autoSpeaks()`, speaks. After reveal: the caption at `.largeTitle`, a speaker button (always works) and "Next". Last "Next" calls `finish()`: record the session, `finalDetail` from a plural key `game.celebration.reminiscence %lld`, show the celebration with `onPlayAgain: deal`. VoiceOver: unrevealed photo labeled "Family photo, no name yet" (no caption leaked); revealed announces the caption.
- [ ] **Step 4:** Add all strings (EN+ES): `game.reminiscence.title` ("Remember Together" / "Recordar juntos"), `game.reminiscence.prompt.photo`, `.prompt.object`, `.together`, `.show`, `.next`, `.hear`, `.a11y.photo`, `game.celebration.reminiscence %lld` (plural), eight `object.*` names. Run the full suite; fix hardcoded game counts. Expected: all pass.
- [ ] **Step 5:** Run `swift tools/generate_project.swift` and the lint command. Verify in the simulator: Home shows the tile; the game plays with no photos (objects) and with a photo. Commit `feat: Remember Together game (#139)`.

### Task 5: Caption sheet in the family screen, and no pin row

**Files:**
- Create: `MenteViva/FamilyPhotoCaptionSheet.swift`
- Modify: `MenteViva/FamilyView.swift` (`FamilyPhotosSection` thumbnails open the sheet and show the caption or "Add a name"; `FamilyGameRow` and `FamilyGameView` skip level/difficulty when `!game.hasLevels`); `MenteViva/Localizable.xcstrings`
- Test: `MenteVivaTests/CaptionStringsTests.swift` (new keys have EN and ES)

**Interfaces:**
- Consumes: `MemoryPhotos.caption(for:)`, `setCaption(_:for:)`, `remove(_:)`, `maxCaptionLength`.
- Produces: `struct FamilyPhotoCaptionSheet: View { let photo: URL; let onChange: () -> Void }`: the photo, a `TextField` (label "A name or a few words", placeholder "Mom's house", limited to 60), the line "Stays on this device only. Not shared, not sent anywhere.", Save (>= 56pt) and Remove photo.

- [ ] **Step 1: Write failing test** `testGivenNewCaptionKeysWhenCatalogReadThenEveryKeyHasEnglishAndSpanish` reading `Localizable.xcstrings` from the bundle (or the source path via `#filePath`) for keys `family.caption.*`, `family.photos.caption.add`, `settings.speak*`, `family.game.nolevel`.
- [ ] **Step 2:** Run it. Expected: FAIL (keys missing).
- [ ] **Step 3:** Build the sheet and wire it; for a game without levels the row says "Photos and names, no levels" and the detail screen shows only the Show toggle. Add the strings (EN+ES): `family.caption.title`, `family.caption.field`, `family.caption.placeholder`, `family.caption.privacy`, `family.caption.save`, `family.photos.caption.add`, `family.game.nolevel`.
- [ ] **Step 4:** Re-run the catalog test and the full suite. Expected: pass.
- [ ] **Step 5:** Verify in the simulator: add a caption, reopen, remove the photo; the game shows the caption on reveal. Commit `feat: name your photos in the family screen (#139)`.

### Task 6: Settings toggle, privacy text, docs

**Files:**
- Modify: `MenteViva/SettingsView.swift` (toggle `@AppStorage(CaptionSpeaker.speakNamesKey)`, default false, 100pt row, hint); `MenteViva/Localizable.xcstrings` (`settings.speak`, `settings.speak.hint`, update `settings.privacy.body` to mention photo names); `docs/privacy-policy.md` (own "Names on photos" section: free text, on this device only, never shared or sent, deleted with the photo); `CHANGELOG.md`; `AGENTS.md` (games count and file map); `docs/decisions.md` (note the opt-in speech decision)
- Test: `CaptionStringsTests` (extend for the settings keys)

- [ ] **Step 1:** Extend the catalog test for the two settings keys; run it. Expected: FAIL.
- [ ] **Step 2:** Add the toggle and strings ("Read names aloud" / "Leer los nombres en voz alta").
- [ ] **Step 3:** Update the docs listed above; the privacy policy keeps "Data Not Collected" and says the names stay on the device.
- [ ] **Step 4:** Run the lint command, the full suite, and the CI build command from AGENTS.md. Expected: lint clean, all tests pass, build succeeds.
- [ ] **Step 5:** Commit `docs+feat: read-names-aloud setting, privacy section (#139)`; push; open the PR with "Closes #139", noting what was verified on screen.
