# Generates a node:test file from a test-suite fixture.
# Args: $name (fixture name), $processor (its compiled Generated Processor, an IIFE).
# Items lacking an id get "ITEM--GENERATED--ID-<position>" (1-based), a name no fixture uses.
# A fixture without citation_items cites every item in one Cluster.
(.input | [range(length) as $i | .[$i] | .id //= "ITEM--GENERATED--ID-\($i + 1)"]) as $items
| (.citation_items // [$items | map({id})]) as $clusters
| (if .mode == "bibliography" then {skip: "bibliography mode"} else {} end) as $opts
| "'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');

\($processor)

const items = \($items | tojson);
const clusters = \($clusters | tojson);
const expected = \(.result | tojson);

test(\($name | tojson), \($opts | tojson), () => {
  const processor = globalThis['cite-hard.styles.' + \($name | tojson)];
  for (const item of items) processor.registry.set(String(item.id), item);
  const actual = clusters.map(cites => processor.cite(cites).html).join('\\n');
  assert.strictEqual(actual, expected);
});
"
