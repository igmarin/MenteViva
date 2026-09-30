# Session sheet — playtest #1 (dad)

Print this. Fill it in with a pen while he plays. Method and the one rule
("watch, don't help") live in [playtest.md](playtest.md) — this sheet is just
what to capture so the findings land on the right GitHub issues.

**Before handing over the iPad:** fresh install (onboarding visible), volume at
his level, you beside him, your phone away.

## Header

```
Date / device / iOS:
Language he picked in onboarding:   EN  /  ES
Build (git sha) / Jev on (Local.xcconfig set)?  Y / N
How long until first tap on "Let's play":
```

## Per-game cards

Play order doesn't matter — note which game he picks first and which he skips.

**Memory Lane** *(feeds #44 — it's the reminiscence anchor)*
```
Theme shown (garden/animals/fruit/vehicles):
Hesitation before first card tap (sec):
Smile / comment on the theme:
"Play again" tapped?  Y / N
```

**Color Clash** *(feeds #47 — rework / retire / cut)*
```
Wrong taps on first round:
Reaction to first wrong tap (words, face):
Said anything like "why did it do that"?  Y / N
Would he open it a second time unprompted?  Y / N
```

**Number Trail** *(feeds #47)*
```
Hesitation per question (rough avg sec):
Found the right answer button without searching?  Y / N
Reaction to a wrong answer:
Did the "best streak" line mean anything to him?  Y / N
```

**Name the Herd** *(code name: category fluency)*
```
Understood the task without asking?  Y / N
Items found before stopping:
Gave up early?  Y / N — if Y, after how many items:
```

**Quick Eyes** *(feeds #46 — untimed redesign)*
```
Said "it disappeared" / looked for the vanished emoji?  Y / N
Visible stress as the display time shrank?  Y / N
Misses in first 3 rounds:
Asked for more time?  Y / N
```

**Across games**
```
Reaction to the gentle amber outline on a miss (noticed / ignored / upset):
Color Clash: did the shape beside the word help or confuse?
Home: noticed the ⭐ "Today's pick" (only if Jev on)?  Y / N — followed it?  Y / N
```

## After ~10 minutes

```
Celebration screen: reacted to the progress line? (read it / ignored it)
My Week: opened unprompted?  Y / N — understood the summary card (days / games / streak)?  Y / N
Kept playing or handed the iPad back?  Minutes total:
Quote worth keeping:
Top 3 friction (→ comment on #6):
1.
2.
3.
```

## Where each finding goes

| Observation | Feeds |
|---|---|
| Color Clash frustration / abandonment | #47 decision |
| Quick Eyes timing stress | #46 redesign |
| Memory Lane engagement, "play again" rate | #44 scope |
| Anything that blocks a game start | new issue, fix same day if small |
| Language choice + any ES confusion | #12 review priority |
| ⭐ Today's pick: ignored / confusing / followed | Jev value (docs/jev-integration.md) |
| My Week card: understood or not | caregiver summary value (#71 shipped) |
