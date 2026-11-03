# Bibliography rendering: one author-substitute Stage, second-field-align as display runs

`subsequent-author-substitute` is one pure bibliography Stage over a tagged names span; `second-field-align` is desugared by the Compiler into `display` runs; plain-text display rules are pinned. Amends ADR 0003's `display` and bibliography bullets.

## Context

ADR 0003 fixed the entry and `layout` shape and left `subsequent-author-substitute`, `second-field-align` and the plain-text `display` details open. ADR 0004 listed `subsequent-author-substitute` as an optional Stage. The test-suite research (`docs/research/test-suite.md`) shows `second-field-align` and `subsequent-author-substitute` only through the same `csl-*` divs as explicit `display`.

## Decision

- **Author-substitute Stage**: `null` unless the Style's `cs:bibliography` has `subsequent-author-substitute`. It runs over the entries after bibliography sorting; "previous" is the previous entry in bibliography order. It compares the rendered first `cs:names` of each entry (substitute output included) with the previous entry's, and replaces that span with the substitute string in both `html` and `text`. Bibliography only.
- **Tags**: the Compiler tags the first-`cs:names` span (the span ADR 0008 tags) for any Style that has the attribute, with or without `collapse`.
- **Rules**: all four `subsequent-author-substitute-rule` values (`complete-all` default, `complete-each`, `partial-each`, `partial-first`). The Compiler selects one of four distinct `lib` functions (ADR 0004); there is no runtime switch. `partial-each` and `partial-first` need per-name strings, so the Compiler tags names individually only for Styles using a `partial-*` rule.
- **`second-field-align`**: the Compiler wraps the first child of `cs:layout` as `left-margin` and the remaining children as `right-inline`, the same mechanism as an explicit `display`. The renderer has no second path.
- **`layout`** (amends ADR 0003): `{hangingIndent: boolean, secondFieldAlign: 'flush'|'margin'|false, entrySpacing: number, lineSpacing: number}`, compile-time constants with spec defaults filled in (`entrySpacing` 1, `lineSpacing` 1, `hangingIndent` false).
- **Plain-text `display`** (refines ADR 0003): `indent` is four spaces on its own line; `left-margin` and `right-inline` join with one space, whitespace collapsed where the right run already starts with one; `hangingIndent`, `entrySpacing` and `lineSpacing` do not affect `text`; entries are always joined by a single `\n`. The `make golden` citeproc-js output overrides any rule it contradicts.
- **Bibliography `html` whitespace** (refines ADR 0003): `<div class="csl-bib-body">`, `\n`, entries joined by `\n`, `\n`, `</div>`, with no indentation. The harness strips whitespace between tags on both sides before the exact compare (amends #9's exact compare).

## Considered options

- Only `complete-all` and `complete-each`: rejected, the `partial-*` rules are core CSL 1.0.2 and cost nothing in Styles that do not use them.
- A separate renderer path for `second-field-align`: rejected, it duplicates `display`.
- Reproducing the fixtures' two-space indentation in `html`: rejected, bytes in every file to match test formatting.
- Letting `hangingIndent` and `entrySpacing` shape `text`: rejected, they are presentation hints for callers' CSS.

## Consequences

Styles pay for tagging and the Stage only when they use the attribute. Per-name tagging is an extra tag set (ADR 0008's list of four grows) for `partial-*` Styles. The four-space indent and one-space margin join are expected-failure candidates if the goldens differ.
