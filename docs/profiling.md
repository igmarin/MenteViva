# Profiling the hot paths

No third-party tools: `os_signpost` (via `HotPath.measure`) plus Instruments.

## What is marked

| Signpost | Where | Why it can be slow |
|---|---|---|
| `photo.downscale` | `MemoryPhotos.add` | decode + redraw + JPEG encode of a full photo |
| `memory.deal` | `MemoryMatchView.deal` | reads the album and decodes up to 8 photos |
| `session.save` | `ModelContext.record` | synchronous SwiftData save after every game |
| `progress.weekly` | `HistoryView`, `FamilyView` | recomputed on every redraw of those screens |

`HotPath.measure("name") { ... }` costs next to nothing with no profiler attached.
Add one only around work that can be slow or runs per redraw (conventions §8: no speculative code).

## Run it

1. Start the app on a simulator (⌘R). For real numbers use a device build.
2. `tools/profile.sh 30` records 30 s of Time Profiler + Points of Interest and opens Instruments.
3. Play the flow you care about (add photos, finish a game, open My Week and Family).
4. In Instruments, the **Points of Interest** lane shows each signpost's interval; select it, then
   read the **Time Profiler** call tree for that time range.

## Budgets

An interval over ~100 ms on a device while someone is waiting (a tap, a card flip) is a bug.
Check `docs/conventions.md` before adding a budget here; none are enforced in CI.
