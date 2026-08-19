# ADR 0002 — Four locales and RTL

| | |
|---|---|
| **Status** | Accepted |
| **Date** | 2026-08-19 |
| **Epic** | E04 |
| **Supersedes** | [0001 — Localisation posture](0001-localisation.md) |

## Context

ADR 0001 settled the posture — four locales, `en` as template and fallback,
gen-l10n with `nullable-getter: false` — and shipped one of them. It deferred
four things to this epic: the `ckb` delegate, the numeral policy, `use-escaping`,
and the translations themselves.

## Decision

### The shipped set, and its one source

| Locale | Code | Direction | Role |
|---|---|---|---|
| English | `en` | LTR | template ARB, source of truth for keys, **and the fallback** |
| German | `de` | LTR | the text-expansion stress case |
| Persian | `fa` | **RTL** | Arabic script, Eastern Arabic numerals |
| Kurdish Sorani | `ckb` | **RTL** | Arabic script plus ڕ ڵ ۆ ێ ھ ە ڤ |

`lib/core/supported_locale.dart` is the only enumeration of shipped locales in
`lib/`. `lib/l10n/supported_locales.dart` is a **projection** of it, and
`test/policy/l10n_posture_test.dart` asserts the ARB filenames map 1:1 onto the
enum, so the app cannot end up with two different answers to "which locales
ship".

**Resolution:** the system locale if it is one of the four, otherwise `en`. The
user may override it in Settings, and the choice persists through the
`locale_tag` column **E02 already shipped in schema v1** — so this epic ships no
migration.

### Measured: gen-l10n's `supportedLocales` is alphabetical

`AppLocalizations.supportedLocales` is emitted in **alphabetical** order:

```
[Locale('ckb'), Locale('de'), Locale('en'), Locale('fa')]
```

Flutter's default resolution falls back to `supportedLocales.first`. Handing
that list to `MaterialApp` would therefore make **Kurdish Sorani** the fallback
for every unsupported system locale — a wrong-language bug that is invisible on
an English device, because an English device resolves `en` by exact match and
never reaches the fallback.

`MaterialApp` is handed `lib/l10n/supported_locales.dart` instead, which is enum
order and therefore `en`-first. A test pins **both** facts: that the list the app
uses is `en`-first, and that gen-l10n's is still alphabetical — so if that ever
changes, someone re-reads why the projection exists rather than deleting it.

### `ckb` needs a vendored delegate trio, and that is measured

Measured on Flutter 3.44.6 and recorded in
`test/l10n/material_delegate_support_test.dart`:

- `kMaterialSupportedLanguages` lists **82** codes and `ckb` is not among them.
  `en`, `de`, `fa` and `ar` all are.
- All three `Global*Localizations` delegates return `false` for `ckb`.
- **The silent half**, and the plan's wording is corrected here: it is
  `DefaultWidgetsLocalizations` — `WidgetsApp`'s built-in fallback — not
  `GlobalWidgetsLocalizations`, that returns `isSupported == true` for **every**
  locale, including the nonsense code `zz`, and hands back a hardcoded
  `TextDirection.ltr`. So fixing only the Material half leaves a Sorani build
  that runs fine and **reads backwards**.
- `DefaultMaterialLocalizations.delegate.isSupported` is
  `locale.languageCode == 'en'`, and `Localizations._loadAll` filters delegates
  by `isSupported`. Under `fa` with only the default delegates there is no
  `MaterialLocalizations` in scope at all, and any `Tooltip`, `SnackBar` or
  `AppBar` back button asserts.

So MindForge vendors a Material, a Cupertino **and** a Widgets delegate for
`ckb`, each serving MindForge's own strings and delegating framework chrome to
the nearest script neighbour.

### `fa` is the numeral base for both RTL locales, and `ar` is not

Measured: `intl` 0.20.2's `numberFormatSymbols` has **no `ckb` entry**, so a
`NumberFormat` for Sorani falls back to Latin digits **silently**. A Sorani UI
full of `1480` reads as untranslated, not as a cosmetic slip.

`fa`'s symbols are the Eastern Arabic block — `ZERO_DIGIT` U+06F0,
`DECIMAL_SEP` U+066B, `GROUP_SEP` U+066C. `ar`'s CLDR default is **Latin**
digits, so borrowing `ar` would produce exactly the bug being avoided. `ckb`
therefore borrows `fa`.

The Arabic-Indic block U+0660–U+0669 is **not** used anywhere: its 4, 5 and 6
are different glyphs from the Eastern Arabic ones Persian and Sorani readers
expect.

### The display face: Vazirmatn, in both roles

E03 measured Lalezar — the closest OFL echo of Fredoka's chunky display voice —
against its own `cmap` and found it **missing five of the seven** letters that
distinguish Sorani from Persian: ڕ ڵ ۆ ێ ە. It is refused. Vazirmatn carries
both the display and the body role, at different weights.

**The Fredoka personality does not survive translation, and no font swap fixes
that.** In `fa` and `ckb` the Sunburst Pop identity is carried by the **shape
language** — the 3px ink border, the hard offset shadow at zero blur, the
press-down translate, the saturated palette on cream. That is enough; those four
things were always the direction. This document does not pretend the swap is
neutral.

### The hard offset shadow does not mirror

Padding, alignment, icon direction, the streak chip, the BEST pills, the nav
bar, the difficulty control, the chart axis and the back affordance all mirror in
RTL. **The shadow does not.** It is a light-source constant — one imaginary light
for the whole app — not a reading-direction property, and a Persian build lit
from the other side would disagree with every reference screenshot.

### `use-escaping` stays off

ADR 0001 deferred this decision to E04 precisely because turning it on changes
how existing messages parse, so it had to be settled before three locales of copy
existed. **Decision: leave it off.** No message in any of the four ARBs contains
a literal `{`, `}` or an apostrophe that ICU would need escaped, and enabling it
would make every future apostrophe in German or English copy a parse hazard
rather than a character.

### Endonyms are not translated

`English`, `Deutsch`, `فارسی`, `کوردیی ناوەندی` are the **same four strings in
all four ARBs**. A user who has accidentally set the app to a language they
cannot read must still be able to find their own — that is the entire purpose of
the Settings language row, and translating the list defeats it. Only
`settingsLanguageSystem` ("Use device language") is translated.

### Game names are translated

`فشاری ستروپ` is a description, not a brand. E07's `GameDefinition` therefore
carries an ARB **key**, never a display string. `appTitle` is the exception: a
wordmark, identical in all four, and bidi-isolated where it sits inside RTL copy.

### No Android work

iOS is the only shipping target. No `android/` manifest edit, no `values-*`
directory, no claim of parity. When Android is picked up it is its own epic.

## Open — and it must not be presented as closed

**Translation quality for `fa` and especially `ckb` needs a native reviewer.**
The strings this epic ships are machine-quality. Sorani is a low-resource
language and game copy is short, idiomatic and dense with UI convention — the
register machine translation is worst at.

**The strings ship, flagged loudly, and release is gated on native review.**
E11's design/QA sweep carries a BLOCKER-graded line item: one native Persian and
one native Sorani reader walk all eight screens on the canonical simulator before
the build is signed off. **No epic between here and there may quietly mark this
done**, and this epic does not.

**Reversal trigger**, carried forward from ADR 0001: if no native Sorani reviewer
is found before E11, ship three locales rather than four. Shipping
machine-quality Sorani to Sorani readers reads as carelessness about the
language, which is the opposite of what including it was for.
