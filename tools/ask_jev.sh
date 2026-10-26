#!/bin/sh
# Sends an archived Jev request and saves the reply next to it (docs/jev-json/README.md).
# Usage: TYPESAFE_API_KEY=... tools/ask_jev.sh docs/jev-json/020-v03-direction.request.json
# The key comes from the shell only; it is never written anywhere.
set -eu

request="${1:?usage: tools/ask_jev.sh docs/jev-json/NNN-slug.request.json}"
: "${TYPESAFE_API_KEY:?set TYPESAFE_API_KEY in your shell}"
response="${request%.request.json}.response.json"

if [ -e "$response" ]; then
    echo "$response already exists; numbers are never reused, ask again under a new number." >&2
    exit 1
fi

# Download to a private temp file, then claim the final name atomically: `ln` fails if it
# exists, so concurrent runs can't overwrite each other and a cut-off transfer leaves nothing.
tmp="$(mktemp "$response.XXXXXX")"
trap 'rm -f "$tmp"' EXIT
# The key goes to curl on stdin (-K -), not argv, so it never shows in process listings.
printf 'header = "Authorization: Bearer %s"\n' "$TYPESAFE_API_KEY" |
    curl -sS --fail-with-body https://api.typesafe.ai/v1/systemone -K - \
        -H "Content-Type: application/json" \
        --data-binary "@$request" -o "$tmp"
if ! ln "$tmp" "$response" 2>/dev/null; then
    echo "$response appeared meanwhile; numbers are never reused." >&2
    exit 1
fi
echo "Saved $response"
