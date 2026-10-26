#!/bin/bash
# Keep public copy at "exercises", never promised cognitive or medical outcomes.
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1

pattern='improve|boost|train your brain|sharpen|prevent|protect|delay|decline|dementia|alzheimer|memory loss|mejora|mejorar|potencia|entrena tu cerebro|previene|protege|retrasa|deterioro|demencia|pérdida de memoria'
files=(
    MenteViva/Localizable.xcstrings
    docs/store-listing.md
    docs/product-brief.md
    site/en
    site/es
    README.md
)

hits="$(grep -RniE "$pattern" "${files[@]}")"
status=$?
if [ "$status" -eq 0 ]; then
    printf '%s\n' "$hits"
    echo "User-facing copy contains a prohibited claim." >&2
    exit 1
fi
if [ "$status" -ne 1 ]; then
    echo "Could not check user-facing copy." >&2
    exit "$status"
fi

echo "User-facing copy contains no prohibited claims."
