#!/bin/bash
# Builds the privacy + support pages (site/) into site-out/, ready to upload to any
# free static host (a public repo's GitHub Pages, Cloudflare Pages). The support
# address is not in the repo: pass it in. Refuses to build without one, so a page
# with a placeholder can never be published.
#   tools/build_site.sh you@example.com
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

email="${1:-}"
# A strict allowlist: no character here means anything to sed or to HTML, so the
# address needs no escaping.
if ! [[ "$email" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; then
    echo "usage: tools/build_site.sh <support email>" >&2
    exit 1
fi

rm -rf site-out
cp -R site site-out
# `-i.bak` is the one in-place form both BSD (macOS) and GNU (Linux) sed accept.
find site-out -name '*.html' -exec sed -i.bak "s/SUPPORT_EMAIL/$email/g" {} +
find site-out -name '*.bak' -delete

if grep -rq 'SUPPORT_EMAIL\|TODO' site-out; then
    echo "placeholder left in site-out/" >&2
    exit 1
fi
echo "built site-out/ ($(find site-out -name '*.html' | wc -l | tr -d ' ') pages)"
