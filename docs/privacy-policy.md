# Privacy policy (#34)

Plain language, for players and their families. The published copy is
`site/en/privacy.html` (Spanish: `site/es/privacy.html`, #34); keep all three in step when the
policy changes. The App Store "App Privacy" label must match it.

---

**Mente Viva — Privacy Policy**
Last updated: 2026-10-23

**The short version:** Mente Viva does not receive your personal data. No account,
no ads, no tracking. Your games, your photos and any names you add stay on your device.

**What is stored, and where.** Your game sessions (which games you played,
how rounds went, how long they took) are stored only on your iPhone or iPad,
in the app's private storage. We never see them. They are not synced anywhere.
Deleting the app removes them from your device; a backup of your device that you made earlier may still hold a copy, which belongs to you and which you control in Apple's Settings.

**Photos for Memory Lane.** If you add photos for Memory Lane, you pick them
with Apple's photo picker, which gives the app only the photos you choose — no
access to the rest of your library. The app keeps a small copy of each in its
private storage on this device, never uploads or shares them, and deletes the
copy when you tap Remove (or delete the app).

**Names on photos.** For each Memory Lane photo you can type a name or a few
words (a person, a nickname, a place, an event). It is stored next to the photo,
in the app's private storage on this device, and nowhere else: it is never
uploaded, never part of a share, and never sent to any service. Removing the
photo removes its name. Like everything an app keeps on your device, photos and
names may be included in your own iPhone or iPad backup (for example iCloud
Backup), which belongs to you and which you control in Apple's Settings. Optionally the app can read a name aloud using your
device's built-in voice; that happens on the device.

**What leaves the device: nothing.** The app works fully offline, and its daily game
suggestion is worked out on your device. The app makes no network requests at all.

**Sharing is your choice.** The "share your week" button uses the standard
iOS share sheet — something leaves your device only when you choose to send
it, to people you choose.

**No third-party SDKs.** The app contains no advertising, analytics, or
tracking libraries of any kind.

**Children.** Mente Viva is designed for older adults and is not directed at
children. We collect no age information from anyone.

**Changes.** If this policy changes, the new version replaces this one at the
same address, with the date updated above.

**Contact.** Questions or requests: **the support email** (`site/` takes it as a
build argument, `tools/build_site.sh`). We answer in English or Spanish.

---

## Notes for us (not part of the published page)

- **Backups (PR #144 review):** photos and captions live in Application Support, which iOS
  backs up by default. We chose to say so in the policy and the in-app text instead of excluding the
  folder, because exclusion would lose the family's typed names whenever a phone is restored. Our
  reading is that a user's own device backup is not data *we* collect, so the label stays Data Not
  Collected; re-check that against Apple's definitions before the App Store submission (#37).
  To switch: set `isExcludedFromBackup` on `MemoryPhotos.folder` and drop the backup sentences.

- Matches the App Privacy label draft in [store-listing.md](store-listing.md): **Data Not Collected**.
- Code facts backing every sentence: the app makes no network request (decisions.md 2026-10-26,
  #195); today's picks are computed on the device by `DailyPolicy`; SwiftData store is app-local;
  no third-party dependencies exist in the project.
- Hosting: the repo is private and GitHub Pages on private repos needs a paid
  plan, so use a tiny public policy repo or Cloudflare Pages (decisions
  2026-09-20). Then link it in-app (Settings) and in App Store Connect — that
  closes #34.
