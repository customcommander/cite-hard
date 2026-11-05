# Disambiguation is a pure Stage returning per-reference overrides

The disambiguation Stage takes reference ids and a render callback and returns Disambiguation Overrides per Reference Id. It follows the CSL 1.0.2 method order and compares across the whole Registry.

## Context

Disambiguation must see every reference, re-render with different name settings, and feed year-suffixes back into Cite and bibliography rendering (ADR 0001, ADR 0004). The spec fixes the method order and has rules that are easy to get subtly wrong. The Stage is optional (ADR 0004).

## Decision

- **Shape**: `disambiguate(refIds, render, bibOrder)` returns a map of Reference Id -> Disambiguation Overrides. `render(refId, overrides, target)` returns plain `text`; `target` is a Cite or a bibliography entry. `CSLProcessor` owns the render closure and the `ctx` plumbing. The Stage never touches the Registry or Cluster list.
- **Overrides are per reference**, not per Cite: shown-name count, an expansion level per name position, a `disambiguate` flag, a year-suffix. They travel in `ctx` as plain data and apply to every Cite of that reference and to its bibliography entry.
- **Scope**: the whole Registry, uncited references included (spec footnote on invisible cites). Adding an uncited reference can change a suffix.
- **Comparand** (spec-silent): the plain `text` of a bare Cite, with no locator, label, prefix or suffix, and position `first`. Two references collide when it is equal.
- **Method order** (spec): (1) given-name expansion, (2) more names, (3) `disambiguate="true"` branches, (4) year-suffix. With both 1 and 2 on, expansion goes first and added names are expanded if that disambiguates. A branch in step 3 is kept for a reference only where it disambiguates. Each method stops for a group once it no longer collides, except global name disambiguation (below).
- **`givenname-disambiguation-rule`**: all five values. `all-names*` also expand ambiguous names in unambiguous cites, so the Stage compares names across the Registry. `primary-name*` touch only the first name. `by-cite` expands only ambiguous names in ambiguous cites and stops after the first name that eliminates the ambiguity. `*-with-initials` do nothing without `initialize-with` or with `initialize="false"`. Individual names expand initials first, then full given names; without `initialize-with`, straight to full names.
- **Bibliography**: methods 1 and 2 also act on entries when an entry does not show what distinguishes it, each only after it has been used to disambiguate cites. Year-suffix applies to entries. A `year-suffix` rendered via `cs:text` in one scope is suppressed in the other unless that scope also renders it; the Compiler resolves this per scope.
- **Year-suffix**: assigned to references still colliding after 1-3, in bibliography order (`a..z, aa, ab..`); first-cited order (ADR 0001) if the Style has no bibliography sort. Without an explicit `year-suffix` text, XSLT emits a year-`date` variant that appends it to the first rendered year.
- **Sort pass** (spec-silent): `disambiguate` tests are false in the Sort Variant; sorting runs before disambiguation.
- **Null rule**: the Stage is `null` only if the Style has no `disambiguate-*` attribute and no `disambiguate` test (the condition has no activating attribute and is always tried).
- **Timing**: full recompute over the Registry on every mutation, once per `batch(fn)` before events fire. Only Clusters whose Output changed are re-emitted; the bibliography is re-emitted if any override changed.
- **Unresolvable collisions** are left as they are: no error, no event.

## Considered options

- Overrides per Cite: rejected, year-suffix must be per reference and the same reference showing different names in different places is confusing.
- Only cited references in scope: rejected, contradicts the spec footnote.
- Year-suffix only for bibliography entries: rejected, methods 1 and 2 must act on entries too.
- Incremental recomputation: rejected, full recompute is simpler and documents are small.
