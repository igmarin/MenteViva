# Outside playtest kit (#33)

Print this. It is for testers outside the family: dad is not a big enough
sample for an app that is meant to be sold. The method and the one rule
("watch, don't help") are in [playtest.md](playtest.md).

**Who:** 5 or more people, 65+, not family (target raised from 3 on #33).
At least one should speak only Spanish.
**Install:** in person from the Mac, inside the 7-day free-signing window
([install-runbook.md](install-runbook.md)). Once TestFlight works (#229),
send them a TestFlight invite instead.
**Success:** they start a game without help, and afterwards they can say
what the app is for ([playtest.md](playtest.md#what-counts-as-success)).

## 1. Invite (send as a text, or say it out loud)

**EN:**
> Hi! I'm testing a small iPhone and iPad app of calm games: memory, words,
> numbers and shapes, with big buttons and no timer. Could I watch you try it
> for about 20 minutes? I'll install it on your device, or you can use mine.
> I only take notes on what you tap and what's unclear, never your name. You
> can stop at any moment, and there's nothing to buy or sign up for. Your
> honest reaction is the most useful thing, especially when something is
> confusing. Thank you!

**ES:**
> ¡Hola! Estoy probando una pequeña app de juegos tranquilos para iPhone y
> iPad: memoria, palabras, números y formas, con botones grandes y sin reloj.
> ¿Me deja verla probarla unos 20 minutos? Se la instalo en su equipo, o puede
> usar el mío. Solo anoto lo que toca y lo que no se entiende, nunca su nombre.
> Puede parar cuando quiera, y no hay nada que comprar ni registrar. Lo que más
> me ayuda es su reacción sincera, sobre todo cuando algo confunde. ¡Gracias!

## 2. Before you hand it over

1. **Say it out loud:** "I'm testing the app, not you. If something is
   confusing, that's the app's fault. You can stop whenever you like."
2. **Give them a code (T1, T2, …).** Write the name only on your paper copy.
   The repo is public: names, ages, health details and photos of testers never
   go in it (decisions.md 2026-10-27).
3. **Fresh install,** so onboarding shows. The language follows the device;
   don't change it for them.
4. Volume at their level, you beside them, your phone away. Put the device
   down on the first screen and say nothing.

## 3. Session sheet (one per tester)

```
Code / date:                         T__ / ____-__-__
Device / iOS / build (git sha):
Language on screen:                  EN  /  ES      Speaks only Spanish?  Y / N
Uses a smartphone or tablet daily?   Y / N

FIRST 5 MINUTES, NO HELP (the point of this session)
Seconds until first tap:             What they tapped first:
Read the onboarding lines?           Y / N
Found "Let's play" without asking?   Y / N    If they asked, their words:
First game they opened:
Understood how to play it alone?     Y / N    Seconds:
Asked "what do I do?" anywhere?      Y / N    Where:

WHERE THEY HESITATED (>5 s still, or a tap that did nothing)
Screen / what they tried / seconds:
1.
2.
3.

WHAT THEY MISREAD (a word, icon, colour or card taken for something else)
1.
2.

WHEN A MOVE DIDN'T FIT ("Almost…")
Tried again / stopped / laughed / frowned:
Their words:

AFTER ~20 MINUTES
Games played, in order:
Which one did they choose by themselves?
In their own words, what is this app for?
Would they open it tomorrow without being asked?   Y / N   Why:
Quote worth keeping:
```

## 4. Day 2 (a text or a call, two questions)

```
Opened it again without a reminder?   Y / N      Which game first?
Anything that annoyed them, now they've slept on it?
```

## 5. Findings: one block per friction point, after every session

Write the top 3. Each one becomes a GitHub issue: copy the title line as it is.

```
Title: <Game or screen>: <what went wrong, in the tester's terms>
Seen by: T__ (and T__)          Language: EN / ES
What happened: <one sentence of what they did, not what we think>
Seconds lost / gave up?:
Smallest fix we can think of:
```

Example: `Title: Sudoku: first-time players don't see that a number goes into the chosen square`

After all the sessions, add a dated section with the top 3 overall to
[playtest.md](playtest.md#results), and comment the issue numbers on #33.

## Where each finding goes

| Observation | Feeds |
|---|---|
| Needed help to start, or asked "what do I do?" | onboarding / Home: a new issue, top priority |
| Didn't understand a game alone | an issue for that game; a small fix ships the same week |
| Misread a word in Spanish | the native-speaker review (#12) |
| Couldn't say what the app is for | store copy and onboarding (store-listing.md) |
| Opened it again on day 2 without a reminder | the success line above; count it for the v1.0 decision (#194) |
