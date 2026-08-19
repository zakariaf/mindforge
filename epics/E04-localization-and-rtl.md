# E04 · Localization and RTL foundation

| | |
|---|---|
| **Branch** | `epic/04-localization-and-rtl` |
| **Depends on** | E02, E03 |
| **Unblocks** | E05, E07 |
| **Status** | Not started |

## The epic

Turn the one-locale gen-l10n pipeline E01 stood up into a four-locale, two-direction foundation that
every later epic builds on without ever thinking about it again.

Four locales: `en` (template), `de` (the text-expansion stress case), `fa` (RTL, Arabic script,
Eastern Arabic numerals) and `ckb` (RTL, Arabic script plus the Sorani letters ڕ ڵ ۆ ێ ھ). The whole
visible string surface of the eight reference screens is harvested out of
`design/sunburst-pop/app.html`, keyed, given ICU plurals and selects where the copy needs them, and
translated into all four. A custom `LocalizationsDelegate` trio fixes the `ckb` gap in
`flutter_localizations` — measured on this machine, not assumed. A numeral policy module pins the
numbering system per locale so `1,480` renders `۱٬۴۸۰` in Persian and Sorani and `1.480` in German,
and normalises back to ASCII before any parse. One FSI/PDI helper isolates the mixed-script runs. Two
existing skill gate scripts move from E01's skip table into `tool/skill_gates.sh`'s run table so
physical-side geometry becomes a build failure from this commit onward — before E05 writes its first
component. The locale choice persists through the `locale_tag` column **E02 already shipped at schema
v1**, and is restored before the first frame, so there is no flash of the wrong language or the wrong
direction — and no migration. E03 already bundled the Arabic-script faces and the script-aware type
resolution against synthetic exemplars; this epic is the first to have a real translated corpus, so it
re-runs the metric checks against the shipped strings. And the eight English LTR reference PNGs gain a
Persian RTL counterpart under `design/sunburst-pop/screens/rtl/`, rendered from the same `app.html`
through the same `capture-screens.sh`, reading its Persian strings straight out of
`lib/l10n/app_fa.arb` so the reference and the app can never disagree.

The last piece is the harness: `pumpLocalized` and `LocaleCase.all`, added beside E03's
`test/support/harness.dart`. E05 needs it in its first task, so it lands here.

**iOS is the only shipping target.** Android is deferred and this epic does nothing for it — no
`android/` manifest edit, no per-locale `values-*` directory, no claim of parity. The app is built and
run on the iOS Simulator, and the canonical device is the one that is exactly 390×844 logical points:
`MindForge iPhone 14`, UDID `C13DDC02-375D-4E1B-8F81-44EB407D09A4`, iOS 18.6.

## Why we need it

Three reasons, in order of how expensive they get if this epic lands later than it does.

**RTL is not a feature you add.** `EdgeInsets.only(left: 16)` compiles, passes every test, renders
correctly on the developer's LTR screen and is silently wrong in Persian. There is no runtime signal
and no analyzer rule; the only enforcement is a grep gate over source that does not exist yet. If E05
builds twenty components before that gate turns on, retrofitting them is a twenty-file diff nobody can
review, and every one of them has to be re-screenshotted. Turning the gate on now costs nothing,
because `lib/ui/` is empty. That is the whole reason this epic sits before the component library
rather than after the games.

**The numerals reach the board.** Schulte Grid's tiles *are* the numbers 1–25. In `fa` and `ckb` they
render ۱–۲۵, which is a different glyph set with different advance widths, which changes the cell
sizing arithmetic E10 writes. Stroop Rush's HUD counts a score, a clock and a streak multiplier. The
results screen sets a 76px score. Every one of those is a formatter call, and every formatter call has
to be pinned to a numbering system explicitly, because `intl` resolves an unknown locale to Latin
digits silently — a Persian UI full of `1480` reads as untranslated, not as a minor cosmetic slip.
Deciding the policy once, here, is the difference between one module and six ad-hoc `toString()`s.

**`ckb` is a real technical gap, not a translation task.** `flutter_localizations` on Flutter 3.44.6
has no `ckb` — verified below, in the SDK on this machine. Without a vendored delegate, switching to
Sorani takes down `MaterialLocalizations` and silently drops the direction back to LTR. That is a
crash and a wrong-direction bug in the same locale switch, and it is exactly the class of thing that
gets discovered in the release build if it is not built and tested deliberately.

## Current state

Verified by `ls`, `grep` and reading the SDK on 2026-08-19, on `main` at `ddcb79d` (5 commits, clean
tree).

**Nothing in this epic exists yet.** There is no `pubspec.yaml`, no `lib/`, no `test/`. E01 through
E03 create them. What those three epics hand E04:

- **E01** ships `l10n.yaml` at the repo root with exactly six keys — `arb-dir: lib/l10n`,
  `template-arb-file: app_en.arb`, `output-localization-file: app_localizations.dart`,
  `output-class: AppLocalizations`, `nullable-getter: false`, and `synthetic-package: false` so the
  generated code lands in `lib/l10n/` as real, greppable, committed source. It ships
  `lib/l10n/app_en.arb` with **exactly one key, `appTitle`**, the generated `app_localizations.dart` +
  `app_localizations_en.dart`, the `localizationsDelegates` / `supportedLocales` lines in
  `lib/app.dart`, `test/policy/l10n_posture_test.dart`, `test/l10n/app_localizations_test.dart`,
  `docs/decisions/0001-localisation.md` (**"adopt gen-l10n now, ship one locale"**),
  `flutter_localizations` (sdk) and `intl` in `pubspec.yaml`, Fredoka and Nunito bundled at four
  weights with both OFL texts registered through `registerSunburstFontLicences()`,
  `tool/skill_gates.sh` with its run table and its skip table,
  `test/policy/skill_gates_coverage_test.dart`, and the iOS Runner target — whose `Info.plist` already
  declares `CFBundleDevelopmentRegion` = `en` and `CFBundleLocalizations` = `en, de, fa, ckb`.
  `check_i18n_bans.sh lib` is already in the run table and in CI. **`check_arb_parity.sh` is in the
  skip table** with the measured reason *"exits 2 on a directory holding only the template"* — E04 is
  what makes it runnable.
- **E02** ships the drift store: `lib/data/db/app_database.dart` at `schemaVersion => 1`, the STRICT
  `settings` table with `CHECK (id = 'app')`, its four boolean columns **and `locale_tag TEXT NULL`
  with its shape `CHECK`**, all seeded under `if (details.wasCreated)`; `SettingsDao`,
  `SettingsRepository` (the single write path, one `db.transaction` per mutation,
  `@useResult Future<Result<AppSettings, DataFailure>> update(...)`), `settingsProvider` (a stream over
  `watch()` — **there is no `AppSettingsNotifier` anywhere in the app**), `lib/core/result.dart`,
  `lib/core/failure.dart`, `lib/data/data_failure.dart` (including
  `DataFailure.unsupportedLocaleTag`), `clockProvider`, `drift_schemas/drift_schema_v1.json`,
  `test/drift/generated/**` and the all-pairs migration harness that is vacuous at v1 and correct
  forever. Two E02 decisions are load-bearing here and **must not be re-opened**:
  - **`locale_tag` ships in schema v1, so E04 ships no migration.** E02's Definition of done states it
    in those words. `NULL` means "follow the system locale"; the supported set is enforced **on read**
    through `SupportedLocale.tryParse`, and an unrecognised tag degrades to "follow system" and logs
    `UnsupportedLocaleTag` rather than throwing or self-healing. T02.4 already round-trips
    `en`/`de`/`fa`/`ckb`, clears to `NULL`, and degrades `'nl'`.
  - **`lib/core/supported_locale.dart` — `enum SupportedLocale { en, de, fa, ckb }` with `tag`,
    `isRightToLeft` and the total `tryParse` — is the only list of shipped locales in the repo.** E04
    derives `supportedLocales`, the `ckb` neighbour choice and its test matrix from it and declares no
    second vocabulary. `lib/core/app_settings.dart` is E02's file and already carries **five** fields:
    the four booleans plus `SupportedLocale? localeOverride`, with `withLocaleOverride` and
    `withSystemLocale`. E04 adds no field.
- **E03** ships `lib/theme/` and the type stack, which is more than the name suggests:
  - `lib/theme/sunburst_type.dart` — ten steps over Fredoka 600/700 and Nunito 700/800, **plus**
    `enum SunburstScript { latin, arabic }`, `scriptOf(Locale)`, `SunburstType forScript(SunburstScript)`
    and the **DERIVED** `arabicLineFactor`. `SunburstType.of(context)` resolves the script from
    `Localizations.maybeLocaleOf` and returns the Arabic scale under `fa`/`ckb`. Every step declares a
    `fontFamilyFallback` ending in the Arabic body face; `letterSpacing` is 0 on all ten Arabic steps.
  - **The Arabic-script faces are already bundled and licensed by E03 T03.7** — Vazirmatn plus whichever
    display face T03.7's cmap measurement selected (Lalezar if it covered ڕ ڵ ۆ ێ ھ ە ڤ and
    `U+06F0`–`U+06F9` with `GSUB`/`GPOS`, otherwise Vazirmatn at its heaviest bundled weight) — each
    with its OFL text yielded from the one `registerSunburstFontLicences()`. **E04 bundles no font and
    does not edit `flutter: fonts:`.** Read T03.7's recorded outcome before writing T04.8.
  - `lib/theme/sunburst_theme.dart` with `buildSunburstTheme()`, already passed to the `MaterialApp` in
    `lib/app.dart`.
  - `test/support/harness.dart` — **the one app-level harness in the repository** — with
    `Device`/`Device.all` at DPR 2, `useDevice` with `addTearDown(view.reset)`, and `pumpApp` layering
    `MediaQuery` above `MaterialApp` from `.copyWith`; `test/support/design_source.dart`, the parser
    that reads `design/sunburst-pop/system.html` and the Dart theme files as text;
    `test/support/font_tables.dart` (the TTF `cmap`/table-tag reader);
    `test/support/load_app_fonts.dart`; and `dart_test.yaml` with the `golden` tag — E03 T03.9 ships
    the first real-font golden (`type_specimen_arabic_test.dart`), so both land there. E04 **extends**
    them; it creates neither.
  - `test/support/harness_locale_test.dart` carries three tests that assert today's broken state —
    `fa` resolves LTR under the default delegates, and a `Scaffold` under `fa` throws naming
    `MaterialLocalizations`. **T04.4 deletes them in the commit that adds the delegates**, and their
    deletion is part of this epic's proof.

Measured facts about the toolchain, taken today. **Do not re-derive these; do re-assert them in a
test, which is not the same thing.**

| Fact | Where measured | Value |
|---|---|---|
| Flutter / Dart | `flutter --version` | 3.44.6 stable · Dart 3.12.2 · DevTools 2.57.0 |
| `intl` version | `flutter_localizations/pubspec.yaml` line 16 | **`intl: 0.20.2` — an exact pin, not a range.** A caret `^0.20.2` in our pubspec resolves to exactly this. |
| `kMaterialSupportedLanguages` | `flutter_localizations/lib/src/l10n/generated_material_localizations.dart:46518` | 82 language codes. `en` ✓ `de` ✓ `fa` ✓ `ar` ✓ — **`ckb` ✗, `ku` ✗** |
| `kWidgetsSupportedLanguages` | `generated_widgets_localizations.dart:5430` | 82 codes, same set. **`ckb` ✗** |
| `GlobalMaterialLocalizations.delegate.isSupported` | `material_localizations.dart:726` | `kMaterialSupportedLanguages.contains(locale.languageCode)` |
| Material fallback delegate | `packages/flutter/lib/src/material/material_localizations.dart:726` | `bool isSupported(Locale locale) => locale.languageCode == 'en';` — **there is no fallback for `ckb`** |
| Widgets fallback delegate | `packages/flutter/lib/src/widgets/localizations.dart:253` | `bool isSupported(Locale locale) => true;` returning `DefaultWidgetsLocalizations`, which is **LTR** |
| Delegate resolution order | `packages/flutter/lib/src/widgets/localizations.dart:57` | *"Only load the first delegate for each delegate type that supports locale.languageCode"* — **first wins**, and `MaterialApp` appends its defaults *after* ours |
| `intl` number symbols | `intl-0.20.2/lib/number_symbols_data.dart` | `"fa"`: `ZERO_DIGIT '۰'`, `DECIMAL_SEP '٫'`, `GROUP_SEP '٬'`. `"de"`: `,` / `.`. `"en"`: `.` / `,`. **No `"ckb"` entry. No `"ku"` entry.** |
| `intl` date symbols | `intl-0.20.2/lib/date_symbol_data_local.dart` | `"fa"` present. **No `"ckb"`.** |
| `intl` bidi | `intl-0.20.2/lib/src/intl/bidi.dart:112` | `Bidi.isRtlLanguage` regex **does** list `ckb` — so `intl` knows it is RTL even though `flutter_localizations` has no strings for it |
| `"ar"` numerals | `number_symbols_data.dart` | `ZERO_DIGIT: '0'` — **CLDR's modern `ar` default is Latin digits.** `ar` is the wrong numeral base; `fa` is the right one, and this is measured rather than assumed. |

Read the two failure modes off that table, because they are different and both matter:

- **Switching to `ckb` throws.** No delegate supplies `MaterialLocalizations`, so
  `MaterialLocalizations.of(context)` trips `debugCheckHasMaterialLocalizations` in debug and the
  null-check operator in release.
- **Switching to `ckb` also silently renders LTR.** `_WidgetsLocalizationsDelegate.isSupported`
  returns `true` for every locale and hands back `DefaultWidgetsLocalizations`, whose
  `textDirection` is `TextDirection.ltr`. Fixing only the Material half leaves a Sorani UI that runs
  fine and reads backwards. Both halves are the same task.

Design sources, unchanged: `design/sunburst-pop/app.html` (75 486 bytes, `<html lang="en">`, eight
`<figure class="fig">` blocks `s1`–`s8`), `capture-screens.sh` (renders each figure standalone at
390×844 @2× through headless Chrome, `--virtual-time-budget=6000` so the webfonts land),
`screens/*.png` (eight files, 780×1688), `screens/README.md`, `screens/contact-sheet.html`.
There is no `screens/rtl/` and no `data-l10n` attribute anywhere in `app.html`.

## What we will achieve

- `lib/l10n/` holds four ARB files and four generated localisation classes.
  `flutter gen-l10n` is clean and its output is committed and diff-clean.
- `.claude/skills/i18n-rtl-l10n/scripts/check_arb_parity.sh lib/l10n` **runs and passes** for the
  first time in this repository, over four locales, and is in `tool/skill_gates.sh`'s run table
  instead of its skip table. Deleting one key from `app_de.arb` makes it fail — proven and reverted.
- `check_i18n_bans.sh lib` scans real hand-written geometry instead of an empty tree, and
  `test/policy/directional_geometry_test.dart` states the same contract from inside `flutter test`
  including the one rule the grep cannot express: **the hard offset shadow does not mirror.**
- Switching the app to each of `en`, `de`, `fa`, `ckb` does not throw, and `Directionality.of` is
  `ltr`, `ltr`, `rtl`, `rtl` respectively. A `MaterialLocalizations` string is non-empty under `ckb`.
- `LocaleNumbers` — reached from a widget as `LocaleNumbers.of(context)`, from a provider as
  `ref.watch(localeNumbersProvider)`, and from a pure function as `LocaleNumbers.forLocale(locale)` —
  renders `1480` as `1,480` / `1.480` / `۱٬۴۸۰` / `۱٬۴۸۰` and `18.6` as
  `18.6s` / `18,6s` / `۱۸٫۶s` / `۱۸٫۶s`, with those exact strings pinned in tests, and
  `AsciiNumerals.normalize` round-trips every one of them back to the ASCII original.
- `appLocalizationsProvider` and `localeNumbersProvider` give E07's `BoardSnapshot` projection and E10's
  Schulte painter — neither of which has a `BuildContext` — the same strings and the same formatter the
  chrome uses, without a second lookup path.
- `flutter test` proves the seeded-generation contract mechanically: nothing under `lib/core/` or
  `lib/games/` imports `package:intl` or `AppLocalizations`, so a golden vector cannot change because
  the locale changed.
- The Arabic-script type stack E03 measured against synthetic exemplars is re-measured against the
  **real translated corpus**: every shipped `fa` and `ckb` string lays out inside its step's line box,
  every glyph the four ARBs actually use is covered by a bundled face, and no step falls through to an
  OS font. E04 bundles no font; it proves E03's cascade holds for the strings that now exist.
- The locale override survives a relaunch through E02's schema **v1** `locale_tag` column, and a widget
  test proves the **first** pumped frame under a persisted `fa` is already RTL — not the second.
- `design/sunburst-pop/screens/rtl/` holds eight Persian RTL PNGs at 780×1688, produced by
  `./capture-screens.sh --rtl` from the same `app.html` and the same `app_fa.arb` the app ships, and
  `screens/README.md` documents both sets and which one a given task compares against.
- Re-running `./capture-screens.sh` leaves the eight LTR PNGs byte-identical — the `data-l10n`
  attributes added to `app.html` are metadata, not layout.
- `flutter analyze --fatal-infos --fatal-warnings` is clean with `public_member_api_docs` at error.
- `flutter run -d C13DDC02-375D-4E1B-8F81-44EB407D09A4` boots, and toggling the locale through the
  provider flips language and direction live, without a restart.
- PR merged into `main` with CI green.

## Skills to load

| Skill | Why, for this epic |
|---|---|
| `flutter-conventions-index` | The front door. Open first; the 14 cross-cutting house rules every task below inherits, and the routing table for anything this one does not cover. |
| `i18n-rtl-l10n` | **The spine of the epic — read all three references.** `references/arb-and-icu.md` carries the `l10n.yaml` keys, the ARB add/translate workflow, ICU plural/select, placeholder typing, and the "widget vendors a delegate for a non-built-in locale" recipe that T04.4 implements. `references/rtl-and-bidi.md` carries the allow/ban geometry table, the icon mirroring rule, the FSI/PDI helper and the LTR-island cases. `references/numerals-and-calendars.md` carries the four digit systems, the separator trap (`1٫5` is 1.5, not 15), and the format/normalise pair — which the skill names `numberFormatFor` and `normalizeToAscii` and which MindForge ships as `LocaleNumbers` and `AsciiNumerals.normalize` (T04.6 explains why the return type differs). Both gate scripts are its. |
| `design-system-structure` | `references/typography-and-fonts.md` is what T04.8 **verifies rather than builds**: E03 T03.7 already bundled and licensed the faces and E03 T03.9 already declared the per-script cascade, so this epic reads the reference for the failure it is checking for — "a glyph falling through to an arbitrary OS font is a defect, not a graceful fallback — and it is invisible on the developer's device" — plus the rule T04.2 depends on: **casing and punctuation belong in the string table, not the render**, so `BEST`, `ON` and `OFF` are authored capitalised in the ARB and nothing calls `toUpperCase()`. |
| `sunburst-tokens` | `references/shape-and-type.md` is the ten type steps with their measured sizes, weights, tracking and `height`. Rule 1 is why **no** file this epic writes may name a font family or a `letterSpacing`: `check_raw_values.sh` fails on either outside `lib/theme/**`, and `lib/theme/` is E03's. T04.9 adds one doc paragraph to `sunburst_shape.dart` and that is E04's only edit under `lib/theme/`. |
| `widget-golden-and-a11y-testing` | Owns `test/support/harness.dart`, which T04.10 extends rather than forks. `references/golden-two-lanes.md` is the argument for T04.10's shape: refuse layout goldens, use computed geometry — and keep goldens for exactly the four things geometry cannot see, of which **three are ours** (script joining, mirroring, numeral glyphs). It also carries the rule that an RTL golden rendered with Ahem proves nothing, so the real-font lane is mandatory here. |
| `testing-strategy` | Test at the cheapest tier that can assert the behaviour: the numeral, ASCII-normalisation, bidi and ARB-parity tests are pure Dart with no `pumpWidget`. `scripts/check_test_hygiene.sh` before the PR. |
| `state-management-riverpod` | `localeProvider` is a manual `Notifier<Locale>` derived from `settingsProvider`, never a legacy `StateProvider` (rule 4 of the index, and `ban-legacy-providers.sh` enforces it) and never a second `AppSettingsNotifier` (E02 T02.4 states there is none). Rules 4 and 5 are why the locale is derived from the settings stream rather than stored twice, and why the override writes through `SettingsRepository.update` and lets the stream republish. `appLocalizationsProvider` and `localeNumbersProvider` are plain `Provider`s over it — pure derivations, no state. |
| `persistence-drift` | Read-only here. **T04.5 adds no column and no migration** — `locale_tag` ships in E02's schema v1 with its shape `CHECK`, and `SupportedLocale.tryParse` already enforces the supported set on read. The skill is loaded so the reader can confirm that: no Drift symbol past the repository, one `db.transaction` per mutation, writes through `SettingsRepository.update` and never a direct DAO call. If T04.5 finds itself bumping `schemaVersion`, that is a defect in this epic, not a gap in E02. |
| `app-startup-and-bootstrap` | Rule 5: *"palette, text-scale policy, **locale**, and any first-paint choice are read synchronously so frame one paints correct. A flash of the wrong theme is a visible defect."* T04.5's first-frame test is that rule made mechanical. Rule 6 fixes where the restored value enters: a `ProviderScope` override at the composition root, not a post-frame `setState`. |
| `seeded-determinism-and-golden-vectors` | The rule T04.6 must not break: a generator's output is a pure function of its key, entropy has exactly one source, and a shipped generator is frozen. Localisation happens at render; a golden vector that moves because the locale moved means a formatter leaked into `lib/core/` or `lib/games/`. |
| `accessibility-as-code` | Rules 4 and 5 are D8's teeth: never `MediaQuery.withClampedTextScaling`, never `textScaleFactor`, never `FittedBox` / computed `fontSize` / `TextOverflow.ellipsis` to make a label fit — *"they turn 'doesn't fit at 200%' from a loud test failure into truncated text on a device."* A German label that stops fitting takes a smaller base type step; it does not get shrunk at the call site. |
| `ci-pipeline-and-gates` | Rule 1 (every gate names one contract), rule 5 (codegen and generated artifacts are **freshness** gates — run the generator, then `git diff --exit-code`), rule 7 and `references/policy-grep-gate.md` for the three-criteria bar the directional-geometry gate has to clear, and rule 9: gates verify, they never bless. No `--update-goldens` in CI. |
| `codegen-and-toolchain` | `flutter gen-l10n` runs **before** `flutter analyze`, never after; the generated `app_localizations*.dart` are committed and freshness-gated; the same pattern covers `design/sunburst-pop/rtl/strings-fa.json`. |
| `dart3-idioms-and-coding-standards` | `SupportedLocale` is E02's payload-free closed set, so it stays an `enum` and every `switch` over it is exhaustive with no `default:`. Total, non-throwing conversion throughout: `tryParse` returns `null`, `resolveLocale` returns `supported.first`, `AsciiNumerals.parseNum` returns `null`. Nothing here throws on bad input. |
| `error-handling-typed-results` | The locale write goes through `SettingsRepository.update`, which returns `Result<AppSettings, DataFailure>` and is switched exhaustively. A failed locale write is a value, not an exception, and `DataFailure` carries a stable code — never a localized string. |
| `dartdoc-conventions` | `public_member_api_docs` is an error. Every public member of `LocaleNumbers`, `AsciiNumerals`, `Bidi`, the two providers and the three delegates needs a `///` that names its unit, its range and its invariant — and rule 8 is why the "shadow does not mirror" comment sits on the shadow, not in a wiki. |
| `naming-conventions` | `lowercase_with_underscores` files matching their primary declaration, `lowerCamelCase` constants, grouped-and-sorted directives. ARB keys are `lowerCamelCase` and the file name is `app_<locale>.arb` because gen-l10n derives the locale from the suffix. |
| `lint-and-style-config` | `--fatal-infos` is a hard gate and suppression is line-scoped only. A physical-side inset is a directional inset, never an `// ignore:`. |
| `dependency-hygiene` | Read-mostly here: this epic adds **no new pub package**. `intl` and `flutter_localizations` arrived in E01. Rule 7 is why: a translation-memory or ICU helper package would be a network path or a transitive liability for something two modules of our own code already do. Fonts are assets, not dependencies. |

## Tasks

Eleven tasks. T04.1–T04.3 build the catalog, T04.4–T04.7 build the runtime, T04.8–T04.10 build the
enforcement and the harness, T04.11 produces the RTL references.

---

### T04.1 — The locale set, `l10n.yaml`, ADR 0002 and the iOS manifest

**Goal.** Go from one locale to four at the toolchain level, with the decision written down and the
iOS side of it done, before a single string is translated.

**Tests first (TDD).** `test/policy/l10n_posture_test.dart` (edit — E01 created it; this task rewrites
its assertions rather than adding a second posture test):
- `'l10n.yaml declares the four settings the pipeline depends on'` — `arb-dir: lib/l10n`,
  `template-arb-file: app_en.arb`, `output-class: AppLocalizations`, `nullable-getter: false`,
  `synthetic-package: false`. Unchanged from E01; re-asserted because this task edits the file.
- `'lib/l10n holds exactly four ARB files'` — the set of `app_*.arb` basenames is exactly
  `{app_en, app_de, app_fa, app_ckb}`. A fifth file that nobody translated is a failure, not a bonus.
- `'AppLocalizations.supportedLocales is exactly the four shipped locales, en first'` —
  `[Locale('en'), Locale('de'), Locale('fa'), Locale('ckb')]` in that order. Order is load-bearing:
  Flutter's default resolution falls back to `supportedLocales.first`, and D1 says that fallback is
  `en`.
- `'the shipped locale set is derived from SupportedLocale, not typed twice'` — the generated
  `AppLocalizations.supportedLocales` equals
  `SupportedLocale.values.map((l) => Locale(l.tag)).toList()`, and `lib/l10n/supported_locales.dart`
  exposes exactly that list. **E02 T02.2 declared `SupportedLocale` "the only list of shipped locales
  in the repo"** and this test is what keeps that true across the gen-l10n boundary: gen-l10n derives
  its list from the ARB filenames, so without this assertion a fifth ARB or a dropped enum case would
  silently give the app two different answers to "which locales ship".
- `'the ARB set matches SupportedLocale exactly'` — the `app_*.arb` basenames map 1:1 onto
  `SupportedLocale.values.map((l) => l.tag)`. A fifth file that nobody translated fails here, and so
  does an enum case with no ARB.
- `'every supported locale has an @@locale matching its filename'` — parses each ARB and compares.
- `'ADR 0001 is marked superseded and ADR 0002 exists'` — `docs/decisions/0001-localisation.md`
  contains a `Superseded by 0002` line and `docs/decisions/0002-four-locales-and-rtl.md` exists.
- `test/policy/ios_localization_test.dart`, new — parses `ios/Runner/Info.plist` as XML and asserts
  `CFBundleDevelopmentRegion` is `en` and `CFBundleLocalizations` is an array containing exactly
  `en`, `de`, `fa`, `ckb`. This is a grep-class gate that clears the three-criteria bar: textually
  decidable, silent when broken (iOS simply never offers the locale), one line to break.

**Implementation.**
- `l10n.yaml` (edit): no new keys are needed — gen-l10n discovers locales from the ARB filenames — but
  add `untranslated-messages-file: build/untranslated.json` so the gap list is an inspectable artifact
  rather than console noise. `build/` is already ignored.
- `lib/l10n/app_de.arb`, `app_fa.arb`, `app_ckb.arb`: created here carrying **only** `@@locale` and
  the one key E01 shipped (`appTitle`). They are filled in T04.3. Creating them now is what makes
  `check_arb_parity.sh` runnable, which is what makes T04.2's inventory verifiable as it is written.
- `docs/decisions/0002-four-locales-and-rtl.md`: the decision record. Supported set and the fallback
  rule (system locale if supported, else `en`; user override persists). Why `ckb` needs a vendored
  delegate, with the four measured facts from *Current state* quoted with their file and line numbers.
  Why `fa` is the numeral base for both RTL locales and `ar` is not (CLDR's `ar` default is Latin
  digits — measured). Why no Android work is in scope. What is explicitly **not** decided here:
  translation quality, which needs a native speaker (see *Risks*).
- `docs/decisions/0001-localisation.md` (edit): one `**Status:** Superseded by ADR 0002` line at the
  top. Do not rewrite its body — the record of what was decided when is the point of the file.
- `lib/l10n/supported_locales.dart` — `final supportedLocales = SupportedLocale.values.map(...)`, the
  single projection of E02's enum into the `List<Locale>` `MaterialApp` and the test harness both
  consume. **No second list of locale tags is declared anywhere in `lib/`.**
- `ios/Runner/Info.plist` — E01 T01.9 already wrote `CFBundleDevelopmentRegion` = `en` and
  `CFBundleLocalizations` = the four codes, because E01 created the iOS target and knew the locale set.
  This task **re-asserts** it rather than writing it, so a hand-edit to the plist during E02 or E03
  fails here rather than on a device set to Persian. If the keys are genuinely absent, that is an E01
  gap and it is fixed in this task with a one-line note in the PR body.
- `tool/skill_gates.sh` (edit): move `check_arb_parity.sh` out of the skip table and into the run
  table with the argument `lib/l10n`, and delete the skip row's measured reason
  ("exits 2 on a directory holding only the template") — it is no longer true.
  `test/policy/skill_gates_coverage_test.dart` already fails if a script sits in neither table, so the
  move is covered.

**Files.** `l10n.yaml`, `lib/l10n/app_de.arb`, `lib/l10n/app_fa.arb`, `lib/l10n/app_ckb.arb`,
`lib/l10n/supported_locales.dart`, `docs/decisions/0002-four-locales-and-rtl.md`,
`docs/decisions/0001-localisation.md`, `ios/Runner/Info.plist` (re-asserted, edited only if E01's keys
are missing), `tool/skill_gates.sh`, `test/policy/l10n_posture_test.dart`,
`test/policy/ios_localization_test.dart`.

**Skills.** `i18n-rtl-l10n` (`references/arb-and-icu.md` — the `l10n.yaml` settings and the
"forgetting `CFBundleLocalizations`" pitfall), `ci-pipeline-and-gates`
(`references/policy-grep-gate.md`), `codegen-and-toolchain`, `naming-conventions`.

**Screenshot check.** n/a (no visual surface).

**Done when.**
- [ ] `flutter gen-l10n` emits `app_localizations_{en,de,fa,ckb}.dart` and all four are committed.
- [ ] `bash .claude/skills/i18n-rtl-l10n/scripts/check_arb_parity.sh lib/l10n` exits **0** — the first
      time it has ever done so in this repository — and its output is pasted into the PR body next to
      E01's pasted exit-2 output, so the change in status is on the record.
- [ ] `bash tool/skill_gates.sh` runs `check_arb_parity.sh` and `test/policy/skill_gates_coverage_test.dart`
      is green.
- [ ] `plutil -lint ios/Runner/Info.plist` passes and `plutil -p ios/Runner/Info.plist | grep -A5 CFBundleLocalizations`
      shows the four codes.

**Commits.**
1. `test: specify the four-locale posture and the iOS localization manifest`
2. `l10n: add the de, fa and ckb ARB files`
3. `ios: declare CFBundleLocalizations for the four shipped locales`
4. `docs: record ADR 0002, four locales and RTL, superseding ADR 0001`
5. `chore: move check_arb_parity into the skill-gate run table`

---

### T04.2 — Key `app.html` and author the English template

**Goal.** Harvest every visible string on the eight reference screens into `app_en.arb` with typed
placeholders, translator descriptions and real ICU, and make the design source and the template
mechanically provable against each other.

**Tests first (TDD).** `test/l10n/design_string_inventory_test.dart`, driven by a new reader on
E03's `DesignSource`:
- `'every data-l10n key in app.html exists in app_en.arb'` — set difference, reported by key.
- `'every key in app_en.arb appears in app.html'` — the reverse difference, with a documented
  exception list for keys that exist for states the eight stills do not show: `pauseTitle`,
  `pauseResume`, `pauseQuit`, `settingsLanguageSystem` and the three non-evening greetings. The list
  is a `const Set<String>` in the test with a one-line reason per entry, not a wildcard.
- `'every visible text node in a screen figure carries data-l10n, data-num, or an exemption'` —
  walks each `<figure>`'s text nodes and fails on an unmarked non-whitespace run. Exemptions: the
  `9:41` status-bar mock and the `figcaption` prose, which is design commentary and never ships.
- `'every template key declares a description'` — `@<key>.description` is a non-empty string for all
  of them. gen-l10n does not require it; a translator does.
- `'every placeholder in a message is declared with a type in its @-metadata'` — extracts `{name}`
  and `{name, plural, …}` tokens from each message and compares against the declared
  `placeholders` keys, asserting each has a `type` of `int`, `num` or `String`.
- `'no message concatenates a count'` — a message whose text matches `\{\w+\}\s+\w+s\b` outside a
  `plural` block fails. This is the "3 games" hazard caught mechanically rather than in review.
- `'no message hardcodes a digit that should be a placeholder'` — any ASCII digit run in a template
  message fails unless the key is in a short allowlist (`toggleOn`/`toggleOff` have none; the
  allowlist exists for `schulteRange`, which really does say "1 to 25" as prose).

**Implementation.**

*Step one — key the design source.* `design/sunburst-pop/app.html` (edit): every visible text node
inside the eight `<figure>` blocks gains `data-l10n="<key>"`, and every purely numeric node gains
`data-num="<value>"`. Messages with arguments carry `data-l10n-args='{"count":4}'`. This is a
mechanical, reviewable, layout-neutral edit — attributes do not render. Re-run `./capture-screens.sh`
and confirm the eight PNGs are **byte-identical** (`git status --porcelain design/sunburst-pop/screens`
is empty); if a byte moved, the edit was not layout-neutral and must be corrected, not blessed.

*Step two — author the template.* `lib/l10n/app_en.arb` grows from one key to the full inventory. The
authority for the key set is the test above, not this list; the groups and the load-bearing decisions:

| Group | Keys | Decisions that are not obvious |
|---|---|---|
| App and nav | `appTitle`, `navPlay`, `navStats`, `navSettings` | `appTitle` already exists from E01; it stays `MindForge` in **all four** locales (a wordmark is not translated) and T04.7 isolates it. |
| Home | `homeGreeting`, `homeReadyPrompt`, `streakDays`, `dailyMixTitle`, `dailyMixSummary`, `yourGamesTitle`, `gamesUnlocked`, `bestLabel`, `comingSoon` | `homeGreeting` is `{daypart, select, morning{…} afternoon{…} evening{…} other{…}}` — four branches, not a Dart `switch` in a widget. `streakDays` is `{count, plural, …}` for "4 day streak". `dailyMixSummary` carries **two** plurals in one message: `{games, plural, …}, {minutes, plural, …}` → "3 games, 4 minutes"; splicing two localized fragments is what rule 3 of the skill bans. `bestLabel` is authored `BEST` — capitals live in the string (`design-system-structure`), and `SunburstType.label` is the only step that permits caps. |
| Game identity | `gameStroopRushName`, `gameStroopRushTagline`, `gameSchulteGridName`, `gameSchulteGridTagline`, `gameNBackName`, `gameTagsReactionFocus`, `gameAndDifficulty` | The names of the games **are** translated — `فشاری ستروپ` is not a brand, it is a description. E07's `GameDefinition` therefore carries an ARB **key**, not a display string; that is stated here so E07 does not put English in the registry. `gameAndDifficulty` is `{game} · {difficulty}` — the interpunct is authored in the string so an RTL locale can move it. |
| Game detail | `yourBest`, `gamesPlayed`, `difficultyTitle`, `difficultyChill`, `difficultyClassic`, `difficultyBlitz`, `playButton` | |
| Countdown | `getReady` | The numeral itself is `LocaleNumbers.count`, not a string. |
| HUD | `hudTime`, `hudScore`, `hudStreak`, `hudFound`, `hudNext`, `streakMultiplier`, `foundOfTotal` | `streakMultiplier` is `{count, plural, …}` around a localized `×` marker, **not** a literal `x` glued to a digit — `x7` in Persian is `×۷` and the multiplication sign is a different character. `foundOfTotal` is `{found} / {total}` with both placeholders typed `int`, so the separator can change per locale. |
| Stroop | `colourRed`, `colourBlue`, `colourGreen`, `colourYellow` | **Four keys, two uses.** The same key renders the stimulus word and its answer key label (D9). The colour–word mismatch that is the game is generated from semantic tokens in E09 and is locale-independent; only the rendering is localized. The German words are markedly longer (`Gelb` is short, but `Grün` carries an umlaut and Persian `زرد`/`آبی` are shorter still) — the answer-key layout absorbs the range rather than fixing a width. |
| Results | `resultsTitle`, `newPersonalBest`, `finalScore`, `accuracyLabel`, `avgReactionLabel`, `unitMilliseconds`, `longestStreakLabel`, `playAgain`, `homeButton` | `unitMilliseconds` is a **separate key** from the number, rendered as its own isolated run (`references/arb-and-icu.md`: never hand-glue a value and its unit). |
| Stats | `statsAllTime`, `bestScore`, `bestTime`, `timeTrained`, `durationHoursMinutes`, `lastNRuns`, `chartSubtitle`, `chartOldest`, `chartLatest` | `durationHoursMinutes` is `{hours}h {minutes}m` in `en`; the `h`/`m` markers are inside the message so `de` can say `3 Std. 12 Min.` and `fa` can say `۳ ساعت و ۱۲ دقیقه`. `lastNRuns` is a plural. |
| Settings | `settingsTitle`, `settingSound`, `settingHaptics`, `settingReduceMotion`, `settingColourBlind`, `toggleOn`, `toggleOff`, `settingsLanguage`, `settingsLanguageSystem`, `aboutTitle`, `aboutTagline` | `toggleOn`/`toggleOff` are authored `ON`/`OFF` capitalised. They print **inside the switch track**, so their rendered width is a hard constraint that T04.10's matrix measures — German `EIN`/`AUS` and Persian `روشن`/`خاموش` are wider, and the track grows rather than the text shrinking. |
| Pause | `pauseTitle`, `pauseResume`, `pauseQuit` | No PNG exists for the pause sheet; these come from `system.html` §10 and are in the inventory test's exception list with that reason. |

Language names are **endonyms and are not translated**: `English`, `Deutsch`, `فارسی`, `کوردیی
ناوەندی` are the same four strings in all four ARBs. A user who has accidentally set the app to a
language they cannot read must still be able to find their own — that is the entire purpose of the
Settings language row, and translating the list defeats it. Only `settingsLanguageSystem` ("Use device
language") is translated.

*Step three — the reader.* `test/support/design_source.dart` (edit) gains
`Map<String, String> htmlL10nKeys()` returning key → the English text node it marks, plus
`Set<String> htmlNumericNodes()`. It parses attributes with a regex over the same text the capture
script reads — no HTML dependency; `dependency-hygiene` rule 7 is why we do not add one for a
30-line parse.

**Files.** `design/sunburst-pop/app.html`, `lib/l10n/app_en.arb`,
`lib/l10n/app_localizations*.dart` (regenerated, committed), `test/support/design_source.dart`,
`test/l10n/design_string_inventory_test.dart`.

**Skills.** `i18n-rtl-l10n` (`references/arb-and-icu.md` — template-first, `@`-metadata, typed
placeholders, ICU over concatenation), `design-system-structure`
(`references/typography-and-fonts.md` — casing in the string table), `dartdoc-conventions`
(descriptions are written for a translator who cannot see the screen), `testing-strategy`.

**Screenshot check.** `design/sunburst-pop/screens/*.png`, all eight — but as a **null result**: the
`data-l10n` edit must leave every one of them byte-identical. Re-run `./capture-screens.sh` and assert
`git status --porcelain design/sunburst-pop/screens` prints nothing. The RTL counterparts do not exist
until T04.11.

**Done when.**
- [ ] `flutter gen-l10n` is clean and `AppLocalizations` exposes every key as a non-nullable getter.
- [ ] The inventory test passes in both directions; deleting one `data-l10n` attribute makes it fail.
- [ ] The eight LTR PNGs are unchanged.
- [ ] No message in the template splices a count, and every placeholder is typed.

**Commits.**
1. `test: specify the app.html to ARB string inventory contract`
2. `design: key every visible string in app.html with data-l10n`
3. `l10n: author the English template from the eight reference screens`
4. `chore: regenerate localisations for the full English template`

---

### T04.3 — Translate into `de`, `fa` and `ckb`

**Goal.** Ship a real translation of every key into the other three locales, with parity enforced and
untranslated leftovers impossible to miss.

**Tests first (TDD).** `test/l10n/arb_translation_test.dart`:
- `'every locale resolves every key'` — for each of the four locales, `lookupAppLocalizations(locale)`
  and read **every** getter through a generated accessor table; assert none throws and none returns
  empty. Not one key, all of them.
- `'no non-English locale ships the English string'` — for each key in `de`/`fa`/`ckb`, assert the
  message differs from the template, with a `const Set<String>` allowlist of the keys where identity
  is correct and intended: `appTitle` (a wordmark), the four language endonyms, and
  `unitMilliseconds` where `ms` is the SI symbol in German too. Every allowlist entry carries a
  one-line reason. This is the check that catches a copy-pasted ARB, which parity alone cannot see.
- `'ICU branch shapes match the template'` — for each message containing `plural` or `select`, assert
  the placeholder name and the argument type match the template, and that a `select` declares the same
  branch names. Branch *bodies* differ per language; branch *shapes* must not.
- `'Persian and Sorani messages carry no ASCII digits'` — a literal `4` left in a Persian string is a
  translation that was not finished. Placeholders are exempt (they are `{count}`, not a digit).
- `'German is the longest locale'` — for each key, records `de.length` vs `en.length` and asserts the
  **sum** over all keys is at least 1.15× English, then writes the per-key ratios to
  `build/expansion_report.txt` for T04.10 to read. Asserting per-key would be false: some German
  strings are shorter. Asserting the aggregate is what D8's premise actually claims.
- `test/l10n/plural_categories_test.dart` — for each plural message, renders it at
  `count ∈ {0, 1, 2, 3, 11, 100}` in all four locales and asserts a non-empty, distinct-where-expected
  result. Persian and Sorani have CLDR categories `one`/`other`; German has `one`/`other`; English has
  `one`/`other` plus our `=0` specials. **Arabic's six categories are not our problem — we do not ship
  `ar`** — and this test says so in a comment so nobody adds `few`/`many` branches by cargo cult.

**Implementation.** Fill `app_de.arb`, `app_fa.arb`, `app_ckb.arb`. Each carries `@@locale` and every
message; **no `@`-metadata**, which lives only in the template.

Per-locale notes that are decisions, not style:

- **`de`.** Compound nouns are the length risk: `Farbenblind-freundliche Palette`,
  `Reaktionsgeschwindigkeit`, `Persönliche Bestleistung`. Do not invent an abbreviation to make
  something fit — that is T04.10's job to detect and E05's job to solve with a smaller base step.
  Numerals are Latin with German grouping, handled by `LocaleNumbers`, not by the strings.
- **`fa`.** Persian, RTL. Use the Persian letters `ی` (U+06CC) and `ک` (U+06A9), never the Arabic
  `ي`/`ك` — they look similar and break search and font coverage. No ASCII digits anywhere; numbers
  are placeholders. The Persian comma is `،` (U+060C), the question mark `؟` (U+061F); authoring an
  ASCII `?` in `homeReadyPrompt` is a defect the eye will not catch.
- **`ckb`.** Central Kurdish (Sorani), RTL, Arabic script with the additional letters ڕ ڵ ۆ ێ ھ that
  T04.8's coverage test asserts the bundled fonts carry. It is **not** Persian with different words:
  the orthography, the plural formation and the vocabulary differ. Sorani also uses the Arabic comma
  and question mark.

Machine-quality output for `fa` and especially `ckb` is what this task can honestly produce, and it
is not shippable. It is recorded as an open question, carried in the PR body, and E11's design/QA
sweep gates on it. See *Risks*.

**Files.** `lib/l10n/app_de.arb`, `lib/l10n/app_fa.arb`, `lib/l10n/app_ckb.arb`,
`lib/l10n/app_localizations*.dart` (regenerated, committed), `test/l10n/arb_translation_test.dart`,
`test/l10n/plural_categories_test.dart`.

**Skills.** `i18n-rtl-l10n` (`references/arb-and-icu.md` — mirror the key, keep placeholder names and
ICU structure identical, CLDR categories), `testing-strategy`.

**Screenshot check.** n/a (no visual surface — the Persian strings become visible in T04.11, which is
where they are compared).

**Done when.**
- [ ] `check_arb_parity.sh lib/l10n` reports four locales, zero missing keys, zero placeholder
      mismatches.
- [ ] Every key resolves in every locale; no key in `de`/`fa`/`ckb` equals its English string except
      the five allowlisted ones.
- [ ] No ASCII digit appears in any `fa` or `ckb` message.
- [ ] `build/untranslated.json` is empty after `flutter gen-l10n`.
- [ ] `build/expansion_report.txt` exists and the German aggregate ratio is recorded in the PR body.

**Commits.**
1. `test: specify translation completeness, ICU shape parity and digit policy`
2. `l10n: translate the catalog into German`
3. `l10n: translate the catalog into Persian`
4. `l10n: translate the catalog into Central Kurdish`
5. `chore: regenerate localisations for all four locales`

---

### T04.4 — The `ckb` delegate: Material, Cupertino and direction

**Goal.** Make Sorani work at all. Vendor the three delegates `flutter_localizations` does not
provide, verify the gap at build time rather than trusting this document, and prove both halves of
the failure — the throw and the silent LTR.

**Tests first (TDD).** `test/l10n/ckb_delegate_test.dart`:
- `'the SDK gap this delegate exists for is still real'` — asserts
  `GlobalMaterialLocalizations.delegate.isSupported(const Locale('ckb'))` is **false** and
  `isSupported(const Locale('fa'))` is **true**. **This is the verification, not the assumption.** If
  a future Flutter adds `ckb`, this test goes red and someone deletes the delegate deliberately
  instead of shipping dead code forever. Same assertion for
  `GlobalCupertinoLocalizations.delegate` and `GlobalWidgetsLocalizations.delegate`.
- `'every supported locale mounts without throwing'` — a loop over
  `AppLocalizations.supportedLocales` pumping a `MaterialApp` with the full delegate list and a
  `Scaffold`, asserting `tester.takeException()` is null. Written **red first against the delegate
  list without the vendored entries**, so the failure it prevents is observed once rather than
  imagined.
- `'direction follows the locale'` — the same loop asserting `Directionality.of(context)` is
  `ltr, ltr, rtl, rtl` for `en, de, fa, ckb`. Under `ckb` **without** the vendored widgets delegate
  this returns `ltr`, which is the silent half of the bug; the test names it.
- `'Material chrome has real strings under ckb'` — reads
  `MaterialLocalizations.of(context).backButtonTooltip`, `.closeButtonTooltip`,
  `.okButtonLabel` and `.cancelButtonLabel` under `ckb` and asserts each is non-empty and equal to the
  `fa` value, proving the delegation target rather than just the absence of a crash.
- `'Cupertino chrome has real strings under ckb'` — the same for
  `CupertinoLocalizations.of(context).alertDialogLabel`.
- `'the vendored delegates claim only ckb'` — `isSupported` returns false for `en`, `de` and `fa`, so
  the built-in `Global*` delegates keep winning for the locales they do cover. First delegate of a
  type wins (`localizations.dart:57`), so a delegate that over-claims would hijack Persian.
- `'the vendored delegates are listed before MaterialApp's own defaults'` — asserts the position of
  each vendored delegate in `lib/app.dart`'s list is before `GlobalMaterialLocalizations.delegate`.
  A pure ordering test, and ordering is the mechanism.
- `test/l10n/intl_symbol_coverage_test.dart` — asserts
  `NumberFormat.decimalPattern('ckb').symbols.NAME` is **not** `'ckb'` (i.e. `intl` fell back), so the
  reason `LocaleNumbers` pins `ckb` to `fa` in T04.6 is proven rather than asserted in a comment. If a
  future `intl` adds `ckb` symbols, this goes red and the pin gets revisited on purpose.

**Implementation.** `lib/l10n/ckb_localizations.dart`, one file holding three small delegates:

- `CkbMaterialLocalizationsDelegate extends LocalizationsDelegate<MaterialLocalizations>` —
  `isSupported(locale) => locale.languageCode == 'ckb'`;
  `load(locale) => GlobalMaterialLocalizations.delegate.load(_scriptNeighbour)`.
- `CkbCupertinoLocalizationsDelegate` — the same against `GlobalCupertinoLocalizations.delegate`.
- `CkbWidgetsLocalizationsDelegate extends LocalizationsDelegate<WidgetsLocalizations>` —
  `load` returns a `const _CkbWidgetsLocalizations()` whose `textDirection` is
  `TextDirection.rtl`. **This one cannot delegate**, because `GlobalWidgetsLocalizations`'s loader is
  keyed by locale and `ckb` is not in `kWidgetsSupportedLanguages`; and it cannot be omitted, because
  `_WidgetsLocalizationsDelegate.isSupported` returns `true` for everything and would hand back an
  LTR default.

`_scriptNeighbour` is a private constant resolved once, with the fallback chain written down:

```dart
/// The nearest locale `flutter_localizations` actually ships Material and Cupertino
/// strings for. Persian first — same script, same numerals, closest vocabulary — then
/// Arabic. Resolved once at load rather than per lookup.
///
/// Measured on Flutter 3.44.6: `kMaterialSupportedLanguages` holds 82 language codes and
/// contains neither `ckb` nor `ku`. `ckb_delegate_test.dart` re-asserts that every build,
/// so this constant becomes a deliberate deletion the day the SDK covers Sorani.
const _scriptNeighbours = <Locale>[Locale('fa'), Locale('ar')];
```

`lib/app.dart` (edit) — the delegate list, in this order and for this reason:

```dart
localizationsDelegates: const <LocalizationsDelegate<Object>>[
  ...AppLocalizations.localizationsDelegates,   // our ARB strings, all four locales
  CkbWidgetsLocalizationsDelegate(),            // BEFORE Global*: first supporting delegate
  CkbMaterialLocalizationsDelegate(),           // of a type wins, and MaterialApp appends
  CkbCupertinoLocalizationsDelegate(),          // its own LTR/en defaults after this list
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
],
```

**Files.** `lib/l10n/ckb_localizations.dart`, `lib/app.dart`,
`test/l10n/ckb_delegate_test.dart`, `test/l10n/intl_symbol_coverage_test.dart`.

**Skills.** `i18n-rtl-l10n` (`references/arb-and-icu.md` §"Widget vendors a delegate for a
non-built-in locale"), `dart3-idioms-and-coding-standards`, `dartdoc-conventions` (rule 8 — the
invariant is restated at its enforcement point, which is why the fallback chain is documented on the
constant), `testing-strategy`.

**Screenshot check.** n/a (no visual surface — the app has no screens until E08).

**Done when.**
- [ ] All four locales mount, and `ckb` reports `TextDirection.rtl`.
- [ ] Temporarily removing `CkbMaterialLocalizationsDelegate` makes the mount test throw, and
      removing `CkbWidgetsLocalizationsDelegate` makes the direction test fail with `ltr` — both
      observed, both reverted, both stated in the PR body.
- [ ] `flutter run -d C13DDC02-375D-4E1B-8F81-44EB407D09A4` with the locale forced to `ckb` starts and
      does not throw.

**Commits.**
1. `test: prove the ckb gap in flutter_localizations and specify the delegate contract`
2. `l10n: vendor Material, Cupertino and Widgets delegates for ckb`
3. `app: register the ckb delegates ahead of the global ones`

---

### T04.5 — Locale resolution, the context-free providers, and the first frame

**Goal.** Resolve the locale to D1's rule over E02's already-persisted column, expose the strings and
the formatter to code that has no `BuildContext`, and restore the choice before the first frame so
language and direction are never briefly wrong.

**No migration, and no second settings field.** E02 T02.3 ships `locale_tag TEXT NULL` in schema **v1**
with its shape `CHECK`; E02 T02.2 ships `AppSettings.localeOverride` as a `SupportedLocale?` with
`withLocaleOverride` / `withSystemLocale`; E02 T02.4 ships the on-read `SupportedLocale.tryParse`
validation, the degrade-to-system behaviour and the round-trip tests for all four tags. **This task
consumes all of it.** It does not bump `schemaVersion`, does not write a `stepByStep`, does not add a
column, does not declare a `LocalePreference` type and does not touch `lib/data/`. E02's Definition of
done says "the v1 snapshot contains `locale_tag`, so E04 ships no migration" — if this branch produces
a `drift_schema_v2.json`, that is a defect in E04.

**Tests first (TDD).**

`test/l10n/locale_resolution_test.dart` (pure Dart — `resolveLocale` names no Flutter type it cannot
get from `dart:ui`):
- `'a supported system locale wins'` — device list `[de_DE]` → `de`; `[fa_IR]` → `fa`;
  `[ckb_IQ]` → `ckb`.
- `'an unsupported system locale falls back to en'` — `[fr_FR]`, `[ja_JP]`, and the empty list.
- `'a supported language with an unsupported region still matches'` — `[de_AT]` → `de`,
  `[fa_AF]` → `fa`. Region is not part of our supported set and must not defeat the match.
- `'an explicit override beats the system locale'` — device `[en_US]`,
  `localeOverride: SupportedLocale.fa`, resolved `fa`.
- `'a null override means follow the system'` — device `[de_DE]`, override `null`, resolved `de`. This
  is E02's documented meaning of `NULL` and the resolver must not reinterpret it as English.
- `'the resolver reads the supported set from SupportedLocale'` — passing
  `supportedLocales` produces the same answers as passing `SupportedLocale.values`; there is no
  hardcoded `['en','de','fa','ckb']` literal inside `locale_resolver.dart`.

`test/l10n/locale_provider_test.dart`:
- `'localeProvider follows the settings stream'` — a fake `SettingsRepository` emits
  `localeOverride: SupportedLocale.fa`; the provider re-reads `fa` without holding a second copy.
- `'select writes through the repository and does not mutate local state'` — `select(SupportedLocale.ckb)`
  calls `SettingsRepository.update` exactly once and the provider's value changes **only** after the
  stream re-emits. Derive, do not store.
- `'a failed write is a value, not a throw'` — the fake returns `Err(DataFailure.storeUnavailable)`;
  the `Result` is switched exhaustively and the provider keeps its previous value.

`test/l10n/l10n_providers_test.dart` — **the two context-free accessors, and why they exist**:
- `'appLocalizationsProvider resolves the active locale'` — with `localeProvider` at `fa`,
  `ref.read(appLocalizationsProvider).appTitle` is the Persian string; flip to `de` and it is the
  German one, with no `pumpWidget` anywhere in the test.
- `'localeNumbersProvider follows the same locale'` — `ref.read(localeNumbersProvider).score(1480)` is
  `۱٬۴۸۰` under `fa` and `1.480` under `de`.
- `'both providers are the only context-free lookup path'` — a source grep asserting no file under
  `lib/` calls `lookupAppLocalizations` outside `lib/l10n/l10n_providers.dart`.

`test/app/first_frame_locale_test.dart`:
- `'the first frame is already RTL when fa is persisted'` — build a `ProviderScope` with the settings
  repository overridden by a fake pre-seeded to `SupportedLocale.fa`, `await tester.pumpWidget(app)`,
  and assert `Directionality.of` is `rtl` **on that first pump**, with no `pumpAndSettle` and no second
  frame. Then `await tester.pump()` and assert the direction did not change — proving there was no
  flash, not merely that it settled correctly.
- `'the first frame is already Persian when fa is persisted'` — the same pump, asserting the rendered
  `appTitle` is the Persian string. Direction and language are two failures and this test names both.

**Implementation.**
- `lib/l10n/locale_resolver.dart` —
  `Locale resolveLocale({required List<Locale>? deviceLocales, required SupportedLocale? override, required List<Locale> supported})`,
  pure and total: an override wins; otherwise the first device locale whose `languageCode` is in
  `supported`; otherwise `supported.first`, which T04.1's test pins to `en`. `supported` is passed in
  rather than imported so the function stays a pure function of its arguments and the test can drive it
  with a degenerate list.
- `lib/l10n/locale_provider.dart` — `localeProvider`, a manual `Notifier<Locale>` whose `build()` reads
  `settingsProvider.select((s) => s.localeOverride)` and runs it through `resolveLocale` with
  `PlatformDispatcher.instance.locales`, plus one intent method `void select(SupportedLocale?)` which
  calls `ref.read(settingsRepositoryProvider).update(settings.withLocaleOverride(...))` — or
  `withSystemLocale()` for `null` — and switches its `Result` exhaustively. **Not a `StateProvider`**;
  `ban-legacy-providers.sh` enforces that. **Not an `AppSettingsNotifier`**: E02 T02.4 states there is
  no in-memory settings state anywhere in the app, and this provider derives rather than stores.
- `lib/l10n/l10n_providers.dart` — the two context-free accessors five later epics consume:
  ```dart
  /// The [AppLocalizations] for the active locale, reachable without a [BuildContext].
  ///
  /// E07's `BoardSnapshot` projection and E10's Schulte painter run outside the widget
  /// tree and cannot call `AppLocalizations.of(context)`. They read this instead, so
  /// there is still exactly one string source and one locale authority in the app.
  final appLocalizationsProvider = Provider<AppLocalizations>(
    (ref) => lookupAppLocalizations(ref.watch(localeProvider)),
  );

  /// The [LocaleNumbers] for the active locale, reachable without a [BuildContext].
  final localeNumbersProvider = Provider<LocaleNumbers>(
    (ref) => LocaleNumbers.forLocale(ref.watch(localeProvider)),
  );
  ```
  Both are `Provider`, not `Notifier`: they are derivations of `localeProvider` and hold no state of
  their own. A widget with a `BuildContext` keeps using `AppLocalizations.of(context)` and
  `LocaleNumbers.of(context)` — the providers are for the code that genuinely cannot.
- `lib/app.dart` (edit) — `locale: ref.watch(localeProvider)` and
  `localeListResolutionCallback:` delegating to `resolveLocale`, so the resolution rule is one tested
  pure function rather than a framework default nobody read. `supportedLocales:` is
  `lib/l10n/supported_locales.dart`'s list from T04.1.
- `lib/bootstrap.dart` — **no edit needed.** E02 T02.9 already reads settings before `runApp` and seeds
  them through a `ProviderScope` override at the composition root; E02's own text says "E04 must build
  `MaterialApp` with the persisted locale on the first frame" and that override is how. This task
  spends E02's line rather than adding one, and the first-frame test is what proves it.

**Files.** `lib/l10n/locale_resolver.dart`, `lib/l10n/locale_provider.dart`,
`lib/l10n/l10n_providers.dart`, `lib/app.dart`, `test/l10n/locale_resolution_test.dart`,
`test/l10n/locale_provider_test.dart`, `test/l10n/l10n_providers_test.dart`,
`test/app/first_frame_locale_test.dart`. **Nothing under `lib/data/`, `lib/core/` or `drift_schemas/`.**

**Skills.** `state-management-riverpod` (derive-don't-store; `Provider` for a pure derivation;
`ban-legacy-providers.sh`), `app-startup-and-bootstrap` (rule 5 — locale is a first-paint choice read
synchronously; rule 6 — it enters through the composition root, not a post-frame `setState`),
`error-handling-typed-results` (the locale write returns `Result<AppSettings, DataFailure>` and is
switched exhaustively), `dart3-idioms-and-coding-standards`, `persistence-drift` (read-only: confirm
this task adds no column and no migration), `dartdoc-conventions`.

**Screenshot check.** n/a (no visual surface — the Settings language row is E08 T08.9's, built against
`design/sunburst-pop/screens/08-settings.png` and its RTL counterpart from T04.11).

**Done when.**
- [ ] `git diff --stat -- lib/data/ drift_schemas/ lib/core/` is **empty** for this task, and
      `grep -rn 'schemaVersion' lib/data/db/app_database.dart` still reads `=> 1`.
- [ ] `grep -rn 'LocalePreference' lib/ test/` is empty — `SupportedLocale` is the only locale
      vocabulary, per E02 T02.2.
- [ ] `bash .claude/skills/state-management-riverpod/scripts/ban-legacy-providers.sh lib` passes.
- [ ] `bash .claude/skills/persistence-drift/scripts/check-drift-confinement.sh lib` passes — no Drift
      symbol appears in any `lib/l10n/` signature.
- [ ] `appLocalizationsProvider` and `localeNumbersProvider` both follow a locale change, proven
      without a `BuildContext`.
- [ ] The first-frame test is green for direction **and** language, and fails if the settings read is
      moved after `runApp`.

**Commits.**
1. `test: specify locale resolution, the context-free providers and the first frame`
2. `l10n: add the pure locale resolver over SupportedLocale`
3. `l10n: expose localeProvider over the settings repository`
4. `l10n: add appLocalizationsProvider and localeNumbersProvider`
5. `app: resolve the locale from the persisted override before the first frame`

---

### T04.6 — The numeral policy: `LocaleNumbers` and `AsciiNumerals`

**Goal.** One module that decides how every number in MindForge renders, per locale, with the
numbering system pinned explicitly — and one that turns any of it back into ASCII before a parse or a
comparison ever happens.

**Tests first (TDD).** `test/l10n/locale_numbers_test.dart`, pure Dart, table-driven, **pinning exact
strings**. The design figures are the fixtures, so the test doubles as a check that the reference
screens are reproducible:

| Method | Input | `en` | `de` | `fa` | `ckb` |
|---|---|---|---|---|---|
| `score` | `1480` | `1,480` | `1.480` | `۱٬۴۸۰` | `۱٬۴۸۰` |
| `score` | `1240` | `1,240` | `1.240` | `۱٬۲۴۰` | `۱٬۲۴۰` |
| `count` | `128` | `128` | `128` | `۱۲۸` | `۱۲۸` |
| `count` | `25` | `25` | `25` | `۲۵` | `۲۵` |
| `seconds` | `18.6` | `18.6` | `18,6` | `۱۸٫۶` | `۱۸٫۶` |
| `seconds` | `12.4` | `12.4` | `12,4` | `۱۲٫۴` | `۱۲٫۴` |
| `clock` | `Duration(seconds: 23)` | `0:23` | `0:23` | `۰:۲۳` | `۰:۲۳` |
| `percent` | `0.92` | `92%` | `92 %` | `۹۲٪` | `۹۲٪` |
| `tile` | `7` | `7` | `7` | `۷` | `۷` |
| `tile` | `25` | `25` | `25` | `۲۵` | `۲۵` |

Every expected string is written in the test as an escaped code-point literal
(`'۱٬۴۸۰'`) with the rendered form in a trailing comment, so a reviewer can
read it and a broken editor cannot silently mangle it.

Further assertions:
- `'ckb formats identically to fa'` — the whole table again, asserting `ckb == fa` output for every
  row, which is the pin `intl_symbol_coverage_test.dart` justified.
- `'fa uses the Persian block, never the Arabic-Indic block'` — every emitted digit code point is in
  `U+06F0..U+06F9`, and none is in `U+0660..U+0669`. Showing `٤٥٦` to a Persian reader is a defect,
  and these are distinct Unicode blocks whose glyphs for 4, 5 and 6 differ.
- `'the separators are the Persian ones'` — the group separator is `U+066C` and the decimal separator
  is `U+066B`, not their ASCII lookalikes.
- `'German grouping is a dot and its decimal is a comma'` — the inverse-of-English trap, asserted
  rather than assumed.

`test/l10n/ascii_numerals_test.dart`:
- `'normalize folds both Eastern blocks'` — `۰۱۲۳۴۵۶۷۸۹` → `0123456789` and `٠١٢٣٤٥٦٧٨٩` →
  `0123456789`. Folding one and not the other is the exact failure the skill calls out.
- `'normalize folds the separators, not just the digits'` — `'۱٫۵'` → `'1.5'` and `'۱٬۲۳۴'` →
  `'1234'`. **`1٫5` means 1.5, not 15**; digits-only normalisation silently corrupts.
- `'parse round-trips every row of the format table'` — for all four locales and every row above,
  `AsciiNumerals.parseNum(LocaleNumbers.of(locale).score(v))` equals `v`. This is the property that
  makes the format table safe rather than decorative.
- `'parse returns null on garbage, it does not throw'` — `''`, `'abc'`, `'۱۲٫۳٫۴'`. Total function.
- `'normalize is idempotent'` — `normalize(normalize(s)) == normalize(s)` over a seeded fuzz of mixed
  strings.
- `'isolate characters are stripped'` — `U+2066`–`U+2069` never survive normalisation, so a value
  that passed through T04.7's bidi helper can never reach storage carrying them.

`test/policy/locale_independence_test.dart` — **this is D3's "seeded generation stays
locale-independent" made mechanical, and it is a source-graph property no runtime test can prove:**
- No file under `lib/core/` imports `package:intl`, `package:flutter/material.dart`, or
  `app_localizations.dart`.
- No file under `lib/games/` imports `package:intl` or `app_localizations.dart`.
- `lib/l10n/locale_numbers.dart` and `lib/l10n/ascii_numerals.dart` are the only files in `lib/` that
  import `package:intl`.
- **`lib/l10n/locale_numbers.dart` is the only `NumberFormat` construction site in `lib/`** — asserted
  as `grep -rn 'NumberFormat' lib/ | grep -v 'lib/l10n/locale_numbers.dart'` being empty, which covers
  `NumberFormat(`, `NumberFormat.decimalPattern`, `NumberFormat.percentPattern` and every other named
  constructor in one rule. E07 T07.3's `ScoreFormatter` therefore takes injected closures rather than
  building a formatter of its own, and E07's own spot-check greps for the same thing. One rule, stated
  once, so the two epics cannot assert mutually exclusive versions of it.

The generators those rules protect do not exist yet — E07 owns `GameDefinition`, E09 and E10 own the
round generators. **The fence lands here so it is impossible to breach**, and T04.10's harness gives
those epics the locale loop their golden-vector tests wrap themselves in. E09 and E10's *Done when*
each carry the assertion that their committed vector table is byte-identical under all four locales.

**Implementation.**
- `lib/l10n/locale_numbers.dart` — `final class LocaleNumbers`, cached per locale, with three entry
  points and no fourth:
  - `factory LocaleNumbers.forLocale(Locale)` — the pure one. Everything else is built on it, and it
    is what `localeNumbersProvider` (T04.5) calls.
  - `factory LocaleNumbers.of(BuildContext)` — reads `Localizations.localeOf` and delegates. This is
    what a widget uses.
  - `ref.watch(localeNumbersProvider)` — what code with no `BuildContext` uses.

  **There is no `numberFormatFor(Locale)` returning a raw `NumberFormat`.** Handing a bare formatter to
  a call site puts unit composition and pattern choice back where D3 says they must not live: the
  caller would decide grouping for a Schulte tile, decide fraction digits for a duration, and glue on
  an `s`. `LocaleNumbers` owns those decisions; its methods are the API. Six downstream epics name the
  formatter in their inherited-symbols tables and they name `LocaleNumbers.of(locale)`.

  The numbering system is pinned by choosing the **formatting locale**, explicitly, in one exhaustive
  switch with the reason on each arm:

  ```dart
  /// The locale whose `intl` number symbols this formatter uses.
  ///
  /// `intl` emits a locale's native digits from that locale's own symbol data; a
  /// `-u-nu-` extension is dropped during fallback and buys nothing. A locale `intl`
  /// has no symbols for resolves to the default and silently emits Latin digits, so
  /// `ckb` is pinned to `fa` — same Extended Arabic-Indic block, same separators.
  /// Measured against intl 0.20.2, the exact version flutter_localizations pins:
  /// number_symbols_data.dart has entries for "fa" and "de" and none for "ckb".
  /// `ar` is NOT a candidate: its CLDR default ZERO_DIGIT is '0'.
  static String _formattingLocale(Locale locale) => switch (locale.languageCode) {
        'fa' || 'ckb' => 'fa',
        'de' => 'de',
        _ => 'en',
      };
  ```

  Public surface, each with a `///` naming its unit and its rounding: `score(int)` (grouped,
  `NumberFormat.decimalPattern`), `count(int)` (grouped), `tile(int)` (ungrouped — a Schulte tile is
  never `2,5`), `seconds(double)` (one fraction digit, fixed, no grouping), `clock(Duration)`
  (`m:ss`, digits localized, colon left alone as a neutral), `percent(double)`
  (`NumberFormat.percentPattern`), `milliseconds(int)`, `ordinal(int)`.
  **`LocaleNumbers` never appends a unit.** `s`, `ms`, `h` and `m` are ARB keys from T04.2, composed by
  the caller as separate isolated runs — `references/arb-and-icu.md` is explicit that a value and its
  unit are never hand-glued.
- `lib/l10n/ascii_numerals.dart` — `abstract final class AsciiNumerals` with
  `static String normalize(String)` (both digit blocks, `U+066B` → `.`, `U+066C` dropped, `U+060C`
  dropped, isolate controls stripped) and `static num? parseNum(String)` /
  `static int? parseInt(String)`, both total. The skill's `examples/numeral_normalizer.dart` is the
  starting point; extend it with the isolate-stripping clause, which the example does not carry.
- The same `LocaleNumbers` instance feeds chrome **and** any `CustomPainter`. E10's Schulte board
  paints tiles on a canvas; it receives a `LocaleNumbers` inside its immutable `Scene` rather than
  calling `toString()` — `i18n-rtl-l10n` requires the painter to share the chrome's formatter, and
  `custom-canvas-and-gestures` rule 1 requires it to arrive as Scene data rather than be looked up
  inside `paint()`. **The tile glyph widths change with the locale**, which is the input to E10's cell
  sizing; T04.10's expansion matrix measures them and writes them to the longest-string table.

**Files.** `lib/l10n/locale_numbers.dart`, `lib/l10n/ascii_numerals.dart`,
`test/l10n/locale_numbers_test.dart`, `test/l10n/ascii_numerals_test.dart`,
`test/policy/locale_independence_test.dart`.

**Naming, fixed here for every consumer.** `LocaleNumbers.of(context)` /
`LocaleNumbers.forLocale(locale)` / `localeNumbersProvider` for formatting;
`AsciiNumerals.normalize(s)` / `parseNum` / `parseInt` for the inverse; `Bidi.isolateLtr` /
`isolateRtl` / `isolate` / `strip` for T04.7. E05 through E11 call exactly these. There is no
`numberFormatFor`, no `numberFormatProvider`, no free `normalizeToAscii` and no free `isolateLtr` — an
epic that names one of those is naming a symbol this repository does not contain.

**Skills.** `i18n-rtl-l10n` (`references/numerals-and-calendars.md` — the four digit systems, the
separator table, format-then-parse), `seeded-determinism-and-golden-vectors` (entropy has one source;
localisation is a render-time projection), `testing-strategy` (seeded fuzz, round-trip properties),
`dart3-idioms-and-coding-standards` (total functions, exhaustive switch),
`dartdoc-conventions`.

**Screenshot check.** n/a (no visual surface). The expected strings are lifted from the eight PNGs —
`1,480`, `18.6s`, `0:23`, `6 / 25`, `92%`, `x7`, `128`, `3h 12m` — so the table is a check against the
design source even though nothing is rendered.

**Done when.**
- [ ] Every row of the format table passes for all four locales with exact string equality.
- [ ] The round-trip property holds for every row.
- [ ] `grep -rn "package:intl" lib/ | grep -v "lib/l10n/"` is empty.
- [ ] `grep -rn "NumberFormat" lib/ | grep -v "lib/l10n/locale_numbers.dart"` is empty — the pattern is
      `NumberFormat` without a trailing paren so the named constructors are covered too.
- [ ] `bash .claude/skills/seeded-determinism-and-golden-vectors/scripts/check-determinism-bans.sh lib`
      passes.

**Commits.**
1. `test: pin the per-locale numeral output and the ASCII round trip`
2. `l10n: add LocaleNumbers with the numbering system pinned per locale`
3. `l10n: add AsciiNumerals for normalise and parse`
4. `test: fence intl and AppLocalizations out of core and games`

---

### T04.7 — Bidi isolation

**Goal.** One helper, used everywhere a Latin or numeric run sits inside RTL copy, so nothing visually
reorders — and isolate characters never escape the view layer.

**Tests first (TDD).** `test/l10n/bidi_test.dart`, pure Dart:
- `'isolateLtr wraps in LRI and PDI'` — exact code points `U+2066` and `U+2069`, asserted as
  code units, not as a rendered string.
- `'isolate uses FSI for unknown direction'` — `U+2068` / `U+2069`.
- `'nesting is balanced'` — isolating an already-isolated run produces balanced controls and does not
  double-open.
- `'an empty or whitespace run is returned unchanged'` — wrapping nothing produces nothing; a pair of
  stray controls in the tree is a rendering hazard for zero benefit.
- `'the wordmark inside Persian copy is isolated'` — the concrete case: `aboutTitle` in `fa` is
  `درباره {app}` and `l10n.aboutTitle(Bidi.isolateLtr('MindForge'))` places the controls around
  `MindForge` only. Asserted on the composed string, because the placeholder-not-splice rule is what
  makes it possible.
- `'a duration inside Persian copy is isolated'` — `۱۸٫۶` plus the `s` unit as one isolated run, so
  the number and its unit cannot be split across a direction boundary.
- `'a game id is isolated'` — `stroop_rush` inside an RTL string. Game ids are ASCII identifiers that
  reach the UI only in diagnostics, and they scramble without isolation.
- `'storage never sees an isolate'` — round-trip a `SupportedLocale.tag`, a `clientRunKey` and a
  `gameId` through `AsciiNumerals.normalize` and assert no `U+2066`–`U+2069` survives. The boundary is
  enforced, not documented.
- `test/policy/bidi_single_helper_test.dart` — greps `lib/` for the four raw isolate code points and
  asserts the only file containing them is `lib/l10n/bidi.dart`. One helper, per rule 8 of the skill;
  a second inline `'⁦'` somewhere is exactly how this rots.

**Implementation.** `lib/l10n/bidi.dart` — `abstract final class Bidi` with
`static String isolateLtr(String)`, `static String isolateRtl(String)`,
`static String isolate(String)` (FSI, documented as the last resort because first-strong
mis-guesses on leading punctuation), and `static String strip(String)`. The four control characters
are private `const` fields with their Unicode names in the doc. **Legacy `LRE`/`RLE`/`LRO`/`RLO`
embeddings are not offered at all** — `check_i18n_bans.sh` scans for them and there is no reason to
have them available.

Where the helper is applied, stated here so E05 and E08 do not each invent a policy:

| Run | Helper | Why |
|---|---|---|
| The `MindForge` wordmark inside translated copy | `isolateLtr` | Known-direction Latin; the header, `aboutTitle` and `aboutTagline`. |
| A formatted duration with its unit (`18.6s`, `640 ms`) | `isolateLtr` | Value and unit are one visual run and must not be split. |
| A score or count **on its own** in a `Text` | none | A standalone numeric field sets `textDirection` on the widget instead — the skill's rule: isolate inline, set direction standalone. |
| A game id in a diagnostic or a semantics value | `isolateLtr` | ASCII identifier. |
| A game **name** in `gameAndDifficulty` | none | It is translated text in the ambient direction; isolating it would be wrong. |

**Files.** `lib/l10n/bidi.dart`, `test/l10n/bidi_test.dart`,
`test/policy/bidi_single_helper_test.dart`.

**Skills.** `i18n-rtl-l10n` (`references/rtl-and-bidi.md` — known-direction over FSI, view layer only,
never let isolates reach storage), `dartdoc-conventions`, `naming-conventions`.

**Screenshot check.** n/a (no visual surface). The visible proof is the Persian header in T04.11's
`rtl/01-home.png`, where an un-isolated wordmark would render with its letters at the wrong end of
the line.

**Done when.**
- [ ] `grep -rn $'⁦\|⁧\|⁨\|⁩' lib/` matches only `lib/l10n/bidi.dart`.
- [ ] `check_i18n_bans.sh lib` reports no legacy embeddings.
- [ ] No isolate character survives `AsciiNumerals.normalize`.

**Commits.**
1. `test: specify FSI and PDI isolation and the storage boundary`
2. `l10n: add the single bidi isolation helper`

---

### T04.8 — The Arabic-script type stack, verified against the real corpus

**Goal.** Prove that E03's bundled faces and script-aware type resolution hold for the strings this
epic actually shipped — every glyph the four ARBs use, at every step they use it, in a line box that
does not clip — and record honestly what the identity loses in translation.

**This task bundles nothing.** E01 T01.7 bundled Fredoka and Nunito; **E03 T03.7 bundled the
Arabic-script faces**, registered their OFL texts through the one `registerSunburstFontLicences()`, and
decided the display face from the font's own `cmap` and `GSUB`/`GPOS` tables; **E03 T03.9** declared the
per-step `fontFamilyFallback` cascade, `scriptOf`, `forScript`, the zero `letterSpacing` on Arabic
steps and the DERIVED `arabicLineFactor`. E01 T01.7 states the ownership rule and E03 T03.7 restates
it: **`pubspec.yaml`'s `flutter: fonts:` block is not edited by this epic**, there is no second cmap
reader, no second `font_coverage_test.dart`, and no second answer to per-glyph versus per-script
resolution — E03's `SunburstType.of(context)` resolving from the ambient locale is the mechanism, and
`buildSunburstTheme()` still takes no locale argument.

What E03 could **not** do is test against real text: at E03 there were no translations, so its no-clip
assertions ran against hand-picked exemplars (`ڵێـ`, `چ`, `ژ`, a `ە`-final word). This task closes that
gap now that `app_fa.arb` and `app_ckb.arb` exist, and it is the first task in the sequence that can.

**Tests first (TDD).**
- `test/l10n/arb_glyph_coverage_test.dart` — pure Dart, over the ARB bytes and the font bytes, reusing
  **E03's** `test/support/font_tables.dart`:
  - `'every code point in app_fa.arb and app_ckb.arb is covered by a bundled face'` — the union of code
    points across every message value in both files, minus ASCII and the ICU syntax characters, checked
    against the union of `coveredCodePoints()` over the bundled Arabic faces. The failure message lists
    the uncovered code points with their `U+XXXX` and the key they appear in. This is strictly stronger
    than E03's fixed exemplar list: a translator who reached for `ھۆ` or a ZWNJ (`U+200C`, which Persian
    genuinely needs) finds out here rather than on a device.
  - `'the ARBs use no code point outside the shipped scripts'` — the same union contains nothing in the
    CJK, Devanagari or emoji blocks. A stray character pasted from a translation tool is a tofu waiting
    to happen and `CLAUDE.md` working agreement 6 bans emoji outright.
  - `'app_de.arb needs no Arabic face'` — the German union is covered by Fredoka and Nunito alone. The
    inverse assertion, so the cascade is not silently carrying Latin text.
- `test/l10n/arb_line_box_test.dart` — widget tier, `setUpAll(loadAppFonts)` (E03's file). For every
  ARB key, at the type step T04.2 recorded it as being used at on the reference screens, lay the
  **real translated string** out with a `TextPainter` under `SunburstType.of` for `fa` and for `ckb`
  and assert the painted glyph bounds fit the resolved line box. E03 T03.9 proved this for its
  exemplars and shipped `arabicLineFactor` to make it pass; this proves the factor is still enough for
  the corpus. **If a key fails, the fix is E03's constant, raised here with its new measurement and its
  `// DERIVED:` note updated** — never a `FittedBox`, never a clamped `textScaler`, never an ellipsis
  (`accessibility-as-code` rule 5).
- `test/theme/sunburst_type_test.dart` (**edit**, E03's file) — one added case:
  `'every step's cascade ends in a face that covers the shipped Arabic corpus'`. E03 asserted the
  cascade ends in the Arabic body **family name**; this asserts that family's file covers the union
  from the coverage test above. Family names are strings and a rename would pass E03's version.
- `test/theme/font_licence_test.dart` (**edit**, E01's file, extended by E03) — re-drained here with
  **no change to its frozen family list**. The assertion this task adds is that the list did not grow:
  E04 adds no face, so a new entry means somebody bundled a font in the wrong epic.

**Implementation.** Mostly assertions over code that already exists; the only production edits this
task should produce are a raised `arabicLineFactor` in `lib/theme/sunburst_type.dart` **if and only if**
the corpus test demands one, carrying its new measurement in the existing `// DERIVED:` comment.

*Honesty, written into this file and into ADR 0002.* **The Fredoka personality does not survive
translation.** Fredoka's rounded, wide, high-x-height arcade voice has no counterpart in Arabic script,
and the display face E03 selected — whichever it is — is a different kind of loud, not the same one. In
`fa` and `ckb` the Sunburst Pop identity is carried entirely by the **shape language**: the 3px ink
`#2B1B4D` border, the hard offset shadow at `blurRadius`/`spreadRadius` 0, the press-down translate,
the saturated pop palette on cream. That is enough — those four things are the direction, and the
typeface was always the smallest of them. But a font swap is not neutral and this epic does not pretend
it is. Copy E03 T03.7's recorded display-face outcome into ADR 0002 so the localisation decision record
carries it too, and say in the PR body which face is actually in the binary.

`google_fonts` remains banned. Every face is bundled; there is no HTTP code path in the binary.

**Files.** `test/l10n/arb_glyph_coverage_test.dart`, `test/l10n/arb_line_box_test.dart`,
`test/theme/sunburst_type_test.dart` (edit), `test/theme/font_licence_test.dart` (edit),
`docs/decisions/0002-four-locales-and-rtl.md` (edit), and `lib/theme/sunburst_type.dart` **only if the
corpus raises `arabicLineFactor`**. **No `assets/`, no `pubspec.yaml`.**

**Skills.** `design-system-structure` (`references/typography-and-fonts.md` — the cascade that must end
in full coverage, and why a `height` tuned for Latin shears other scripts), `sunburst-tokens`
(`references/shape-and-type.md` — the steps whose factor may move, and rule 1: the change happens in
`lib/theme/` or nowhere), `i18n-rtl-l10n` (rule 9), `accessibility-as-code` (rule 5 — the line box
grows, the type never shrinks), `testing-strategy` (rule 11 — say what the test does not prove).

**Screenshot check.** n/a here; the visual proof is T04.11's `rtl/*.png`, where a missing glyph shows as
a tofu box and a sheared ascender shows as a clipped numeral. Named there rather than claimed here.
**What this task cannot prove:** that the shaped Persian and Sorani text is *readable and correctly
joined to a native reader.* Coverage and bounds are machine-checkable; typographic quality is not. That
is E11 T11.5's native-speaker line item.

**Done when.**
- [ ] `git diff --stat -- pubspec.yaml assets/` is **empty** for this task.
- [ ] The ARB glyph union is fully covered, and deleting one code point from a bundled face's expected
      set is the only way to make an uncovered glyph pass.
- [ ] Every ARB key's real `fa` and `ckb` string fits its step's line box; if `arabicLineFactor` moved,
      the new measurement and the key that drove it are in the `// DERIVED:` comment and the PR body.
- [ ] `test/theme/font_licence_test.dart`'s frozen family list is **unchanged** from E03.
- [ ] `bash .claude/skills/design-system-structure/scripts/check_font_bundling.sh lib` passes and no
      `package:google_fonts` import exists anywhere.
- [ ] `bash .claude/skills/sunburst-tokens/scripts/check_raw_values.sh lib` passes — no `fontFamily:`
      or `fontFamilyFallback:` string was added outside `lib/theme/`.
- [ ] ADR 0002 carries E03's measured display-face outcome and the honest statement about the identity.

**Commits.**
1. `test: assert the shipped ARB corpus is covered by the bundled faces`
2. `test: assert every translated string fits its step's line box`
3. `docs: record the display-face outcome and the identity trade in ADR 0002`

---

### T04.9 — Directional geometry as a build failure

**Goal.** Turn the RTL discipline into a gate that runs on every commit, before there is any code for
it to catch — plus the one rule a grep cannot express.

**Tests first (TDD).** `test/policy/directional_geometry_test.dart`:
- `'no physical-side geometry in lib'` — the same patterns `check_i18n_bans.sh` scans, restated inside
  `flutter test` so a developer who runs only the Dart suite still sees it: `EdgeInsets.only(left:|right:)`,
  `Alignment.centerLeft|centerRight`, `Positioned(left:|right:)`, `TextAlign.left|right`,
  `BorderRadius.only(topLeft:|…)`, `Icons.arrow_back|arrow_forward`. Generated files and
  `app_localizations*.dart` excluded, exactly as the script excludes them, so the two cannot disagree.
- `'the ban list matches the script'` — parses the `scan` invocations out of
  `.claude/skills/i18n-rtl-l10n/scripts/check_i18n_bans.sh` and asserts the Dart pattern list covers
  the same five categories. If the script gains a sixth ban, this test fails until the policy test
  gains it too. A gate and a test that quietly diverge are worse than one of them.
- `'the hard offset shadow does not mirror'` — **the rule of this task that no grep can hold.** Pump a
  plain `DecoratedBox` whose `BoxDecoration.boxShadow` comes from E03's
  `SunburstShape.of(context).shadow(...)` at the e2 step, wrapped in an
  `EdgeInsetsDirectional.only(start: 16)` padding, under `TextDirection.ltr` and under
  `TextDirection.rtl`. Assert the resolved `BoxShadow.offset` is identical — `Offset(5, 5)` both times
  — and that `blurRadius` and `spreadRadius` are 0 both times. Then assert the *padding* on the same
  widget **does** mirror, so the test proves the two behave differently on purpose rather than proving
  nothing mirrors. **No `PopSurface`, no `PopElevation`** — those are E05 T05.3's types and do not exist
  on this branch; E04 depends only on E02 and E03, and the rule belongs to the shape token, not to the
  component built on it. E03 T03.5 is titled "`SunburstShape`, and the shadow that does not mirror" and
  already asserts the LTR half; check it before writing this and make this an **extension** of that
  test file if the assertion is already there, rather than a second copy of it.
- `'directional insets resolve to swapped physical values'` — `EdgeInsetsDirectional.only(start: 16)`
  resolves to `left: 16` under LTR and `right: 16` under RTL. The mechanism, asserted once, so nobody
  has to trust it.

**Implementation.**
- `tool/skill_gates.sh` (edit) — `check_i18n_bans.sh lib` is already in the run table from E01; add a
  comment row noting it now scans real code. Nothing else changes: T04.1 already moved
  `check_arb_parity.sh`.
- `.github/workflows/ci.yml` (edit) — both scripts already run through `tool/skill_gates.sh`; add
  `flutter gen-l10n` before the codegen freshness step if E01 did not already (it did) and extend the
  freshness `git diff --exit-code` glob with `design/sunburst-pop/rtl/strings-fa.json`, which T04.11
  produces.
- **The shadow rule, written where it is enforced.** `lib/theme/sunburst_shape.dart` (edit — E03's
  file) gains one doc paragraph on `shadow()`:

  ```dart
  /// The hard offset shadow does NOT mirror under RTL.
  ///
  /// The offset is a light-source constant — one imaginary light, up and to the left,
  /// for the whole app — not a reading-direction property. Mirroring it would light the
  /// Persian build from the other side and every surface in the app would disagree with
  /// every screenshot. Padding, alignment and icon direction mirror; illumination does
  /// not. `test/policy/directional_geometry_test.dart` asserts both halves.
  ```

  This is the single question a reviewer will raise on the RTL PR, so it is answered in the source, in
  the test, in this epic and in the PR body — four places, because it is counter-intuitive and being
  asked twice is worse than one paragraph.
- `CLAUDE.md` — **read, not edited.** Working agreement **11** (all geometry is directional, with the
  hard-offset-shadow exception) and working agreement **12** (the numeral policy and normalise-to-ASCII)
  are already in the document; E01 T01.6 verified them and ships the gate that keeps the layout block
  honest. This task's job is to make agreement 11 *enforced* — the grep gate over real source and the
  policy test above — not to write it down again. If either agreement is missing when this branch
  opens, that is an E01 T01.6 gap: add it there and note it in the PR body.

**Files.** `test/policy/directional_geometry_test.dart`, `tool/skill_gates.sh`,
`.github/workflows/ci.yml`, `lib/theme/sunburst_shape.dart`. **Not `CLAUDE.md`** — agreements 11 and 12
are already there.

**Skills.** `i18n-rtl-l10n` (`references/rtl-and-bidi.md` — the allow/ban table and the
mirror/never-mirror icon split), `ci-pipeline-and-gates` (rule 1, rule 7,
`references/policy-grep-gate.md` — the three-criteria bar this gate clears: textually decidable,
silent when broken, one line to break), `sunburst-tokens` (rule 4 — the shadow is an ink rectangle at
blur 0, and `SunburstShape.shadow()` is the only `BoxShadow` constructor in the app),
`widget-composition` (`references/structural-layout.md` — the directional structural primitives).

**Screenshot check.** n/a (no visual surface).

**Done when.**
- [ ] `bash .claude/skills/i18n-rtl-l10n/scripts/check_i18n_bans.sh lib` exits 0 over real code, and
      introducing one `EdgeInsets.only(left: 8)` makes both it and the policy test fail — observed and
      reverted.
- [ ] `bash tool/skill_gates.sh` is green and both i18n scripts are in the run table.
- [ ] The shadow test asserts identical offsets under both directions and mirrored padding in the same
      test body.
- [ ] `CLAUDE.md`'s working agreements 11 and 12 were read and confirmed present; this epic added no
      working agreement and the diff does not touch `CLAUDE.md`.

**Commits.**
1. `test: specify directional geometry and the non-mirroring shadow`
2. `theme: document why the hard offset shadow does not mirror`
3. `chore: run the i18n gates over real source in CI`
4. `chore: extend the CI freshness glob for the RTL design-string dump`

---

### T04.10 — The locale and direction test harness

**Goal.** Ship the one helper every later epic pumps its widgets through, plus the expansion matrix
that catches a German overflow before a reviewer does.

**Tests first (TDD).** A harness has no behaviour of its own; its first real assertions are the two
suites in this task that use it. This is the second and last task in the whole sequence whose tests
cannot come first, and like E03's it is kept deliberately small so nothing hides in it.

`test/l10n/text_expansion_matrix_test.dart` — the matrix, and the first consumer:
- One `testWidgets` per (locale × textScale × width) tuple: 4 × 3 × 4 = 48 cases.
  Locales `en, de, fa, ckb`; scales `1.0, 1.3, 2.0`; widths `Device.all` (320, 360, 390, 430 at DPR 2).
  **One test per tuple, not one loop inside one test** — a `RenderFlex` overflow reports once per
  `RenderObject` per frame, so a single test would hide every overflow after the first.
- The surface under test is `_TypeSpecimen`, a test-only widget rendering every ARB key at the type
  step it is used at on the reference screens, inside a `ConstrainedBox` at the case's width. It is
  the closest thing to a screen that exists at this point in the sequence, and it is honest about
  that: it proves the **strings** fit their **type steps**, not that E08's layouts fit.
- `expect(tester.takeException(), isNull)` per case. **Never `takeException()` to swallow**, never
  `FlutterError.onError`, never `ignoreOverflowErrors` — `widget-golden-and-a11y-testing` rule 5.
- A pseudo-locale case: `PseudoLocale.expand(en)`, a **test-only** synthesizer that stretches each
  English string by 1.4× and brackets it. It is not an ARB and never ships — an `app_en_XA.arb` would
  break `check_arb_parity.sh` and put a fake language in `supportedLocales`. It runs as a fifth locale
  in the matrix and catches a truncation that German has not yet reached.
- `'the longest string per type step is recorded'` — writes
  `build/longest_strings_by_step.txt` (step → locale → key → measured width at scale 1.0 via
  `TextPainter`). **That table is E05's input**: when a label stops fitting, D8's rule is that it takes
  a smaller base type step, never a `FittedBox`, never a clamped `textScaler`, never an ellipsis on a
  value.

`test/l10n/rtl_mirroring_golden_test.dart`, `@Tags(['golden'])` — the narrow real-font lane:
- Three goldens per RTL locale over the i18n **primitives**, not over screens: a numeral specimen
  (every digit 0–9 plus `1,480` and `18.6`), a mixed-script specimen (the wordmark inside Persian
  copy, isolated), and a mirroring specimen (a directional row with `Icons.adaptive.arrow_forward`).
  Six files under `test/goldens/rtl/`.
- `setUpAll(loadAppFonts)` in **this suite only** — E03 T03.7's `test/support/load_app_fonts.dart`,
  extended here with nothing (E03 already registers all six faces). **Not a global
  `test/flutter_test_config.dart` hook**: loading real fonts for every test in the repository is the
  opposite of the two-lane discipline this task is built on, and it slows the default lane for the
  ~95% of tests that assert geometry. The golden lane opts in; the default lane stays on Ahem.
  **An RTL golden rendered with Ahem proves nothing** — every glyph is the same box, so broken cursive
  joining and a wrong digit block both pass.
- **What the golden lane proves and does not.** Six PNGs detect a *change* in shaping, mirroring or
  digit block. They do not prove the shaping is *correct*, and they prove nothing at all about
  translation — E03 T03.9 states this for its own specimen and the same limit applies here. The
  correctness proof is T04.11's human comparison against the RTL references plus E11 T11.5's
  native-speaker review.
- Golden the primitives exhaustively and **sample** screens, never the cross-product. E08–E10 add at
  most one sampled screen each; that budget is stated here so the golden lane cannot sprawl.
- CI runs `flutter test --tags golden` on the pinned runner and **compares only**. No
  `--update-goldens` step exists; re-blessing is a local, reviewed act with a titled commit.

**Implementation.** `test/support/harness.dart` (**edit** — E03's file, extended, never forked; there
is one app-level harness in this repository and adding a second `pumpApp` is the failure mode this
whole document exists to prevent):

- `final class LocaleCase { const LocaleCase(this.supported, this.locale, this.direction); }` with four
  const instances and `static const all = <LocaleCase>[en, de, fa, ckb]`. Each case names its
  `SupportedLocale`, so the harness list and the production list are the same vocabulary; a test asserts
  `LocaleCase.all.map((c) => c.supported).toSet() == SupportedLocale.values.toSet()`, which is what
  keeps a fifth enum case from silently going untested. The **direction** is declared rather than
  derived, so a delegate regression that flips `ckb` to LTR fails a test instead of quietly changing
  every golden.
- `test/support/locale_matrix.dart` (**edit** — E02 T02.11's file) — E02 declared
  `const localeMatrix = ['en', 'de', 'fa', 'ckb']` as a pure-Dart tag list for its canonical-storage
  suite, which cannot import `flutter_test`. Re-express it as
  `SupportedLocale.values.map((l) => l.tag)` so the two lists cannot diverge, and leave
  `runInEachLocale` where it is. **Two projections of one enum, not two lists.**
- `extension PumpLocalized on WidgetTester { Future<void> pumpLocalized(Widget child, {required LocaleCase localeCase, required ThemeData theme, TextScaler textScaler = TextScaler.noScaling, bool boldText = false, List<Override> overrides = const []}) }`
  — builds `ProviderScope` → `MaterialApp(locale:, localizationsDelegates:, supportedLocales:, theme:)`
  → `MediaQuery` layered **above** `MaterialApp` from `.copyWith`. It sets the locale and lets
  `Directionality` follow, per the skill's rule 4 and rule 5: **never wrap the tree in a hardcoded
  `Directionality`**, because that is precisely what hides a physical-side bug — it happens to look
  right. It then asserts `Directionality.of` equals `localeCase.direction` before returning, so a
  test that silently ran LTR while claiming RTL cannot exist.
- `Iterable<LocaleCase> get rtlCases` and `ltrCases` for suites that only need one side.
- `test/support/pseudo_locale.dart` — the expander, test-only, ~30 lines.

E05, E07, E08, E09, E10 and E11 all consume `LocaleCase.all`. **None of them declares a second locale
list or a second direction constant**, and `kTestLocales`, `kSupportedLocales` and
`test/support/locales.dart` do not exist — an epic naming one of those is naming a file this repository
does not contain.

Exactly **two** wrappers around `pumpLocalized` are sanctioned, both already agreed in E03 T03.1: E05
T05.2's `pumpPopComponent` in `test/support/component_harness.dart` and E08 T08.1's `pumpShellApp` in
`test/support/shell_harness.dart`. Both take a `LocaleCase` — not a bare `Locale` — and both **delegate
to `pumpLocalized` rather than building their own `MaterialApp`**, so the direction assertion and the
MediaQuery layering happen once. A third wrapper, or either of these two constructing its own
`ProviderScope` → `MaterialApp` chain, is the failure mode this paragraph exists to prevent.

**Files.** `test/support/harness.dart`, `test/support/pseudo_locale.dart`,
`test/support/locale_matrix.dart` (edit), `test/l10n/text_expansion_matrix_test.dart`,
`test/l10n/rtl_mirroring_golden_test.dart`, `test/goldens/rtl/*.png`, `.github/workflows/ci.yml`.

**Skills.** `widget-golden-and-a11y-testing` (`references/harness-and-mediaquery.md` — the four
load-bearing lines and MediaQuery above MaterialApp; `references/overflow-and-textscale.md` — one test
per tuple and the four wrong fixes; `references/golden-two-lanes.md` — the refusal, the two lanes,
`loadAppFonts`, blocking accidental blessing), `accessibility-as-code` (rules 4 and 5 — nothing
shrinks to fit), `testing-strategy`, `i18n-rtl-l10n`.

**Screenshot check.** n/a for the reference PNGs — the six golden files under `test/goldens/rtl/` are
test artifacts, blessed once on the pinned runner, and are a different thing from
`design/sunburst-pop/screens/`. The README T04.11 rewrites says so explicitly so the two never get
confused.

**Done when.**
- [ ] 48 matrix cases plus the pseudo-locale lane, each its own `testWidgets`, all green with
      `takeException()` null.
- [ ] `pumpLocalized` asserts the resolved direction; `LocaleCase.all` is proven equal to
      `SupportedLocale.values`; `grep -rn 'kTestLocales\|kSupportedLocales' test/` is empty.
- [ ] `build/longest_strings_by_step.txt` is produced and its German and Persian maxima are quoted in
      the PR body.
- [ ] `flutter test --tags golden` passes on the pinned runner; the default lane excludes them.
- [ ] `grep -rn "update-goldens" .github/` is empty.
- [ ] `bash .claude/skills/widget-golden-and-a11y-testing/scripts/check-test-hygiene.sh lib test` is
      clean.

**Commits.**
1. `test: add LocaleCase and pumpLocalized to the shared harness`
2. `test: add the locale by text-scale by width expansion matrix`
3. `test: add the pseudo-locale longest-string lane`
4. `test: add the RTL real-font golden lane for numerals, bidi and mirroring`

---

### T04.11 — The Persian RTL reference screenshots

**Goal.** Give RTL work the same class of implementation target LTR has had since day one: eight
Persian, right-to-left PNGs at 390×844 @2×, rendered from the same `app.html` and reading the same
`app_fa.arb` the app ships.

**Tests first (TDD).** `test/l10n/design_string_dump_test.dart`:
- `'the committed fa string dump matches AppLocalizationsFa'` — reads
  `design/sunburst-pop/rtl/strings-fa.json`, and for every key renders the live Persian message with
  the sample arguments declared in `app.html`'s `data-l10n-args`, asserting equality. This is what
  makes the reference screenshots and the app **one** source rather than two that drift.
- `'every data-num node has a Persian rendering'` — every `data-num` value in `app.html` appears in
  the dump's `numbers` map with its `LocaleNumbers.of(fa)` output.
- `'the dump covers every key the eight screens use'` — the same set equality T04.2 asserts against
  the template, now against the dump.
- `test/policy/rtl_screens_test.dart` — `design/sunburst-pop/screens/rtl/` holds exactly the eight
  expected basenames, and each file's PNG header reports 780×1688. A capture that silently rendered at
  the wrong size is otherwise invisible until someone lays it beside an implementation.

**Implementation.**

*The dump.* `tool/dump_design_strings_test.dart`, tagged `@Tags(['tool'])` and excluded from the
default lane, instantiates `AppLocalizations` for `fa`, renders every key with its declared sample
arguments, formats every `data-num` through `LocaleNumbers`, and writes
`design/sunburst-pop/rtl/strings-fa.json`. It runs under `flutter test` because the generated
localisations import `package:flutter/widgets.dart`. CI runs it and then
`git diff --exit-code design/sunburst-pop/rtl/strings-fa.json` — a **freshness gate**, the same
pattern the repo already uses for `*.g.dart`, `*.drift.dart` and `app_localizations*.dart`. Editing an
ARB without re-dumping fails the build.

*The renderer.* `design/sunburst-pop/rtl/render-rtl.py` — reads `app.html`, writes a transformed copy
into a temp directory (**it is never committed**; committing a 75 KB duplicate of the design source is
exactly how two sources of truth are born):

1. `<html lang="en">` → `<html lang="fa" dir="rtl">`.
2. Replaces the text of every `data-l10n` node with its `strings-fa.json` value, and every `data-num`
   node with its Persian numeral rendering.
3. Appends a Google Fonts `<link>` for Vazirmatn and Lalezar and a small `[dir=rtl]` block binding
   them to the display and body roles. **The design page fetching webfonts is not a violation of the
   offline constraint** — `CLAUDE.md`'s rule governs the Flutter binary, and `app.html` has always
   fetched Fredoka and Nunito the same way. The shipped app bundles its faces (T04.8).
4. Leaves every layout rule alone. The mirroring must come from `dir="rtl"` and the stylesheet's own
   logical properties. **Anywhere the CSS uses a physical side and therefore fails to mirror, fix the
   CSS to a logical property** (`margin-inline-start`, `inset-inline-start`, `text-align: start`) —
   that is a real defect in the design source, it is the CSS twin of the Dart rule this epic enforces,
   and fixing it is why the LTR PNGs are re-captured and compared byte-for-byte in the check below.

*The capture.* `design/sunburst-pop/capture-screens.sh` (edit) — accepts `--rtl`. Under `--rtl` it
runs `render-rtl.py` first and writes to `screens/rtl/` instead of `screens/`. The injected capture
CSS, the `--force-device-scale-factor=2`, the `--window-size=390,844` and the
`--virtual-time-budget=6000` are unchanged, so the two sets are directly comparable. Without the flag
its behaviour is byte-identical to today's.

*The README.* `design/sunburst-pop/screens/README.md` (rewritten) documents both sets: the file
table gains an RTL column, the provenance section explains that RTL is rendered from `app.html` plus
`app_fa.arb` rather than from a second HTML file, the regeneration section carries both commands, and
the comparison procedure gains a fourth ordering step for RTL work — **structure mirrors, spacing
rhythm mirrors, surface construction is identical, the shadow offset is identical, type role is the
Arabic-script cascade, numerals are Persian**. It also states plainly that the six files under
`test/goldens/rtl/` are test artifacts and are not these.

*The contact sheet.* `design/sunburst-pop/screens/contact-sheet.html` (edit) — a second row for the
RTL set so both are visible side by side.

**Files.** `design/sunburst-pop/rtl/render-rtl.py`,
`design/sunburst-pop/rtl/strings-fa.json`, `design/sunburst-pop/capture-screens.sh`,
`design/sunburst-pop/screens/rtl/{01-home,02-game-detail,03-countdown,04-stroop-rush,05-schulte-grid,06-results,07-stats,08-settings}.png`,
`design/sunburst-pop/screens/README.md`, `design/sunburst-pop/screens/contact-sheet.html`,
`design/sunburst-pop/app.html` (logical-property CSS fixes only),
`tool/dump_design_strings_test.dart`, `test/l10n/design_string_dump_test.dart`,
`test/policy/rtl_screens_test.dart`, `.github/workflows/ci.yml`.

**Skills.** `i18n-rtl-l10n` (`references/rtl-and-bidi.md` — what must mirror and what must not),
`ci-pipeline-and-gates` (rule 5 — freshness gate; rule 9 — the capture script is run by a human, never
by CI, because a gate that regenerates what it checks asserts nothing),
`design-review-workflow` (the sweep matrix E11 runs against these files).

**Screenshot check.** This task **is** the screenshot check, and it runs in both directions.

*New files, inspected individually:* `rtl/01-home.png`, `rtl/02-game-detail.png`,
`rtl/03-countdown.png`, `rtl/04-stroop-rush.png`, `rtl/05-schulte-grid.png`, `rtl/06-results.png`,
`rtl/07-stats.png`, `rtl/08-settings.png`. Each is laid beside its LTR twin and checked for:
- **Mirroring** — the streak chip, the BEST pills, the nav bar, the difficulty segmented control, the
  chart axis and the back affordance have all moved to the opposite side. Anything that did not move
  is a physical-side CSS rule that T04.11's step 4 must fix.
- **Non-mirroring** — the hard offset shadow is still down-and-right on every raised surface. This is
  the one thing to look at twice; the whole page should look lit from the same direction as the
  English one.
- **Numerals** — the Schulte board reads ۱۰–۲۵, the score reads ۱٬۴۸۰, the timer reads ۰:۱۲٫۴, the
  streak reads ×۷, the accuracy reads ۹۲٪. A Latin digit anywhere is a defect in `strings-fa.json` or
  a missed `data-num`.
- **Glyphs** — no tofu box anywhere, and the Sorani-only letters are not on this page (it is Persian);
  their proof is T04.8's coverage test and E11's on-device `ckb` pass.
- **Clipping** — nothing sheared at the top or bottom of the score, the countdown numeral or the
  Stroop stimulus. A clipped ascender here means T04.8's height floor is too low and the fix is in
  `sunburst_type.dart`, not in the HTML.
- **Bidi** — the `MindForge` wordmark reads left-to-right inside the Persian header and its letters
  are not at the wrong end of the line.

*Existing files, as a null result:* re-run `./capture-screens.sh` with no flag and confirm
`git status --porcelain design/sunburst-pop/screens/*.png` is empty. If a logical-property CSS fix
moved an LTR pixel, that is a **deliberate design change**: keep it, commit the regenerated LTR PNG in
the same commit, and say what moved and why in the PR body. What must never happen is a silently
regenerated reference.

**Done when.**
- [ ] `cd design/sunburst-pop && ./capture-screens.sh && ./capture-screens.sh --rtl` writes 16 files
      and prints OK twice.
- [ ] `file design/sunburst-pop/screens/rtl/*.png` reports `780 x 1688` on all eight.
- [ ] The eight LTR PNGs are unchanged, or every changed one is accounted for in the PR body.
- [ ] `strings-fa.json` is committed and CI's freshness diff is clean.
- [ ] `screens/README.md` documents both sets, both commands, and the RTL comparison ordering.
- [ ] All eight RTL screens were opened beside their LTR twin and the six checks above were performed,
      with the findings listed in the PR's **Screens compared** section — including any that were
      accepted rather than fixed, and why.

**Commits.**
1. `test: specify the fa design-string dump and the RTL screen set`
2. `tool: dump the Persian design strings from the shipped ARB`
3. `design: fix physical-side CSS to logical properties in app.html`
4. `design: render the Persian RTL variant and extend capture-screens`
5. `design: capture the eight Persian RTL reference screens`
6. `docs: document both reference screen sets and the RTL comparison`

---

## Gates that must pass

From the repo root, in this order. `flutter gen-l10n` and the codegen pass run **before** `analyze`,
never after (`codegen-and-toolchain`).

```bash
flutter pub get
flutter gen-l10n
dart run build_runner build --delete-conflicting-outputs
dart format --output=none --set-exit-if-changed .
flutter analyze --fatal-infos --fatal-warnings
flutter test --test-randomize-ordering-seed random
flutter test --tags golden
flutter test --tags tool                       # regenerates strings-fa.json
git diff --exit-code -- 'lib/l10n/app_localizations*.dart' '*.drift.dart' \
  'drift_schemas/' 'design/sunburst-pop/rtl/strings-fa.json'
bash tool/skill_gates.sh
```

Named spot-checks — the gates whose contracts this epic changes, run individually so a failure names
itself:

```bash
bash .claude/skills/i18n-rtl-l10n/scripts/check_i18n_bans.sh                     lib
bash .claude/skills/i18n-rtl-l10n/scripts/check_arb_parity.sh                    lib/l10n
bash .claude/skills/design-system-structure/scripts/check_font_bundling.sh       lib
bash .claude/skills/sunburst-tokens/scripts/check_raw_values.sh                  lib
bash .claude/skills/persistence-drift/scripts/check-drift-confinement.sh         lib
bash .claude/skills/persistence-drift/scripts/check-persistence-bans.sh          lib
bash .claude/skills/state-management-riverpod/scripts/ban-legacy-providers.sh    lib
bash .claude/skills/seeded-determinism-and-golden-vectors/scripts/check-determinism-bans.sh lib
bash .claude/skills/widget-golden-and-a11y-testing/scripts/check-test-hygiene.sh lib test
bash .claude/skills/testing-strategy/scripts/check_test_hygiene.sh
```

The reference captures, run by a human and never by CI:

```bash
cd design/sunburst-pop
./capture-screens.sh            # eight LTR PNGs; must come back byte-identical
./capture-screens.sh --rtl      # eight Persian RTL PNGs into screens/rtl/
git status --porcelain design/sunburst-pop/screens
```

And on the canonical device — the only simulator that is exactly 390×844 logical points, which is why
screenshot comparison uses it and nothing else (iPhone 16 is 393×852, 16 Pro is 402×874):

```bash
xcrun simctl boot C13DDC02-375D-4E1B-8F81-44EB407D09A4
flutter run -d C13DDC02-375D-4E1B-8F81-44EB407D09A4
```

**`tool/skill_gates.sh` is the only sanctioned way to run the skill gates.** Do not glob
`.claude/skills/*/scripts/*.sh` — measured against this repository that loop fails on 29 of the 49
scripts (`CLAUDE.md` working agreement 10).

## Risks and open questions

- **Translation quality is the open question this epic cannot close.** `fa` and especially `ckb` are
  machine-quality here, and Sorani is a low-resource language where machine output is materially
  worse than it is for Persian. Game copy is short, idiomatic and dense with UI conventions — "Nice
  run!", "Get ready", "Tap the colour, not the word" — which is the register machine translation is
  worst at. **Decision: ship the strings, flag them loudly, and gate release on a native-speaker
  review.** T04.3's PR body says so, ADR 0002 says so, and **E11's design/QA sweep carries a
  BLOCKER-graded line item: one native Persian and one native Sorani reader walk all eight screens on
  the canonical simulator before the build is signed off.** No epic between here and there may quietly
  mark this done. Presenting machine translation as shippable is the single most likely way this
  requirement fails in public.
- **The display-face decision belongs to E03 T03.7 and is already made by the time this branch opens.**
  Vazirmatn is the body face; the display face is Lalezar if E03's cmap and `GSUB`/`GPOS` measurement
  cleared it for ڕ ڵ ۆ ێ ھ ە ڤ and `U+06F0`–`U+06F9`, and Vazirmatn at its heaviest bundled weight if
  it did not. **Read E03's recorded outcome before writing T04.8; do not re-run the decision and do not
  bundle a font here.** What E04 adds is the check E03 could not run — coverage against the *real*
  translated corpus rather than a fixed exemplar list — and copying E03's outcome into ADR 0002 so the
  localisation record carries it too. If T04.8's corpus test finds a gap E03's exemplars missed, that
  is a genuine E03 defect: fix it in `lib/theme/` and say so in the PR body.
- **The Fredoka personality does not survive translation, and no font swap fixes that.** In `fa` and
  `ckb` the Sunburst Pop identity is carried by the shape language — the 3px ink border, the hard
  offset shadow at blur 0, the press-down translate, the saturated palette on cream — not by the
  typeface. That is a real and acceptable loss, stated rather than papered over, and it is one of the
  things E11's sweep looks at with a designer's eye rather than a test.
- **`ckb` is absent from `flutter_localizations` and from `intl`'s symbol data, and both absences are
  load-bearing.** Measured on Flutter 3.44.6 / intl 0.20.2, with file and line numbers in *Current
  state*. T04.4 vendors three delegates and T04.6 pins the formatter to `fa`. Both carry a test that
  **re-asserts the gap**, so if a future SDK adds `ckb` the tests go red and the workaround is deleted
  deliberately instead of rotting in place for years. **Decision:** vendor now, verify every build,
  delete on purpose.
- **The silent half of the `ckb` bug is worse than the loud half.**
  `_WidgetsLocalizationsDelegate.isSupported` returns `true` for every locale and returns an LTR
  default, so a Sorani build with only the Material delegate fixed runs perfectly and reads backwards.
  Both halves are one task and one test. Flagged because a reviewer seeing "the crash is fixed" may
  reasonably assume the locale works.
- **`ar` is not the numeral fallback and the reason is measured.** intl 0.20.2's `"ar"` NumberSymbols
  carry `ZERO_DIGIT: '0'` — CLDR's modern `ar` default is Latin digits. Delegating our numerals to
  `ar` would emit `1480` in Sorani. `fa` is the only correct base, and the skill's own `'ar' =>
  decimalPattern('ar')` line is stale against this version. **Decision:** `fa` for both RTL locales,
  asserted by `intl_symbol_coverage_test.dart`; we ship no `ar` locale so the skill's guidance is not
  contradicted, only unused.
- **`locale_tag` has a shape `CHECK`, not a closed `CHECK … IN` — E02's decision, restated so E04 does
  not "tighten" it.** The data layer does not interpret the value, a closed list turns a fifth locale
  into a needless migration, and — the sharper reason — a database written by a build that supported a
  locale a later build drops would become **unopenable**. E02 pairs the shape check with
  `SupportedLocale.tryParse` on read, degrading an unknown tag to "follow system" and logging
  `UnsupportedLocaleTag` without rewriting the column. **Decision:** leave all of it alone.
- **`AppSettings` and `SupportedLocale` are E02's, and E04 must not fork either.** Under the old
  numbering `lib/core/app_settings.dart` belonged to motion-and-feedback; that epic is now E06 and
  lands *after* persistence, so ownership moved with the reorder. E02 T02.2 ships the file with **five**
  fields — four booleans plus `SupportedLocale? localeOverride` — and `lib/core/supported_locale.dart`
  as "the only list of shipped locales in the repo". **Decision:** E04 adds no field and declares no
  second locale type. An earlier draft of this epic introduced a `sealed class LocalePreference`; it is
  deleted, because two vocabularies for one column is exactly the failure these files exist to prevent.
  If E02 shipped without the field, that is a gap in E02 and it is fixed there.
- **There is no schema migration in this epic, and that is a deliberate reversal of an earlier plan.**
  An earlier draft had T04.5 bump `schemaVersion` to 2 and write a `from1To2` step for `locale_tag`.
  E02 then moved the column into schema **v1** precisely so that adding three locales would be a string
  job rather than the app's first migration on a database holding user history — its Definition of done
  says "the v1 snapshot contains `locale_tag`, so E04 ships no migration". **Decision:** consume the v1
  column. `run-migration` is not a skill for this epic, `drift_dev make-migrations` is not in its gate
  list, and a `drift_schema_v2.json` appearing on this branch is a defect. The project's first real
  migration is now unscheduled, and E02 says so rather than inventing a placeholder.
- **The expansion matrix tests strings against type steps, not screens against layouts.** No screen
  exists at E04. `_TypeSpecimen` is the honest approximation and the epic says so rather than claiming
  a coverage it does not have. The real overflow surface is E08's eight screens and E11's sweep;
  what E04 guarantees is the harness, the 48-case matrix shape, the pseudo-locale lane and the
  measured longest-string-per-step table those epics consume. **Decision:** ship the matrix over the
  specimen, hand E05 the table, and state the limit in the PR body.
- **The German expansion assertion is aggregate, not per-key, and that is deliberate.** Some German
  strings are shorter than their English source; asserting ≥1.15× per key would be false and would
  push a translator toward padding. The sum over the catalog is what D8's premise actually claims and
  is what T04.3 asserts.
- **`app.html` gains `data-l10n` attributes and this couples the design source to the ARB keys.**
  That coupling is the point — it is what makes the string inventory provable and lets the RTL capture
  read `app_fa.arb` instead of a hand-maintained second copy. The cost is that renaming an ARB key now
  requires an `app.html` edit, caught by T04.2's inventory test. **Decision:** accept the coupling;
  a second Persian string table would drift within one epic.
- **The RTL capture may expose physical-side CSS in `app.html`.** The design source predates the RTL
  requirement and almost certainly uses `left`/`right` somewhere. Fixing those to logical properties
  is in scope for T04.11 and is exactly the CSS twin of the Dart rule this epic enforces. The risk is
  that a fix moves an LTR pixel. **Decision:** re-capture the LTR set, compare byte-for-byte, and
  either confirm no change or commit the regenerated PNG with the reason — never let the two drift
  silently in either direction.
- **`flutter gen-l10n`'s handling of `ckb` was not verified before writing this file.** It derives the
  locale from the filename and should emit `AppLocalizationsCkb` without complaint, but it may print a
  warning about a locale `flutter_localizations` does not cover. **T04.1 must observe the actual
  output and paste it into the PR body.** If it warns, that is a note; if it errors, that is a blocker
  to raise, not a thing to work around with a locale alias.
- **The API this epic exposes is fixed here, and six epics depend on the names.**
  `LocaleNumbers.of(context)` / `LocaleNumbers.forLocale(locale)` / `localeNumbersProvider`;
  `AsciiNumerals.normalize` / `parseNum` / `parseInt`; `Bidi.isolateLtr` / `isolateRtl` / `isolate` /
  `strip`; `appLocalizationsProvider`; `localeProvider`; `resolveLocale`; `supportedLocales` derived
  from E02's `SupportedLocale`. **Decision:** `LocaleNumbers` owns the formatting decisions rather than
  handing out a raw `NumberFormat`, because a `numberFormatFor(Locale)` would put grouping, fraction
  digits and unit composition back at the call site — the precise thing D3 forbids. An earlier draft of
  E05–E11 named `numberFormatFor`, `numberFormatProvider` and a free `normalizeToAscii`; those epics
  have been swept to the names above. If a later epic reaches for a symbol not on this list, the fix is
  in that epic, not a second module here.
- **Android is deferred and this epic ships nothing for it.** No `android/` edit, no `values-fa/`, no
  per-locale resource directory, no claim of parity. When Android is picked up, its locale manifest is
  its own task in its own epic. Stated so a reader does not assume the iOS work covered both.

## Definition of done

- [ ] All eleven tasks complete, each with its tests written before its implementation and committed
      alongside the code they cover — except T04.10, which states in one line why a harness cannot
      lead with its own tests.
- [ ] `lib/l10n/` holds four ARBs, four generated classes, `ckb_localizations.dart`,
      `supported_locales.dart`, `locale_resolver.dart`, `locale_provider.dart`, `l10n_providers.dart`
      (`appLocalizationsProvider` + `localeNumbersProvider`), `locale_numbers.dart`,
      `ascii_numerals.dart` and `bidi.dart`; `test/` mirrors it 1:1. **No file under `lib/data/`,
      `lib/core/`, `assets/` or `drift_schemas/` changed.**
- [ ] `check_arb_parity.sh lib/l10n` passes over four locales and is in `tool/skill_gates.sh`'s **run**
      table, not its skip table.
- [ ] `check_i18n_bans.sh lib` scans real source and passes; introducing one physical-side inset makes
      both it and `test/policy/directional_geometry_test.dart` fail — observed and reverted.
- [ ] Every supported locale mounts without throwing and resolves to the declared direction
      (`en` ltr, `de` ltr, `fa` rtl, `ckb` rtl), and Material chrome under `ckb` carries the `fa`
      strings.
- [ ] The numeral table passes with exact string equality in all four locales, including the Persian
      digit block `U+06F0`–`U+06F9` and the separators `U+066B`/`U+066C`; every row round-trips
      through `AsciiNumerals`.
- [ ] There is exactly one bidi helper and exactly one `NumberFormat` construction site in `lib/`
      (`lib/l10n/locale_numbers.dart`); no isolate character can reach storage. `LocaleNumbers`,
      `AsciiNumerals` and `Bidi` are the names shipped, and E05–E11 call those names.
- [ ] `lib/core/` and `lib/games/` import neither `package:intl` nor `AppLocalizations`, so a golden
      vector cannot move because a locale moved.
- [ ] Every code point in `app_fa.arb` and `app_ckb.arb` is covered by a face **E03 bundled**, and
      every translated string fits its step's line box in both RTL locales. `pubspec.yaml` and
      `assets/` are untouched by this epic and `font_licence_test.dart`'s frozen family list is
      unchanged. E03's measured display-face outcome is copied into ADR 0002.
- [ ] No `FittedBox`, no clamped `textScaler`, no computed `fontSize` and no ellipsis on a value
      anywhere in the diff.
- [ ] The locale override persists through E02's schema **v1** `locale_tag` column and the **first**
      pumped frame under a persisted `fa` is already RTL and already Persian. `schemaVersion` is still
      `1`, there is no `drift_schema_v2.json`, and `git diff --stat -- lib/data/ drift_schemas/` is
      empty.
- [ ] The 48-case expansion matrix plus the pseudo-locale lane are green, and
      `build/longest_strings_by_step.txt` is produced for E05.
- [ ] `test/support/harness.dart` carries `LocaleCase.all` and `pumpLocalized`, `LocaleCase.all` is
      proven equal to `SupportedLocale.values`, and there is still exactly one app-level harness in
      the repository. `grep -rn 'LocalePreference\|kTestLocales\|kSupportedLocales\|AppLocales' lib/ test/`
      is empty.
- [ ] `design/sunburst-pop/screens/rtl/` holds eight 780×1688 Persian PNGs; `strings-fa.json` is
      committed and freshness-gated; `screens/README.md` documents both sets; the eight LTR PNGs are
      unchanged or their change is accounted for.
- [ ] `CLAUDE.md` was not edited — working agreements 11 (directional geometry, with the shadow
      exception) and 12 (the numeral policy) already state what this epic enforces — and ADR 0002
      supersedes ADR 0001.
- [ ] `/simplify` run and its findings addressed.
- [ ] `/code-review` run and its findings addressed.
- [ ] Every command under **Gates that must pass** is green locally, and the app runs on
      `C13DDC02-375D-4E1B-8F81-44EB407D09A4` with the locale switching live in all four languages.
- [ ] Pushed to `epic/04-localization-and-rtl`; PR body carries the five required sections — **What
      changed**, **Why**, **How it was verified** (the gate commands and their output, including
      `check_arb_parity.sh`'s first-ever exit 0 and the two deliberately-broken-then-reverted gate
      proofs), **Screens compared** (all eight `rtl/*.png` beside their LTR twins, the six checks, and
      the null result on the LTR set), **Deliberately left out** (Android entirely; any locale beyond
      the four; a calendar projection — MindForge shows no dates, only durations and counts, so no
      Jalali or Hijri work is in scope; a "Western digits" user toggle; the Settings language row
      itself, which is E08's screen; and native-speaker-reviewed copy, which is E11's blocker).
- [ ] CI green on the PR, including the gen-l10n, drift-schema and `strings-fa.json` freshness gates
      and the golden lane.
- [ ] Merged preserving the granular commits, branch deleted, back on `main`, pulled.
