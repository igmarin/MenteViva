# Session sheet — playtest #3 (dad, the three new games)

Print this. Fill it in with a pen while he plays. Method and the one rule
("watch, don't help") live in [playtest.md](playtest.md). This session checks
whether the new games fix "he gets bored": Sudoku (#179), Up or Down (#180) and
Finish the Saying (#181). Why these three: decisions.md 2026-10-19.

## Before handing over the iPad

1. **Install over the old build, never delete it.** Deleting erases his week and
   progress. Re-sign with ⌘R as in [install-runbook.md](install-runbook.md); the
   build only runs for 7 days, so check the date on the sheet header.
2. **Open each new game yourself once, first.** His iPad is on iOS 17.7, and the
   new games have only run on newer simulators. A freeze, a blank screen or a
   board that doesn't fit is a bug to fix before the session, not a finding.
   *(Open Set up → pin a level if you want to see all three levels.)*
3. **Make sure Home will deal them.** Set up must not hide the new games. Today's
   three are picked from all visible games, so a new game may not appear on a
   given day; if none of the three shows up, open them from "All games" and note it.
4. Volume at his level, you beside him, your phone away. Put the iPad down on
   Home and say nothing.

## Header

```
Date / device / iOS:                       iPad Viejita / 17.7
Build (git sha):
Language on screen:                        EN  /  ES
Which of the three did Home deal today?    Sudoku / Up or Down / Sayings / none
Seconds until his first tap:
What he tapped first:
```

## Sudoku

```
Did he know what it was, unprompted? ("sudoku")         Y / N
Level shown:  4x4 easy / 4x4 medium / 6x6 hard
Understood "tap a square, then a number" without help?   Y / N   Seconds:
Used "Show me one"?  Y / N        Asked for it by name?  Y / N
When a number didn't fit ("Almost — try another number"):
  Tried another number, or froze?                        tried / froze
  Reaction (words, face):
Could he see the 2x2 / 2x3 boxes (the shaded blocks)?    Y / N
Finished the board?  Y / N        Minutes:
Wanted another board right away?                         Y / N
```

## Up or Down

```
Did he know the game from cards he played before?       Y / N   Which one:
Understood "one higher or one lower" without help?       Y / N   Seconds:
Read every card (rank and suit) from his distance?       Y / N
  Mixed up red / black, or the small suit symbols?       Y / N
Tapped a card that didn't fit ("Almost — it needs…")?    Y / N   Reaction:
Found the deck pile when no card fit?                    Y / N
  Turned the deck while a card still fit (allowed)?      Y / N
Did the King-Ace wrap confuse him (easy / medium)?       Y / N
Ended on: cleared the table / ran out of cards
  Reaction to "You cleared N cards" (no "you lost"):
```

## Finish the Saying

```
Did the saying ring a bell right away?                   Y / N
Said the ending out loud before choosing?                Y / N
Read the long endings without leaning in?                Y / N
Wrong ending (dims, "Almost — try again"):
  Kept choosing, or got stuck?                           kept / stuck
Used the speaker button on the full saying?              Y / N
Sayings he knew:                                         (write 2–3)
Sayings that felt odd, old-fashioned or unknown:
Anything that sounded sad or about age, memory or illness?  Y / N   (must be N)
Which language did he get them in?                       EN / ES
```

## After ~15 minutes (the point of this session)

```
Played all three?  Y / N    Minutes total:
Which did he pick by himself next? (not told)
Which did he ask to play again?
Which did he leave first, and what did he say?
Did it still feel "the same as yesterday"?               Y / N   His words:
Top 3 friction (→ comment on #6):
1.
2.
3.
Quote worth keeping:
```

## Later this week (the roadmap's exit test)

```
Opened the app on his own, no prompt?       day 1: Y / N    day 2: Y / N
Which game did he start with?
```

## Where each finding goes

| Observation | Feeds |
|---|---|
| Froze, blank screen or wrong layout on iOS 17.7 | fix first; there is no iOS 17 simulator, so reproduce on the iPad |
| Needed help with how to play, or a hint he didn't find | a new issue for that game; small fixes the same day |
| Hard Sudoku too hard (6x6), or he stopped at the first miss | tell me; Jev 016's open question (`jev-json/016`), decisions.md 2026-10-19 |
| Cards misread (suits, red/black) | card face size and colour (Up or Down, #180) |
| A saying he didn't know, or one that landed badly | edit that saying slot; Spanish ones go to the native review (#12) |
| He picked a new game by himself twice in a week | roadmap exit criteria (mvp.md G1b) |
| He still said "same as yesterday" | variety is not solved: ask what he wants more of, then score the next idea with Jev before building (decisions.md 2026-10-19) |
