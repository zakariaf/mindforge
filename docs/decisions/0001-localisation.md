# ADR 0001 — Localisation posture

| | |
|---|---|
| **Status** | Accepted |
| **Date** | 2026-08-19 |
| **Epic** | E01 T01.9 |
| **Supersedes** | nothing |

## Context

MindForge ships strings on eight screens. The posture — how many locales, which
ones, where the strings live, how a missing one behaves — has to be settled
**before the first string ships**, because E08, E09 and E10 each write copy and
a posture decided after them is a posture three epics have already guessed at.

E04 is the localization epic. This ADR is not that epic's job: E04 fills the
contract with three more locales, the `ckb` delegate, the numeral formatter, the
bidi helper and the RTL geometry sweep. It does not invent the contract.

## Decision

### Four locales

| Locale | Code | Direction | Role |
|---|---|---|---|
| English | `en` | LTR | template ARB, source of truth for keys, and the fallback |
| German | `de` | LTR | the text-expansion stress case (~30% longer) |
| Persian | `fa` | **RTL** | Arabic script, Eastern Arabic numerals |
| Kurdish Sorani | `ckb` | **RTL** | Arabic script plus the Sorani letters ڕ ڵ ۆ ێ ھ |

**Resolution:** the system locale if it is one of the four, otherwise `en`. The
user can override it in Settings and the choice persists through E02's
`locale_tag` column — which is exactly why persistence sits ahead of
localization in the epic order.

`lib/core/supported_locale.dart` (E02) is the **only** list of shipped locales
in the repository. Every other list — `lib/l10n/supported_locales.dart`, the
test harness's `LocaleCase.all`, `CFBundleLocalizations` — is a projection of
it, asserted against it, never a second list.

### gen-l10n now, one locale shipped in E01

Every user-facing string lives in an ARB and is read through `AppLocalizations`.
`nullable-getter: false` turns a missing key into a **compile** error, which is
a stronger guarantee than any grep over hardcoded literals.

`intl` is a dependency regardless — it is the one `NumberFormat` construction
site E04's `LocaleNumbers` is built on — so the marginal cost of gen-l10n is
`l10n.yaml`, one `flutter: generate: true` line and one delegate list.

### Seeded generation stays locale-independent

Generators produce integers and semantic tokens; localisation happens at render.
A golden vector must not change because the locale changed. E07 owns the test
that proves it. Stated here so E07 and E10 inherit it rather than discovering it.

### `use-escaping` is deferred to E04

Turning it on changes how existing messages parse, so it must be decided
**before** three locales of copy exist, not after. None of the six seeded keys
contains `{`, `}` or an apostrophe, so E01 is unaffected either way.
`untranslated-messages-file` is likewise E04's — it has nothing to report at one
locale.

## Measurements

Both were **run**, not quoted. Every expectation in
`test/l10n/material_delegate_support_test.dart` is written from these outputs, so
a future SDK closing either gap turns E04's workaround red instead of letting it
rot.

### Measurement 1 — `ckb` in `flutter_localizations`

Flutter **3.44.6**, `flutter_localizations` from the SDK. Observed 2026-08-19:

```
MATERIAL en -> true      CUPERTINO en -> true      WIDGETS en -> true
MATERIAL de -> true      CUPERTINO de -> true      WIDGETS de -> true
MATERIAL fa -> true      CUPERTINO fa -> true      WIDGETS fa -> true
MATERIAL ckb -> false    CUPERTINO ckb -> false    WIDGETS ckb -> false
MATERIAL ar -> true      CUPERTINO ar -> true      WIDGETS ar -> true

kMaterialSupportedLanguages count -> 82
ckb in kMaterialSupportedLanguages -> false
```

**`ckb` is absent.** Switching to Sorani without a vendored delegate throws.
`fa` and `ar` are both present, so either is available as a script neighbour to
delegate Material and Cupertino chrome to.

**The silent half, measured, with one correction to the plan's wording.** It is
`DefaultWidgetsLocalizations` — `WidgetsApp`'s built-in fallback — not
`GlobalWidgetsLocalizations`, that accepts everything:

```
DEFAULT_WIDGETS en  isSupported -> true   textDirection -> TextDirection.ltr
DEFAULT_WIDGETS fa  isSupported -> true   textDirection -> TextDirection.ltr
DEFAULT_WIDGETS ckb isSupported -> true   textDirection -> TextDirection.ltr
DEFAULT_WIDGETS zz  isSupported -> true   textDirection -> TextDirection.ltr
```

It claims even the nonsense code `zz`, and returns a hardcoded
`TextDirection.ltr` for **every** locale including `fa`. So fixing only the
Material half leaves a Sorani build that runs fine and **reads backwards**.
E04 T04.4 must vendor a Widgets delegate as well as a Material and a Cupertino
one, and must verify the *actual* delegate list at build time rather than
assuming it.

### Measurement 2 — `ckb` in `intl` number symbols

`intl` **0.20.2**, read from `pubspec.lock`. An exact pin inside
`flutter_localizations`, not a range. Observed 2026-08-19:

```
intl numberFormatSymbols has en  -> true
intl numberFormatSymbols has de  -> true
intl numberFormatSymbols has fa  -> true
intl numberFormatSymbols has ckb -> false
intl numberFormatSymbols has ar  -> true

fa ZERO_DIGIT   -> U+06F0
fa DECIMAL_SEP  -> U+066B
fa GROUP_SEP    -> U+066C
```

**`ckb` has no entry**, so a `NumberFormat` for it falls back to Latin digits
**silently**. A Sorani UI full of `1480` reads as untranslated, not as a
cosmetic slip.

`fa`'s symbols are the Eastern Arabic block `CLAUDE.md` working agreement 12
mandates — U+06F0 zero, U+066B decimal, U+066C group — and **not** the
Arabic-Indic block U+0660–U+0669, whose 4, 5 and 6 are different glyphs. That is
what makes `fa` a safe donor: E04 pins `ckb` to `fa`'s symbol data and asserts
the emitted digit block in a test.

## Alternatives considered

**English only, with a `const` string map.** Rejected. It costs less this week
and forecloses the four-locale product entirely: retrofitting directional
geometry across a built component catalog is the twenty-file unreviewable diff
the whole epic order exists to avoid, and a `const` map has no plural
categories, no placeholder typing and no missing-key compile error.

**Three locales, dropping `ckb`.** Not chosen, but it is the recorded
**reversal trigger** — see below.

## Open questions

**Translation quality for `fa` and especially `ckb` needs a native speaker, and
this is not closed.** The strings E04 ships will be machine-quality. Sorani is a
low-resource language and game copy is short, idiomatic and dense with UI
convention — the register machine translation is worst at.

**Decision: ship the strings, flag them loudly, and gate release on native
review.** E11's design/QA sweep carries a BLOCKER-graded line item: one native
Persian and one native Sorani reader walk all eight screens on the canonical
simulator before the build is signed off. No epic between E01 and E11 may
quietly mark this done.

**Reversal trigger.** If no native Sorani reviewer is found before E11, ship
three locales rather than four. Shipping machine-quality Sorani to Sorani
readers is worse than not offering it — it reads as carelessness about the
language, which is the opposite of what including it was for.

## Consequences

- `CFBundleLocalizations` declares all four from E01 (T01.4), three epics before
  three of them have a translated string. Between E01 and E04 the bundle claims
  four languages and resolves all of them to English. Nothing ships in that
  window, so no user sees it, and declaring it early is the only way the plist
  edit gets a policy test instead of being remembered mid-translation.
- **The Fredoka personality does not survive translation, and no font swap fixes
  that.** Fredoka's rounded, wide, arcade voice has no Arabic-script
  counterpart. In `fa` and `ckb` the Sunburst Pop identity is carried by the
  **shape language** — the 3px ink border, the hard offset shadow at zero blur,
  the press-down translate, the saturated palette on cream. That is enough;
  those four things were always the direction. But a font swap is not neutral
  and this document does not pretend it is.
- `check_arb_parity.sh` cannot pass at one locale. Measured, it exits 2 with
  `FAIL: no locale ARB files (app_*.arb) beside the template`. It sits in
  `tool/skill_gates.sh`'s skip table with that measured reason until **E04**
  lands `app_de.arb`, `app_fa.arb` and `app_ckb.arb`. Its sibling
  `check_i18n_bans.sh lib` runs from E01 onward — it is the half that is
  meaningful at one locale, and the gate that keeps E04's RTL work a string job
  rather than a layout rewrite.
