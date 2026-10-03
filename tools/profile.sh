#!/bin/bash
# Records a Time Profiler + Points of Interest trace of the running app on a
# simulator, then opens it in Instruments. Usage: tools/profile.sh [seconds] [simulator-udid|booted]
# Start the app first (⌘R or `xcrun simctl launch`); play for the duration.
set -euo pipefail
seconds="${1:-30}"
device="${2:-booted}"
out="${TMPDIR:-/tmp}/MenteViva-$(date +%Y%m%d-%H%M%S).trace"

# xctrace can't attach to a simulator app by name, only by pid.
pid="$(xcrun simctl spawn "$device" launchctl list | awk '/UIKitApplication:com.igmarin.MenteViva/{print $1}' | head -1)"
[ -n "$pid" ] && [ "$pid" != "-" ] || { echo "MenteViva is not running on $device" >&2; exit 1; }

xcrun xctrace record \
  --template 'Time Profiler' \
  --instrument 'Points of Interest' \
  --device "$(xcrun simctl list devices | awk -v d="$device" 'd=="booted"&&/Booted/{match($0,/[0-9A-F-]{36}/);print substr($0,RSTART,RLENGTH);exit} d!="booted"{print d;exit}')" \
  --attach "$pid" \
  --time-limit "${seconds}s" \
  --output "$out"
echo "Saved $out"
[ -n "${NO_OPEN:-}" ] || open "$out"
