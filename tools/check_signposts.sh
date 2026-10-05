#!/bin/bash
# Fails when docs/profiling.md and the HotPath.measure calls in MenteViva/
# disagree, in either direction. A signpost nobody documented is a signpost
# nobody reads; a documented one that no longer exists sends you hunting.
# Timings are NOT checked here — see the Budgets section of docs/profiling.md.
set -euo pipefail
cd "$(dirname "$0")/.."

in_code="$(grep -rhoE 'HotPath\.measure\("[^"]+"' MenteViva | sed -E 's/.*"(.*)"/\1/' | sort -u)"
in_docs="$(grep -oE '^\| `[^`]+`' docs/profiling.md | tr -d '|` ' | sort -u)"

if diff <(echo "$in_code") <(echo "$in_docs") > /dev/null; then
  echo "Signposts and docs/profiling.md agree ($(echo "$in_code" | wc -l | tr -d ' ') signposts)."
  exit 0
fi

echo "docs/profiling.md does not match the HotPath.measure calls in MenteViva/." >&2
comm -23 <(echo "$in_code") <(echo "$in_docs") | sed 's/^/  in code, missing from the doc table: /' >&2
comm -13 <(echo "$in_code") <(echo "$in_docs") | sed 's/^/  in the doc table, no longer in code: /' >&2
exit 1
