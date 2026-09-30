# Playtest protocol

For #6 (family playtest) and #33 (non-family seniors). Same method for both —
the only difference is who is holding the iPad. For the #6 session itself,
print [playtest-session-1.md](playtest-session-1.md): it maps each observation
to the issue it unblocks (#44, #46, #47).

## The one rule

**Watch, don't help.** The moment you point at the screen, lean over, or say
"tap the puzzle thing", you've taught us what *you* know, not what the app
communicates. If he's stuck for 30 seconds, that's a finding. Write it down and
let him keep struggling a little — or hand him the device fresh later.

## Setup

- Real iPad, real lighting, volume at his normal level.
- App freshly installed: **onboarding shows on first launch only.** If he's
  already passed it, delete and reinstall to see his genuine first reaction.
- You sit beside, not across. Phone away.

## Watch for (in order of what we most need to know)

1. **First 30 seconds on onboarding** — does he read the lines? Does he find the
   language choice? Which language does he pick?
2. **The "Let's play" moment** — does he tap it without asking? If he asks "what
   do I do?", that's the most important finding of the session.
3. **Per game, first round only** — where does he hesitate, what does he tap
   first, does he look for instructions?
4. **When he gets one wrong** — reaction. Frustration? Amusement? Does he try
   again or stall? (Copy check: does the app feel kind?)
5. **End of a game** — does the celebration mean anything to him? Does he tap
   "Play again" or go home?
6. **My Week** — does he open it unprompted? Does he understand it?
7. **After 10 minutes** — put your phone away and just watch. Does he keep
   going? Did he ask a question nobody answered?

## Record

```
Date / who (relation, age, language, device, iOS):
Onboarding reaction:
Stuck where / how long:
Games played, in order:
Wrong-answer reaction:
Celebration: noticed / ignored
My Week: opened / ignored
Questions he asked:
Lasted (minutes) / came back later?:
Quote worth keeping:
Top 3 friction:
```

Top 3 friction goes into the issue. If a fix is obvious and small, fix it the
same day; if it needs a design decision, it becomes its own issue.

## Install logistics (free-account builds)

Until the paid Developer Program is bought, every build installed on a device
**stops launching after 7 days**. That shapes how to run a session:

- **Plan sessions to fit inside a week.** Install, test within a few days, done.
  Don't promise a tester "keep it and use it for a month".
- **Re-sign weekly** when the same person is testing long-term: reconnect the
  device to the Mac and ⌘R again. Two minutes, but it needs the device present.
- **Bring the device to the Mac** (or the Mac to the device) — free accounts
  can't invite testers remotely. TestFlight needs the paid account.
- Free provisioning also caps how many apps/devices can be signed at once, so
  keep the device list short and remove stale ones in Xcode → Settings →
  Accounts → Manage Certificates/Devices.
- **Local-only builds are the default**: no CloudKit entitlement,
  so a free Apple ID can provision them. Store data stays on that iPad.

## Results

No session has been recorded in the repo yet (#6 and #33 are open). After each
session, paste the Record block above into the issue and add a dated section
here with the top 3 friction.

## What counts as success

- **#6 (dad):** he plays twice in one week without being asked (docs/mvp.md G1b).
- **#33 (strangers):** they start a game without help and understand what the
  app is for afterwards.
