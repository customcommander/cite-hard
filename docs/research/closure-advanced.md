# Research: Closure ADVANCED constraints for the Generated Processor

Issue #5 (parent #1). Facts and options only; no design decisions.

Method: ran the real compiler (`google-closure-compiler` npm, **v20261011**, Java 27) with the flags from the `dist/%.js` rule in the working-tree `Makefile` (`-O ADVANCED --js=vendor/base.js ... --entry_point=goog:citehard.styles.uncompiled --isolation_mode=IIFE --hide_warnings_for=vendor/base.js`). Scratch experiments lived outside the repo; sizes below are from those runs on small synthetic Processor/style files (not the full apa output unless stated). Node 22 was used to run the compiled output.

Primary sources: the compiler's actual behaviour (below), the Closure Compiler docs ("Advanced Compilation: Key Concepts", https://developers.google.com/closure/compiler/docs/api-tutorial3), and RxJS 7.8.2 source (`src/internal/observable/innerFrom.ts`, `symbol/observable.ts`, `util/isInteropObservable.ts`).

## 1. What ADVANCED renames or removes

- Properties accessed with **dot syntax are renamed** unless the name is in the externs (the compiler's built-in browser externs count, so `type`, `title`, `id`, `size`, `add`, `cite`, `next`, `unsubscribe` happen to survive by accident of the default externs; `issued`, `on`, `off`, `citation`, `added`, `container` do not). Docs: names in externs are "names you do not control and therefore cannot be changed".
- Properties accessed with **quoted syntax (`o['x']`) are never renamed**. Docs: "Don't mix the syntaxes, especially in reference to the same property."
- **Unused methods are removed.** Proof: a `Processor` with `on`/`off` and no externs compiled to a class with no `on`/`off` at all (`typeof apa.on === 'undefined'` at runtime).
- Externs match by **name, not by type**: declaring `Processor.prototype.cite` pins every property called `cite` everywhere in the compilation, and keeps the method even if no style calls it.

## 2. Current repo state (real build)

- `src/uncompiled/apa.js` (current working tree) compiles with **0 errors and 0 warnings**. Output: **12,364 bytes, 3,189 gzip**.
- The generated style reads CSL-JSON keys as **quoted strings** (`reference['DOI']`, `reference['title']`) or dynamically (`reference[varname]` in `lib.test_variable`). That is safe under ADVANCED: in the output they print as `b.archive_collection` / `b["archive-place"]` but keep their original names. Hyphenated keys (`archive-place`, `container-title`) can only ever be quoted anyway.
- Hazard: any **dotted** read of a CSL key inside the compiled code (e.g. `reference.type`, `ref.issued`) is renamed. Proof: `ref.issued` compiled to `a.o`, so `cite()` returned `undefined` for the date. Quoted reads of the same key worked. In the working-tree `lib.js`, `test_type` uses `reference['type']` (quoted, safe), but note the Closure docs prefer dotted syntax, so the convention must be chosen and kept uniform. Compiler externs can also protect dotted access (see 3b).
- Observation unrelated to ADVANCED: the compiled real `apa` throws `Cannot read properties of undefined (reading 'variable')` when `cite()` is called, and it does so identically under `-O SIMPLE` and `-O WHITESPACE_ONLY`, so it is a WIP bug, not an optimisation problem. One visible mismatch: `Processor.cite` calls `this._cite(reference, {})` while the generated function is `_cite(ctx, reference)` (swapped), but swapping alone did not fix the throw.
- `vendor/base.js` is required: without it, `goog.module` fails with `variable goog is undeclared`. It leaves no code in the output (stripped).
- `--isolation_mode=IIFE` is what keeps compiled helpers off the global scope. Without it the output has top-level `function d` and `class e` leaking as globals. With it the output is `(function(){...}).call(this)`.

## 3. Requirements for a public API that survives (all verified)

Baseline: Processor with `on/off/add/cite/citation`, emitting `{added, size}` on a `registry` event.

| Variant | Result |
|---|---|
| a. Only `cite`, `citation` in externs (repo today) | `on`/`off` removed; `citation` kept; event payload keys: `added` renamed to `m`; `ref.issued` renamed. Public API broken. |
| b. Externs: `Processor.prototype.{on,off,add}`, `@record` types with `added`, `size` (payload) and `issued` (CSL-JSON key) | All work: `on/off/add` present, payload keys `added,size` intact, dotted `ref.issued` intact. 579 B raw / 374 gzip (synthetic). |
| c. No externs; quoted method names (`'on'(){}`) and quoted payload keys (`{'added': ...}`) | Works, 565 B / 370 gzip. Caveat: class bodies are `@struct` by default so `this['off']` warns `JSC_ILLEGAL_PROPERTY_ACCESS` (call `this.off` or mark `@unrestricted`). Also `{cite, citation}` in the constructor destructuring: `citation` renamed to `j` (harmless, internal). Output prints methods dotted but unrenamed. |

Not tested: `@export` / `goog.exportSymbol` with `--generate_exports`, and ES-module input (which would drop the need for `vendor/base.js`). The docs page above only describes the externs route.

Consumer-side note: the objects the **consumer** builds (CSL-JSON items passed in, observer objects passed to `subscribe`) are not renamed because they are outside the compile. Only the compiled code's own property reads/writes matter.

## 4. Exposing the global instance

- `globalThis['apa'] = p` and `window['apa'] = p` (quoted): name preserved. The repo's `globalThis['cite-hard.styles.apa']` works too (confirmed in the real build output).
- `globalThis.apa = p` or `window.apa = p` (**dotted**): renamed to `globalThis.h` / `window.i`. Global assignment must be quoted (or externed).
- `window` throws in Node/worker (`ReferenceError`), `globalThis` does not; `.call(this)` from the IIFE is `undefined` in strict module contexts, so the explicit global object is the one to rely on.

## 5. Cost of RxJS interop

RxJS 7.8.2 `from(x)` accepts an object only if `x[Symbol.observable || '@@observable']()` returns something with `subscribe`; `subscribe` receives a Subscriber and may return `{unsubscribe}` or a function (`innerFrom.ts`: `fromInteropObservable`). A bare `{subscribe}` is **not** accepted by `from()`; `Symbol.observable` is not native (non-standard, from the stalled TC39 observable proposal), so RxJS falls back to the string `'@@observable'`.

Measured on the (b) externs variant, bare emitter baseline 579 B raw / 374 gzip:

| Addition | Raw | Gzip |
|---|---|---|
| `subscribe(observer)` (function or `{next}`; returns `{unsubscribe}`) | +148 B | +67 B |
| plus `[Symbol.observable \|\| '@@observable']() { return this; }` | +50 B | +26 B |
| Total | +198 B (777) | +93 B (467) |

Verified end-to-end: `rxjs.from(apa).subscribe(...)` received events and `unsubscribe()` stopped them against the ADVANCED output.

Gotchas:
- Without an extern for `Symbol.observable`, ADVANCED renames it (`Symbol.h`) and warns `JSC_ILLEGAL_PROPERTY_ACCESS` (struct class). Interop then works **only through the `'@@observable'` fallback** (RxJS's own fallback), which hides the breakage in an RxJS test. Declaring `Symbol.observable` in externs avoids this.
- `next` and `unsubscribe` survived without custom externs (default externs); do not rely on that. `error`/`complete` handling was not implemented in this measurement; handling them adds more bytes.
- Costs are small and constant, not per-style; the real apa output is 3,189 B gzip, so +93 B is roughly 3%.

## 6. Options (facts only)

- Public-API names: (i) externs file listing methods and payload/CSL-JSON record types, or (ii) quoted names throughout. (i) matches the existing `src/externs.js`, but pins names compilation-wide and keeps unused API methods in every Generated Processor. (ii) needs no extern file but needs discipline (and `@unrestricted` or no bracket-access on `this`).
- Whatever is chosen, never mix quoted and dotted access for the same property.
- Global instance via quoted assignment; IIFE isolation as now.
- Observable interop: one `subscribe` method plus the symbol method, approx. 93 B gzip extra; requires an extern for `Symbol.observable` if the symbol form is used.
