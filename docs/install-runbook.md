# Install runbook (free Apple ID, no paid account)

For the current bootstrapping phase: **no TestFlight, no App Store, no CloudKit.**
Every install is a signed build from this Mac, and it expires 7 days later.

Team: Ismael Marin Cabrera (Personal Team), `VB42T7NYX2` — already pre-filled by
the generator, so Xcode never asks.

## Install (or re-install) on a device

```sh
cd <path-to-your-MenteViva-checkout>
swift tools/generate_project.swift               # local-only is the default
open MenteViva.xcodeproj
```

In Xcode:

1. Connect the device, unlock it, tap **Trust This Computer**.
2. Select the device as the run destination.
3. **⌘R**.

On the device, first install only:

4. **Settings → General → VPN & Device Management → Developer App → Trust**.

Command-line alternative (device already trusted and connected):

```sh
DEV=$(xcrun devicectl list devices | awk '/available/ {print $NF; exit}')
xcrun devicectl device install app --device "$DEV" \
  ~/Library/Developer/Xcode/DerivedData/MenteViva-*/Build/Products/Debug-iphoneos/MenteViva.app
```

## The 7-day expiry

A free-account build **stops launching 7 days after it was signed**. Re-sign
the day before any playtest rather than trusting an old install.

- Renewal = repeat the install steps with the device connected. Two minutes.
- The app's data (sessions, settings) survives renewal. **Deleting the app does
  not:** it erases My Week and all progress (#106). Never delete to "fix" an
  expired install — renew it.
- Renewal stops the running app. Since #106 every finished game is saved the
  moment it ends, so a renewal right after a game loses nothing.
- The app icon stays on the home screen but taps do nothing until renewed; the
  iOS error is "Unable to Verify App".

## When signing refuses

| Symptom | Fix |
|---|---|
| "Maximum number of apps for free development profiles has been reached" | Delete *other* unused apps installed from Xcode on that device (each device allows 3 at a time) — not MenteViva, which would erase its history |
| "The device is not registered" / provisioning fails | Xcode → Settings → Accounts → select the team → **Manage Certificates / Download Manual Profiles**; then ⌘R again |
| Bundle ID taken by another team | Change `PRODUCT_BUNDLE_IDENTIFIER` in `tools/generate_project.swift` to something unique |
| Build installs but immediately closes | Check `~/Library/Logs/DiagnosticReports/` for the crash log, or Xcode → Window → Devices → View Device Logs |

## What cannot work in this mode (don't fight it)

- **TestFlight** — needs the paid program.
- **CloudKit / family sharing / push** — need the iCloud entitlement; the app
  falls back to an on-device store (see `MenteVivaApp.swift`, `LOCAL_ONLY`).
- **Installs lasting longer than a week.**
- **Remote testers** — they must bring the device to this Mac.

## CloudKit later

```sh
swift tools/generate_project.swift --cloudkit   # only with the paid account + container
```
