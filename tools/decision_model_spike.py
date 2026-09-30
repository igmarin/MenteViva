#!/usr/bin/env python3
"""Re-test a Jev-compatible decision model against our real payload (docs/jev-json/011).

Sends the app's real 10-question request, then 12 synthetic players, to any server that
speaks POST /v1/systemone, and compares it with the archived Jev answer and with a Python
mirror of DailyPolicy.swift (keep the two in sync). No network beyond the URL you pass,
no secrets, no Jev calls. Results from 2026-09-30: docs/decision-model-spike-2026-09-30.md.

  python3 tools/decision_model_spike.py --url http://localhost:11434/v1/systemone --model nimble --label Nimble
  python3 tools/decision_model_spike.py --url http://127.0.0.1:8700/v1/systemone --model "" --label Laya
"""
import json, pathlib, subprocess, time, urllib.request, statistics as st, sys, os

REPO = pathlib.Path(__file__).resolve().parent.parent
import argparse
ap = argparse.ArgumentParser()
ap.add_argument("--url", default="http://localhost:11434/v1/systemone")
ap.add_argument("--model", default="nimble")
ap.add_argument("--label", default="Nimble")
ARGS = ap.parse_args()
URL = ARGS.url
LABEL = ARGS.label


def with_model(b):
    b = dict(b)
    if ARGS.model: b["model"] = ARGS.model
    else: b.pop("model", None)
    return b
GAMES = ["memory_match", "stroop", "category_fluency", "math_streaks", "quick_eyes"]
LEVELS = ["easy", "medium", "hard"]
GATE = 0.6  # app's confidence gate on difficulty scores


def git_show(path):
    return json.loads((REPO / path).read_text())


def post(body, timeout=900):
    data = json.dumps(body).encode()
    req = urllib.request.Request(URL, data=data, headers={"Content-Type": "application/json"})
    t0 = time.time()
    with urllib.request.urlopen(req, timeout=timeout) as r:
        out = json.load(r)
    return out, (time.time() - t0) * 1000


def decide(answers):
    """Same policy the app applies to Jev answers: noul desc -> top 3; score gated by confidence."""
    mix = sorted(GAMES, key=lambda g: -answers[f"include_{g}"]["noul"])[:3]
    diff = {}
    for g in GAMES:
        a = answers[f"difficulty_{g}"]
        diff[g] = "keep" if a.get("confidence", 0) < GATE else LEVELS[round(min(2, max(0, a["score"])))]
    return mix, diff


# ---- rule policy (prototype of the proposed on-device DailyPolicy)
BASE = {"memory_match": 1.0, "quick_eyes": 0.8, "category_fluency": 0.7, "stroop": 0.3, "math_streaks": 0.3}


def rule_decide(state):
    g = state["games"]
    mix = sorted(GAMES, key=lambda k: -BASE[k] * (0.5 + 0.5 * min(g[k]["daysSinceLastPlayed"], 7) / 7))[:3]
    diff = {}
    for k in GAMES:
        acc, n = g[k].get("meanAccuracy"), g[k]["sessionsLast14Days"]
        diff[k] = "keep" if (n < 1 or acc is None) else "easy" if acc < 0.65 else "hard" if (acc >= 0.9 and n >= 3) else "keep"
    return mix, diff


def gs(n, acc, rounds, days, diff=1):
    d = {"sessionsLast14Days": n, "meanRoundsCompleted": rounds, "daysSinceLastPlayed": days, "currentDifficulty": diff}
    if acc is not None:
        d["meanAccuracy"] = acc
    return d


SCENARIOS = {
    "brand-new player": {g: gs(0, None, 0, 14) for g in GAMES},
    "struggling everywhere": {g: gs(4, 0.4, 8, 2) for g in GAMES},
    "thriving everywhere": {g: gs(6, 0.95, 10, 1) for g in GAMES},
    "only memory, daily": {**{g: gs(0, None, 0, 14) for g in GAMES}, "memory_match": gs(12, 0.8, 8, 0)},
    "lapsed for 10 days": {g: gs(2, 0.75, 8, 10) for g in GAMES},
    "hard stroop only": {**{g: gs(3, 0.8, 8, 3) for g in GAMES}, "stroop": gs(5, 0.3, 10, 1)},
    "strong herd, weak math": {**{g: gs(3, 0.8, 8, 3) for g in GAMES}, "category_fluency": gs(5, 0.95, 3, 1), "math_streaks": gs(4, 0.45, 10, 2)},
    "balanced mid": {g: gs(3, 0.75, 8, 3) for g in GAMES},
    "one game avoided": {**{g: gs(5, 0.8, 8, 2) for g in GAMES}, "quick_eyes": gs(0, None, 0, 14)},
    "speedy, accurate quick eyes": {**{g: gs(3, 0.7, 8, 3) for g in GAMES}, "quick_eyes": gs(8, 0.93, 12, 0)},
    "tiny sample": {g: gs(1, 1.0, 8, 5) for g in GAMES},
    "weekly player": {g: gs(1, 0.8, 8, 7) for g in GAMES},
}


def rss_gb():
    try:
        pids = subprocess.check_output(["pgrep", "-f", "ollama|rapid-mlx"]).split()
        tot = 0
        for p in pids:
            r = subprocess.run(["ps", "-o", "rss=", "-p", p.decode()], capture_output=True, text=True).stdout.strip()
            tot += int(r or 0)
        return tot / 1048576
    except Exception:
        return float("nan")


def main():
    req = git_show("docs/jev-json/011-daily-plan.request.json")
    jev = git_show("docs/jev-json/011-daily-plan.response.json")["answers"]
    body = with_model(req)
    print(f"== [{LABEL}] Real payload (docs/jev-json/011): 10 questions")
    lat = []
    last = None
    for i in range(4):
        out, ms = post(body)
        lat.append(ms)
        last = out
        print(f"  run {i+1}: {ms:8.0f} ms {'(cold: includes model load)' if i == 0 else ''}")
    na = last["answers"]
    jm, jd = decide(jev)
    nm, nd = decide(na)
    print(f"  warm latency median {st.median(lat[1:]):.0f} ms; Ollama-reported usage: {last.get('usage')}")
    print(f"  resident memory of ollama processes: {rss_gb():.1f} GB")
    print("  Jev mix   :", jm)
    print(f"  {LABEL} mix:", nm, "| same set:", set(jm) == set(nm), "| same order:", jm == nm)
    print(f"  {'game':17} {'jev noul':>8} {'mod noul':>8} | {'jev diff':>9} {'mod diff':>9} | jev score@conf | nim score@conf")
    agree = 0
    for g in GAMES:
        jn, nn = jev[f"include_{g}"]["noul"], na[f"include_{g}"]["noul"]
        js, ns = jev[f"difficulty_{g}"], na[f"difficulty_{g}"]
        agree += jd[g] == nd[g]
        print(f"  {g:17} {jn:8.2f} {nn:8.2f} | {jd[g]:>9} {nd[g]:>9} | {js['score']:.2f}@{js['confidence']:.2f}      | {ns['score']:.2f}@{ns.get('confidence', 0):.2f}")
    print(f"  difficulty decisions identical on {agree}/5 games")
    # determinism: compare runs 2..4 answers
    print("  deterministic across runs:", all(
        json.dumps(post(body)[0]["answers"], sort_keys=True) == json.dumps(na, sort_keys=True) for _ in range(1)))

    print(f"\n== [{LABEL}] 12 synthetic players vs rule policy (no Jev calls)")
    agree_set = agree_order = agree_diff = tot_diff = 0
    flats = []
    for name, games in SCENARIOS.items():
        state = {"games": games}
        b = with_model({"state": state, "questions": req["questions"]})
        out, ms = post(b)
        a = out["answers"]
        nm, nd = decide(a)
        rm, rd = rule_decide(state)
        agree_set += set(nm) == set(rm)
        agree_order += nm == rm
        for g in GAMES:
            agree_diff += nd[g] == rd[g]
            tot_diff += 1
        nn = [a[f"include_{g}"]["noul"] for g in GAMES]
        flats.append(max(nn) - min(nn))
        print(f"  {name:28} {ms:6.0f}ms  model={[m[:4] for m in nm]} rule={[m[:4] for m in rm]}  diff model={ {g[:4]: nd[g][0] for g in GAMES} } rule={ {g[:4]: rd[g][0] for g in GAMES} }")
    n = len(SCENARIOS)
    print(f"\n  mix: same top-3 SET {agree_set}/{n}, same ORDER {agree_order}/{n}; difficulty identical {agree_diff}/{tot_diff}")
    print(f"  Model noul spread per scenario: median {st.median(flats):.2f} (Jev on the real payload: 0.19)")
    print(f"  resident memory now: {rss_gb():.1f} GB")


if __name__ == "__main__":
    main()
