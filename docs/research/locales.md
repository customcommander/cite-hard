# CSL locale fallback and `cs:locale` merge rules

Research for issue #7 (parent map #1). Facts and options only; no design decisions.

Sources (all primary):

- **Spec**: CSL 1.0.2 specification, https://docs.citationstyles.org/en/stable/specification.html. Read from its source file `specification.rst` in `citation-style-language/documentation` (header "CSL 1.0.2 Specification"). Cited below as *Spec, <section>*.
- **Schema**: `vendor/schema/styles/csl.rnc` (the `cs:locale` and `cs:term` patterns).
- **Locale data**: `vendor/locales`, tag v0.0.97 (the version pinned in the `Makefile`): 63 `locales-*.xml` files plus `locales.json`.
- **Test suite**: `vendor/test-suite` (845 fixtures). Used as the executable reading of the spec.
- **Style corpus**: `vendor/styles` (2801 independent styles), used only for usage statistics.
- **PoC**: `src/transform.xsl` as it is in the main checkout working tree (uncommitted changes included).

## 1. Chosen locale

- `default-locale` on `cs:style` is an optional `xsd:language` code (Spec, *The Root Element*; schema `style.default-locale`).
- If it is absent, this project uses `en-US` (map #1 Notes; the spec itself does not name a default, but its fallback chain ends in `en-US`).
- If it is a bare language (`fr`), the **primary dialect** is used in place of the dialect everywhere in the chain below (Spec, *Locale Fallback*: "If the chosen output locale is a language (e.g. "de"), the (primary) dialect is used in step 1").

### Language to primary dialect

The spec only tabulates the languages that have more than one dialect file (de-DE, en-US, es-ES, fr-FR, pt-PT, zh-CN). The complete language to primary-dialect map is published as data in `vendor/locales/locales.json`, key `primary-dialects` (55 entries, e.g. `af` -> `af-ZA`, `ar` -> `ar`, `eu` -> `eu`, `la` -> `la`, `sr` -> `sr-Latn-RS`, `zh` -> `zh-CN`).

- The 55 `case` lines in `transform.xsl` (lines ~26-79) match this JSON entry for entry.
- The same file also has a `language-names` map (63 entries: one per locale file, `[native name, English name]`).
- Options: keep the XSLT `choose`; generate it from `locales.json` (JSON is not readable by `xsltproc`, so a `make` step or a derived XML would be needed); or resolve at the `make` level and pass `--stringparam`.

### Secondary dialect to primary dialect

Per the spec table (Spec, *Locale Fallback*): de-AT, de-CH -> de-DE; en-GB -> en-US; es-CL, es-MX -> es-ES; fr-CA -> fr-FR; pt-BR -> pt-PT; zh-TW -> zh-CN.

- `transform.xsl` `dialect-primary` has these 8 plus `sr-Cyrl-RS` -> `sr-Latn-RS`. The `sr-Cyrl-RS` row is **not** in the spec table. It is consistent with `locales.json` (`sr` -> `sr-Latn-RS`) and with the existence of both `sr-Cyrl-RS` and `sr-Latn-RS` files, but it is a PoC addition.
- The spec says the table is "at the moment of writing" and does not give a rule for deriving it. Files present in v0.0.97 that are in a multi-dialect language but not in the table: `sr-Cyrl-RS` only. `tl-PH`, `ca-AD`, etc. are single-file.

### Inputs seen in the wild

- Corpus (2801 styles): `default-locale` is absent in 316; the rest are mostly full dialects (`en-US` 1255, `en-GB` 650, `fr-FR` 150, `de-DE` 136, ...). Bare languages are rare: `ca` 2, `fr` 2, `en` 1, `es` 1. Every value in the corpus maps to an existing locale file directly or via `locales.json`.
- Test suite: `default-locale` values include codes with **no** locale file: `gx` (`locale_NonExistentLocaleDef`) and `en-US-x-sort-ja-alalc97...` (multilingual/Juris-M extension, out of scope). `locale_NonExistentLocaleDef` expects the style's own `<locale xml:lang="gx">` term to be used and everything else to fall to `en-US`. So an unknown dialect means "no locale file at steps 4-5, still use steps 1-3 and 6".
- Other test-suite values worth knowing: `ar` (the file is `locales-ar.xml`, no region), `km-KH`, `zh-TW`, `el`, `fr`, `en`.

## 2. The fallback chain

Verbatim from Spec, *Locale Fallback*, for chosen locale `de-AT`. Each **localizable unit** is looked up individually, in this order, stopping at the first source that defines it:

| # | Source | `xml:lang` |
|---|--------|-----------|
| 1 | `cs:locale` in the style | the chosen dialect (`de-AT`) |
| 2 | `cs:locale` in the style | the language (`de`) |
| 3 | `cs:locale` in the style | absent |
| 4 | locale file | chosen dialect (`de-AT`) |
| 5 | locale file | primary dialect (`de-DE`); only when the chosen locale is a secondary dialect |
| 6 | locale file | `en-US` |

Rules stated by the spec:

1. **Unit of fallback** is "a date format, localized option, or specific form of a term" (Spec, *Locale Fallback*). That means:
   - a term is keyed by (`name`, `form`) (plus `gender-form`/`match` for ordinals, see 4);
   - a date format is keyed by `form` = `text` or `numeric` (whole `cs:date` element);
   - an option is keyed by attribute name (`limit-day-ordinals-to-day-1`, `punctuation-in-quote`).
2. **Empty counts as defined**: "Fallback stops once a localizable unit has been found. For terms, this even is the case when they are defined as empty strings (e.g. `<term name="and"/>`)." Fixtures: `locale_EmptyTerm`, `locale_ForceEmptyEtAlTerm`, `locale_ForceEmptyAndOthersTerm`, `locale_OverloadWithEmptyString`.
3. **Locale fallback beats form fallback**: "Locale fallback takes precedence over fallback of term forms" (Spec, *Locale Fallback*). So for `<text term="x" form="short"/>` all six sources are searched for (`x`, short) before trying form `long`.
4. Step 3 means an unlabelled `cs:locale` applies for every locale but is lower priority than a language- or dialect-specific `cs:locale`. Fixtures: `locale_EmptyPlusOverrideTerm` (en `weird term` beats unlabelled empty), `locale_EmptyPlusOverrideDate`, `locale_EmptyPlusOverrideStyleOpt`.
5. **Dialect and language match is exact on the primary subtag only for step 2**: step 2 uses the language of the chosen dialect. The spec does not say what happens with a style `cs:locale xml:lang="de-DE"` when the chosen locale is `de-AT`: it is not in steps 1-3 (de-DE appears only for locale files, step 5). Not covered by any fixture.
6. The spec does not say how `xml:lang` values are compared (case, `_` vs `-`, script subtags such as `sr-Latn-RS`). In the corpus, `xml:lang` on style locales is: `en` 876, `de` 226, `fr` 198, `en-GB` 122, `es` 51, `en-US` 38, `pt-BR` 31, ... plus 268 unlabelled. No style in the corpus has two `cs:locale` with the same `xml:lang`; the spec is silent on that case.

### Term form fallback (applies inside the chain, per rule 3)

Spec, *Terms*: "verb-short" -> "verb" -> "long"; "symbol" -> "short" -> "long"; "short" -> "long"; "verb" -> "long". Also `long-ordinal-01..10` fall back to the ordinal-suffix term set. "If no locale or form fallback is available, the term is rendered as an empty string." Fixture `locale_UnknownTerm` (verb form of `interviewer`, defined in en-US) confirms the end-to-end behaviour.

Term forms in the data (`locales-*.xml`, all files): no form attribute (long) 12694, `short` 5137, `verb` 1754, `verb-short` 1163, `symbol` 144. Attributes that occur on `cs:term`: `name`, `form`, `gender-form` (317), `gender` (133), `match` (23).

### Ordinals do not fall back termwise

Spec, *Ordinal Suffixes*: "(re)defining any of the ordinal terms through `cs:locale` replaces all previously defined ordinal terms." The set is `ordinal` and `ordinal-00` .. `ordinal-99` (including their `gender-form` and `match` variants). So at each chain step the question is "does this source define **any** ordinal term"; if yes, that source supplies the entire ordinal set. `long-ordinal-NN` are in a different group (individual terms with a `gender-form`, schema `terms.long-ordinals`) and are not stated to be part of the replace-all rule.

- Fixture `number_SeparateOrdinalNamespaces` (default-locale `fr-FR`; style defines `ordinal`, `ordinal-01` x3, `ordinal-02`): all output comes from the style's set; fr-FR's `ordinal-01 ... match="whole-number"` terms do not leak in.
- Fixture `number_NewOrdinalsWithGenderChange`: style `xml:lang="fr-FR"` replaces the fr-FR ordinal set.
- Data: all 63 locale files except `he-IL` define `ordinal`; `he-IL` has no ordinal term at all, so a Hebrew style falls to `en-US`'s whole set (`th`/`st`/`nd`/`rd`), per rule above.
- The legacy CSL 1.0 scheme applies "when neither the style or locale file define the `ordinal` term, but do define `ordinal-01` through `ordinal-04`" (Spec, *Ordinal Suffixes*). No shipped locale file triggers it (every file with ordinal terms defines `ordinal`); it could be triggered only by a style.
- Matching rules at render time: `match` = `last-digit` (default for `ordinal-00..09`), `last-two-digits` (default for `ordinal-10..99`), `whole-number`; the 10-99 group beats the 00-09 group (e.g. 13); `long-ordinal-NN` always whole-number for 1-10, else falls to `ordinal`; gender: look up term with `gender-form` equal to the target noun's `gender`, else neuter (no `gender-form`). Rendering of ordinal day-of-month uses the **month** term's `gender`.

## 3. How `cs:locale` in the style merges

- Placed directly after `cs:info` (Spec, *Locale*). Schema: `cs:locale` has optional `xml:lang`, and contains `style-options?`, `date*`, `terms?` in any order (schema `style.locale`).
- Merge is **per unit, not per element**. A style `cs:locale` that defines only `<term name="editor" form="short">` overrides just that term form; every other term still comes through the chain.
- Dates: a style `cs:locale` `<date form="text">` replaces the whole localized `text` format of lower-priority sources; there is no partial merge of `cs:date-part`s. Fixture `locale_EmptyDate`: the unlabelled style date replaces the `en-US` file's `text` format. Fixture `locale_EmptyPlusOverrideDate`: the `xml:lang="en"` date beats the unlabelled one.
- Style options: fixtures `locale_EmptyStyleOpt`, `locale_SpecificStyleOpt`, `locale_EmptyPlusOverrideStyleOpt`. Whether the unit is the element or each attribute is not stated; the schema gives both attributes a default of `false`. In the data every locale file's `cs:style-options` carries `punctuation-in-quote` and only fr-FR, fr-CA, lij-IT, pt-BR also carry `limit-day-ordinals-to-day-1="true"`.
- A `cs:term` content is either text or `cs:single` + `cs:multiple` (schema `terms.term`). Term-level attributes `gender` (on a long-form term of a number-variable or month name) and `gender-form`/`match` (ordinals) travel with the term. The spec does not say whether `gender` is a separate unit if a style overrides the text of a term but omits `gender`; fixture `number_SeparateOrdinalNamespaces` redeclares `gender` on `issue` and `edition` with a comment "same as locale", suggesting authors expect to have to repeat it.

Corpus (1675 of 2801 styles have `cs:locale`): children used inside style locales: `terms` 2004, `date` 237, `style-options` 95. Term attributes used: `form` 5930, `gender` 37, `gender-form` 10, `match` 9; 295 `ordinal*` terms.

### Fixed-locale consequence

Because the output locale is fixed at compile time, every `cs:locale` whose `xml:lang` is not the chosen dialect, its language, or absent is dead and can be dropped at compile time (the chain above never reads it). Example: a style with `default-locale="en-US"` and `<locale xml:lang="de">` can ignore the `de` block entirely. (This is a corollary of the spec chain plus map #1's "no runtime locale switching", not a spec statement.)

## 4. What localisable units exist

All names below are in the schema/spec; `vendor/locales/locales-en-US.xml` defines 384 (name, form) term keys, `cs:style-options`, a `text` and a `numeric` `cs:date`.

**Terms** (Spec, *Appendix II - Terms*; en-US data):
- type terms (one per item type, long and short), name-variable terms (author, editor, ... with `long`, `short`, `verb`, `verb-short`), number-variable terms (edition, issue, volume, ... `long`/`short`), locators (page, chapter, section [with `symbol`], paragraph [`symbol`], ...).
- months `month-01..12` (long, short; long form may carry `gender`), seasons `season-01..04`.
- ordinals: `ordinal`, `ordinal-00..99`, `long-ordinal-01..10`.
- punctuation: `open-quote`, `close-quote`, `open-inner-quote`, `close-inner-quote`, `page-range-delimiter`, `colon`, `comma`, `semicolon`.
- misc: `and` (long and `symbol`), `and others`, `et-al`, `ad`, `bc`, `bce`, `ce`, `circa`, `no date`, `anonymous`, `accessed`, `available at`, `at`, `by`, `from`, `in`, `ibid`, `loc-cit`, `op-cit`, `henceforth`, `forthcoming`, `in press`, `online`, `retrieved`, and others.
- Terms the data has that Appendix II does not list explicitly as such: `editortranslator` and `editor-translator`, `legal_case`, `personal_communication`, `page-first`, `first-reference-note-number`. (The PoC emits `editortranslator`; the data has both spellings.)

**Date formats**: `text` and `numeric` only (schema `date.form`). Per locale file exactly one each. They are consulted when `cs:date` carries `form`; `date-parts` limits which parts, child `cs:date-part` elements override attributes but not order or affixes (Spec, *Date*).

**Options**: `punctuation-in-quote` and `limit-day-ordinals-to-day-1` (Spec, *Locale Options*).

**Term-bearing grammar**: `gender` (on `long` term, for number-variable terms and months), `gender-form`, `match`.

### Coverage gaps in the data (affects the final `en-US` step)

`locales-en-US.xml` is the last resort. Other files define fewer term keys than en-US (counts of en-US keys missing): en-GB 0, tl-PH 0, fr-FR/fr-CA 7, af-ZA 52, de-DE 57, es-ES 58, zh-CN 58, ... hy-AM 92, bal-PK 143, pa-PK 137, brh-PK 141, ms-MY 226 (only 158 terms). The chain therefore routinely mixes languages within one output for sparse locales; this is spec behaviour, not a bug. Every file has both date formats and `cs:style-options`.

## 5. What the compiler must resolve at compile time

Given a fixed output locale, resolution reduces to: for each unit the style can reach, walk steps 1-6 once and embed the value (or the fact it is empty). Units the compiler can discover statically from the style tree:

| Style construct | Units reached |
|---|---|
| `cs:text term=T form=F plural=P` | (T, F) single and, when P is runtime or true, multiple. Includes terms like `no date`, `ibid`, `accessed`. |
| `cs:label variable=V form=F plural=P` | term named by V (`page`, `locator`, any number variable), form F, single/multiple. `variable="locator"` and `variable="page"` are runtime-selected: for `locator` the actual term depends on the cite's locator label (a locator term such as `chapter`, `section`, `verse`, ...), so every locator term in the chosen form may need to be embedded. |
| `cs:names` / `cs:label` in names | role terms from `variable` (editor, translator, `editortranslator`, `editor-translator`), form F; `and` (`text` form long, `symbol` for `and="symbol"`); `et-al` or `and others` (`et-al term=...`, default et-al), even when the style has no explicit `cs:et-al`. |
| `cs:date form=text|numeric` | the localized date format for that `form`; month terms (long/short) for text months, `season-01..04`, `ad`/`bc`. Date ranges use an en dash by default (Spec, *Date Ranges*), not a term. `cs:date` without `form` needs only month/season terms if `date-part name=month` is not numeric. |
| `cs:date-part name=day form=ordinal` | ordinal set, plus `limit-day-ordinals-to-day-1`, plus month term `gender`. |
| `cs:number form=ordinal|long-ordinal` | whole ordinal set (replace-all semantics, see 2) and `long-ordinal-01..10`; the term `gender` of the variable's own term (e.g. `edition`) is needed to choose `gender-form`. |
| `quotes="true"` on text | `open-quote`, `close-quote`, and inner pair when nested; `punctuation-in-quote` option. |
| page ranges (`page`, `locator`, ranges in `cs:number`) | `page-range-delimiter` term (CSL 1.0.1+; Spec, *Page Ranges*, line ~1908). en-US and fr-FR (v0.0.97) use an en dash; `locales-de-DE.xml` uses a non-breaking hyphen (U+2011). Fixtures `locale_PageRangeDelimiterTermDefined`, `...Undefined` (en dash expected). Note `...FrenchUndef` (default-locale fr-FR) expects a non-breaking hyphen, which disagrees with the v0.0.97 fr-FR data (en dash); the fixture and the data are out of step. |
| `cs:text variable=title text-case=title` | no locale unit, but English-only behaviour depends on `default-locale` (Spec, *Non-English Items*): absent or primary tag `en` means items are assumed English unless `language` says otherwise; any other primary tag means assumed non-English unless the item's `language` starts with `en`. Fixtures `locale_TitleCase*` (several use `default-locale="fr-FR"` or an item `language`). This is a runtime test on item data with a compile-time-known default. |
| `cs:choose` `position`, citation-number terms, `cs:substitute` | no extra units beyond the above; `ibid`/`op-cit`/`loc-cit` only if the style references them with `cs:text term`. |

Not statically knowable: the actual locator label of a cite (runtime), item `language`, and item type (the `type` term via `cs:text term="..."` is static, but a style can use the item type only through `choose type=`, which needs no term).

Notes for "emit only used terms":

- Term reachability above is a superset: the PoC currently collects `//csl:text[@term]` and `//csl:names/csl:label` role terms only (see section 6), so labels on `variable`s, `and`, `et-al`, dates, ordinals and quotes are not yet covered.
- Substitute/macros: the PoC iterates over the whole style document (`//`), so macros are included even if never called. Unused macros could be pruned for locale purposes; that is a compiler-architecture matter (#8).

## 6. PoC (`src/transform.xsl`) versus the spec

Observations only. The PoC already implements steps 1-6 in order via `attempt-1` .. `attempt-6` chained with JS `??`:

1. `attempt-1` style locale `xml:lang = $dialect`; `attempt-2` `xml:lang = $lang` (first token of dialect); `attempt-3` unlabelled; `attempt-4` locale file of `$dialect`; `attempt-5` of `$dialect-primary`; `attempt-6` `en-US`. Order and sources match the spec table.
2. **Empty terms** produce `[""]` (non-null), so `??` stops there: matches rule 2 of section 2.
3. **Form fallback happens inside each source** (template `csl:locale`): when the requested form is not found, it takes the unlabelled (`not(@form)`, i.e. long) term of the same source before the chain moves on. The spec says locale fallback takes precedence over form fallback, i.e. sources 1-6 for (T, `short`) should all be tried before accepting (T, `long`). Example: style `<locale xml:lang="en">` defines `editor` long only; with `form="short"`, the PoC returns the style's long term and never reaches the locale file's `short` (`ed.`). Also, only `short` -> `long` is handled; `verb-short` -> `verb` -> `long` and `symbol` -> `short` -> `long` are not.
4. `effective-form` defaults to `long` when `@form` absent; `plural` is declared in `l10n` but unused; `single`/`multiple` are emitted as `[single, multiple]`.
5. **Missing locale file**: `document()` of a nonexistent file (e.g. `gx`) gives an empty node-set and the `attempt-N` variable becomes empty text, which would produce invalid JS (`( ?? ...`). Not run; inferred from the template structure. `locale_NonExistentLocaleDef` needs the opposite.
6. **No ordinal handling**, no `long-ordinal`, no date formats, no style-options, no seasons/months, no quotes, no `page-range-delimiter` in the PoC yet. `lib.js` has `number_ordinal`/`number_long_ordinal` stubs.
7. Style locale selection uses exact string equality on `@xml:lang`.
8. `dialect-primary` includes `sr-Cyrl-RS` (not in spec table, see section 1).
9. `$lang` is derived as the first `-` token, which is correct for `sr-Latn-RS` -> `sr`; but `de-AT` style `xml:lang="de-DE"` blocks are ignored (consistent with the spec).

## 7. Open questions the sources do not answer

1. Case and subtag normalisation when comparing `xml:lang` values (`en-us`, `en_US`, `sr-Latn` vs `sr`).
2. Whether `limit-day-ordinals-to-day-1` and `punctuation-in-quote` are separate units (per attribute) or one unit (the element) in the chain.
3. Whether `gender` on a term is part of the term unit or a separate one when a style overrides only text.
4. Which source's `gender` is used for the month/number-variable terms when the text comes from a different source than the `gender` attribute.
5. A style that has two `cs:locale` elements with the same `xml:lang` (none in the 2801-style corpus).
6. How to treat style `cs:locale` for the primary dialect (e.g. `xml:lang="de-DE"`) when the chosen locale is `de-AT`: ignored by the spec's chain.
7. Whether `long-ordinal-NN` participates in the ordinal replace-all rule (spec lists only `ordinal` and `ordinal-00..99`).

## 8. Options the compiler could take (not decisions)

- **Locale data access**: (a) keep `document()` over `vendor/locales/*.xml` at XSLT time (as the PoC does); (b) pre-flatten the chain in a build step into one resolved locale XML per style.
- **Chain implementation**: (a) keep six chained variables; (b) build one merged node-set in XSLT (style locales by priority, then files) and select the first match per (name, form) with a key; (b) makes ordinal replace-all and form-fallback-after-locale-fallback easier to express: resolve (name, form) over the six sources, then retry with the next form.
- **Language to primary dialect**: keep the XSLT table, or generate it from `locales.json`.
- **Which units to emit**: per-reachable-unit (section 5) with lazy lookups, versus emitting a full resolved term object for the style and relying on Closure ADVANCED property stripping (#5). The choice interacts with the Closure ADVANCED constraints being researched in #5.
- **Unreachable style locales**: drop `cs:locale` blocks outside the chain at compile time (section 3).
