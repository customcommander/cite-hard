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
