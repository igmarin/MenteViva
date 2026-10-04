# Privacy policy — draft (#34)

Plain language, for players and their families. Host this verbatim once a
public URL exists; the App Store "App Privacy" label must match it.
Spanish translation lands when hosted (docs/README rule 5).

---

**Mente Viva — Privacy Policy**
Last updated: 2026-10-01

**The short version:** Mente Viva collects nothing about you. No account, no
name, no email, no ads, no tracking. Your games stay on your device.

**What is stored, and where.** Your game sessions (which games you played,
how rounds went, how long they took) are stored only on your iPhone or iPad,
in the app's private storage. We never see them. They are not synced anywhere.
Deleting the app deletes them completely.

**Photos for Memory Lane.** If you add photos for Memory Lane, you pick them
with Apple's photo picker, which gives the app only the photos you choose — no
access to the rest of your library. The app keeps a small copy of each in its
private storage on this device, never uploads or shares them, and deletes the
copy when you tap Remove (or delete the app).

**Names on photos.** For each Memory Lane photo you can type a name or a few
words (a person, a nickname, a place, an event). It is stored next to the photo,
in the app's private storage on this device, and nowhere else: it is never
uploaded, never part of a share, and never sent to any service. Removing the
photo removes its name. Optionally the app can read a name aloud using your
device's built-in voice; that happens on the device.

**What leaves the device: normally, nothing.** The app works fully offline, and
its daily game suggestion is worked out on your device. There is one optional
variant of that suggestion that, *only if it is turned on in a given build*, sends a small summary to our suggestion service:
counts and averages only (for example "played 4 sessions this fortnight,
average accuracy 0.8"), per game. It contains no name, no device ID, no dates,
no location — nothing that identifies you. The summary goes through our proxy
to the suggestion provider (TypeSafe AI, api.typesafe.ai), which answers the
suggestion. Current builds ship
with this feature **off**; when off, the app makes no network requests at all.

**Sharing is your choice.** The "share your week" button uses the standard
iOS share sheet — something leaves your device only when you choose to send
it, to people you choose.

**No third-party SDKs.** The app contains no advertising, analytics, or
tracking libraries of any kind.

**Children.** Mente Viva is designed for older adults and is not directed at
children. We collect no age information from anyone.

**Changes.** If this policy changes, the new version replaces this one at the
same address, with the date updated above.

**Contact.** Questions or requests: **[TODO-owner: support email before
hosting]**. We answer in English or Spanish.

---

## Notes for us (not part of the published page)

- Matches the App Privacy label draft in [store-listing.md](store-listing.md):
  **Data Not Collected** while the proxy is off; re-audit if it ships on.
- Code facts backing every sentence: `PlayerStateSummary` in
  `Services/JevService.swift` is the entire outgoing payload (counts/ratios,
  no identifiers, no dates); `proxyURL == nil` ⇒ zero network calls; SwiftData
  store is app-local; no third-party dependencies exist in the project.
- **Default builds (Jev off, #101):** today's picks are computed on the device and the app makes
  no network request, so **Data Not Collected** holds with no caveats.
- **Before any build turns the optional Jev backend on:** the proxy rate-limits by client IP
  (`proxy/worker.js`), so Cloudflare sees the device IP on each daily request even though we store
  nothing and the payload has no identifiers. Decide with Apple's App Privacy definitions whether
  the label still holds, and add one plain sentence about the IP to the published text above.
  In-app `settings.privacy.body` already says "only anonymous totals leave"; the payload also
  carries each game's current difficulty and days since last play (numbers, not dates).
- Hosting: the repo is private and GitHub Pages on private repos needs a paid
  plan, so use a tiny public policy repo or Cloudflare Pages (decisions
  2026-09-20). Then link it in-app (Settings) and in App Store Connect — that
  closes #34.
