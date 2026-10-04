# Reminiscence game with photo captions — design (#139)

Evidence: Jev 013 (`docs/jev-json/013-*`, §013 in `docs/jev-revisit.md`), decisions 2026-10-03.

## Intent

He recognizes a face but can't find the name. A short caption (a name, a nickname, a place,
an event) closes that gap. A new game shows his own photos one at a time with "Who is this?";
nothing can be answered wrongly. Captions are typed by family and stay on the device.

## Behavior

1. **Captions.** Each Memory Lane photo has an optional caption, up to 60 characters. Edited
   in For family → photos: tapping a photo opens a sheet (photo, text field, Save, Remove photo).
   The sheet says: "Stays on this device only. Not shared, not sent anywhere."
2. **Game ("Reminiscence").** A session is up to 5 cards, in random order:
   - Photo with a caption: "Who is this?" and a 64pt+ "Show me". It reveals the caption in
     large type. The name is spoken automatically **only if the player turned on "Read names
     aloud" in Settings (off by default, separate from the sound-and-haptics toggle)**. A speaker
     button on the revealed card always works: tapping it is asking to hear the name. Then "Next".
   - Photo without a caption: "Let's look together", then "Next".
   - No photos at all: bundled everyday objects (SF Symbols such as cup, clock, key, house),
     same flow, caption = the object's localized name.
3. **Finish.** The usual celebration; records one `GameSession`.
4. **Plan.** It is a normal game: a Home tile, a candidate for the daily pick, hideable.

## Data

- **Storage:** a `<photo id>.txt` sidecar next to each `<photo id>.jpg` in `MemoryPhotos`
  (`caption(for:)`, `setCaption(_:for:)`); `remove` deletes both. No new index file. Captions
  never enter a share text, `PlayerStateSummary`, or any Jev payload.
- **`GameID.reminiscence`** (`"reminiscence"`): emoji, title key, `HomeView` destination.
- **Session:** `score 0`, `rounds` = cards seen, `correct 0`, `attempts 0`, no difficulty. So
  `accuracy == nil`: it counts toward plays and days but never toward accuracy, level or trends.
  The daily-policy difficulty logic ignores it, and the pin row is hidden for it in For family.

## Files

New: `Games/ReminiscenceView.swift`, `Services/CaptionSpeaker.swift` (one small speech wrapper, plus the `speakNamesKey` setting),
`Services/EverydayObjects.swift` (the fallback list). Changed: `GameID`, `HomeView`,
`DailyPolicy` (mix weight), `MemoryPhotos` (caption), `FamilyView` (caption sheet, no pin row), `SettingsView` (the toggle),
strings, `docs/privacy-policy.md`, `CHANGELOG.md`.

## Rules honored

Warm copy only; no medical claims; 100pt targets; VoiceOver (photo described by its caption once
revealed, "photo, no name yet" before); strings EN+ES; zero dependencies (AVFoundation, PhotosUI).

## Tests (written first)

Speech is never started without the toggle or a tap; caption round trip and delete-with-photo; the 60-character limit; accuracy nil for a reminiscence
session; the daily plan never raises or lowers its difficulty from it; card dealing (5 max,
photos first, objects only when the album is empty).

## Out of scope

Photo-to-caption Memory Lane variant (#142), "My progress" (#141), a Quick Eyes variant (#46).
