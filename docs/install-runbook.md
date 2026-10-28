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

A free-account build **stops launching when its provisioning profile expires**,
7 days after the *profile* was created, not after the build was signed. Xcode
reuses a cached profile until it expires, so a fresh build can have only a day
or two left (2026-10-13: signed that day, profile from Oct 8, expiring Oct 15).
Re-sign the day before any playtest, then check the date:

```sh
APP=$(ls -dt ~/Library/Developer/Xcode/DerivedData/MenteViva-*/Build/Products/Debug-iphoneos/MenteViva.app | head -1)
security cms -D -i "$APP/embedded.mobileprovision" | plutil -extract ExpirationDate raw -
```

The date is in UTC. Fewer than 6 days left? Move the cached profile out of
`~/Library/Developer/Xcode/UserData/Provisioning Profiles/` and build again;
Xcode makes a new 7-day one. The file to move is `<UUID>.mobileprovision`, where
`<UUID>` is the same command with `UUID` in place of `ExpirationDate`.

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

## Privacy and support pages (Cloudflare Pages, #34)

The pages are plain files in `site/`; nothing to build. `tools/check_site.sh` guards them (pre-push, CI).
The live URL does not exist until the owner does this, once:

1. Cloudflare dashboard → **Workers & Pages** → **Create** → **Pages** → **Connect to Git** → pick
   `igmarin/menteviva` (grant the Cloudflare GitHub app access to that repo if asked).
2. Project name `menteviva` (gives `menteviva.pages.dev`; take another if it is used).
   Production branch `main`. Framework preset **None**. Build command: empty. Build output directory:
   `site`. **Save and Deploy**.
3. OWNER TODO, domain: project → **Custom domains** → **Set up a custom domain** → enter the
   subdomain (e.g. `menteviva.<your domain>`) → follow the DNS step. Optional: `.pages.dev` works.
4. Open `https://<host>/en/privacy.html` and `/es/privacy.html` in a browser and check both load.
5. App Store Connect → the app → **App Information** → **Privacy Policy URL**: `https://<host>/en/privacy.html`.
   **Support URL** (version page): `https://<host>/en/support.html`. For the Spanish localization use
   the `/es/` pages.
6. Then, and only then, a ticket adds the link in Settings with the same URL.

Pushes to `main` redeploy; PR branches get preview URLs.

## CloudKit later

```sh
swift tools/generate_project.swift --cloudkit   # only with the paid account + container
```
