# cite-hard specification

Assembled from the wayfinder map (#1) and ADRs 0001-0009. Where this file and an ADR disagree, the ADR wins and this file is a bug. Vocabulary is in `CONTEXT.md`; this file adds no new decisions beyond the two marked **Assembled** below.

## 1. What is built

A **Compiler** (XSLT 1.0 + EXSLT via `xsltproc`, `src/transform.xsl`, plus the runtime library `src/lib.js` and `src/processor.js`) turns one CSL 1.0.2 **Style** into one standalone **Generated Processor** JS file, minified by Closure Compiler ADVANCED. The file exposes one global `CSLProcessor` instance named after the Style (`window['apa']`) and contains only the library code and locales that Style needs.

Toolchain: `make` on the owner's machine. No CI, no packaged CLI, no ClojureScript (`build.clj`, `deps.edn`, `out/` are abandoned and removable).

Scope: CSL 1.0.2 core. Out of scope: multilingual/Juris-M extensions, runtime locale switching, packaged CLI/npm distribution, drop-in citeproc-js API compatibility, RTF output, item `language` handling.

## 2. Compile-time specialisation (ADR 0004)

- XSLT resolves every Style-dependent choice and emits a tree of calls to distinct `lib` functions with constants baked in. `lib` and `CSLProcessor` never read Style configuration at runtime.
- CSL-JSON variables are pruned by call-site selection (type-specific `lib` functions for names, date, number, text). Variable names are quoted string literals.
- One JS function per `cs:macro`; no inlining in XSLT.
- Emitted functions take `(ctx, reference)`. `ctx` is a fixed record built per render (Cite data, Cluster context, Disambiguation Overrides); `reference` is the untouched CSL-JSON object.
- Pseudo-variables and the `position`/`disambiguate` tests are routed in XSLT from a fixed name list; every other name becomes `lib.variable('name')`.
- Optional **Stages** are passed to `new CSLProcessor(...)` as functions or `null`: cite sorting, bibliography sorting, disambiguation (ADR 0007), collapse (ADR 0008), author-substitute (ADR 0009). Static values (`layout`, delimiters) are plain data.
- Closure ADVANCED constraints (research #5): CSL-JSON keys by quoted access; the API surface and the keys `html`, `text`, `output`, `entries`, `layout`, `ctx` fields and Stage parameter names go in `src/externs.js` or are quoted; `--isolation_mode=IIFE`; global named by quoted assignment.

## 3. Render tree and the Sort Variant

### Node shape

The IR node shape of the PoC holds under ADR 0004: `{raw: string, styled: StyledNode, variable: boolean}`, with leaf `{text, format}` and branch `{children, format}`. `raw` is what sorting, disambiguation and `text` Output read; `styled` produces `html`. Emitted `(ctx, reference)` functions change how nodes are produced, not their shape.

**Assembled:** the Compiler's span tags (ADR 0008's four spans, ADR 0009's per-name tags) are carried as an optional marker on a node, set only in Styles that have the consuming Stage. They add no field to Styles that do not.

Affixes stay outside formatting: the affix wrapper and the formatted inner node never share a `StyledNode`, so `(<i>x</i>)` is structural. Any XSLT template that extracts `font-style` and friends must merge into the inner `[fn, opts, children]` tuple, not the affix opts.

Attribute groups: content-affecting attributes (`form`, `text-case`, `strip-periods`, number form, date parts, name options, affixes, delimiter, quotes) go into `raw`; pure formatting (`font-style`, `font-weight`, `font-variant`, `text-decoration`, `vertical-align`, `display`) is `styled`-only and never reaches `raw`.

### Sort Variant (ADR 0004)

For each `cs:key`, XSLT emits a second tree, and second copies of the macros it reaches, built from canonical-form `lib` functions. `lib` has no `sort` flag. Styles without `cs:sort` emit nothing. Canonical forms apply both for `cs:key variable=` (the single element) and `cs:key macro=` (the macro tree), as the spec's Sorting Macros section states.

| Element | Sort Variant function behaviour |
| --- | --- |
| `cs:number` | ignores `form`; canonical integer regardless of numeric/ordinal/long-ordinal/roman display |
| `cs:names` / `cs:name` | `name-as-sort-order="all"` forced; et-al and "and others" terms suppressed; `cs:label` suppressed |
| `cs:date` | see below |
| `cs:group`, `cs:choose`, `cs:text`, affixes, delimiter, quotes | unchanged |

`text-case` and `strip-periods` apply as in the display tree. `disambiguate` tests are false in the Sort Variant; sorting runs once, before disambiguation (ADR 0007), so there is no feedback loop and no re-sort.

**Date handling (Assembled, spec-dictated, closes the checklist item).** The spec's Sorting Macros section decides it, and the old "always full `YYYYMMDD`" is wrong:

- `cs:key variable="issued"` (or any date variable): the complete date, canonical `YYYYMMDD`, missing parts zero-padded.
- A date reached through a macro: only the date-parts that would otherwise be rendered, honouring `date-parts` (`year`, `year-month`, `year-month-day`) and the `cs:date-part` list of a localized or custom date, each part zero-padded to a fixed width so a lexical compare orders them chronologically.
- Per ADR 0004 these are distinct `lib` functions chosen by XSLT (a full-date key function, and a parts function whose rendered-parts list is a baked-in constant), not one function with a flag.

Date-part values arrive as numbers or numeric strings (ADR 0005) and are coerced numerically inside the date `lib` function.

Sort comparison and `year-suffix` ordering follow bibliography sort order; without a bibliography sort they follow first-cited order (ADR 0001).

## 4. CSLProcessor

### State and mutation (ADR 0001, 0002, 0005)

- **Registry**: `add`, `remove`, `has`, `get`, `clear`. Ids are coerced to strings at the boundary (**Reference Id**). A missing `id` makes `add()` throw before any mutation; re-adding an id replaces. Input is trusted CSL-JSON valid per `csl-data.json` v1.0.2 and stored as given.
- **Clusters**: an ordered list. The Cluster call is an upsert by id: a new id is placed by `before`/`after` another Cluster (else appended); an existing id replaces its Cites in place and moves only if placement is given; `noteIndex` is optional on an existing id; several Clusters may share a `noteIndex`. (The method name is not fixed by an ADR; slice 6 chooses it, suggested `cluster(id, cites, opts)`.)
- A **Cite** carries `id`, locator, label, prefix, suffix. A **Dangling Cite** (reference not in Registry) renders `[?]`, is ignored by disambiguation, numbering and collapsing, keeps its authored sort position, occupies its position slot (breaks `ibid` chains), and is appended after the collapsed Output by the processor, joined by the layout delimiter (ADR 0008). Re-adding the id restores it.
- `cite(cites, opts)` is a stateless one-off render. There is no `citation()`.
- `bibliography()` returns `{html, text, entries: [{id, output}], layout}` (ADR 0003 as amended by ADR 0009).
- Everything is recomputed eagerly and synchronously per mutation, once per `batch(fn)`, before events fire. Without a bibliography sort, bibliography order, `citation-number` and year-suffix order are first-cited order, then uncited references in insertion order.

### Events (ADR 0002)

`on(type, fn)` returns an unsubscribe function; `off(type, fn)` exists. Three events: `registry` `{type: 'add'|'remove'|'clear', ids}`, `cluster` `{id, output, missing}` (once per Cluster whose Output changed, including shifted later ones), `bibliography` (the full new bibliography). A flush emits `registry`, then `cluster` in document order, then `bibliography`. Listener errors are caught and re-raised with `setTimeout`; calling a mutator while dispatching throws; no replay on subscribe. No built-in Observable; RxJS users wrap with `fromEventPattern` (documented recipe).

### Output (ADR 0003, 0009)

Every result is an `{html, text}` pair computed together; no format setting. `display` maps to `csl-block|csl-left-margin|csl-right-inline|csl-indent` divs in html and to newline/space rules in text (ADR 0009 pins them). `second-field-align` is desugared by the Compiler into `display` runs. `layout` is `{hangingIndent, secondFieldAlign, entrySpacing, lineSpacing}`, a compile-time constant with spec defaults.

## 5. Stages and pipeline

Citation render order per Cluster: resolve Cites, cite sort (Sort Variant keys), disambiguation (ADR 0007), group and collapse (ADR 0008), append Dangling Cites. Bibliography: bibliography sort, disambiguation overrides applied to entries, author-substitute (ADR 0009).

| Stage | Present when | Contract |
| --- | --- | --- |
| cite sort / bibliography sort | `cs:sort` in `cs:citation` / `cs:bibliography` | comparator over Sort Variant keys |
| disambiguation | any `disambiguate-*` attribute or `disambiguate` test | pure; returns per-reference Disambiguation Overrides over the whole Registry; methods in spec order (givenname expansion, more names, `disambiguate` branches, year-suffix); full recompute per batch; the comparand is the plain `text` of the uncollapsed Cite |
| collapse | `collapse` or `cite-group-delimiter` | `collapse(items) -> {html, text}` over four tagged spans; fixture-driven rules listed in ADR 0008 |
| author-substitute | `subsequent-author-substitute` | pure over sorted entries; four distinct rule functions |

## 6. Locale (ADR 0006, research #7)

Resolved entirely at compile time: style `default-locale` (language to Primary Dialect), else `en-US`; spec-literal six-step chain per term/form, date format and option; case-insensitive `xml:lang`; `gender` travels with its term; `long-ordinal` sits outside the ordinal replace-all rule; duplicate style locales merge (last wins); only referenced terms are compiled in. Dead `cs:locale` blocks are dropped. Known won't-fix: item `language` (8 fixtures), the fr-FR page-range-delimiter fixture.

## 7. Testing (ADR 0005, issue #9)

- CSL test-suite pinned at `6eefc5b` (the Makefile currently fetches `master` and must change). `test/` is gitignored.
- The harness extracts each fixture's CSL, compiles one Generated Processor per fixture under `make -j`, runs the compiled ADVANCED output, compares `html` exactly (bibliography html compared with inter-tag whitespace stripped on both sides, ADR 0009).
- An expected-failures baseline with a per-group table is checked in. Permanent won't-fix: the 2 `[CSL STYLE ERROR]` fixtures, item `language`, the fr-FR fixture. The harness synthesises ids only for 4 fixtures.
- The 43 edit-sequence fixtures are replayed through the Cluster API (one `batch` per step, order set from pre/post, `noteIndex` of post Clusters updated, final-state compare). Until the replay exists they are `pending`.
- Smoke styles live as data with citeproc-js goldens (`make golden`); goldens override ADR 0009's plain-text display rules where they differ.
- Compiled output may be checked in.

## 8. Known issues and spec-silent areas

- `cite()` throws in the compiled PoC output (research #5), unrelated to the design; fixed by slice 2.
- The PoC's locale form fallback is wrong (research #7); replaced by the six-step chain.
- Spec-silent rules resting on one fixture, expected-failure candidates: collapse range minimum and suffix-range threshold (ADR 0008), the four-space `indent` and one-space margin join in plain text (ADR 0009).
- `docs/research/*.md` cited by ADR 0009 live only on the unmerged `research/*` branches (`research/test-suite`, `research/locales`, `research/closure-advanced`). Cherry-pick what the build slices need, or drop the reference.

## 9. Proposed slicing into build issues

Ordered; each is AFK-able once its blockers land.

1. **Harness and baseline**: pin the test-suite, per-style compile under `make -j`, fixture extraction and id synthesis, exact `html` compare, expected-failures baseline and per-group table, `externs.js` skeleton. Everything below is measured by it.
2. **Compiler spine**: `(ctx, reference)` emitted functions, `cs:macro` as functions, `text`/`group`/`choose`, pseudo-variable routing, affixes/formatting/quotes, the `{raw, styled}` renderer and `{html, text}` Output, fix compiled `cite()`.
3. **Names**: `cs:names`, `cs:name`, `cs:substitute`, et-al, initials, labels, name-part formatting.
4. **Dates and numbers**: `cs:date`/`cs:date-part` (ranges, seasons, numeric coercion), `cs:number` forms, ordinals, page ranges.
5. **Locale compilation**: six-step chain, `cs:locale` merge, dialect map, term/format pruning.
6. **CSLProcessor core**: Registry, ids, Cluster upsert and placement, positions (`first`/`subsequent`/`ibid`/`near-note`), `batch`, events, `cite()`, `bibliography()` with unsorted first-cited order, Dangling Cites, `layout`.
7. **Sorting**: Sort Variant (canonical number/name functions, the two date functions above), cite and bibliography sort Stages.
8. **Disambiguation Stage** (ADR 0007) including `year-suffix` and the year-date variant.
9. **Collapse Stage** (ADR 0008) with span tagging.
10. **Bibliography rendering**: `display`, `second-field-align` desugaring, author-substitute Stage with four rules, plain-text rules, whitespace normalisation (ADR 0009).
11. **Edit-sequence replay** in the harness (43 fixtures).
12. **Docs and cleanup**: README with the `fromEventPattern` recipe, remove abandoned ClojureScript files, tidy `Makefile~`.

Slices 3-5 can run in parallel after 2; 7-10 after 6 and the names/dates they read; 11 after 6.
