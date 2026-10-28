#!/bin/bash
# The site/ pages are served as they are (Cloudflare Pages, no build step), so what is in the repo
# is what is published. Fails on a placeholder or TODO, and on a support address on the wrong
# language's pages (#188, #34).
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1

if grep -rnE 'SUPPORT_EMAIL|TODO' site; then
    echo "Placeholder left in site/." >&2
    exit 1
fi
for lang in en:hello es:hola; do
    dir="site/${lang%%:*}"
    want="${lang##*:}@nebulaideas.com"
    # Every address on these pages must be the one for the page's language.
    if grep -rhoE '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+' "$dir" | grep -vxF "$want"; then
        echo "$dir must only mention $want." >&2
        exit 1
    fi
    if ! grep -rq "mailto:$want" "$dir"; then
        echo "$dir has no mailto:$want link." >&2
        exit 1
    fi
done
echo "Site pages have no placeholders and the right support address."
