#!/bin/bash
# Fails when a .swift file on disk is missing from MenteViva.xcodeproj, or the
# project lists one that no longer exists. Read-only, needs no Xcode, so it runs
# in the pre-push hook and on CI's Linux job. "sourcecode.swift" is Xcode's
# file-type token, not a file.
set -euo pipefail
cd "$(dirname "$0")/.."

diff \
    <(grep -oE '[A-Za-z0-9_]+\.swift' MenteViva.xcodeproj/project.pbxproj \
        | grep -v '^sourcecode\.swift$' | sort -u) \
    <(find MenteViva MenteVivaTests -name '*.swift' -exec basename {} \; | sort -u) || {
    echo "Close Xcode, run 'swift tools/generate_project.swift', commit the result." >&2
    exit 1
}
echo "Project file lists every .swift file."
