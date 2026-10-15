# CSL test-suite fixtures: format and mapping to the new API

Research for issue #6 (parent map #1). Facts and options only; no design decisions.

## Sources and method

- Fixtures: `vendor/test-suite/*.json`, produced by `make vendor/test-suite`, which untars `processor-tests/machines` from the `master` archive of https://github.com/citation-style-language/test-suite (unpinned, so counts below are a snapshot of 2026-10-15; the Makefile does not pin a tag).
- Every number below was computed by loading all 845 files with a Python script (JSON parsing plus regexes over the embedded CSL string). The regexes are crude (no XML parser), so feature counts are "fixtures whose CSL text matches", not semantic counts.
- Not verified against upstream: how citeproc-js's own runner turns these fields into engine calls (inferred from the fixture data, see "Semantics inferred"). Not measured: compile time per fixture.
- Domain context: `CONTEXT.md` (Generated Processor, CSLProcessor, Registry) and the Notes of map #1. The current `src/processor.js` PoC only has `cite(reference)` and `citation(references)`; none of the primitives proposed in #1 exist yet.

## 1. Fixture format

845 files, one JSON object each. Every file has exactly these 11 keys:

| key | values across the 845 fixtures |
|---|---|
| `mode` | `"citation"` 646, `"bibliography"` 199 |
| `csl` | full CSL style XML as a string; 696 distinct strings; every one has the CSL namespace; 729 `class="note"`, 115 `in-text`, 1 with no class (`bugreports_SingleQuoteXml`) |
| `input` | array of CSL-JSON items (1,757 items total; 1 item in 531 fixtures, up to 61) |
| `result` | expected output, always a string (never empty) |
| `citation_items` | `false` in 643; array of clusters in 202 |
| `citations` | `false` in 802; array in 43 |
| `abbreviations`, `bibentries`, `bibsection`, `tags` | `false` in all 845 (dead keys in this snapshot) |
| `version` | `"1.0"` 837, `false` 6, `"1.0.1"` 2 |

Minimal example (`affix_CommaAfterQuote.json`): `mode: "citation"`, `citation_items: [[{"id":"ITEM-1","prefix":"'quote', "}]]`, input one book with `title: "Hello Thing"`, style `<layout><text variable="title"/></layout>`, `result: "“quote”, Hello Thing"`.

Each fixture carries its own CSL, so there is no shared style: 696 distinct styles for 845 fixtures. The styles are tiny, hand-written test styles, with a few full styles (`fullstyles_*`, 5; Bluebook in `position_NearNoteWithPlugin`).

### Three ways a fixture specifies what to render

| shape | `citation` mode | `bibliography` mode | total |
|---|---|---|---|
| neither field set (`citation_items` false, `citations` false) | 442 | 159 | 601 |
| `citation_items` only | 163 | 38 | 201 |
| `citations` only | 41 | 2 | 43 |

One fixture sets both `citations` and `citation_items`; it is counted in the `citations` row (so 202 fixtures have a `citation_items` array in total, 201 exclusively).

1. **Neither (601, 71%).** Implied: register all `input` items, then render. In citation mode the evidence is that all inputs go into one cluster: 77 of these fixtures have more than one input and e.g. `bugreports_CollapseFailure` has items 1-3 and result `(Doe et al. 1965a, 1965b, 1970)`, a single cluster. In bibliography mode all inputs appear in the bibliography.
2. **`citation_items` (202).** An array of clusters, each an array of cite items `{id, prefix?, suffix?, locator?, label?, position?, first-reference-note-number?, near-note?}`. Cluster counts: 1 cluster in 116 fixtures, 2 in 43, 3 in 27, up to 20 (2 fixtures). Items per cluster: 1 (335 clusters), 2 (53), up to 13. `result` has one line per cluster joined by `\n` (checked: 0 mismatches over the 79 multi-cluster citation-mode fixtures). Cite-item keys seen: `id` 686, `locator` 37, `label` 24, `prefix` 12, `position` 12 (7 fixtures), `suffix` 7, `first-reference-note-number` 2, `near-note` 1.
3. **`citations` (43).** The processCitationCluster shape: each entry is `[cluster, pre, post]` where `cluster = {citationID, citationItems, properties: {noteIndex}}` (2 clusters lack `properties`), `pre` is a list of `[citationID, noteIndex]` for clusters before it, `post` the same for clusters after. Fixtures describe a sequence of edits to a document: `pre` is non-empty in 26 fixtures, `post` in 6 (the same citationID can be re-submitted with different items or `noteIndex`). `noteIndex` max is 5, and 24 fixtures have a non-sequential noteIndex/cluster sequence (re-submission, insertion). The `result` marks each rendered cluster with a prefix: `..[i]` (unchanged, 48 lines) or `>>[i]` (changed by this edit, 51 lines), where `i` is the cluster's index in the document. 41 of the 43 results use these markers.
   Example, `integration_IbidOnInsert`: four submissions where the last re-submits CITATION-4 with `pre=[CITATION-1]` and `post=[CITATION-2, CITATION-3]`; result `..[0] (Doe p. 12)\n>>[1] (Noakes p. 34)\n>>[2] (Ibid.)\n..[3] (Snoakes p. 45)`.
   Example, `collapse_CitationNumberRangesInsert`: result `..[0] [1]\n>>[1] [1]–[4]` (a later edit changes what an earlier cluster number range renders to).

### Result format

- Citation mode: plain text, or HTML-ish where styles use formatting. Tag counts across `result` strings (opening+closing occurrences): `div` 1322, `i` 462, `sup` 258, `b` 236, `span` 66, `sub` 8. 34 fixtures contain HTML entities (`&#...;`, `&amp;`, `&lt;`).
- Bibliography mode: always `<div class="csl-bib-body">\n  <div class="csl-entry">…</div>\n…</div>` (199/199, no attributes on the body div). `csl-left-margin`/`csl-right-inline` appear in 18, `csl-indent` in 1, `csl-block` in 3.
- Curly quotes appear in results (`“quote”`), i.e. the expected output has typographic quote conversion (`punctuation-in-quote` is set on `<style>` in 24 fixtures).
- 2 fixtures expect an error string rather than output: `[CSL STYLE ERROR: reference with no printed form.]` (`date_DateNoDateNoTest`, `sort_OmittedBibRefMixedNumericStyle`).

### Input format quirks (CSL-JSON, but not clean)

Map #1 says input is trusted CSL-JSON, never validated. The fixture inputs are loosely CSL-JSON:

- `id` is a string in 1,694 items, an **integer** in 59 items (24 fixtures), and **missing** in 4 items.
- `date-parts` contains **strings** instead of numbers in 163 fixtures (e.g. `[["1910"]]`, see `position_IbidWithLocator`); 4 fixtures use `raw`/`literal` dates.
- Names use `family`, `given`, plus `isInstitution` (24 names), `non-dropping-particle` (21), `literal` (17), `suffix` (17), `dropping-particle` (14), `comma-suffix` (3).
- Cheater-syntax `note` field (`variable: value` lines) is used in 3 fixtures (e.g. `number_LimitOrdinalsToDayOne` has `"note": "event-date: 2004-10-01/2004-10-14"` as documentation only).
- 61 distinct item keys, including non-standard `multi` (2 fixtures), `original-title`, `system_id`, `citation-label` (explicit label supplied by input, 5 fixtures use `citation-label` in CSL).
- Item `type` is missing in 44 items (the engine must cope) and includes `legal_case` 4, `legislation` 3, `personal_communication` 2, etc.; `book` dominates (1,539 of 1,757).

## 2. Fixtures per feature group

Group = filename prefix before the first underscore. 38 groups.

| group | n | | group | n |
|---|---|---|---|---|
| name | 111 | | condition | 17 |
| date | 101 | | punctuation | 16 |
| nameattr | 97 | | position | 16 |
| bugreports | 83 | | integration | 14 |
| disambiguate | 71 | | page | 10 |
| sort | 54 | | affix | 9 |
| magic | 40 | | decorations, group, plural, substitute | 7 each |
| textcase | 31 | | nameorder, locator | 6 each |
| locale | 23 | | display, fullstyles, variables | 5 each |
| collapse | 21 | | etal, quotes | 4 each |
| number | 20 | | form | 3 |
| label | 19 | | testers | 2 |
| flipflop | 19 | | namespaces, simplespace, sortseparator, unicode, virtual | 1 each |

Group by shape (cites from the table in section 1):

- All of `name` (111), `date` (101), `nameattr` (97), `locale` (23), `nameorder` (6), `decorations` (7) are almost entirely "neither" fixtures, i.e. trivially one-shot.
- `integration` (14): 12 use `citations` (stateful edits), 2 `citation_items`; 8 of its CSL use `position`.
- `position` (16): 7 `citations`, 6 `citation_items`, 3 neither; 15 use `position=` in CSL.
- `collapse` (21): 16 `citation_items`, 4 neither, 1 `citations`.
- `disambiguate` (71): 34 neither, 33 `citation_items`, 4 `citations`.
- `sort` (54): 33 bibliography; 34 neither, 15 `citation_items`, 5 `citations`.
- `bugreports` (83): mixed (44 / 31 / 8), the most heterogeneous group; 14 use position in CSL.
- `magic` (40): behavioural flags (hanging indent, entry spacing, punctuation-in-quote, name particles, year-suffix delimiter, strip-periods...), mostly "neither".

Bibliography-layout attributes seen in CSL `<bibliography>` roots (fixtures): `hanging-indent` 66, `entry-spacing` 29, `subsequent-author-substitute` 8 on the element (52 fixtures mention it anywhere), `line-spacing` 2, `second-field-align` 1 on the element (18 fixtures mention it). In results these do not become CSS: the expected `result` uses plain `csl-bib-body`/`csl-entry` divs, with `csl-left-margin`/`csl-right-inline` for second-field-align and `csl-indent`/`csl-block` for display.

## 3. Dependency on cluster order and note positions

Several overlapping signals; none of them can be merged into one exact count without fixture-by-fixture review.

| signal | fixtures |
|---|---|
| `citations` shape (cluster edits, noteIndex, pre/post, `..[`/`>>[` markers) | 43 |
| `citation_items` with more than one cluster | 86 (79 citation mode, 7 bibliography) |
| CSL contains `position=` or `near-note-distance` | 52 |
| cite items carry explicit `position` / `first-reference-note-number` / `near-note` | 8 |
| CSL references `first-reference-note-number` | 7 |
| union of the four signals above | 152 (18% of 845) |

Details:

- Of 52 fixtures whose CSL tests position, 20 are `citations` fixtures, 9 are multi-cluster `citation_items` (6 of those give `position` explicitly in the items), and 24 have a single cluster or none. So a single cluster can still hit `position=` branches, e.g. `first` for one-cite fixtures; those need no cluster history. 22 position-testing fixtures are in none of the other three categories ("B only", for example `position_TrueInCitation`, `position_FalseInBibliography`, `position_NearNoteUnsupported`, `bugreports_LabelsOutOfPlace`).
- Explicit `position` in the fixture: `position_IbidWithLocator` passes `"position": 3` on the second cite so the expected `Ibid. p. 23.` comes from caller-provided position, not engine inference. Only 7 fixtures do this, versus 9 multi-cluster fixtures that test position in CSL, so for 3 of those the expected output depends on the engine inferring position from cluster order (or on the runner doing so).
- 79 multi-cluster citation-mode fixtures: 36 of the 86 multi-cluster fixtures contain no cross-cluster CSL feature at all (no `position`, `near-note`, `collapse`, year-suffix, `disambiguate-add-*`, `subsequent-author`, `cite-group`, `givenname-disambiguation`), e.g. `affix_WordProcessorAffixNoSpace`, `condition_EmptyDate`, `flipflop_ItalicsFlipped`. The remaining 50 do have some such feature (several of which, such as disambiguation and year-suffix, depend on the whole Registry, not on cluster order, see below).
- Citation-number styles: `citation-number` appears in the CSL of 36 fixtures; the number is the Registry order of first citation (e.g. `collapse_CitationNumberRangesInsert` shows `[1]–[4]` after an insert), so these also depend on cite order.

### Registry-wide state independent of cluster order

Disambiguation (`disambiguate-add-givenname` 29, `disambiguate-add-year-suffix` 18, `disambiguate-add-names` 12 as `<citation>` attributes; `year-suffix` mentioned in 122 CSL; `disambiguate=` conditions 17) and `collapse` (34 as a `<citation>` attribute) need all cited items known before the first cluster is rendered. This is a Registry property; in 86 multi-cluster fixtures the Registry must hold the union of cited items before rendering cluster 1. Bibliography-mode fixtures with `citation_items` (38) use it to say *which* inputs are cited: in the 6 inspected, all inputs are cited; in citation mode, 1 fixture has an input item that is not cited (`sort_WithAndInOneEntry`), which matters only if registering an item without citing it changes output.

## 4. Runtime locale and multilingual features (scope check)

Map #1 puts multilingual/Juris-M and runtime locale switching out of scope.

**Multilingual / Juris-M markers.** A regex pass found zero fixtures with `<layout locale=`, `form="translit`, `prefer-`, `jurisdiction`, or extra XML namespaces; zero with `abbreviations`. (A naive grep for `multi` matches `<multiple`, 36 fixtures, a false positive from `<multiple...>`-style text; do not use it.) The only multilingual-looking data is the item key `multi` in 2 fixtures (`flipflop_ApostropheInsideTag`, `position_NearNoteWithPlugin`, the latter is the Juris-M Bluebook style with `"multi": {"_keys": {}}`, i.e. an empty object, harmless). Legal item types (`legal_case`, `legislation`) appear in 6 fixtures, but they are in CSL 1.0.2 core types.

**Compile-time locale (in scope per map #1).**

- `default-locale` set in the CSL of 65 fixtures; non-English in 36 (`fr-FR` 16, `de-DE` 5, `fr` 4, `el` 2, `zh-TW` 2, `ar`, `pt-BR`, `fr-CA`, `km-KH`, `ro-RO`, `da-DK` once each; 2 with Juris-M extended tags, `en-US-x-sort-ja-alalc97...`; 1 with a nonexistent `gx`).
- Inline `<locale>` in the CSL: 137 fixtures; with a non-English `xml:lang` in 18 fixtures.
- The `locale` group (23 fixtures) is all compile-time: inline `cs:locale` term/date/style-option overrides, empty-string overrides, an undefined locale (`locale_NonExistentLocaleDef`: `default-locale="gx"`, expected `John Doe (edxitor) + Jane roe (translator)`, so the inline `gx` term and the en-US fallback for the missing `translator` term both apply, matching the map's fallback chain).
- All fixtures use the en-US locale unless the style says otherwise, so a harness needs only the locale files the style references (vendor/locales is tag v0.0.97 in the Makefile).

**Runtime, per-item language dependence (candidates for out of scope).** 16 fixtures set an item `language`; in 8 of them it is non-English: `locale_TitleCaseGarbageLangEmptyLocale`, `locale_TitleCaseGarbageLangEnglishLocale`, `locale_TitleCaseGarbageLangNonEnglishLocale`, `locale_TitleCaseNonEnglishLangUpperEmptyLocale`, `number_LimitOrdinalsToDayOne` (item language `fr` chooses the French ordinal rule, with `limit-day-ordinals-to-day-1`), `textcase_LocaleUnicode`, `textcase_TitleCaseNonEnglish`, `textcase_TitleCaseWithVolumeTitle`. Item `language` values are messy: `en`, `de`, `fr`, `FR`, `tr`, `french language`, `fr French language`, `en--other stuff commenting about the lingo`, `original-one hello`. These are text-case/ordinal behaviours switched by the *item's* language at render time, not by the style locale. Options: treat as out of scope (item language is runtime locale), or compile in a title-case "is English" check keyed off the item `language` field. Also 4 fixtures have CSL that tests `language`/`xml:lang` conditions together with item language (`label_NameLabelThroughSubstitute`, `number_LimitOrdinalsToDayOne`, `variables_ContainerTitleShort`, `variables_ContainerTitleShort2`).

## 5. Mapping to the proposed API

Proposed primitives in map #1: Registry `add/remove/has/get/clear`; pure `cite(refs, opts)`; `bibliography()`; `on/off`.

| fixture shape | count | harness driving it |
|---|---|---|
| neither, citation mode | 442 | `add` all `input`; one `cite(all items)` call; compare to `result` |
| neither, bibliography mode | 159 | `add` all `input`; `bibliography()` |
| `citation_items`, citation mode | 163 | `add` all `input` first (Registry is needed for disambiguation, citation-number); then one `cite()` per cluster, join with `\n`. Position must come from `opts` (only explicit in 7 fixtures) |
| `citation_items`, bibliography mode | 38 | as above, then `bibliography()` |
| `citations`, either mode | 43 | not expressible with a pure `cite()` alone; needs a cluster list with ids/noteIndex, re-render on change, and some way to know which clusters' output changed (`>>`) |

Open points where the choice affects the count that can pass:

1. **`citations` fixtures (43, 5%).** They describe an ordered list of clusters, each with identity (`citationID`) and `noteIndex`, edited over time. With a pure `cite(refs, opts)`, a harness could emulate them by rebuilding the final cluster list and calling `cite` per cluster with explicit positions computed by the harness (position inference is then in the harness, not the processor). Whether the `..`/`>>` marker can be reproduced depends on tracking previous output (the harness can diff two renderings; the processor need not know).
2. **Position.** The pure `cite` raises the question already noted in #1: positions (`first`, `subsequent`, `ibid`, `ibid-with-locator`, `near-note`) can be supplied by the caller in `opts` or computed from a cluster sequence. 7 fixtures supply `position` explicitly; 152 fixtures depend on cluster order or position in some way (section 3).
3. **Error-string fixtures (2).** The expected output encodes a processor failure mode (`[CSL STYLE ERROR: reference with no printed form.]`); the API needs a decision on what an empty render returns.
4. **Result normalisation.** Bibliography expected output is HTML with the fixed `csl-bib-body`/`csl-entry` wrapper (199 fixtures), so `bibliography()` either returns that HTML or the harness wraps entries. Citation output uses `<i>`, `<b>`, `<sup>`, `<sub>`, `<span>` (see tag counts), so the output format is HTML in all cases that use formatting.
5. **Input tolerance.** Integer ids (24 fixtures), string date-parts (163 fixtures) and missing ids (4 items) contradict "trusted CSL-JSON, never validated" unless the harness normalises inputs. Normalising in the harness (stringify ids, numberify date-parts) keeps the compiler lean; not normalising makes those fixtures fail.

### Harness mechanics

- **Compilation is per fixture.** 696 distinct CSL strings (not 845): a harness that caches by CSL text compiles 696 Generated Processors, a 17.6% saving over one per fixture. Compile time per style (xsltproc + Closure ADVANCED) was not measured; the number of compiles is the key cost driver.
- **Style source.** The current `Makefile` rule `src/uncompiled/%.js` reads `vendor/styles/$*.csl` and passes `--stringparam stylename $*`; fixture CSL is embedded in JSON, so a harness step must first extract each `csl` string to a `.csl` file (a different source directory/pattern rule), named after the fixture, so the global instance name is unique (`window['<fixture-name>']`).
- **Global instance.** A Generated Processor exposes one global instance. One fixture per compiled file means no cross-fixture state; running several fixtures in one JS context requires `clear()` on the Registry between runs, and for `citations` fixtures the cluster list too.
- **Expected-result inputs a harness must supply:** `mode`, `input`, the cluster description (`citation_items` or `citations`), `result`. `version`, `abbreviations`, `bibentries`, `bibsection`, `tags` can be ignored in this snapshot (always false / version string).
- **Tests are "compiled before running"** (map #1): fixture JSON -> `.csl` + a data file or generated test source -> compile -> run against ADVANCED output. Because ADVANCED renames properties, the harness must reach the processor only through exported names (`window['...']` plus whatever `externs.js` declares).

## 6. Reproducible numbers

Counts above come from five throwaway Python scripts over `vendor/test-suite/*.json` (not committed). Spot-check commands, run from the repo root with fixtures present:

```sh
ls vendor/test-suite | wc -l                                  # 845
grep -l '"mode": "bibliography"' vendor/test-suite/*.json | wc -l   # 199
grep -l '"citations": \[' vendor/test-suite/*.json | wc -l          # 43
```
