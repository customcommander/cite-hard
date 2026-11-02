# Input follows the CSL-JSON schema; ids are coerced to strings

The processor trusts its input to be valid per `csl-data.json` (CSL 1.0.2) and handles every type the schema allows. The one check it makes is that a reference has an `id`.

## Context

The map said input is "trusted CSL-JSON, never validated". The test-suite research (#6) then found looser input: 59 items with integer ids, 4 with no id, 163 fixtures with string date-parts. Investigation (#10) showed all of it is legacy fixture noise, not deliberate leniency tests, but integer ids and string date-parts are valid per the schema (`string | number`), so callers such as Zotero exports can legitimately send them. Only the 4 missing ids are schema-invalid.

## Decision

- The contract is the schema. Input valid per the schema is handled natively by the processor; there is no test-harness normaliser for types. Input that is invalid is undefined behaviour and is not validated, with one exception below.
- A reference without an `id` (`null` or `undefined`) makes `add()` throw. The whole input is validated before any mutation, so a throw leaves the Registry untouched and emits nothing. Inside `batch(fn)` the error propagates out of `fn`, and earlier mutations still flush. `""` and `0` are valid ids.
- Ids are coerced to strings once at the boundary (`add`, `remove`, `has`, `get`, Cites). `1` and `"1"` are the same reference. Everything internal and every emitted id (`registry`, `cluster`, `entries[].id`) is a string. The reference object is stored untouched (ADR 0004).
- Adding an id already in the Registry replaces the stored reference, recomputes what depends on it and emits `registry` with `type: 'add'`.
- Date-part elements are coerced numerically inside the date `lib` functions; elements that are not numeric afterwards are skipped, as citeproc-js does. The Compiler is not involved.
- Test harness: the only input patch is a synthetic id (`ITEM-<n>`) for the 4 fixtures whose items have none (`flipflop_ApostropheInsideTag`, `flipflop_StartingApostrophe`, `group_SuppressValueWithEmptySubgroup`, `label_NoFirstCharCapWithInTextClass`). Nothing is reported upstream.
- The 2 fixtures expecting `[CSL STYLE ERROR: ...]` (`date_DateNoDateNoTest`, `sort_OmittedBibRefMixedNumericStyle`) are deliberate upstream behaviour but out of scope: the Compiler trusts the Style and a Generated Processor reports no runtime style errors. They are permanent expected failures ("won't fix") in the baseline, not `pending`.

## Considered options

- Strict processor plus a harness normaliser for ids and date-parts: rejected, schema-valid input would be rejected for real callers.
- Coercing only in the harness for missing ids and nowhere else for types: same objection.
- Validating the whole reference: rejected, bytes in every file for input the caller is trusted to get right; only the missing id breaks Registry identity.
- Throwing on duplicate ids: rejected, editing a reference would need `remove` + `add`, briefly turning its Cites into Dangling Cites.

## Consequences

A few bytes of coercion in `add()` and the date `lib`; the `throw` for a missing id is the only validation in the file. The 59 + 4 + 163 fixtures count towards compatibility with only the 4 id patches.
