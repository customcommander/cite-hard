# Generates a node:test file from a test-suite fixture.
# Args: $name (fixture name), $processor (its compiled Generated Processor, an IIFE, or the compile-error stub),
# $passing (the contents of passing.txt: the fixtures that must pass; all others are generated with expectFailure).
# Items lacking an id get "ITEM--GENERATED--ID-<position>" (1-based), a name no fixture uses.
# A fixture without citation_items cites every item in one Cluster.
# Bibliography mode compares the bibliography html with whitespace between tags stripped on both sides (ADR 0009).
($passing | split("\n") | index($name) == null) as $known
| (.input | [range(length) as $i | .[$i] | .id //= "ITEM--GENERATED--ID-\($i + 1)"]) as $items
| (.citation_items // [$items | map({id})]) as $clusters
| "'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');

\($processor)

const items = \($items | tojson);
const clusters = \($clusters | tojson);
const expected = \(.result | tojson);

// Strips only whitespace between tags; whitespace inside text is kept.
const strip = html => html.replace(/>\\s+</g, '><');

test(\($name | tojson), \(if $known then "{ expectFailure: true }, " else "" end)() => {
  const compileError = globalThis['cite-hard.compile-error.' + \($name | tojson)];
  if (compileError) throw new Error(compileError);
  const processor = globalThis['cite-hard.styles.' + \($name | tojson)];
  for (const item of items) processor.registry.set(String(item.id), item);
  if (\(.mode == "bibliography") /* i.e. mode=bibliography */) {
    assert.strictEqual(strip(processor.bibliography().html), strip(expected));
  } else {
    const actual = clusters.map(cites => processor.cite(cites).html).join('\\n');
    assert.strictEqual(actual, expected);
  }
});
"
