#!/bin/bash
# Records a Time Profiler + Points of Interest trace of the app on a simulator,
# prints every HotPath interval against the budget, then opens the trace.
#
#   tools/profile.sh [seconds] [simulator-udid|booted]
#       attaches to the running app; start it first (⌘R) and play.
#   tools/profile.sh --launch [seconds] [simulator-udid|booted]
#       relaunches the app under the recorder, so cold start is in the trace.
#       The only way to catch plan.today, which runs on Home's first appear.
set -euo pipefail
cd "$(dirname "$0")/.."
bundle="com.igmarin.MenteViva"

launch=""
if [ "${1:-}" = "--launch" ]; then
  launch=yes
  shift
fi
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

if [ -n "$launch" ]; then
  # The app has to be down, or xctrace records a launch that never happens.
  xcrun simctl terminate "$udid" "$bundle" > /dev/null 2>&1 || true
  target=(--launch "$bundle")
else
  # xctrace can't attach to a simulator app by name, only by pid.
  pid="$(xcrun simctl spawn "$udid" launchctl list | awk -v b="UIKitApplication:$bundle" '$0 ~ b {print $1}' | head -1)"
  if [ -z "$pid" ] || [ "$pid" = "-" ]; then
    echo "MenteViva is not running on $udid. Press ⌘R in Xcode, or:" >&2
    echo "  xcrun simctl launch $udid $bundle" >&2
    echo "Or record a cold start instead: tools/profile.sh --launch $seconds" >&2
    exit 1
  fi
  target=(--attach "$pid")
fi

xcrun xctrace record \
  --template 'Time Profiler' \
  --instrument 'Points of Interest' \
  --device "$udid" \
  "${target[@]}" \
  --time-limit "${seconds}s" \
  --output "$out"
echo "Saved $out"

# The trace is already on disk, so a budget miss must not cost you the trace:
# report it, still open Instruments, and only then exit non-zero.
status=0
swift tools/signpost_budget.swift "$out" || status=$?
[ -n "${NO_OPEN:-}" ] || open "$out"
exit $status
