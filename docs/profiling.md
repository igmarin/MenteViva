# Profiling the hot paths

No third-party tools: `os_signpost` (via `HotPath.measure`) plus Instruments.

## What is marked

| Signpost | Where | Why it can be slow |
|---|---|---|
| `plan.today` | `HomeView.refreshPlan` | 14-day fetch, then the plan |
| `photo.import` | `MemoryPhotos.add([Data?])` | one photo per call (`FamilyPhotoImport` shrinks each as it arrives), so one interval per photo the family waits on |
| `photo.downscale` | `MemoryPhotos.add` | ImageIO downsample + JPEG encode of a full photo (off the main actor) |
| `photo.caption` | `MemoryPhotos.caption` | Set up reads it per photo inside a `ForEach` body |
| `memory.deal` | `MemoryMatchView.deal` | reads the album and decodes up to 8 photos |
| `reminiscence.deal` | `ReminiscenceView.deal` | reads the album and one caption file per photo |
| `reminiscence.photo` | `ReminiscenceView` `PhotoCard` | loads one photo per card, off the main actor, on every card |
| `session.save` | `ModelContext.record` | synchronous SwiftData save after every game |
| `history.fetch` | `ModelContext.sessions(since:)` | one-shot fetch of 14 days (My Week) or 5 weeks (My progress), when the screen opens |
| `progress.weekly` | `HistoryView` | recomputed on every redraw of My Week |
| `sliding.hints` | `SlidingBlocksMap.init` | breadth-first walk of up to ~175k positions, run off the main thread when a puzzle starts |
| `progress.rates` | `MyProgressView` | recomputed on every redraw of My progress (#141) |

`HotPath.measure("name") { ... }` costs next to nothing with no profiler attached.
Add one only around work that can be slow or runs per redraw (conventions §8: no speculative code).

Memory Lane decodes every photo up front inside `memory.deal`; Remember Together decodes
one at a time, which is why it needs its own per-card signpost.

`reminiscence.photo` is the only one that covers `await`, through `HotPath.measure`'s async overload —
the suspensions are the point there, since the slow case is waiting on the photo decode.

`photo.caption` is marked for its **run count**, not its duration. Each read is well under a
millisecond; what a trace shows is how many of them one redraw of Set up costs.

## What is deliberately not marked

- **Quick Eyes** — a round is one `filter` and two `shuffled()` over 12 emoji. No I/O,
  no decode. A signpost here would measure nothing. Its save is already `session.save`.
- **Color Clash, Name the Herd, Number Trail** — same reason: arithmetic and string
  lookups only.

## Run it

1. Start the app on a simulator (⌘R). For real numbers use a device build.
2. `tools/profile.sh 30` records 30 s of Time Profiler + Points of Interest.
   Use `tools/profile.sh --launch 30` to relaunch the app under the recorder instead:
   attaching can never catch cold start, so that is the only way to see `plan.today`.
3. Play the flow you care about (add photos, finish a game, open My Week, My progress and Set up,
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

### Known misses

Both measured on an iPhone 18 Pro simulator, 2026-10-04. Neither is fixed; measure on a
device before deciding, since a simulator number is not a device number.

- **`plan.today`, ~300 ms** (299 and 302 ms on two cold starts) — there is no network
  involved. It is the gap between launch and
  Home being able to star today's games. The 14-day `FetchDescriptor`, `PlayerStateSummary`
  and the plan all run before anything is shown.
- **`reminiscence.photo`, ~120 ms on the first card** (1.3 ms on later ones — the first
  decode pays for the cold file cache). Measured while `PhotoCard` decoded on the main actor;
  it now loads through `MemoryPhotos.image(at:)` off the main actor, so the interval is a wait,
  not a stall. Re-measure on a device before removing this entry.

Measured and fine, recorded so nobody re-measures them: `photo.caption` 0.05 ms a read,
`progress.weekly` 0.30 ms median / 7.62 ms worst, `reminiscence.deal` 7.85 ms.

`photo.caption` ran **12 times for one visit** to For family, and `progress.weekly` 4 times.
Both are cheap enough not to matter today; the counts are there so it is obvious if a
future change makes either of them expensive.

**That number is not enforced in CI, on purpose.** It is a device number; CI has no device,
and shared macOS runners make simulator timings noise rather than signal. A timing gate that
flakes gets skipped, not fixed. Read it off a trace from step 2 instead.

Two things *are* enforced automatically, both deterministic: by the pre-push hook
(`.githooks/pre-push`) and again on every PR by CI (`checks.yml`, `swift.yml`; AGENTS.md
Workflow 5). Install the hook once:

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

## Measured once, no signpost (#417, 2026-10-31)

Both on an iPhone simulator on an Apple Silicon Mac, with a temporary app-hosted XCTest
(removed after). Body counts do not depend on the hardware; times are an upper bound on
speed, so scale them by about 10x for an old device.

**`fitOrScroll()` — dropped, no change.** A counting view in a `UIHostingController`, read
after layout, at the default size and at accessibility xxxLarge:

| Content | Bodies on first layout | Bodies per state change | ScrollView built |
|---|---|---|---|
| plain, no `fitOrScroll` | 1 | 1 | — |
| fits (everyday sizes) | 1 | 1 | no |
| does not fit (any size) | 2 | 2 | yes |

A re-layout without a state change evaluates no body either way. So the body doubles only
when the screen is already scrolling. The proposed fix (`ViewThatFits` only at `.xLarge`
and up) would save nothing where the screen fits and, below `.xLarge`, would cut off a
screen that does not fit a small phone, which #117 exists to prevent. Recorded and dropped.

**`AppLanguage.localized` — cached.** A `ContinuousClock` loop of 10k calls, best of 5:

| Per call | Before | After the cache |
|---|---|---|
| plain key (`game.sliding.block.small`) | 7.3 µs | 2.7 µs |
| interpolated key (`game.sliding.place.cell`) | 22.5 µs | 17.5 µs |

English and Spanish within 10% of each other. Of the 7.3 µs, finding the `.lproj` and
building its `Bundle` was 3.4 µs; `String(localized:)` itself is 1.8 µs plain, 15.4 µs
interpolated. A Sliding Blocks body redraws on every drag update (the touch is read in it)
and makes 38 to 44 lookups with 12 to 14 blocks (3 per block for its VoiceOver name, the
rest for the instruction, the guide and the buttons). That was about 0.5 ms a frame, 3% of
a 16 ms frame and some 30% at 10x, well over the 1% bar, so `lookup(in:)` keeps the bundle
and locale behind an `NSLock` and rebuilds them when the stored choice changes (#134 still
switches at once; `AppLanguageTests`). Now about 0.3 ms a frame; what is left is the
interpolated cell names, inside `String(localized:)`.
