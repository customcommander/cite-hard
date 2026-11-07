#!/usr/bin/env bash
# Usage: scripts/extract-fixture.sh <fixture.json> <out-dir>
# Splits one test-suite fixture into style.csl, items.json and expected.txt.
# Items lacking an id get "ITEM--GENERATED--ID-<position>" (1-based), a name no fixture uses.
set -euo pipefail

fixture=$1
out=$2

mkdir -p "$out"
jq -j '.csl'    "$fixture" > "$out/style.csl"
jq    '.input | [range(length) as $i | .[$i] | .id //= "ITEM--GENERATED--ID-\($i + 1)"]' "$fixture" > "$out/items.json"
jq -j '.result' "$fixture" > "$out/expected.txt"
