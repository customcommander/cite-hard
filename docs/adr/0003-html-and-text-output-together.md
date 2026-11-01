# Every output is rendered as HTML and plain text together

Every rendered result of a `CSLProcessor` is an `{html, text}` pair, computed eagerly from the same tree. There is no format setting.

## Context

Events carry rendered output (ADR 0002), so the output format has to be known when a mutation is processed, not chosen per call. The Compiler produces one file per Style with no runtime style config. The remaining question was how callers pick a format.

## Decision

- Formats: HTML and plain text. RTF is out of scope.
- Output is a pair `{html, text}`. `cluster` payloads are `{id, output, missing}`; `cite()` returns the pair.
- `bibliography()` and the `bibliography` event carry `{entries: [{id, output}], layout: {hangingIndent, secondFieldAlign, entrySpacing, lineSpacing}}`. `layout` comes from `cs:bibliography` and is a compile-time constant. Entries are in bibliography sort order.
- A Dangling Cite renders as `[?]` in both formats, replacing the whole Cite (locator, prefix and suffix included).
- `display` in HTML: runs wrapped in `<div class="csl-block|csl-left-margin|csl-right-inline|csl-indent">`; the entry itself is not wrapped. In text: consecutive `block` runs joined by `\n` with no leading or trailing newline, `indent` on its own line with a fixed indent, `left-margin` and `right-inline` joined by one space. Text behaviour is to be refined once the test-suite research reports what fixtures expect.
- The styled tree is internal and not exposed.

## Considered options

- Compile-time format, one per file: rejected, callers wanting both load two files.
- Runtime `setFormat`: rejected, it adds a global mutation with a full recompute, its own batching and listener rules, and lets one subscriber change what another receives.
- Per-call `format` option: rejected, it does not work with events.
- Exposing the styled tree: rejected, public surface and byte cost for something callers can post-process.

## Consequences

Both renderers are in every file, which ADVANCED cannot prune; the text renderer is nearly free because every node already carries `raw`. Payloads roughly double in size. `html`, `text`, `output`, `entries` and `layout` keys must be in the externs.
