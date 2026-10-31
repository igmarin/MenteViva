# TestFlight beta pack (#229)

Testers install from TestFlight: builds last 90 days, no cable, no 7-day re-sign.
The owner clicks; everything below is ready to paste. Menu names are from memory of
App Store Connect and may have moved: follow the intent, not the exact label.

## What the archive uses (read this once)

- **Default local-only build** (`swift tools/generate_project.swift`, no `--cloudkit`). It has
  no entitlements file, so no iCloud/push capability and nothing for App Store Connect to reject.
  **Never archive a `--cloudkit` build for TestFlight**: it traps at launch (AGENTS.md Workflow 3)
  and TestFlight is a real device, which is the case the simulator never reproduces.
- Version `0.1.0`, build `2` (build 1 is already uploaded) live in `tools/generate_project.swift` (`MARKETING_VERSION`,
  `CURRENT_PROJECT_VERSION`). Export compliance is answered in the build
  (`ITSAppUsesNonExemptEncryption = NO`: no network, no custom crypto), so uploads don't stop to ask.
- **Privacy manifest** (`MenteViva/PrivacyInfo.xcprivacy`, copied to the .app root): no tracking, no
  collected data (matches the "Data Not Collected" label, #34). It declares the two required-reason APIs
  the code calls: UserDefaults (`CA92.1`) and file timestamps (`C617.1`, the photos folder is in the app
  container). Adding an API from another category (disk space, system uptime) means adding its reason here,
  or App Store Connect refuses the upload (ITMS-91053).
- **Signing team: the generator still pre-fills the free Personal Team `VB42T7NYX2`.** The paid team
  (#224) is not in the repo. Archive with it as a command-line override, no regenerate needed:
  `DEVELOPMENT_TEAM=<paid team id>`. If `com.igmarin.MenteViva` is registered under the Personal
  Team, App Store Connect will refuse it: change `PRODUCT_BUNDLE_IDENTIFIER` in the generator first.

## Checked on 2026-10-28 (Xcode 27.1, no upload, no account)

```sh
xcodebuild -project MenteViva.xcodeproj -scheme MenteViva -configuration Release \
  -destination 'generic/platform=iOS' -archivePath MenteViva.xcarchive archive CODE_SIGNING_ALLOWED=NO
```

`** ARCHIVE SUCCEEDED **`: arm64, `com.igmarin.MenteViva`, 0.1.0 (1), min iOS 17.0, dSYM present, no entitlements,
`ITSAppUsesNonExemptEncryption = false` in the app's Info.plist. **Not checked** (needs the owner's paid account
and 2FA): the signed archive, `-exportArchive`, and the upload.

## Reproducible build (every upload)

1. Clean tree on `main`: `git status` prints nothing; `git pull`.
2. Bump the build: in `tools/generate_project.swift` raise `CURRENT_PROJECT_VERSION` by 1 (App Store
   Connect needs each build number unique within a `MARKETING_VERSION`; never reuse one, even after a failed upload).
   Regenerate with Xcode closed, run the checks, merge the bump as its own PR ("Build N").
3. Archive from that merge commit. Write down `git rev-parse --short HEAD`.
4. Tag it so the build can be rebuilt: `git tag testflight-0.1.0-<build> && git push origin --tags`.
5. Paste the commit hash into the build's **Test Details** ("What to Test") in App Store Connect.

## First upload (owner, once)

1. developer.apple.com → Identifiers: `com.igmarin.MenteViva` exists under the paid team (Xcode creates it on first signed build).
2. App Store Connect → **Apps → +** → New App: iOS, name Mente Viva, languages English + Spanish, that bundle ID.
3. Xcode → Product → Archive (scheme MenteViva, destination Any iOS Device, team = paid) → Organizer →
   **Distribute App → App Store Connect → Upload**.
4. Command-line equivalent: archive with `DEVELOPMENT_TEAM=<id>` (drop `CODE_SIGNING_ALLOWED=NO`) and
   `-allowProvisioningUpdates`, then `xcodebuild -exportArchive -archivePath MenteViva.xcarchive -exportPath out
   -exportOptionsPlist ExportOptions.plist` where the plist has `method` = `app-store-connect`,
   `destination` = `upload`, `teamID` = the paid id.
5. Wait for "Processing" to finish (about 10 to 30 minutes; an email arrives).

## Internal first, then external

1. **Internal**: TestFlight tab → Internal Testing → new group `Owner` → add your own App Store Connect user and devices.
   Install via the TestFlight app, play two games from Home, check Settings and My Week. No review is needed.
2. **External**: TestFlight tab → External Testing → **+** → group `Family and seniors` → add the build → fill
   **Test Information** with the notes below (both languages, if it offers a language picker) → Submit for Beta App Review.
   - Feedback email: `hello@nebulaideas.com` (Spanish: `hola@nebulaideas.com`).
   - Sign-in required: **No**. Contact first/last name, phone, email: the owner's.
   - Privacy policy / marketing URL, if asked: `https://<host>/en/privacy.html` (see the Pages steps in `install-runbook.md`).
3. Review usually takes up to a day for the first build. Later builds of the same version usually skip it.

### Beta review notes: English

```
Mente Viva is a set of short, friendly puzzle and memory games for older adults. It is a fun mental
exercise, nothing more. No account or sign-in is needed, and the app makes no network calls.

What to test: open the app, answer the short welcome questions, then play any of the games on the
Home screen. Try Settings (language English/Spanish, text size) and "My Week" after one game.
Games reward every try; there is no "wrong" screen by design.

Feedback and questions: hello@nebulaideas.com
```

### Beta review notes: Español

```
Mente Viva es un conjunto de juegos cortos y amables de memoria y rompecabezas para personas mayores.
Es un ejercicio mental divertido, nada más. No necesita cuenta ni inicio de sesión, y la app no usa la red.

Qué probar: abre la app, responde las preguntas de bienvenida y juega cualquiera de los juegos de la
pantalla de inicio. Prueba Ajustes (idioma español/inglés, tamaño del texto) y "Mi Semana" después de un juego.
Cada intento se celebra; por diseño no hay pantallas de "error".

Comentarios y preguntas: hola@nebulaideas.com
```

### "What to Test" (per build, short, both languages)

```
EN: Play two games, then open My Week. Tell us anything that was hard to see, tap or understand.
ES: Juega dos juegos y abre Mi Semana. Cuéntanos qué costó ver, tocar o entender.
```

## Inviting testers

1. TestFlight → the external group → **Add Testers** → by email, one line per person. Family first.
2. The non-family seniors of #33: add them by email too, and **sit with each one for the install**
   (10 minutes): they need an Apple ID, the free **TestFlight** app from the App Store, then tap Install on Mente Viva.
   A public link is the fallback for someone whose email is awkward: group → Public Link → send it by message.
   Anyone with the link can join, so remove it after the session. **Exception, contest period (#386):** the
   public link of the external group stays open from upload until Nov 9, 2026, so judges can install without
   an invite; remove it then.
3. Tell every tester: "It stays installed; a new version arrives through TestFlight. Don't delete the app."
4. A build expires after 90 days: upload a new one before then, or the testers are back to a dead icon.
5. Unverified: whether a game history from an older free-signed install carries into the TestFlight one
   (different team). Try one device before promising a family member their week survives; otherwise say it starts fresh.
