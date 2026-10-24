#!/bin/bash
# Builds the privacy + support pages (site/) into site-out/, ready to upload to any
# free static host (a public repo's GitHub Pages, Cloudflare Pages). The support
# address is not in the repo: pass it in. Refuses to build without one, so a page
# with a placeholder can never be published.
#   tools/build_site.sh you@example.com
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

email="${1:-}"
case "$email" in
    *?@?*.?*) ;;
    *) echo "usage: tools/build_site.sh <support email>" >&2; exit 1 ;;
esac

rm -rf site-out
cp -R site site-out
find site-out -name '*.html' -exec sed -i '' "s/SUPPORT_EMAIL/$email/g" {} +

if grep -rq 'SUPPORT_EMAIL\|TODO' site-out; then
    echo "placeholder left in site-out/" >&2
    exit 1
fi
echo "built site-out/ ($(find site-out -name '*.html' | wc -l | tr -d ' ') pages)"
