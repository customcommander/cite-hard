# Cite grouping and collapsing are one pure Stage over tagged Cites

A single `collapse` Stage handles cite grouping, `cite-group-delimiter` and all four `collapse` modes. It runs per Cluster after cite sorting and disambiguation and returns the finished Cluster Output.

## Context

The spec activates cite grouping through either `cite-group-delimiter` or `collapse`, and year collapse works on cite groups, so the two cannot be separated. ADR 0004 listed them as two Stages; ADR 0007 fixed the disambiguation results the collapse reads.

## Decision

- **One Stage**, `null` only if the Style has neither `collapse` nor `cite-group-delimiter`.
- **Order** (spec: "cite grouping takes place after cite sorting and disambiguation"): sort, disambiguate, group and collapse. Collapsing never feeds back into disambiguation, whose comparand is the bare uncollapsed Cite (ADR 0007). Grouping compares the rendered first `cs:names` (substitute output included), so it sees disambiguated names.
- **Contract**: `collapse(items) -> {html, text}`. `items` are the Cluster's resolved Cites in cite-sorted order, each a record `{refId, overrides, names, date, suffix, number, rest}` with an Output pair per part. The Stage only rearranges, suppresses and joins; it never re-renders.
- **Tags**: the Compiler tags exactly four spans in the render tree, and only for Styles that have the Stage: the first `cs:names` (including `cs:substitute`), the date/year, the year-suffix, `citation-number`. Everything else is opaque `rest`. Year-suffixes are read from Disambiguation Overrides, not parsed from text.
- **Delimiters** are compile-time constants passed to the Stage: `cite-group-delimiter` (default `", "`) joins cites within a Cite Group; `year-suffix-delimiter` joins a suffix run; `after-collapse-delimiter` follows the last cite of a group and any cite carrying a locator. The latter two default to the layout delimiter.
- **Modes**: `citation-number` ranges increasing runs; `year` suppresses names of subsequent cites in a group; `year-suffix` also suppresses the repeated year; `year-suffix-ranged` also ranges suffix runs with an en-dash. `year-suffix*` fall back to `year` when `disambiguate-add-year-suffix` is false, decided at compile time.
- **Spec-stated breaks**: a cite with a locator prevents year-suffix collapse for itself: it renders its full year and a fresh run starts after it.
- **Fixture-driven, spec-silent rules** (the spec gives no minimum run length and says nothing on prefix/suffix): ranges need 3 or more consecutive items (numbers, and letters in suffix order `a..z, aa, ab..`); a non-increasing step starts a new run (`NumericDuplicate`: `1,2,2–4`); a locator also breaks `citation-number` ranges (`...GroupedLocator`); the delimiter after a locator cite is `after-collapse-delimiter` (`ChicagoAfterCollapse`); `after-collapse-delimiter` separates all Cite Groups, singletons included. Prefix and suffix break nothing unless a fixture shows otherwise. The 3-letter threshold for suffix ranges is untested by any fixture.
- **Dangling Cites** (amends ADR 0002): `CSLProcessor`, not the caller, passes only resolved Cites to the Stage and appends the `[?]` placeholders after the Stage output, joined by the layout delimiter. Their slot for position is unaffected.

## Considered options

- Separate grouping and collapsing Stages: rejected, grouping exists only to serve collapsing and `cite-group-delimiter`, and the two would share the tag set.
- Re-rendering through a callback as disambiguation does: rejected, collapsing needs no new settings, only suppression of already-rendered parts.
- Keeping Dangling Cites in place and treating them as run breakers: rejected, needs gap-tracking state in the Stage for no spec benefit.
- Parsing year-suffixes out of rendered text: rejected, fragile; overrides already carry them.

## Consequences

Styles pay for the tagging and the Stage only when they use `collapse` or `cite-group-delimiter`. A Dangling Cite loses its visual position within its Cluster. Several rules rest on single fixtures and are expected-failure candidates in the harness (ADR 0005 baseline).
