# Decision-model spike — can an open model replace Jev? (2026-09-30)

**Question:** the owner wants to avoid per-call charges. Can Nimble (Bespoke Labs) or Laya
replace TypeSafe Jev for the app's daily plan, and for the dev-time classifier?

**Answer:** not for the app. The app now decides by rules on the device
(`DailyPolicy`, decisions.md 2026-09-30). The dev-time classifier stays on TypeSafe Jev (owner
decision, #103). Nothing here is medical or health evidence; it is engineering evidence.

## What was tested

| | Nimble | Laya |
|---|---|---|
| Model | Bespoke-Nimble-9B, fine-tuned Qwen3.5-9B; weights Apache-2.0 (Hugging Face card); GitHub repo has no LICENSE file | `convaiinnovations/laya`, ~0.4B encoder, Apache-2.0 |
| Served by | Ollama 0.35.0, `nimble:latest` (9.5 GB, probably 8-bit: inferred from size) | Rapid-MLX 0.15.3 `system-one` (laya-mlx 0.2.0) |
| API | `/v1/systemone`, same `choice`/`noul`/`score` shapes as Jev, `confidence` on choice and score | same |
| Age | repo created 2026-09-18 ("we built Nimble in one day, so expect some rough edges") | repo created 2026-09-18 |

Machine: MacBook Pro M1 Pro, **16 GB RAM**. Inputs: the app's real 10-question request
(`docs/jev-json/011`, state is a sample fixture) and 12 synthetic players (new, struggling,
thriving, lapsed, one-game-only, …). No Jev calls were made for the comparison; Jev's answer is
the archived one.

## Results

| | Nimble 9B | Laya ~0.4B |
|---|---|---|
| Cold start | 15.5 s (the app gives up at 10 s) | 3.1 s |
| 10 questions, warm | 2.6 s (repeated request) to ~7.3 s (new state) | 0.58 s |
| Memory | 8.3–8.7 GB resident, 100% GPU; host reached 6.6 of 7.2 GB swap with 1.1 GB free RAM | ~0.8 GB of model files |
| Deterministic | yes | yes |
| Reacts to player data | partly: singles out an outlier game, ignores overall accuracy | no: same picks for "struggling" and "thriving"; difficulty confidence 0.02–0.03 (≈ uniform) |
| vs Jev on the real payload | difficulty decisions identical on 1/5 games; mix overlap 1/3 (Number Trail 0.99, Memory Lane 0.07) | mix differs; difficulty always "keep" |
| vs the rule policy (12 scenarios) | same top-3 set 0/12; difficulty identical 17/60 | same set 2/12; identical 46/60 (both mostly "keep") |

Dev-time classifier (`task-complexity-classifier`) pointed at local Nimble with env vars and a
config file only: 5/5 sample tasks sensible (3 routine p 0.94–0.98; 2 complex p 0.55–0.71, which
the skill's 0.8 threshold turned into the safe `complex` fallback), 1.1–1.5 s per call. Works, but
needs ~9 GB resident; kept on Jev (#103).

## Reading it

- These questions have **no ground truth**. Both models follow the literal criteria text (Nimble:
  "rested too long → include" put an abandoned, low-value game first). Accuracy benchmarks do not
  measure this task.
- Vendor benchmarks are the authors' own and were measured on the **unquantized** weights: Nimble
  74.8% vs Jev 76.0% macro over 13 public human-labeled datasets (Yes/no questions 80.2% vs
  84.6%, rubric scores Nimble ahead); probabilities less well calibrated. The 9.5 GB Ollama build
  is not what they benchmarked.
- Nimble's difficulty `confidence` was 0.18–0.47, so our 0.6 gate would block nearly every change;
  its README says thresholds must be re-tuned on your own data.
- Hosting for free means an always-on machine. The owner's 16 GB laptop swaps with Nimble loaded,
  and Ollama has no authentication (it must never be exposed directly). A hosted GPU brings the
  charges back. Bespoke's free public demo sleeps after 2 minutes and needs ~3 minutes to wake.

## Caveats

One machine under memory pressure (latencies inflated); the rule policy is a judgment, not a
validated baseline; 12 synthetic players are illustrative; Laya and Nimble are both ~12 days old.

## Re-running

`tools/decision_model_spike.py` sends the same payload and scenarios to any `/v1/systemone`
server (usage in its docstring) and prints the comparison. The tooling used here (Ollama, the
models, a temporary Rapid-MLX venv) was removed afterwards; Rapid-MLX turns anonymous telemetry on
by default (`DO_NOT_TRACK=1` to disable).
