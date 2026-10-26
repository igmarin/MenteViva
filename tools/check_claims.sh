#!/bin/bash
# Fails when a user-facing file says the app improves, boosts, prevents or
# treats anything (EN and ES). The rule is "a game exercises memory or
# attention; copy never says it improves them" (decisions.md 2026-10-26,
# conventions §5). Matching is a case-insensitive substring match, so a word
# that merely contains a banned one (e.g. "prevention") is also a hit: rephrase
# it. Code comments are not scanned; only what a stranger can read.
set -euo pipefail
cd "$(dirname "$0")/.."

banned='improv|boost|train your brain|sharpen|prevent|protect|delay|declin|dementia|alzheimer|memory loss|mejora|mejorar|entrena tu cerebro|previene|protege|retrasa|deterioro|demencia|p[eé]rdida de memoria|potencia\b'

files=(MenteViva/Localizable.xcstrings README.md docs/store-listing.md docs/product-brief.md site/en site/es)

if hits="$(grep -rniE "$banned" "${files[@]}")"; then
    echo "Banned claim words in user-facing copy (rephrase as 'exercises'):"
    echo "$hits"
    exit 1
fi
echo "No banned claim words in user-facing copy."
