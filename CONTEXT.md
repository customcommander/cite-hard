# cite-hard

Compiles a single CSL style into a standalone, minimal JS file that formats citations and bibliographies for that style only.

## Language

**Style**:
One CSL file (e.g. `apa.csl`) from the CSL styles repository; the sole input to the Compiler.
_Avoid_: Template, theme

**Compiler**:
The XSL stylesheets that turn one Style into one Generated Processor source file.
_Avoid_: Transpiler, converter

**Generated Processor**:
The standalone JS file produced for one Style; it exposes a single global instance of `CSLProcessor` named after the Style (e.g. `window['apa']`) and contains only the code and locales that Style needs.
_Avoid_: Bundle, build

**CSLProcessor**:
The stateful, observable class at the heart of every Generated Processor; it holds the registry and citation clusters and emits events when they change. Its API is a small composable surface, not a clone of citeproc-js.
_Avoid_: Engine, citeproc

**Registry**:
The set of references currently known to a CSLProcessor.
_Avoid_: Library, store

**Reference Id**:
The string form of a reference's CSL-JSON `id`. Callers may pass a string or a number; the CSLProcessor coerces it once at its boundary, so `1` and `"1"` are the same reference and every id it emits is a string.
_Avoid_: Key, item id

**Cite**:
One reference occurrence in a document, with its locator, label, prefix and suffix.
_Avoid_: Citation item, reference (a reference is the Registry entry a Cite points at)

**Cluster**:
An ordered group of Cites rendered together at one place in the document. The CSLProcessor keeps Clusters in document order; the caller tells it where each Cluster sits relative to the others.
_Avoid_: Citation (ambiguous with a single Cite)

**Dangling Cite**:
A Cite whose reference is not in the Registry. It stays in its Cluster and renders as a placeholder until a reference with the same id is added.
_Avoid_: Orphan, broken cite

**Primary Dialect**:
The locale file a bare language (`de`) or a secondary dialect (`de-AT`) falls back to (`de-DE`). The Compiler's hard-coded map decides it, following the spec table plus `sr-Cyrl-RS`.
_Avoid_: Default dialect

**Output**:
The rendered result of a Cite, Cluster or bibliography entry: a pair of strings, one HTML and one plain text, always produced together.
_Avoid_: Format setting, rendering mode

**Stage**:
An optional per-Style behaviour (cite sorting, bibliography sorting, disambiguation, collapsing) that the Generated Processor hands to the CSLProcessor as a function, or leaves out entirely.
_Avoid_: Plugin, hook, option

**Sort Variant**:
The second compiled form of the macros a Style's `cs:sort` keys use, which produces canonical sort keys.
_Avoid_: Sort mode, sort pass

**Layout**:
The per-Style bibliography presentation parameters (hanging indent, second-field align, entry spacing, line spacing) delivered alongside the bibliography entries.
_Avoid_: Bibliography options

**Disambiguation Overrides**:
The per-reference data the disambiguation Stage computes (how many names to show, how far each name is expanded, whether `disambiguate` branches apply, the year-suffix) and the render reads from its context.
_Avoid_: Disambiguation state, disambiguation config
