# Profiling the hot paths

No third-party tools: `os_signpost` (via `HotPath.measure`) plus Instruments.

## What is marked

| Signpost | Where | Why it can be slow |
|---|---|---|
| `photo.downscale` | `MemoryPhotos.add` | decode + redraw + JPEG encode of a full photo |
| `memory.deal` | `MemoryMatchView.deal` | reads the album and decodes up to 8 photos |
| `reminiscence.deal` | `ReminiscenceView.deal` | reads the album and one caption file per photo |
| `reminiscence.photo` | `ReminiscenceView` `PhotoCard` | decodes one full photo per card, on every card |
| `session.save` | `ModelContext.record` | synchronous SwiftData save after every game |
| `progress.weekly` | `HistoryView`, `FamilyView` | recomputed on every redraw of those screens |

`HotPath.measure("name") { ... }` costs next to nothing with no profiler attached.
Add one only around work that can be slow or runs per redraw (conventions §8: no speculative code).

Memory Lane decodes every photo up front inside `memory.deal`; Remember Together decodes
one at a time, which is why it needs its own per-card signpost.

## What is deliberately not marked

- **Quick Eyes** — a round is one `filter` and two `shuffled()` over 12 emoji. No I/O,
  no decode. A signpost here would measure nothing. Its save is already `session.save`.
- **Color Clash, Name the Herd, Number Trail** — same reason: arithmetic and string
  lookups only.

## Run it

1. Start the app on a simulator (⌘R). For real numbers use a device build.
2. `tools/profile.sh 30` records 30 s of Time Profiler + Points of Interest.
3. Play the flow you care about (add photos, finish a game, open My Week and Family,
   play Remember Together past the first card).
4. The script then prints every interval it recorded against the budget and opens the trace:

   ```
   Signpost intervals, budget 100 ms:
     OVER reminiscence.photo    3 run(s)  median 1.34 ms    worst 119.95 ms
     ok   reminiscence.deal     1 run(s)  median 7.85 ms    worst 7.85 ms
   ```

   It exits non-zero when something is over, so it can gate a script. The trace is saved
   and opened either way. `swift tools/signpost_budget.swift <trace> [budget-ms]` re-reads
   an old trace without recording a new one.
5. In Instruments, the **Points of Interest** lane shows each signpost's interval; select the
   one the script flagged, then read the **Time Profiler** call tree for that time range.

If the script says no signposts were found, the recording never reached one — the lane is
empty, not fast.

## Budgets

An interval over ~100 ms on a device while someone is waiting (a tap, a card flip) is a bug.
That threshold is what `tools/profile.sh` flags; pass a different one as
`swift tools/signpost_budget.swift <trace> 50`.

**Known miss:** `reminiscence.photo` measured ~120 ms on the first card of a simulator run
(1.3 ms on later cards — the first decode pays for the cold file cache). `PhotoCard` decodes
on the main actor inside `.task`. Not yet fixed; measure it on a device before deciding.

**That number is not enforced in CI, on purpose.** It is a device number; CI has no device,
and shared macOS runners make simulator timings noise rather than signal. A timing gate that
flakes gets skipped, not fixed. Read it off a trace from step 2 instead.

Two things *are* enforced automatically, both deterministic, and both by the pre-push hook
(`.githooks/pre-push`) rather than by CI — the GitHub Actions minutes are out, so
`swift.yml` is manual-dispatch only. Install the hook once:

```
git config core.hooksPath .githooks
```

- **This page stays true.** `tools/check_signposts.sh` fails when the table above and the
  `HotPath.measure` calls in `MenteViva/` disagree in either direction. Run it before
  committing a new signpost.
- **`progress.weekly` stays linear.** `WeeklyProgressPerformanceTests` runs a year of daily
  play (2,000 sessions) through it and fails over a 2 s ceiling. Real cost is 4 ms, so the
  ceiling only trips on a superlinear rewrite — not on a slow machine. It replaced an
  `XCTest` `measure {}` block, which records timings but, with no stored baseline, could
  never fail.

Nothing automatic records a trace: profiling needs a booted simulator, the app installed,
and someone playing. `tools/profile.sh` is the whole ritual; run it by hand after a change
that touches photos, dealing, or the weekly screens.
