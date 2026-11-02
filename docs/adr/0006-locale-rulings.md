# Locale rulings: spec-literal chain, resolved at compile time

The Compiler resolves every localizable unit once, at compile time, by walking the CSL 1.0.2 six-step fallback chain exactly as the spec words it. Where the spec is silent, this ADR rules. Item `language` is out of scope.

## Context

The locale research (#7) left spec-silent questions, and the test-suite research (#6) found 8 fixtures that switch behaviour on an item's `language`, which conflicts with a locale fixed at compile time. Full facts: branch `research/locales`, `docs/research/locales.md`.

## Decision

- **Chain**: for a chosen locale, each unit (a term form, a `text`/`numeric` date format, a locale option) is looked up in: style `cs:locale` for the chosen dialect, its language, unlabelled; then locale file for the chosen dialect, its Primary Dialect, `en-US`. First source that defines it wins; an empty term counts as defined. Locale fallback runs before form fallback.
- **Matching**: `xml:lang` and `default-locale` are compared case-insensitively (schema type is `xsd:language`: hyphen-separated, case not guaranteed). No other normalisation; `_` is schema-invalid and never matches. Locale files and the dialect map use canonical names.
- **Unknown locale** (e.g. `gx`): no locale file at the file steps; style steps and `en-US` still apply.
- **Style block for the Primary Dialect** (`xml:lang="de-DE"` when the chosen locale is `de-AT`) is dead, as in the spec. Follow-up: raise upstream.
- **Dead blocks**: any style `cs:locale` outside the chain is dropped at compile time.
- **Duplicate `xml:lang`** style locales behave as one block; the last in document order wins per unit.
- **Options** (`punctuation-in-quote`, `limit-day-ordinals-to-day-1`) fall back per attribute. The schema default `false` applies only after the last step.
- **`gender`** travels with its (name, form) term. The source that supplies the text supplies the `gender`; overriding a term overrides all of it.
- **Ordinals**: defining any `ordinal*` term in a source supplies the whole set from that source. `long-ordinal-NN` is outside that rule and falls back per (name, `gender-form`).
- **Dialect map**: the language-to-primary-dialect table and the secondary-to-primary table are hard-coded in XSLT. The secondary table is the spec's 8 rows plus `sr-Cyrl-RS` -> `sr-Latn-RS`, a deliberate extension that matches `locales.json`.
- **Item `language` is out of scope.** The style's `default-locale` alone decides everything locale-dependent, including whether title-case assumes English. `choose` on the `language` variable sees it like any other variable. The 8 fixtures that depend on it (`locale_TitleCaseGarbageLangEmptyLocale`, `locale_TitleCaseGarbageLangEnglishLocale`, `locale_TitleCaseGarbageLangNonEnglishLocale`, `locale_TitleCaseNonEnglishLangUpperEmptyLocale`, `number_LimitOrdinalsToDayOne`, `textcase_LocaleUnicode`, `textcase_TitleCaseNonEnglish`, `textcase_TitleCaseWithVolumeTitle`) are permanent expected failures, one baseline group "item language unsupported".
- **`locale_PageRangeDelimiterTermFrenchUndef`** expects U+2011 but locales v0.0.97 fr-FR has an en dash. Won't-fix for now; vendored locale data is never patched. Follow-up: ask upstream which side is wrong.

## Considered options

- Style block for the Primary Dialect read just before the locale-file Primary Dialect: rejected, departs from the spec and cannot be tested against the suite.
- Option fallback per `cs:style-options` element: rejected, setting one option would silently reset the other.
- `gender` as its own fallback unit: rejected, mixes text and grammar from different sources.
- Generating the dialect map from `locales.json`: rejected, a build step for 55 rows that change rarely.
- Runtime item `language`: rejected, it would put language data and branches in `lib` and contradict compile-time locale.

## Consequences

Locale resolution costs nothing at runtime; unused terms are never emitted. Styles relying on item `language` render with the style locale's rules. The baseline gains two entries (the 8-fixture group and the fr-FR fixture).
