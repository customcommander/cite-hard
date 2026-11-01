# The Compiler specialises at compile time; `lib` stays config-free

XSLT resolves every style-dependent choice and emits a tree of calls to distinct `lib` functions. `lib` and `CSLProcessor` never read Style configuration at runtime, so Closure ADVANCED can drop whatever the Style does not reference.

## Context

The Generated Processor must be as small as possible (see the map, #1). Closure ADVANCED removes unreferenced functions but cannot remove branches inside a function that is referenced, nor code guarded by a runtime flag in an object literal. How much work XSLT does versus shared library code therefore decides the file size.

## Decision

- XSLT resolves attribute-driven choices and emits a call to a distinct `lib` function (`lib.case_title`, `lib.number_roman`) with constants baked in. A `lib` function does not switch on Style config values; it may branch on runtime data (the reference, the position).
- CSL-JSON variables are pruned by call-site selection: type-specific `lib` functions (names, date, number, text) are referenced only if some element of that type uses them. Variable names are quoted string literals. There is no generated manifest of variables.
- Each `cs:macro` is one JS function, called at each use site. XSLT does no inlining or deduplication; Closure does.
- Sorting has a Sort Variant: for each `cs:key`, XSLT emits a second tree (and second copies of the macros it reaches) built from canonical-form `lib` functions. `lib` has no `sort` flag. Styles without `cs:sort` emit nothing.
- Disambiguation re-renders differ per Cite at runtime, so overrides travel in `ctx` as plain data.
- Optional Stages (cite sorting, bibliography sorting, disambiguation, collapsing, `subsequent-author-substitute`, cite grouping) are passed to `new CSLProcessor(...)` as functions, or `null` when the Style does not use them. `CSLProcessor` never inspects Style options at runtime. Static values such as `layout` stay plain data.
- Pseudo-variables (`locator`, `label`, `position`, `citation-number`, `year-suffix`, `first-reference-note-number`, `citation-label`, and the `position`/`disambiguate` tests) are routed at compile time from a fixed name list in XSLT, which emits ctx-reading calls for them and reference-reading calls (`lib.variable('title')`) for every other name. `lib` has no runtime "is this name special?" check.
- Emitted functions take `(ctx, reference)`. `ctx` is a fixed record built by the processor per render (Cite data, Cluster context, disambiguation overrides); `reference` is the untouched CSL-JSON object, stored as given in the Registry.

## Considered options

- One generic `lib` function per element kind switching on an emitted config object: rejected, every branch stays alive under ADVANCED.
- `if (config.collapse)` style flags inside `CSLProcessor`: rejected, the guarded algorithm stays reachable.
- A `sort` flag threaded through `lib`: rejected, it puts a branch in every function and breaks the rule above. Costs some duplicated emitted code for Styles with macro sort keys.
- A generated per-Style variable manifest or per-variable code: rejected, type-level pruning is enough and adds no generated structure.
- Inlining macros in XSLT: rejected, Closure already inlines single-use functions and keeps shared ones as one copy.

## Consequences

Adding a CSL feature means adding a `lib` function and an XSLT template that selects it, not a config option. Styles pay bytes only for what they reference. Sort-key macros are emitted twice. The `ctx` record and the Stage parameter names must be in the externs.
