#!/bin/bash
# Records a Time Profiler + Points of Interest trace of the running app on a
# simulator, prints every HotPath interval against the budget, then opens the
# trace in Instruments. Usage: tools/profile.sh [seconds] [simulator-udid|booted]
# Start the app first (⌘R or `xcrun simctl launch`); play for the duration.
set -euo pipefail
cd "$(dirname "$0")/.."
seconds="${1:-30}"
device="${2:-booted}"
out="${TMPDIR:-/tmp}/MenteViva-$(date +%Y%m%d-%H%M%S).trace"

# xctrace wants a UDID, so resolve "booted" once and use it for both calls.
# Checking against the booted list first is what keeps a missing or wrong
# simulator from surfacing as simctl's bare "No devices are booted."
booted="$(xcrun simctl list devices | awk '/\(Booted\)/{match($0,/[0-9A-F-]{36}/); print substr($0,RSTART,RLENGTH)}')"
if [ "$device" = booted ]; then
  udid="$(printf '%s\n' "$booted" | head -1)"
else
  udid="$device"
fi
if [ -z "$udid" ] || ! printf '%s\n' "$booted" | grep -qx "$udid"; then
  echo "No booted simulator matches '$device'. Open Simulator.app (or 'xcrun simctl boot <udid>')," >&2
  echo "then press ⌘R in Xcode to install and run MenteViva. Booted right now:" >&2
  printf '%s\n' "${booted:-  (none)}" | sed 's/^/  /' >&2
  exit 1
fi

# xctrace can't attach to a simulator app by name, only by pid.
pid="$(xcrun simctl spawn "$udid" launchctl list | awk '/UIKitApplication:com.igmarin.MenteViva/{print $1}' | head -1)"
[ -n "$pid" ] && [ "$pid" != "-" ] || {
  echo "MenteViva is not running on $udid. Press ⌘R in Xcode, or:" >&2
  echo "  xcrun simctl launch $udid com.igmarin.MenteViva" >&2
  exit 1
}

xcrun xctrace record \
  --template 'Time Profiler' \
  --instrument 'Points of Interest' \
  --device "$udid" \
  --attach "$pid" \
  --time-limit "${seconds}s" \
  --output "$out"
echo "Saved $out"

# The trace is already on disk, so a budget miss must not cost you the trace:
# report it, still open Instruments, and only then exit non-zero.
status=0
swift tools/signpost_budget.swift "$out" || status=$?
[ -n "${NO_OPEN:-}" ] || open "$out"
exit $status
