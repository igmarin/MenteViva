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

curl -sS --fail-with-body https://api.typesafe.ai/v1/systemone \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $TYPESAFE_API_KEY" \
    --data-binary "@$request" -o "$response"
echo "Saved $response"
