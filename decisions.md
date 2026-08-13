# CSL IR attribute categorization — design decision record

## Context

`src/lib.js` implements a work-in-progress CSL processor. The IR node
has two representations per node: `raw` (plain string) and `styled` (a
tree carrying `format` for HTML rendering). Sorting and disambiguation
need to know which CSL attributes affect the actual content being
compared versus which ones are purely visual and must never leak into
a sort key or disambiguation check.

Cross-checked against the CSL 1.0.2 specification
(https://docs.citationstyles.org/en/stable/specification.html),
sections: Sorting Variables, Sorting Macros, Disambiguation.

## 1. Node shape — unchanged

`leaf`/`branch` keep their current shape exactly as implemented today:

```js
{ raw: string, styled: StyledNode, variable: boolean }

// StyledNode:
{ text: string, format: Format }            // leaf
{ children: StyledNode[], format: Format }  // branch
```

No new `content` field is needed. Instead, a **`sort` mode** is
threaded through the existing pipeline as an option — the same pattern
`render()` already uses for its `ctx.italic` flag — via `opts`/context
through `interpret` → `group`/`choose` → the leaf-producing functions,
rather than post-hoc derived from a built node.

| Function                                                 | Behavior in sort mode                                                                                |
| -------------------------------------------------------- | ---------------------------------------------------------------------------------------------------- |
| `number_*`                                               | ignore `form`, always return the canonical integer, regardless of numeric/ordinal/roman display form |
| `date`/`date_part`                                       | always return canonical `YYYYMMDD` (zero-padded for missing parts), ignoring date-part formatting    |
| `names`/`name`                                           | force `name-as-sort-order="all"`, suppress et-al/"and others" terms, suppress `cs:label` output      |
| `group`/`choose`/`text`/`value`/affixes/delimiter/quotes | unchanged — no special-casing needed                                                                 |

This holds for both ways a CSL `cs:key` can name a sort key:
`variable="issue"` (degenerate case: run just the one
`cs:number`/`cs:date`/`cs:names` element in sort mode) and
`macro="..."` (run the whole macro tree in sort mode) — same
mechanism either way, confirmed by the spec's Sorting Macros section
explicitly stating `cs:number`/date/names get the canonical-form
override even when nested inside a macro.

The sort-mode pipeline's output is read off the same `.raw` field
that already exists on every node — no separate field required.

## 2. Attribute groups

### Group A — content-affecting, part of `raw`

Also sensitive to `sort` mode for the number/date/name cases below.

| Attribute                                                              | Sort-mode behavior                                                          |
| ---------------------------------------------------------------------- | --------------------------------------------------------------------------- |
| `form` (long/short) on `variable`/`names`/`date`                       | selects content; not touched by sort mode itself                            |
| `text-case`                                                            | applies normally in both modes                                              |
| `strip-periods`                                                        | applies normally in both modes                                              |
| number form — `numeric`/`ordinal`/`long-ordinal`/`roman` (`cs:number`) | **overridden to canonical integer** in sort mode                            |
| date formatting / date-parts                                           | **overridden to canonical `YYYYMMDD`** in sort mode                         |
| `name-as-sort-order`, et-al truncation, `cs:label` (names)             | **overridden to all-order, et-al terms and labels suppressed** in sort mode |
| `prefix` / `suffix` (affixes)                                          | unchanged by sort mode; already folded into `raw` today via `wrap()`        |
| `delimiter`                                                            | unchanged by sort mode; already folded into `raw` today via `group()`       |
| `quotes`                                                               | unchanged by sort mode                                                      |

This is also the group used for **disambiguation**: the spec confirms
disambiguation is a re-run of the normal *display* pipeline (expand
given names → show more names → trigger `cs:choose
disambiguate="true"` branches → append year-suffix), comparing
`.raw`-equivalent output ("without rich text markup") between colliding
cites — not a separate canonical form. So `raw` (display mode, not
sort mode) is the correct comparand for disambiguation.

### Group B — pure formatting, `styled`-only

Never affects `raw` in either mode.

| Attribute                                         | Notes                                                                 |
| ------------------------------------------------- | --------------------------------------------------------------------- |
| `font-style` (italic)                             | already modeled — `render()`'s flip/open logic                        |
| `font-weight` (bold)                              | already modeled via `WRAPPERS`                                        |
| `font-variant` (small-caps)                       | already modeled via `WRAPPERS`                                        |
| `text-decoration` (underline)                     | already modeled via `WRAPPERS`                                        |
| `vertical-align` (sup/sub)                        | already modeled via `WRAPPERS`                                        |
| `display` (block/left-margin/right-inline/indent) | not yet modeled; bibliography layout only, never appears in citations |

## 3. Confirmed ordering: sort → disambiguate

Spec states cite grouping happens after both sorting and
disambiguation. No sort-key path depends on disambiguation output
(e.g. no evidence `year-suffix` can be used as a `cs:key` variable), so
there's no feedback loop: sorting runs once, then disambiguation runs
on the already-fixed order. No re-sort pass needed.

## 4. Affixes render outside formatting scope — confirmed compatible with current node shape

Spec (Affixes section): "affixes are outside the scope of formatting,
quotes, strip-periods and text-case attributes set on the same
element" — e.g. `<group prefix="(" suffix=")" font-style="italic">`
must render `(<i>...</i>)`, not `<i>(...)</i>`.

Concern raised: with the leaf/branch shape, `format` lives on the same
`StyledNode` as the content it decorates, so wouldn't it also swallow
the affixes?

No conflict, verified by simulation. `wrap()` (affixes) and the
formatted node it wraps never share a `StyledNode`:

- `mode="affixes"` (transform.xsl:145) composes as
  `wrap(reference, {prefix, suffix}, [fn, opts, children])` — an outer
  call layered *around* `fn`'s own invocation.
- `fn` (e.g. `group`) builds its own `branch(children, format)` — the
  `format` (e.g. `fontStyle: 'italic'`) is attached only to that inner
  node.
- `wrap()` treats that whole inner node as an opaque `inner` value and
  adds prefix/suffix as sibling `leaf()`s around it, defaulting their
  own `format` to `{}` — they never inherit the inner node's format.
- `render()` walks top-down, so `<i>` only opens around the inner
  branch, not the outer one holding the affix leaves.

Ran the actual composition tree transform.xsl would emit for the
example above through the real `wrap`/`join`/`group`/`render`
functions: output was `(<i>hello</i>)`, matching the spec.

**Constraint this implies for future work:** when a `mode="options"`
template is added to extract `font-style`/etc. into `format` (e.g. for
`csl:group`), it must merge into the *inner* `[fn, opts, children]`
tuple's opts (transform.xsl:202), not into the `mode="affixes"`
template's `{prefix, suffix}` opts object (transform.xsl:149). As long
as that separation holds, affix-outside-formatting is structurally
guaranteed — no extra code needed to special-case it.

## Not yet decided / out of scope for this pass

- Exact function signatures for threading `sort` mode through
  `interpret`/`group`/`choose`/`number_*`/`date`/`date_part`/`names`/
  `name` (an `opts.sort` flag vs. a separate `ctx` parameter mirroring
  `render`'s `ctx.italic`).
- Whether `cs:choose disambiguate="true"` branches are suppressed
  during the sort pass (spec doesn't address this explicitly;
  reasonable default: sort pass uses `disambiguate` tests as `false`
  since disambiguation hasn't run yet at that point).
- Implementation of the disambiguation re-render loop itself (expand
  names / show more names / disambiguate branches / year-suffix).
- `number_*`/`text-case`/`strip-periods` are currently `'TODO'` stubs;
  none of this changes their eventual implementation, just how a
  `sort`-mode caller would invoke them.
- No implementation should start until explicitly requested.
