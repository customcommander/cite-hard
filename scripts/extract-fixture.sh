#!/usr/bin/env bash
# Usage: scripts/extract-fixture.sh <fixture.json> <out-dir>
# Splits one test-suite fixture into style.csl, items.json and expected.txt.
set -euo pipefail

fixture=$1
out=$2

mkdir -p "$out"
jq -j '.csl'    "$fixture" > "$out/style.csl"
jq    '.input'  "$fixture" > "$out/items.json"
jq -j '.result' "$fixture" > "$out/expected.txt"
