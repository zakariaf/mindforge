# E03 · Design tokens and theme

| | |
|---|---|
| **Branch** | `epic/03-design-tokens-and-theme` |
| **Depends on** | E01 |
| **Unblocks** | E04, E05, E06, E07 |
| **Status** | Not started |

## The epic

Build `lib/theme/` by transcribing `design/sunburst-pop/system.html` into eight Dart files:
`sunburst_primitives.dart` (the fenced `_P` tier — the only file in MindForge allowed a hex),
`sunburst_colors.dart` (34 semantic slots, the gameplay/colour-blind tier, `answerColour` /
`answerLabel`, and the `// @contrast fg bg min` declarations the contrast gate reads),
`sunburst_shape.dart` (`borderWidth` 3, the five-step radius scale, the four hard-shadow elevations
with `blurRadius`/`spreadRadius` pinned to 0, the press law, the `space1..space7` /
`gutter` / `cardGap` / `cardPadding` rhythm), `sunburst_motion.dart` (`durTap` 120, `durState` 160,
`durMove` 180, `durCelebrate` 240; `easePop` `Cubic(0.2, 1.5, 0.4, 1)`, `easeOut`, `easeInOut`, and
`resolve()` — Sunburst Pop's binding of `design-system-structure`'s `resolveMotion`, reading
`MediaQuery.disableAnimationsOf`), `sunburst_type.dart` (ten steps over the bundled Fredoka and
Nunito **plus the script-aware resolution that serves those same ten steps in Arabic script**),
`game_accent.dart` (`GameAccent` + `GameColourRole` and the `GameAccentTokens` extension), and
`sunburst_theme.dart` (a hand-authored `ColorScheme` keeping M3 role names, all four extensions
attached, `buildSunburstTheme()`, and the two lines in `lib/app.dart` that actually spend it).

The eighth file in `lib/theme/` is `font_licences.dart`, which **E01 already shipped** along with the
four Latin `.ttf` faces and the Fredoka/Nunito OFL texts. This epic names those faces in
`SunburstType` and **extends** that one registration with the Arabic-script faces it bundles itself —
it does not add a second `registerSunburst*` function.

Two things are new relative to the pre-localization plan, and both live in the type layer:

1. **MindForge ships four locales, two of them right-to-left** — `en`, `de`, `fa` (Persian),
   `ckb` (Kurdish Sorani). Fredoka and Nunito have **no Arabic-script coverage**, so the same
   semantic step (`displayL`, `body`, `numericHud`…) must resolve to a different family, a
   different weight and a different line box depending on the script being rendered. This epic
   bundles that second font pair, verifies its glyph coverage instead of assuming it, and ships
   `SunburstType.forScript()` so no call site ever picks a family.
2. **The shape language, not the typeface, is what survives translation.** The 3px ink border, the
   hard offset shadow, the press-down and the palette are identical in every locale — and the hard
   shadow deliberately **does not mirror** in RTL. Both statements are pinned by tests here, because
   E05 builds every component on top of them.

Each of the four extensions is a `ThemeExtension` with a `const` constructor, `copyWith`, an honest
`lerp` (except `SunburstMotion`, which snaps at the midpoint on purpose) and an asserting
`of(context)`. Behind them sits a test suite whose job is to make drift impossible: a token-parity
test that reads the hexes straight out of `system.html` and fails when Dart and the design file
disagree, field-count invariants that fail when a new slot is forgotten in `copyWith`/`lerp`/`_props`,
a WCAG contrast test on colour values, a font-table assertion that fails when the shipped Arabic face
cannot draw a Sorani letter or an Eastern Arabic digit, and a reference-pixel test that samples the
eight shipped PNGs and asserts the sampled hexes are the shipped slots.

## Why we need it

Every screen, component, board and animation in E04–E11 reads its colour, radius, shadow, duration,
curve and type step off these four extensions. Nothing above this layer may hold an aesthetic value —
`check_raw_values.sh` fails the build for it — so until `lib/theme/` exists there is literally no
legal way to paint a pixel in this repo. E05 cannot build `PopSurface` without `SunburstShape.shadow()`
and `pressTranslate()`; E06 cannot name a moment without the four durations; E08 cannot lay out a
screen without `gutter`/`cardGap` or a `GameAccent` to tint the play band.

E04 is the reason the type layer changed shape. E04 wires `AppLocalizations`, the four ARB files, the
locale controller and the `ckb` delegate — and the first thing it will do is render a Persian string.
If the type layer cannot answer "which family draws this" by then, E04 either invents a font decision
at a call site or ships tofu. Localization lands **before** components (E05) for the same reason in
the other direction: no component may be written against a Latin-only type scale and retrofitted.

The second reason is drift. A design system rots one forgotten `lerp` line and one "improved" hex at a
time. `system.html` is the authority for values and the eight PNGs are the implementation targets; if
the Dart is not mechanically pinned to both, six months from now nobody can tell which of the two is
wrong. The parity test and the reference-pixel test are the pins.

`check_raw_values.sh` and `check_palette_contrast.sh` have never scanned a line of Dart. Today they
print `note: 'lib' not found; nothing to scan.` and exit 0. This epic is the first time either gate
proves anything, and the first time `check_i18n_bans.sh` has any Dart to refuse.

## Current state

Verified by reading the tree on 2026-08-19, and by reading the installed Flutter framework source:

- **No Flutter app.** No `pubspec.yaml`, no `lib/`, no `test/`, no `.github/`, no `ios/`. E01 creates
  them, targets **iOS only** (Android is explicitly deferred), and pins the canonical simulator.
- `design/sunburst-pop/system.html` (1570 lines) — the `:root` block at lines 16–89 holds 30
  hex-valued CSS custom properties: 19 chrome primitives, 7 gameplay, 4 colour-blind (all four
  duplicating a gameplay hex). Below that: `--bw:3px`, `--r-sm|md|lg|xl|pill`, `--sh-0:none` plus
  `--sh-1..4`, `--dur-tap|state|move|celebrate`, `--ease-pop|out|inout`, `--display`, `--body`.
  Comment at line 14: *"All colour lives on `:root`. Nothing below `:root` uses a hex."*
- `design/sunburst-pop/screens/*.png` — eight PNGs, all `780 x 1688, 8-bit/color RGB` (390x844 @2x),
  plus `README.md` (the comparison procedure) and `contact-sheet.html`. They are **English LTR**;
  the RTL counterparts under `screens/rtl/` are produced by **E04**, not here.
- `.claude/skills/sunburst-tokens/` — `SKILL.md`, three references
  (`palette-and-slots.md`, `shape-and-type.md`, `adding-a-token.md`), a 784-line worked
  `examples/sunburst_theme.dart` that carries the whole layer as one file,
  `templates/theme_file_template.dart`, and the two gate scripts.
- 49 gate scripts under `.claude/skills/*/scripts/`. **They do not all exit 0 on an absent target** —
  measured with no argument, 20 exit 0, 21 exit 2, 7 exit 1 and `check-scheduler-purity.sh` exits 127 on
  macOS bash 3.2. E01's *Current state* carries the full accounting and corrects `CLAUDE.md` working
  agreement 10 to match. The three this epic cares about: `check_raw_values.sh` and
  `check_palette_contrast.sh` print `note: 'lib' not found; nothing to scan.` and exit 0 (which is why
  they have never proven anything), while `check_i18n_bans.sh` exits **2** on a missing target and so
  becomes runnable for the first time the moment `lib/` exists.
- `tool/skill_gates.sh` exists from E01 and is the only sanctioned way to run the skill gates.
- `.claude/skills/sunburst-components/examples/*.dart` import `package:mindforge/theme/...`, so the
  package name E01 must pick is **`mindforge`**.

Toolchain, verified on this machine (do not re-derive): Flutter **3.44.6** stable, Dart **3.12.2**,
Xcode **26.6**, CocoaPods **1.15.2**. The canonical device is the simulator
**`MindForge iPhone 14`**, UDID `C13DDC02-375D-4E1B-8F81-44EB407D09A4`, iOS 18.6 — chosen because it
is exactly **390×844 logical points**, the geometry the eight PNGs were rendered at. No iPhone
16-class simulator matches (16 is 393×852, 16 Pro is 402×874), so any screenshot comparison that does
not run on this UDID is not an honest comparison.

Three framework facts read out of `/Users/zakariafatahi/development/flutter` at 3.44.6, because this
epic's tests depend on them and guessing is how E04 loses a day:

- `flutter_localizations` ships `material_ar.arb`, `material_de.arb`, `material_fa.arb` and **no
  `material_ckb.arb`**; `kMaterialSupportedLanguages` lists 85 languages and `ckb` is not among them.
  The `ckb` delegate gap in E04's D2 is a measured fact, not a suspicion.
- `Localizations._loadAll` filters delegates by `isSupported(locale)`
  (`widgets/localizations.dart:62`), and `DefaultMaterialLocalizations.delegate.isSupported` is
  `locale.languageCode == 'en'` (`material/material_localizations.dart:726`). Under `fa` with only the
  default delegates there is **no `MaterialLocalizations` in scope at all**, and any `Scaffold`,
  `Tooltip` or `SnackBar` asserts.
- `Localizations` supplies the ambient `Directionality` from `WidgetsLocalizations.textDirection`
  (`widgets/localizations.dart:721-744`), `_WidgetsLocalizationsDelegate.isSupported` returns `true`
  for every locale, and `DefaultWidgetsLocalizations.textDirection` is **hardcoded
  `TextDirection.ltr`**. Without `GlobalWidgetsLocalizations`, pumping `locale: fa` yields an
  **LTR** tree, silently. An RTL claim made in this epic's tests is a stand-in, and is labelled one.

Nothing in this epic exists yet, in any form.

## What we will achieve

- `lib/theme/` holds exactly eight files; `grep -rn 'Color(0x' lib/` returns hits in
  `sunburst_primitives.dart` and nowhere else.
- `.claude/skills/sunburst-tokens/scripts/check_raw_values.sh lib` prints
  `OK: no raw aesthetic values outside */theme/.` over real code.
- `.claude/skills/sunburst-tokens/scripts/check_palette_contrast.sh lib/theme/sunburst_colors.dart lib/theme/sunburst_primitives.dart`
  recomputes 26 declared pairs from the shipped hexes and prints `OK`. Deliberately corrupting one
  primitive hex makes it fail — proven and reverted, not assumed.
- `.claude/skills/i18n-rtl-l10n/scripts/check_i18n_bans.sh lib` prints `i18n bans: PASS` over the
  first Dart in the repo. From this epic on it is in the gate list, so E05 inherits a green gate
  rather than retrofitting directional geometry across a component catalog.
- `flutter test` runs a theme suite that fails if: a hex in Dart differs from `system.html`; a
  `SunburstColors` field is missing from `copyWith`, `lerp` or `_props`; `easePop` stops overshooting;
  `resolve()` returns anything but `Duration.zero` under `disableAnimations`; a `BoxShadow` gains blur;
  the hard shadow starts mirroring under RTL; an eleventh type step appears; the bundled Arabic face
  cannot draw `ڕ ڵ ۆ ێ ھ` or `۰۱۲۳۴۵۶۷۸۹`; an Arabic step's line box is shorter than the script needs;
  an Arabic step carries non-zero `letterSpacing`; or a pixel sampled from `01-home.png` stops matching
  `colors.surface`.
- `SunburstType.of(context)` returns Fredoka/Nunito under `en`/`de` and the bundled Arabic pair under
  `fa`/`ckb`, resolved from the ambient `Locale` and nothing else. No widget in MindForge ever names a
  font family, and no widget branches on locale to pick one.
- Six faces are bundled and licensed: Fredoka 600/700 and Nunito 700/800 (E01) plus the Arabic pair
  this epic adds, each with its own OFL text registered through the single
  `registerSunburstFontLicences()` E01 wrote. `google_fonts` still appears nowhere; the app makes no
  network call to render a glyph.
- `flutter run -d C13DDC02-375D-4E1B-8F81-44EB407D09A4` shows a **cream** iOS window instead of white:
  T03.11 sets `theme:` on the `MaterialApp` E01 built, so the app is themed from this epic onward
  rather than rendering unthemed Material through E04 and E05.
- A human can run `flutter test` and see the token suite green, then open `lib/theme/sunburst_colors.dart`
  beside `design/sunburst-pop/system.html` and find the same 30 values in the same order.
- `flutter analyze --fatal-infos --fatal-warnings` is clean with `public_member_api_docs` promoted to
  error: every public slot, method and enum case carries a `///`.
- PR merged into `main` with CI (created in E01) green.

## Skills to load

| Skill | Why, for this epic |
|---|---|
| `flutter-conventions-index` | The front door. Open first; it routes and carries the 14 house rules the tasks below inherit — including rule 12, RTL and a11y by construction, which is why the type layer changes here and not in E05. |
| `sunburst-tokens` | Owns every value in this epic. `references/palette-and-slots.md` is the slot table with measured ratios, `references/shape-and-type.md` the radius/elevation/spacing/type tables and the pubspec font block, `references/adding-a-token.md` the four-places-plus-the-gate procedure, `examples/sunburst_theme.dart` the compiling target. |
| `i18n-rtl-l10n` | New here, and load-bearing. Rule 9 (bundle fonts covering every shipped script, with a fallback, no runtime fetch) is T03.7; the numerals section fixes that `fa`/`ckb` render `۰۱۲۳۴۵۶۷۸۹` (U+06Fx, distinct from Arabic U+066x) and that `ckb` has no `intl` number symbols and must borrow `fa` — which is why the Arabic display face must cover the digit block. Rule 5 (directional-only geometry) is what `SunburstShape` must not violate, and `scripts/check_i18n_bans.sh` is the gate. E04 owns the ARB layer; this epic owns the fonts and metrics it will render with. |
| `design-system-structure` | Owns the mechanism the values ride on: two-tier tokens, `ThemeExtension`, the asserting `of()` with no `?? fallback`, hand-authored `ColorScheme` over `fromSeed`, honest `lerp`, `resolveMotion`. `references/typography-and-fonts.md` is the direct source for T03.7–T03.9: `LicenseRegistry.addLicense`, `FontWeight` driving `wght`, the silent `FontVariation('opsz'\|'ital')` no-op, subsetting without instancing (`--layout-features='*'` or cursive shaping breaks), the per-script `fontFamilyFallback` cascade that must end in a known-good face, and the warning that a `height` tuned for Latin shears glyphs of other scripts. |
| `sunburst-game-surfaces` | Declares `GameAccent` and `GameColourRole` in `lib/theme/game_accent.dart` (T03.10) and fixes the tier rule the whole colour file obeys: no `play*`/`cb*` slot may paint chrome. `references/accent-contract.md` carries the per-game table and the open N-Back request. |
| `sunburst-motion-and-haptics` | Fixes that there are four durations and three curves and no fifth, and states that `SunburstMotion.resolve` is Sunburst Pop's binding of `resolveMotion`. It decides who spends the durations (E06); this epic only ships them. |
| `dart3-idioms-and-coding-standards` | `PlayFill`/`PlayAnswer`/`GameAccent`/`GameColourRole`/`SunburstScript` are payload-free closed sets, so they are enums (rule 3); `final` fields + `const` constructors + value equality (rule 5); exhaustive `switch` with no `default:` in `answerColour`/`base`/`deep`/`forScript` (rule 1); the file ≤ ~300-line limit the colour file will overrun and must justify (rule 11). |
| `naming-conventions` | `lowercase_with_underscores` file names matching their primary declaration, `lowerCamelCase` constants (`space5`, never `SPACE_5`), grouped-and-sorted directives, and rule 5 (one primary public type per file) — which `sunburst_colors.dart` and `sunburst_type.dart` both overrun deliberately and must justify. |
| `dartdoc-conventions` | `public_member_api_docs` is an error: 34 colour slots, 16 shape fields, 7 motion fields and 10 type steps each need a `///` that says the role, not the value — and rule 8 (restate the invariant at its enforcement point) is why `lerp`'s midpoint snap, `danger`'s primitive wiring, the non-mirroring shadow and the Arabic `letterSpacing: 0` each carry a comment. |
| `testing-strategy` | Test at the cheapest tier that can assert the behaviour: parity, field-count, contrast and font-table tests are pure Dart, not `pumpWidget`. Rule 11 is why the glyph-coverage claim is split into a machine assertion plus a named manual line, instead of being faked green. `scripts/check_test_hygiene.sh` runs before the PR. |
| `widget-golden-and-a11y-testing` | Owns `test/support/harness.dart` — **this epic creates it and it is the one app-level harness in the repo**: `Device`/`Device.all` at DPR 2 (the `capture-screens.sh` and simulator geometry), `useDevice` with `addTearDown(view.reset)`, `MediaQuery` layered **above** `MaterialApp` built from `.copyWith`. E05 and E08 extend this file; neither forks a second `Device` or a second `pumpApp`. Also owns the pure-Dart WCAG-on-colour-values pattern rather than `textContrastGuideline`, the rule that RTL/numeral goldens must run on **real bundled fonts and never Ahem**, and `loadAppFonts` — which T03.9's metric measurements depend on absolutely. |
| `accessibility-as-code` | The 4.5 body / 3.0 large + non-text floors the `@contrast` block declares; the rule that a11y state is read from `MediaQuery` — not app state — which is why `resolve()` takes a `BuildContext`; and rule 5, no `FittedBox`, no computed `fontSize`, no ellipsis to make a label fit. That rule is what forces German and Sorani to be absorbed by the type scale and the layout rather than by shrinking, so it constrains what an Arabic step is allowed to do. |
| `lint-and-style-config` | `flutter analyze --fatal-infos` is a hard gate; suppression is line-scoped only, and a raw value is a new slot, never an `// ignore:`. |
| `dependency-hygiene` | This epic adds **no package** and must not: `google_fonts` is standing-refused (rule 7, network path), and a Persian-font helper package would be the same refusal. It does edit `pubspec.yaml` — the `flutter: fonts:` block only — so rule 3 applies: `pubspec.lock` must show **no delta**, and `audit-deps.sh` runs to prove the tree is unchanged. |
| `ci-pipeline-and-gates` | T03.12 proves the token gates are wired into E01's workflow and actually fail on a bad value; `references/policy-grep-gate.md` is the pattern for the light-only source grep. Rule 10 is why the font-coverage claim states plainly what CI cannot prove: that the rendered Sorani text is correctly *shaped and readable*, which needs a human with the script. |

## Tasks

### T03.1 — Test support: device harness, the locale seam, and the design-source parser

**Goal.** Ship the two test-support files every later task's tests import, pinned to the reference
render geometry and to the canonical simulator, with a locale seam the type tasks can drive.

**Tests first (TDD).** A harness has no behaviour of its own and its first real assertion is T03.2's
parity test — with one exception that is a real test and belongs here, because it pins a framework
fact E04 depends on: `test/support/harness_locale_test.dart`
- `'pumping a non-en locale resolves that locale'` — `pumpApp(const Text('x'), locale: const Locale('fa'))`
  then `Localizations.localeOf(context)` is `fa`.
- `'the default delegates report LTR for fa — E04 replaces this'` — asserts `Directionality.of(context)`
  is `TextDirection.ltr` under `locale: fa` with no explicit override, and that
  `pumpApp(..., locale: fa, textDirection: TextDirection.rtl)` gives `rtl`. The test name is the
  documentation: `DefaultWidgetsLocalizations.textDirection` is hardcoded LTR, so direction in this
  epic is a **test-only stand-in**, and E04 deletes the override when `GlobalWidgetsLocalizations`
  lands.
- `'a Material surface under fa fails loudly today'` — `pumpApp(const Scaffold(), locale: const Locale('fa'))`
  and assert the thrown `FlutterError` names `MaterialLocalizations`. This is the `ckb`/`fa` delegate
  gap discovered here, in a 12-line test, instead of in a game screen in E09. **E04 deletes this test
  in the commit that adds the delegates**, and its deletion is part of E04's proof.

**Implementation.**
- `test/support/harness.dart` per `widget-golden-and-a11y-testing`. **This is the one app-level harness
  in the repository.** E05 adds `pumpPopComponent` beside it, E08 adds `pumpShellApp` beside it; neither
  declares a second `Device` type, a second device-preset list or a second `pumpApp`.
  `final class Device { const Device(this.name, {required this.logicalSize, required this.dpr}); }`,
  with four presets named by their measured size and **all four at DPR 2** — the exact geometry
  `capture-screens.sh` rendered the eight PNGs at (780×1688 = 390×844 @2), which is also exactly the
  `MindForge iPhone 14` simulator. A golden lane at DPR 3 cannot be laid beside a DPR-2 reference, so
  one number serves every consumer:
  ```dart
  static const compact320   = Device('320', logicalSize: Size(320, 640), dpr: 2);
  static const small360     = Device('360', logicalSize: Size(360, 800), dpr: 2);
  static const reference390 = Device('390', logicalSize: Size(390, 844), dpr: 2); // PNG + simulator
  static const large430     = Device('430', logicalSize: Size(430, 932), dpr: 2);
  static const all = <Device>[compact320, small360, reference390, large430];
  ```
  `Device.all` is the one matrix name — E05, E08, E09, E10 and E11 all iterate it.
  `void useDevice(Device d)` sets `view.devicePixelRatio`, `view.physicalSize = d.logicalSize * d.dpr`
  and `addTearDown(view.reset)`.
  `extension PumpApp on WidgetTester { Future<void> pumpApp(Widget child, {required ThemeData theme, Locale locale = const Locale('en'), TextDirection? textDirection, bool disableAnimations = false, List<Override> overrides = const []}) }`
  builds `ProviderScope` → `MaterialApp(theme: theme, locale: locale, supportedLocales: _kHarnessLocales)`
  → `Builder` + `MediaQuery.of(context).copyWith(...)` layered **above** `MaterialApp`, never a bare
  `MediaQueryData()`. `_kHarnessLocales` is `[en, de, fa, ckb]` with a comment naming E04 as the owner
  of the real `supportedLocales`. `textDirection`, when non-null, wraps the child in `Directionality` —
  documented as the stand-in for the absent `GlobalWidgetsLocalizations`, and explicitly **not** a
  pattern production code may copy (`i18n-rtl-l10n` rule 4 bans a hardcoded root `Directionality`).
  **`theme` is a required parameter, not `buildSunburstTheme()`.** That function does not exist until
  T03.11, and a harness that calls it would leave every test in T03.2–T03.10 uncompilable. Call sites in
  those tasks pass an inline `ThemeData(extensions: [...])` carrying only the extension under test;
  T03.11 adds `ThemeData theme = _defaultTheme` defaulting to `buildSunburstTheme()` in the same commit
  that creates it, and E05/E08 onward rely on that default.
- `test/support/design_source.dart`: `final class DesignSource` with static readers that parse text,
  not Dart types — `cssRootHexes()` → `{'--cream': 'FFF8EC', ...}` from the `:root{}` block of
  `design/sunburst-pop/system.html`; `cssRootAliases()` → `{'--surface': '--cream', ...}`;
  `cssScalar(String name)` for `--bw`/`--r-*`/`--dur-*`/`--ease-*`; `dartPrimitiveHexes()` parsing
  `static const <name> = Color(0xFF<HEX>);` out of `lib/theme/sunburst_primitives.dart`;
  `dartSlotBindings()` parsing `<slot>: _P.<primitive>,` out of the const instance;
  `dartFieldNames(File f, String className)` returning the `final <Type> a, b, c;` names declared in a
  class; and `pubspecFontFamilies()` returning `{family: [(asset, weight), …]}` parsed from the
  `flutter: fonts:` block, which T03.8 and T03.9 assert against. It parses the same shapes
  `check_palette_contrast.sh` parses, on purpose — if the parser and the gate disagree, the gate is
  silently passing.
- Both read files with `dart:io` relative to the package root; add a `pathToRepoFile()` helper so a
  test never hardcodes a `../`.

**Files.** `test/support/harness.dart`, `test/support/design_source.dart`,
`test/support/harness_locale_test.dart`.

**Skills.** `widget-golden-and-a11y-testing`, `i18n-rtl-l10n`, `testing-strategy`, `naming-conventions`.

**Screenshot check.** n/a (no visual surface).

**Done when.**
- `Device.reference390` is 390x844 at DPR 2, matches simulator `C13DDC02-375D-4E1B-8F81-44EB407D09A4`,
  and nothing else in the repo restates those numbers.
- `pumpApp` takes `theme` as a required parameter; `buildSunburstTheme` appears nowhere in this file
  until T03.11.
- `useDevice` calls `addTearDown(view.reset)`; no test file touches `tester.binding.window`.
- `DesignSource.cssRootHexes()` returns 30 entries when run against the shipped `system.html`.
- The three locale-seam tests are green and each names in its title what it is pinning.
- `.claude/skills/widget-golden-and-a11y-testing/scripts/check-test-hygiene.sh lib test` is clean.

**Commits.**
1. `test(support): device harness with Device.all pinned to the @2x reference geometry`
2. `test(support): locale and direction seam, with the default-delegate gap pinned`
3. `test(support): DesignSource parser for system.html, the primitives file and the font block`

---

### T03.2 — `_P` primitives and the system.html parity gate

**Goal.** Land the 26 primitives as the only hexes in the app, mechanically pinned to `system.html`.

**Tests first (TDD).** `test/theme/token_parity_test.dart`:
- `'every _P primitive matches its system.html custom property'` — a `const Map<String, String>`
  transcription table (`'cream': '--cream'`, `'creamSunk': '--cream-2'`, `'inkSoft': '--ink-2'`,
  `'grapePop': '--grape-pop'`, `'playRed': '--play-red'`, …, 26 rows) drives one `expect` per row
  comparing `DesignSource.dartPrimitiveHexes()[name]` with `DesignSource.cssRootHexes()[cssVar]`.
- `'no primitive exists in Dart that system.html does not declare'` — the Dart key set equals the
  table key set (a hex invented in Dart has escaped design review).
- `'no hex custom property is left untranscribed'` — the CSS hex-var set minus the four `--cb-*`
  equals the table's value set.
- `'the colour-blind vars reuse gameplay primitives rather than adding new ones'` —
  `--cb-blue == --play-blue`, `--cb-yellow == --play-yellow`, `--cb-orange == --play-orange`,
  `--cb-pink == --play-pink`.
- `'_P is unreachable outside its own file'` — greps `lib/` for `_P.` and asserts the only matching
  file is `lib/theme/sunburst_primitives.dart`.

**Implementation.** `lib/theme/sunburst_primitives.dart` declares `abstract final class _P` holding the
26 constants. `_P` is private to its *library*, not its file, so the primitives file opens with
`part of 'sunburst_colors.dart';` and `sunburst_colors.dart` declares
`part 'sunburst_primitives.dart';`. That is the only arrangement that satisfies all three constraints
at once: `_P` unreachable from every other library (rule 2), the hexes in their own file (so
`check_palette_contrast.sh`'s default two-file invocation resolves), and the `*/theme/*` exemption in
`check_raw_values.sh` intact. Record the decision in a header comment. Order the constants exactly as
`:root` orders them: cream family, ink family, hue families with their `-deep` partners, `dot`, then
the gameplay block.

**Files.** `lib/theme/sunburst_primitives.dart`, `test/theme/token_parity_test.dart`.

**Skills.** `sunburst-tokens`, `design-system-structure`, `dartdoc-conventions`, `naming-conventions`.

**Screenshot check.** n/a (no visual surface — the sampled-hex proof against the PNGs is T03.12).

**Done when.**
- 26 constants, each `static const <name> = Color(0xFF……);`, one per line.
- `flutter test test/theme/token_parity_test.dart` is green; changing one hex digit turns it red.
- `grep -rn '_P\.' lib/ | grep -v 'lib/theme/'` is empty.
- `check_raw_values.sh lib` is clean.

**Commits.**
1. `test(theme): primitive-to-system.html parity spec (red)`
2. `feat(theme): _P primitive tier transcribed from system.html`

---

### T03.3 — `SunburstColors`: chrome slots and the extension contract

**Goal.** Land the 24 chrome slots and the four mechanics that keep them honest — `of`, `copyWith`,
`lerp`, `_props` — with tests that fail when a future slot is forgotten in any of them.

**Tests first (TDD).** `test/theme/sunburst_colors_test.dart`:
- `'every chrome slot resolves to the primitive the palette table names'` — table-driven over the 24
  rows of `references/palette-and-slots.md`, asserting `SunburstColors.sunburstPop.<slot>` equals the
  expected `Color(0xFF……)` value read via `DesignSource.dartPrimitiveHexes()`.
- `'of(context) returns the attached extension'` — `pumpApp` a `Theme(data: ThemeData(extensions: [SunburstColors.sunburstPop]))`
  and assert identity with the const instance.
- `'of(context) asserts when the extension is missing'` — `expect(() => SunburstColors.of(ctx), throwsAssertionError)`
  under a bare `ThemeData()`, proving there is no `?? fallback`.
- `'the palette is identical under every locale'` — the same const instance resolves under
  `locale: en`, `de`, `fa` and `ckb`. Colour is not a localized property; this test exists so nobody
  ever adds a per-locale palette branch, and so the RTL screenshots E04 captures are diffable against
  the LTR ones on hue.
- `'copyWith covers every declared field'` — a `const Map<String, Color Function(SunburstColors)>`
  accessor table plus a `SunburstColors Function(SunburstColors, Color)` setter table; assert
  `setters.length == DesignSource.dartFieldNames(colorsFile, 'SunburstColors').length`, then for each
  entry assert the sentinel lands on that field **and** every other field is unchanged.
- `'lerp moves every field'` — build `other` by mapping every field to a distinct sentinel, then assert
  `lerp(other, 0.5)` differs from `this` on **all** fields (a field missing from `lerp` returns its own
  value and fails), plus `lerp(other, 0) == this`, `lerp(other, 1) == other`, `lerp(null, 0.5) == this`.
- `'equality covers every declared field'` — for each field, `copyWith` one sentinel and assert
  `!=` and a different `hashCode`; this is what pins `_props`.

**Implementation.** `lib/theme/sunburst_colors.dart` — `@immutable class SunburstColors extends ThemeExtension<SunburstColors>`
with the 24 chrome fields grouped surfaces / text / structure / accents / game, a `const` constructor
with `required this.x`, the asserting `static SunburstColors of(BuildContext)`, `copyWith`, the honest
per-field `lerp` with a local `Color c(Color a, Color b) => Color.lerp(a, b, t)!`, `List<Object?> get _props`,
`==`/`hashCode`, and `static const SunburstColors sunburstPop` with **one `slot: _P.primitive,` per
line** — `check_palette_contrast.sh` matches that block line by line and two slots on one line makes
the second invisible to the gate. `borderDisabled: _P.inkMuted` carries the `DERIVED` comment
(`system.html` §11 names a "soft-ink" shadow colour this system has no token for).

**Files.** `lib/theme/sunburst_colors.dart`, `test/theme/sunburst_colors_test.dart`.

**Skills.** `sunburst-tokens`, `design-system-structure`, `dart3-idioms-and-coding-standards`,
`dartdoc-conventions`, `testing-strategy`.

**Screenshot check.** n/a (no visual surface).

**Done when.**
- 24 fields; the three coverage tests derive their expected count from the source file, not a literal.
- Deleting one line from `lerp` turns `'lerp moves every field'` red; deleting one from `_props` turns
  `'equality covers every declared field'` red. Both proven once, then reverted.
- `flutter analyze --fatal-infos` clean, every public member documented.

**Commits.**
1. `test(theme): SunburstColors slot, of(), copyWith, lerp and equality coverage specs (red)`
2. `feat(theme): SunburstColors chrome slots with asserting of(context)`

---

### T03.4 — `SunburstColors`: gameplay tier, colour-blind swap, and the contrast gate

**Goal.** Add the 10 gameplay/colour-blind slots, the two answer resolvers, and the 26 `// @contrast`
declarations — then make `check_palette_contrast.sh` go green over real code for the first time.

**Tests first (TDD).**
- `test/theme/sunburst_colors_test.dart` (extended):
  - `'answerColour maps each answer to its default hue'` — red→`playRed`, blue→`playBlue`,
    green→`playGreen`, yellow→`playYellow`, purple→`playPurple`, orange→`playOrange`.
  - `'the colour-blind swap re-points exactly red, green, blue and yellow'` — with `colourBlind: true`:
    red→`cbPink`, green→`cbOrange`, blue→`cbBlue`, yellow→`cbYellow`; purple and orange are identical
    in both palettes.
  - `'answerLabel is ink on yellow and paper everywhere else'` — `PlayAnswer.yellow` → `textPrimary`,
    every other case → `surfaceRaised`.
  - `'PlayAnswer binds each answer permanently to a fill pattern'` — red stripe, blue solid, green dot,
    yellow ring, purple solid, orange stripe; and no widget can obtain a bare `Color` without a fill.
  - `'PlayAnswer carries no display string'` — the enum has a fill and nothing else. The colour **word**
    is an ARB key resolved in E04 and rendered by E09; a `String get label` here would hardcode English
    into the theme layer and make the Stroop stimulus untranslatable. Asserted by
    `DesignSource.dartFieldNames` over the enum: the only field is the `PlayFill`.
  - `'chrome slots are wired to primitives, not to gameplay slots'` — the tier tripwire. Parse the
    const instance with `DesignSource.dartSlotBindings()` and assert `danger` binds to `playRed` and
    `accentAlt` to `grape` **as primitive names**, and that no chrome slot name binds to a primitive
    that the `cbBlue`/`cbYellow`/`cbOrange`/`cbPink` slots also bind to. A grep gate cannot see tier;
    this test can.
  - The field-count, `copyWith`, `lerp` and equality coverage tests from T03.3 now cover 34 fields
    automatically — no test edit; if they need one, the count was hardcoded and that is a defect.
- `test/theme/contrast_test.dart` — pure-Dart WCAG relative-luminance ratio over colour **values**
  (never `textContrastGuideline`, which has a known false negative): one `test` per declared pair,
  asserting the measured ratio clears the declared floor. It duplicates the shell gate on purpose so a
  contrast regression fails `flutter test` too, not only a script somebody forgot to run.
- `'playYellow is illegal as bare text on cream'` — asserts the ratio is below 4.5 and documents why
  the stimulus is three paint passes; an inverted expectation here would be a silent a11y regression.

**Implementation.** Add `enum PlayFill { solid, stripe, dot, ring }` and
`enum PlayAnswer { red(PlayFill.stripe), blue(PlayFill.solid), green(PlayFill.dot), yellow(PlayFill.ring), purple(PlayFill.solid), orange(PlayFill.stripe) }`
to `sunburst_colors.dart` — a deliberate exception to one-public-type-per-file, justified in the PR:
they are the argument and return vocabulary of `answerColour`/`answerLabel` and `sunburst-game-surfaces`
lists `sunburst_colors` as the importable file boards get them from. Add the six `play*` and four `cb*`
fields, the two resolvers as exhaustive `switch` expressions with no `default:`, and the 26
`// @contrast <fg> <bg> <min>` lines from `examples/sunburst_theme.dart`.

**Files.** `lib/theme/sunburst_colors.dart`, `test/theme/sunburst_colors_test.dart`,
`test/theme/contrast_test.dart`.

**Skills.** `sunburst-tokens`, `sunburst-game-surfaces`, `accessibility-as-code`,
`widget-golden-and-a11y-testing`, `dart3-idioms-and-coding-standards`.

**Screenshot check.** n/a (no visual surface).

**Done when.**
- `.claude/skills/sunburst-tokens/scripts/check_palette_contrast.sh lib/theme/sunburst_colors.dart lib/theme/sunburst_primitives.dart`
  prints `OK` over 26 pairs.
- Changing `textSecondary` to `_P.inkMuted` makes both the script and `contrast_test.dart` fail.
  Proven once, reverted.
- `SunburstColors` has 34 fields; `answerColour` and `answerLabel` contain no `default:` and no `case _:`.
- `PlayAnswer` carries no English string.
- `.claude/skills/sunburst-game-surfaces/scripts/check_game_palette.sh lib` is clean.

**Commits.**
1. `test(theme): answer palette, colour-blind swap and tier-separation specs (red)`
2. `feat(theme): gameplay and colour-blind slots with PlayAnswer/PlayFill`
3. `test(theme): WCAG contrast test over colour values`
4. `feat(theme): 26 @contrast declarations, check_palette_contrast.sh green`

---

### T03.5 — `SunburstShape`, and the shadow that does not mirror

**Goal.** Land border width, radius scale, the four hard-shadow elevations, the press law, the focus
ring and the spacing rhythm — with blur and spread unrepresentable rather than merely unset, and with
the direction-invariance of the shadow pinned before E05 builds anything on it.

**Tests first (TDD).** `test/theme/sunburst_shape_test.dart`:
- `'shape scalars match system.html'` — `borderWidth == 3` against `--bw`, the five radii against
  `--r-sm|md|lg|xl|pill`, and `e1..e4` against the offsets parsed out of `--sh-1..4`, all via
  `DesignSource.cssScalar`.
- `'stripePitch and stripeAngle are transcribed from the track rule, not :root'` — 9 and 45, asserted
  against the `repeating-linear-gradient(45deg, … 0 9px, 9px 18px)` declaration in `system.html`
  (`.track i`, ~line 311); the test names the source so the odd provenance is not a mystery later.
- `'the radius scale nests strictly upward'` — `radiusSm < radiusMd < radiusLg < radiusXl < radiusPill`.
- `'shadow() produces exactly one unblurred ink rectangle'` — `shadow(shape.e2, colors.border)` has
  `length == 1`, `blurRadius == 0`, `spreadRadius == 0`, `offset == Offset(5, 5)`,
  `color == colors.border`.
- `'the hard shadow does not mirror in RTL'` — pump the same `shadow(shape.e2, …)` under
  `textDirection: TextDirection.ltr` and `TextDirection.rtl` and assert an identical `Offset(5, 5)`
  both times; same for `pressTranslate(e2) == Offset(4, 4)`. **The offset is a light-source constant,
  not a reading-direction property.** Every raised surface in Sunburst Pop is lit from the top-left and
  the press moves *toward* its own shadow; mirroring that in RTL would light two locales from opposite
  sides and make the RTL screenshots undiffable against the LTR ones for anything but text. This is the
  first question a reviewer will ask about RTL, so it is answered by a named test and a doc comment at
  the enforcement point rather than in a PR thread.
- `'there is no e0 field'` — `DesignSource.dartFieldNames` contains no `e0`; the absence of a shadow is
  `const <BoxShadow>[]`, and an absent value must not be interpolable.
- `'pressTranslate is derived from the resting elevation'` — `e2` → `Offset(4, 4)`, `e1` → `Offset(2, 2)`,
  `e3` → `Offset(7, 7)`, `e4` → `Offset(9, 9)`; `pressedShadow == Offset(1, 1)`.
- `'two press scales ship'` — `pressScale == 0.98`, `pressScaleSmall == 0.97`, with the comment that
  §12's single 0.98 loses to the rendered gallery.
- `'the spacing rhythm is static and complete'` — `space1..space7` are 4/8/12/16/20/28/40;
  `gutter == space5`, `cardGap == space4`, `cardPadding == space4`; and they are `static`, asserted by
  the fact the test reads them off the class, not an instance.
- `'the shape layer exposes Radius, never a physical BorderRadius'` — `dartFieldNames` shows every
  radius typed `Radius`, and `grep` finds no `BorderRadius.only(` in the file. Components compose
  `BorderRadiusDirectional` from these; a `BorderRadius.only(topLeft:…)` here would be a
  `check_i18n_bans.sh` failure and would ship an un-mirrored corner into every locale.
- `of()` present/absent pair, and the `copyWith`/`lerp`/field-count coverage trio from T03.3 retargeted
  at `SunburstShape` (16 fields, mixed `double`/`Radius`/`Offset` — `lerp` uses `lerpDouble`,
  `Radius.lerp`, `Offset.lerp`).

**Implementation.** `lib/theme/sunburst_shape.dart` per `references/shape-and-type.md`.
`List<BoxShadow> shadow(Offset elevation, Color ink)` is the only `BoxShadow` constructor in MindForge
and hardcodes `blurRadius: 0, spreadRadius: 0`. `Offset pressTranslate(Offset elevation)` and
`static const Offset pressedShadow`. Spacing as `static const double`, because a gutter is layout
rhythm and interpolating one mid-animation is meaningless — state that in the doc comment. The
non-mirroring rule is restated as a `///` on `shadow()` and on `e1..e4`, per `dartdoc-conventions`
rule 8.

**Files.** `lib/theme/sunburst_shape.dart`, `test/theme/sunburst_shape_test.dart`.

**Skills.** `sunburst-tokens`, `design-system-structure`, `i18n-rtl-l10n`, `dartdoc-conventions`,
`dart3-idioms-and-coding-standards`.

**Screenshot check.** n/a (no visual surface — E05 compares the first surfaces built on these numbers,
against both the LTR PNGs and the RTL set E04 captures).

**Done when.**
- `.claude/skills/sunburst-components/scripts/check_component_hygiene.sh lib` is clean, including its
  blur/spread rule which applies inside `lib/theme/` too.
- `.claude/skills/i18n-rtl-l10n/scripts/check_i18n_bans.sh lib` is clean — the first time it runs
  against Dart in this repo.
- `grep -rn 'BoxShadow(' lib/` matches only `sunburst_shape.dart`.
- 16 fields; no `e0`.

**Commits.**
1. `test(theme): SunburstShape scale, shadow and press-law specs (red)`
2. `feat(theme): SunburstShape with the only BoxShadow factory in the app`
3. `test(theme): pin the hard shadow as direction-invariant under RTL`
4. `feat(theme): static spacing rhythm — space1..space7, gutter, cardGap, cardPadding`

---

### T03.6 — `SunburstMotion`

**Goal.** Land the four durations, three curves, the deliberate midpoint-snap `lerp`, and `resolve()` —
the single place a widget in MindForge asks whether to animate.

**Tests first (TDD).** `test/theme/sunburst_motion_test.dart`:
- `'durations match system.html'` — 120/160/180/240 ms against `--dur-tap|state|move|celebrate`.
- `'nothing exceeds durCelebrate'` — every duration `<= durCelebrate`; past 240ms this direction reads
  sluggish, and this is the ceiling E06 will be tempted to raise.
- `'curves match system.html'` — `easePop == Cubic(0.2, 1.5, 0.4, 1)`, `easeOut == Cubic(0.2, 0.8, 0.2, 1)`,
  `easeInOut == Cubic(0.6, 0, 0.3, 1)` against `--ease-pop|out|inout`.
- `'easePop overshoots past 1.0'` — sample `easePop.transform(t)` across `t` and assert
  `max > 1.0`, while `easeOut.transform(t)` and `easeInOut.transform(t)` stay within `[0, 1]`. This is
  the machine-checkable reason `easePop` is legal on transform and illegal on colour.
- `'resolve collapses to zero under disableAnimations'` — a widget test via `pumpApp(..., disableAnimations: true)`
  asserting `motion.resolve(context, motion.durMove) == Duration.zero`, and the mirror case asserting
  it returns the full 180ms when the flag is off. Reduced motion means stop, never "shorter".
- `'durations are locale-invariant'` — the same four values resolve under `en`, `de`, `fa` and `ckb`.
  A slower duration "so RTL readers can follow" is a tempting and wrong idea; motion timing is a
  physical property of the surface, not a reading-speed property, and a per-locale duration would make
  E06's eighteen moments untestable as one catalog.
- `'lerp snaps at the midpoint on purpose'` — `lerp(other, 0.49) == this`, `lerp(other, 0.5) == other`,
  `lerp(other, 1) == other`, `lerp(null, 0.5) == this`; the test name is the guard against a future
  reader "fixing" it into a per-field interpolation.
- `copyWith` field-count coverage over the 7 fields, and the `of()` present/absent pair.

**Implementation.** `lib/theme/sunburst_motion.dart`.
`Duration resolve(BuildContext context, Duration full) => MediaQuery.disableAnimationsOf(context) ? Duration.zero : full;`
— Sunburst Pop's binding of `design-system-structure`'s `resolveMotion`, reading the flag from
`MediaQuery` and never from app state (E06 folds the Settings row into `MediaQuery` at the composition
root; nothing changes here). `lerp` is a documented midpoint snap.

**Files.** `lib/theme/sunburst_motion.dart`, `test/theme/sunburst_motion_test.dart`.

**Skills.** `sunburst-tokens`, `sunburst-motion-and-haptics`, `design-system-structure`,
`accessibility-as-code`, `widget-golden-and-a11y-testing`.

**Screenshot check.** n/a (no visual surface — and the reference PNGs are end states only; motion is
not verifiable from them at all, per `screens/README.md`).

**Done when.**
- `.claude/skills/sunburst-motion-and-haptics/scripts/check_motion_tokens.sh lib` is clean.
- `grep -rn 'Cubic(\|Duration(milliseconds' lib/ | grep -v 'lib/theme/'` is empty.
- The overshoot test fails if `easePop`'s third control point is edited to stay under 1.0.

**Commits.**
1. `test(theme): duration, curve, overshoot and reduced-motion specs (red)`
2. `feat(theme): SunburstMotion with resolve() reading MediaQuery.disableAnimationsOf`

---

### T03.7 — Arabic-script faces: bundle, licence, and glyph-coverage verification

**Goal.** Put a body face and a display face for `fa`/`ckb` on disk, licensed, and **prove from the
font's own tables** that they can draw Sorani letters and Eastern Arabic digits — before any type step
names them.

**Ownership.** E01 owns the four Latin faces (Fredoka 600/700, Nunito 700/800), their OFL text, the
`flutter: fonts:` block for them, `lib/theme/font_licences.dart` and `test/theme/font_licence_test.dart`.
This task **extends** all four artifacts; it does not fork them. There is exactly one
`registerSunburstFontLicences()` in MindForge.

**The candidates and the decision rule.**
- **Body, `fa`/`ckb`: Vazirmatn** (SIL OFL). Chosen because it is the broadest-coverage modern Persian
  sans with real weights, and because `i18n-rtl-l10n` requires the fallback cascade to end in a face
  that covers every shipped script.
- **Display, `fa`/`ckb`: Lalezar preferred** (SIL OFL) — the closest OFL analogue to Fredoka's chunky
  round personality. **Its Sorani coverage is not assumed and its weight set is not assumed.** If it
  fails either check below, the display face for `fa`/`ckb` is **Vazirmatn at its heaviest bundled
  weight**, and that outcome is recorded in this epic's PR body and in "Risks and open questions"
  rather than left implicit.

**Tests first (TDD).** `test/theme/font_coverage_test.dart` — pure Dart over the asset bytes, no
rendering, no dependency; a small `test/support/font_tables.dart` reads the TTF table directory and the
`cmap` (format 4 and 12) and exposes `Set<int> coveredCodePoints(File ttf)` and
`Set<String> tableTags(File ttf)`.
- `'the Arabic body face covers the Sorani letter set'` — one `expect` per codepoint, each named in the
  failure message: `ڕ U+0695`, `ڵ U+06B5`, `ۆ U+06C6`, `ێ U+06CE`, `ھ U+06BE`, plus `ە U+06D5`,
  `ڤ U+06A4`, `ک U+06A9`, `گ U+06AF`, `پ U+067E`, `چ U+0686`, `ژ U+0698`, `ی U+06CC`. The last seven
  are not decoration: Sorani and Persian text is unreadable without them, and a face that has the
  brief's five but not `ە` still ships broken text.
- `'the Arabic display face covers the same set'` — the identical table against the display candidate.
  **This is the test that decides Lalezar vs Vazirmatn.**
- `'both Arabic faces cover the Eastern Arabic digits'` — `U+06F0`–`U+06F9`. This is the sharpest
  requirement in the task: per D3 the Schulte Grid **tiles are numbers**, and tiles, the countdown
  numeral, `scoreHero` and `numericHud` are all **display-face** steps. A display face without
  `۰۱۲۳۴۵۶۷۸۹` tofus every number in both games.
- `'both Arabic faces ship shaping tables'` — `tableTags()` contains `GSUB` and `GPOS`. Arabic script
  is cursive: without `init`/`medi`/`fina` substitutions the letters render disconnected and the text
  is wrong even though every codepoint is "covered". A subset built without `--layout-features='*'`
  fails exactly here.
- `'every declared family resolves to a file that exists'` — `DesignSource.pubspecFontFamilies()` cross
  checked against `File.existsSync`. A missing `.ttf` silently falls back to a system face (or Ahem in
  tests) and every golden after it is a lie; `check_font_bundling.sh` cannot see that.
- `test/theme/font_licence_test.dart` (extended, E01's file): the registry yields a licence entry for
  **every** bundled family — Fredoka, Nunito, Vazirmatn, and the display face — with a non-empty body
  containing the OFL header string. Adding a face without its licence turns this red.

**Implementation.**
- Download the faces from their upstream OFL releases and commit the `.ttf` files unmodified. Do
  **not** subset: subsetting an Arabic face is how shaping breaks, and if size later forces it,
  `references/typography-and-fonts.md` requires `--layout-features='*'` and no instancing.
- `assets/fonts/Vazirmatn-Bold.ttf` (weight 700) and `assets/fonts/Vazirmatn-ExtraBold.ttf` (800) —
  700 mirrors Nunito 700 for body/caption, 800 is the display fallback and mirrors E01's unspent
  Nunito 800. `assets/fonts/Lalezar-Regular.ttf` (400) **only if it passes the coverage tests**.
- `pubspec.yaml`: extend the `flutter: fonts:` block only. **No dependency is added**; `pubspec.lock`
  must be byte-identical after `flutter pub get`.
- `assets/fonts/OFL-Vazirmatn.txt` and (if bundled) `assets/fonts/OFL-Lalezar.txt`, each yielded from
  the existing `registerSunburstFontLicences()` with its own `LicenseEntryWithLineBreaks([...])`.
  Fredoka/Nunito keep E01's entry; the file gains rows, not a second function.
- Record in the file header: which display face won, the measured coverage result, and the byte size of
  each face (Arabic fonts are large; the PR states the app-size delta rather than discovering it at
  submission).
- If the display candidate ships a **single weight**, the Arabic display steps in T03.9 must declare
  **that** weight and never request 600/700 against it — a synthesized "faux" bold mangles the joining
  strokes of a cursive script (`references/typography-and-fonts.md`). Verify the shipped weights from
  the file, not from the foundry's website.

**The real-font test lane is created here, because this is where the faces arrive.**
`test/support/load_app_fonts.dart` — `Future<void> loadAppFonts()` over `FontLoader`, registering every
family `DesignSource.pubspecFontFamilies()` declares — and `dart_test.yaml` carrying the `golden` tag
both land in this task. They are **not** E05's: T03.9's Arabic metric measurements are meaningless
under Ahem's fixed em-square and its `type_specimen_arabic_test.dart` is tagged `@Tags(['golden'])`, so
both files have a consumer two epics before the component library. E04 and E05 **extend** the font list
if a face is ever added; neither creates the file, and there is exactly one `loadAppFonts` in the
repository.

**Files.** `assets/fonts/*.ttf`, `assets/fonts/OFL-*.txt`, `pubspec.yaml` (fonts block only),
`lib/theme/font_licences.dart` (edit), `test/support/font_tables.dart`,
`test/support/load_app_fonts.dart`, `dart_test.yaml`, `test/theme/font_coverage_test.dart`,
`test/theme/font_licence_test.dart` (edit).

**Skills.** `i18n-rtl-l10n`, `design-system-structure` (+ `references/typography-and-fonts.md`),
`dependency-hygiene`, `testing-strategy`, `widget-golden-and-a11y-testing`.

**Screenshot check.** n/a (no visual surface yet). The first rendered Persian and Sorani strings are
E04's, compared against the RTL reference set E04 captures into
`design/sunburst-pop/screens/rtl/`. **What CI cannot prove is stated here, not later:** these tests
prove the glyphs and shaping tables exist; they do **not** prove the text is correctly shaped,
correctly spaced or readable to a native reader. That is a named line in E11's manual pass and needs a
person who reads the script.

**Done when.**
- `.claude/skills/design-system-structure/scripts/check_font_bundling.sh lib` is clean; no
  `google_fonts`, no `FontVariation('opsz'|'ital')`.
- `flutter test test/theme/font_coverage_test.dart` is green, and deleting one codepoint row from the
  expected set is the only way to make an uncovered glyph pass.
- The display-face decision is recorded with its evidence (which codepoints, which file) in the PR body
  **and** in this epic's Risks section.
- `git diff pubspec.lock` is empty; `.claude/skills/dependency-hygiene/scripts/audit-deps.sh` is clean.
- Every bundled family yields an OFL entry from the one registration function.
- `test/support/load_app_fonts.dart` and `dart_test.yaml` exist and `flutter test --tags golden`
  runs (it selects nothing until T03.9 adds the first golden); `grep -rn 'FontLoader' test/` matches
  only `load_app_fonts.dart`.

**Commits.**
1. `test(theme): TTF cmap/GSUB reader and Sorani + Eastern-digit coverage spec (red)`
2. `feat(theme): bundle Vazirmatn for fa/ckb body with its OFL licence`
3. `feat(theme): bundle the fa/ckb display face and record the coverage outcome`
4. `test(support): add loadAppFonts and the golden tag for the real-font lane`

---

### T03.8 — `SunburstType`: the ten steps

**Goal.** Land the ten type steps over the four Latin faces E01 bundled, with a fallback cascade that
cannot tofu.

**Tests first (TDD).** `test/theme/sunburst_type_test.dart`:
- `'every step matches the §04 specimen'` — table-driven over the ten rows of
  `references/shape-and-type.md`: family, weight, `fontSize`, `height`, `letterSpacing`.
- `'tracking is the design percentage times the font size'` — recompute each: `scoreHero` −4% x 76 =
  −3.04, `displayXl` −3% x 42 = −1.26, `displayL` −2.5% x 33 = −0.83, `title` −1.5% x 21 = −0.32,
  `numericHud` −2% x 22 = −0.44, `label` +14% x 10 = +1.4, `stimulus` +1% x 78 = +0.78; `button`,
  `body` and `caption` are 0. A transcription typo cannot survive this.
- `'tabular figures are on exactly the two steps that need them'` — `scoreHero` and `numericHud`
  carry `FontFeature.tabularFigures()`; the other eight carry none.
- `'title and button follow §04 at w600, not §12 at w700'` — named so the known design-doc
  contradiction is pinned rather than rediscovered.
- `'the scale ships exactly the steps its source file declares'` — the count is read from the source
  (`DesignSource.dartFieldNames(typeFile, 'SunburstType').length`) and compared against a **named list
  literal of the expected step names** in the test, so an eleventh step is a one-line, reviewed test
  edit rather than a silent addition. It is ten here; E05's component gallery takes it to twelve
  (`buttonLarge`, `chip`), E08's shell screens to eighteen (`titleBar`, `greeting`, `sectionLabel`,
  `heroTitle`, `countdownNumeral`, `statValue`) and E09 to **twenty** — E09 adds **two** steps, not
  one: `buttonCompact` in T09.5 and `stimulusCompact` in T09.7. Each addition amends this literal in
  the same commit with its reason. Do **not** hardcode `== 10` — see Risk 9.
- `'only bundled families are named'` — every step's `fontFamily` is `Fredoka` or `Nunito` and every
  entry in every `fontFamilyFallback` is a family `DesignSource.pubspecFontFamilies()` declares. A step
  naming a fifth face, or a fallback naming an OS font, fails.
- `'every Latin step falls back to the Arabic body face'` — the cascade is
  `['Nunito', 'Vazirmatn']` for display steps and `['Vazirmatn']` for body steps, and no cascade is
  empty. This is not theoretical: the Settings language list renders each language in its own script
  (`Deutsch`, `فارسی`, `کوردیی ناوەندی`) **while the app is still in English**, so a Latin step with no
  Arabic fallback tofus on the screen that switches locale. `displayFallback` keeps its `DERIVED` note
  (the design names Baloo 2, which an offline app does not ship).
- `copyWith`/`lerp` field-count coverage and the `of()` present/absent pair.

**Implementation.**
- `lib/theme/sunburst_type.dart`: `static const String display = 'Fredoka'`, `bodyFace = 'Nunito'`,
  `displayArabic` and `bodyArabic` (the T03.7 outcome), the fallback cascades as `static const
  List<String>`, the ten `TextStyle` steps on the const instance, `copyWith`, `lerp` via
  `TextStyle.lerp`, asserting `of`.
- Nunito ExtraBold is bundled by E01 and no step here spends it — documented in this file, not silently
  dropped; `app.html` renders strings at 800 and E08 must not need a re-bundle.
- No asset and no `pubspec.yaml` edit in this task: T03.7 owns both.

**Files.** `lib/theme/sunburst_type.dart`, `test/theme/sunburst_type_test.dart`.

**Skills.** `sunburst-tokens`, `design-system-structure` (+ `references/typography-and-fonts.md`),
`i18n-rtl-l10n`, `dartdoc-conventions`.

**Screenshot check.** n/a (no visual surface). Type **role** is checked against the PNGs in E05/E08
when the first text renders; this task only pins the numbers.

**Done when.**
- `.claude/skills/design-system-structure/scripts/check_font_bundling.sh lib` is clean.
- Ten steps, and the count test reads the source file rather than a literal `10`.
- `grep -rn 'fontSize:\|fontFamily:' lib/ | grep -v 'lib/theme/'` is empty.
- `git diff --stat -- assets/ pubspec.yaml` is empty for this task.

**Commits.**
1. `test(theme): ten type steps, tracking maths and fallback-cascade specs (red)`
2. `feat(theme): SunburstType — the ten steps of the Sunburst Pop scale`

---

### T03.9 — Script-aware type resolution and Arabic metrics

**Goal.** Make the same semantic step render correctly in Arabic script: right family, right weight,
no cursive-breaking tracking, and a line box tall enough that nothing clips in `fa`/`ckb` — resolved
from the ambient locale so no call site ever chooses.

**Tests first (TDD).**
- `test/theme/sunburst_script_test.dart` — pure Dart over `scriptOf(Locale)`:
  - `'en and de are Latin; fa and ckb are Arabic'` — one `expect` per locale, plus `ar` → Arabic (E04
    may borrow `ar` as `ckb`'s Material/Cupertino neighbour, and this function must already agree).
  - `'an unknown locale falls back to Latin'` — `Locale('ja')` → `SunburstScript.latin`, matching D1's
    fallback-to-`en` rule. Documented as: an unshipped script has no bundled face, so Latin is the only
    honest answer.
- `test/theme/sunburst_type_arabic_test.dart` — widget tier, `setUpAll(loadAppFonts)` because every
  measurement below is meaningless under Ahem's fixed em-square:
  - `'of(context) returns the Arabic scale under fa and ckb'` — `pumpApp(..., locale: fa)` then
    `SunburstType.of(ctx).body.fontFamily == SunburstType.bodyArabic`; the same under `ckb`; and
    `Fredoka`/`Nunito` under `en` and `de`.
  - `'of(context) does not allocate a new scale per build'` — two reads under the same locale return
    `identical` instances. `forScript` memoizes the derivation of the const `sunburstPop`, which is the
    only instance production ever attaches; a fresh `SunburstType` on every `build()` in every widget is
    a real cost on the Schulte board's 25 tiles.
  - `'every Arabic step has zero letterSpacing'` — all ten. `letterSpacing` inserts space **between**
    glyphs, and Arabic script is cursive: tracking visibly breaks the joins. The Latin scale's −3.04 on
    `scoreHero` and +1.4 on `label` do not carry over, and the doc comment says why at the enforcement
    point.
  - `'no Arabic step clips its exemplar'` — for each step, `TextPainter` lays out a Sorani/Persian
    exemplar chosen for maximum vertical extent (ascender + descender + diacritic: `ڵێـ`, `چ`, `ژ` and
    a `ە`-final word), with `height: null`, and asserts
    `step.fontSize * step.height! >= painter.height` for the resolved Arabic style. A line box shorter
    than the script's natural height is exactly how the same component clips in `fa`/`ckb` while
    passing in `en`.
  - `'the Arabic line factor is applied to every step, not a subset'` — the resolved `height` of every
    step equals `max(latinHeight, SunburstType.arabicLineFactor * latinHeight)`; a step-by-step
    hand-tune would drift the moment a step is added.
  - `'the Arabic display steps declare a weight the bundled face actually ships'` — cross-checked
    against `DesignSource.pubspecFontFamilies()`. If the display face is single-weight, every display
    step resolves to that weight and the test says so by name; the alternative is synthesized bold on a
    cursive script.
  - `'tabular figures survive into the Arabic scale, or are recorded as unavailable'` — measure the
    advance width of each of `۰`–`۹` under the resolved `numericHud` style with `TextPainter` and
    assert they are equal to within 0.01. If the bundled face does not implement `tnum` for the
    Eastern digit block, this test is **inverted with a name that says so**
    (`'the Arabic face has no tabular Eastern digits — the HUD reserves max-digit width'`) and the
    reservation becomes a named requirement handed to E08's HUD. Nothing is hand-waved: either the
    feature works or the compensation is written down.
  - `'the scale is identical under en and de'` — German is a length problem, not a script problem;
    a per-locale type scale for `de` would be the wrong fix for D8's expansion matrix, whose right fix
    is layout and a smaller **base** step.
- `test/theme/goldens/type_specimen_arabic_test.dart`, tagged `@Tags(['golden'])`, `loadAppFonts` in
  `setUpAll`: one specimen card rendering three steps in `ckb` under RTL. Per
  `widget-golden-and-a11y-testing` rule 11 this is the narrow real-font lane — the only artifact in the
  repo that shows whether the script actually joins. It proves shaping to a human eye; it does not
  prove translation.

**Implementation.**
- `enum SunburstScript { latin, arabic }` and `SunburstScript scriptOf(Locale locale)` live in
  `lib/theme/sunburst_type.dart` — a second deliberate one-type-per-file exception, justified in the PR
  on the same grounds as `PlayAnswer` in `sunburst_colors.dart`: it is the argument vocabulary of
  `forScript`, and `lib/games/**` must be able to import it from a slot file.
- `SunburstType forScript(SunburstScript script)` — an exhaustive `switch` with no `default:`, applying
  one documented transform per step: family swap (`display`→`displayArabic`, `bodyFace`→`bodyArabic`),
  fallback cascade swap, `letterSpacing: 0`, weight clamped to what the Arabic face ships, and
  `height: max(latin.height, arabicLineFactor * latin.height)`.
- `static const double arabicLineFactor` — **DERIVED**, with the measurement in the doc comment (the
  exemplar set, the step it was driven by, and the date). It is one constant rather than ten hand-tuned
  heights so a font change is one measurement, not ten.
- `static SunburstType of(BuildContext context)` reads the asserted extension, then
  `forScript(scriptOf(Localizations.maybeLocaleOf(context) ?? const Locale('en')))`. It reads the
  **locale**, not `Directionality`: script and direction are different questions, and E04 owns
  direction. Memoize the derivation of `sunburstPop`.
- Casing stays out of the render: the `label` step's caps come from the ARB string in E04, never
  `toUpperCase()` — Arabic has no case, and a caps transform there is a no-op that reads as a bug.
  Restate this as a `///` on `label`.

**Files.** `lib/theme/sunburst_type.dart` (edit), `test/theme/sunburst_script_test.dart`,
`test/theme/sunburst_type_arabic_test.dart`, `test/theme/goldens/type_specimen_arabic_test.dart`.

**Skills.** `i18n-rtl-l10n`, `design-system-structure` (+ `references/typography-and-fonts.md`),
`widget-golden-and-a11y-testing`, `accessibility-as-code`, `dart3-idioms-and-coding-standards`,
`dartdoc-conventions`.

**Screenshot check.** n/a for the eight LTR PNGs — no screen exists yet, and the reference set has no
Arabic specimen. The golden specimen above is this task's visual artifact; the real comparison targets
are `design/sunburst-pop/screens/rtl/` once **E04** produces them.

**Done when.**
- `SunburstType.of(context)` is the only place a script is resolved, and `grep -rn 'Vazirmatn\|Lalezar\|Fredoka\|Nunito' lib/ | grep -v 'lib/theme/'`
  is empty.
- All ten steps pass the no-clip assertion for the Arabic exemplars; the constant that makes them pass
  is documented with its measurement.
- `check_i18n_bans.sh lib` and `check_raw_values.sh lib` are both clean.
- The tabular-figure result — works, or does not and E08 reserves width — is written into the epic and
  the PR body.

**Commits.**
1. `test(theme): script resolution, Arabic metrics and no-clip specs (red)`
2. `feat(theme): SunburstScript and locale-driven script resolution`
3. `feat(theme): Arabic metric transform — family, weight, zero tracking, taller line box`
4. `test(theme): real-font ckb specimen golden`

---

### T03.10 — `GameAccent` and `GameColourRole`

**Goal.** Give a game a way to declare its identity as an enum case that the theme layer resolves, so
nothing under `lib/games/**` ever holds a `Color`.

**Tests first (TDD).** `test/theme/game_accent_test.dart`:
- `'each accent resolves to its game slot pair'` — `stroopCoral.base(colors) == colors.gameStroop` and
  `.deep(colors) == colors.gameStroopDeep`; same for `schulteTurquoise`.
- `'both shipped accents carry an ink label'` — `onAccent(colors) == colors.textPrimary` for both;
  grape is the only accent that would invert, and it is not declared yet.
- `'only the two shipped games have an accent'` — `GameAccent.values.length == 2`. `nBackGrape` is
  deliberately absent: `gameNBack`/`gameNBackDeep` are not in `system.html` and grape has no measured
  deep partner (`grapePop` is *lighter* and already spent on `focusRing`), so the case would not
  compile. The test name carries the reason.
- `'no accent resolves into the gameplay tier'` — every `base`/`deep` result is drawn from
  `{gameStroop, gameStroopDeep, gameSchulte, gameSchulteDeep}` and equals no `play*`/`cb*` slot by
  identity of the slot, not of the value.
- `'GameAccent carries no display name'` — the enum has no `String get title`. A game's name is an ARB
  key (E04) read off the registry (E07); an English string here would make the home cards
  untranslatable and would put copy in the theme layer.
- `'GameColourRole has both cases'` — `decorative` and `mechanic`, with the doc stating the invariant
  E09/E10 must keep: `mechanic` ⇒ `BoardBackground.surfaceSunk`, `decorative` ⇒ `BoardBackground.gameAccent`.

**Implementation.** `lib/theme/game_accent.dart`:
`enum GameAccent { stroopCoral, schulteTurquoise }`, `enum GameColourRole { decorative, mechanic }`, and
`extension GameAccentTokens on GameAccent` with `base`, `deep` and `onAccent` as exhaustive `switch`
expressions with no `default:` — so adding a third game is a compile error until its slot pair exists.
The file lives in `lib/theme/` precisely so `lib/games/**` may import it while
`sunburst_primitives.dart` stays unreachable.

**Files.** `lib/theme/game_accent.dart`, `test/theme/game_accent_test.dart`.

**Skills.** `sunburst-game-surfaces` (+ `references/accent-contract.md`), `sunburst-tokens`,
`dart3-idioms-and-coding-standards`, `dartdoc-conventions`.

**Screenshot check.** n/a (no visual surface — the coral and turquoise bands are compared in E08
against `02-game-detail.png`, `04-stroop-rush.png` and `05-schulte-grid.png`, and against their RTL
counterparts once E04 captures them).

**Done when.**
- Two enum cases, three extension methods, zero `default:` clauses, no English string.
- `check_game_palette.sh lib` is clean.
- The N-Back omission is recorded in the PR body as an open design request, not as an oversight.

**Commits.**
1. `test(theme): GameAccent resolution and tier-separation specs (red)`
2. `feat(theme): GameAccent and GameColourRole with token resolution`

---

### T03.11 — `buildSunburstTheme()` and the first themed frame on iOS

**Goal.** Fold the four extensions and a hand-authored `ColorScheme` into the one `ThemeData` the app
will ever have, with Material's own soft elevation and ink splash switched off everywhere — and spend
it on the simulator in the same task.

**Tests first (TDD).** `test/theme/sunburst_theme_test.dart`:
- `'all four extensions are attached and resolvable'` — `pumpApp` and assert
  `SunburstColors.of(ctx)`, `SunburstShape.of(ctx)`, `SunburstMotion.of(ctx)` each return the
  corresponding `sunburstPop` const instance, and `SunburstType.of(ctx)` returns the Latin instance
  under `en` and the Arabic derivation under `fa` — `of()` resolves script, so identity here is
  locale-dependent by design.
- `'the ColorScheme is hand-authored from slots'` — `primary == accent`, `onPrimary == textPrimary`,
  `secondary == accentAlt`, `onSecondary == textInvert`, `tertiary == success`, `error == danger`,
  `onError == surfaceRaised`, `surface == surface`, `onSurface == textPrimary`,
  `onSurfaceVariant == textSecondary`, `outline == border`, `shadow == border`,
  `inverseSurface == surfaceInvert`, `surfaceTint == Colors.transparent`.
- `'M3 elevation tint is off'` — `surfaceTint` is transparent and every component theme's `elevation`
  is 0: `appBarTheme` (`elevation` and `scrolledUnderElevation`), `cardTheme`, `dialogTheme`,
  `bottomSheetTheme` (`elevation` and `modalElevation`), `snackBarTheme`.
- `'the press is a translate, not a ripple'` — `splashFactory == NoSplash.splashFactory`,
  `splashColor` and `highlightColor` transparent.
- `'row dividers are ink at the structural border width'` — `dividerTheme.color == colors.border`,
  `thickness == shape.borderWidth`; not `colors.divider`, which is 1.26:1 on paper and is the
  toggle-track inset only.
- `'the textTheme maps every step to its Material role'` — the nine mappings from the worked example,
  with `bodyColor`/`displayColor` applied as `textPrimary`.
- `'the textTheme is Latin and Material widgets are not the localized surface'` — `ThemeData.textTheme`
  is built from the const Latin instance because a `ThemeData` cannot see a locale. Every MindForge
  surface reads `SunburstType.of(context)`, which does resolve script; Material's own widgets are not
  used for content (E05 replaces them). Named so nobody later "fixes" the theme by trying to make
  `textTheme` locale-aware, which is not a thing `ThemeData` can do.
- `'a Scaffold under this theme paints cream'` — `pumpApp(const Scaffold())`, then read the
  `Material`'s colour and assert `colors.surface`.
- `test/policy/light_only_test.dart` — a grep policy test per `ci-pipeline-and-gates`
  `references/policy-grep-gate.md`: strip comments first, then assert `lib/` contains no `darkTheme`,
  no `themeMode`, and no `Brightness.dark`. One accumulated failure listing every hit, with the reason
  written for a stranger: a dark Sunburst Pop is a separate design direction with its own
  `system.html`, not a token flip.

**Implementation.** `lib/theme/sunburst_theme.dart`: `ColorScheme _sunburstColorScheme(SunburstColors c)`
stating every role the app consumes and letting the rest take `ColorScheme`'s own defaults (never
`fromSeed`, whose per-role overrides do not propagate), and `ThemeData buildSunburstTheme()` returning
exactly one `ThemeData` with `useMaterial3: true`, `scaffoldBackgroundColor: colors.surface`, the four
extensions, the splash kill-switches, the `textTheme` mapping and the five component themes. Material's
button themes stay at their defaults on purpose — MindForge's buttons are E05's custom widgets, and a
themed `ElevatedButton` would be an invitation to use one.

**Spend it in the same task.** Edit the `MaterialApp` E01 built in `lib/app.dart` to pass
`theme: buildSunburstTheme()` and `themeAnimationStyle: AnimationStyle.noAnimation` — Sunburst Pop has
one theme, so an implicit cross-fade between `ThemeData`s is 200ms of animation over a change that never
happens. A `ThemeData` that no call site reads is not a theme layer, it is a library: without this edit
`flutter run` renders unthemed Material through all of E04 and E05, and the first person to notice is
whoever compares a golden. Still **no `darkTheme:`**, no `themeMode:` — `test/policy/light_only_test.dart`
is the gate. **Do not touch `localizationsDelegates`, `supportedLocales` or `locale` on that
`MaterialApp`: E04 owns all three**, and E08 changes only `MaterialApp` → `MaterialApp.router`.

Also give `test/support/harness.dart`'s `pumpApp` its default in this commit:
`{ThemeData? theme}` resolving to `buildSunburstTheme()`. T03.1 made the parameter required precisely so
this default could not be forward-referenced; from here on E05/E08 call sites omit it.

**Files.** `lib/theme/sunburst_theme.dart`, `lib/app.dart` (edit), `test/support/harness.dart` (edit),
`test/theme/sunburst_theme_test.dart`, `test/policy/light_only_test.dart`.

**Skills.** `sunburst-tokens`, `design-system-structure`, `ci-pipeline-and-gates`,
`widget-golden-and-a11y-testing`, `dartdoc-conventions`.

**Screenshot check.** n/a (no screen is composed yet). The theme's ground truth against the PNGs is
T03.12; the first structural comparison is E05's component gallery.

**Done when.**
- `buildSunburstTheme()` is the only `ThemeData` constructor in `lib/`.
- `lib/app.dart` passes it, plus `themeAnimationStyle: AnimationStyle.noAnimation`.
- `xcrun simctl boot C13DDC02-375D-4E1B-8F81-44EB407D09A4` then
  `flutter run -d C13DDC02-375D-4E1B-8F81-44EB407D09A4` shows a **cream** window, not a white one, and
  the screenshot taken from it is 390×844 @2 — the same geometry as `screens/*.png`. Android is not
  built and not checked: iOS is the only target.
- `pumpApp`'s `theme` parameter now has a default and every T03.2–T03.10 call site still compiles.
- `test/policy/light_only_test.dart` is green and fails if `darkTheme:` is added anywhere in `lib/`.
- `flutter analyze --fatal-infos --fatal-warnings` clean.

**Commits.**
1. `test(theme): extension wiring, ColorScheme role and component-theme specs (red)`
2. `feat(theme): buildSunburstTheme with a hand-authored ColorScheme`
3. `feat(app): paint MindForgeApp with the Sunburst theme and no theme animation`
4. `test(policy): light-theme-only grep gate`

---

### T03.12 — Reference-pixel verification and gate proof

**Goal.** Close the loop between the shipped tokens, `system.html` and the eight rendered PNGs — and
prove the token and i18n gates fail on a bad value instead of passing vacuously.

**Tests first (TDD).** `test/theme/reference_pixel_test.dart`:
- Decode each PNG with `dart:ui` — `instantiateImageCodec(bytes)` then
  `toByteData(format: ImageByteFormat.rawRgba)`; no new dependency, `dart:ui` reads PNG natively.
- `'sampled reference pixels match the shipped slots'` — a table of
  `(file, x, y, expectedSlot, description)` rows covering at minimum: the page background on all eight
  screens → `surface`; a card interior on `01-home.png` → `surfaceRaised`; a border run on
  `01-home.png` → `border`; the primary button fill on `02-game-detail.png` → `accent`; the countdown
  ring on `03-countdown.png` → `accentAlt`; the Stroop band on `04-stroop-rush.png` → `gameStroop`;
  the Schulte board field on `05-schulte-grid.png` → `gameSchulte`; a found-tile fill on
  `05-schulte-grid.png` → `gameSchulteDeep`; the toggle-on track on `08-settings.png` → `success`.
  Coordinates are in the PNGs' own 780x1688 space and are **derived by opening the file**, never
  guessed.
- `'each sample sits in a flat region'` — every sample reads a 5x5 block and asserts all 25 pixels are
  identical, so no coordinate lands on an antialiased edge and silently starts measuring a blend.
- A failure message that prints the file, the coordinate, the sampled hex and the expected slot — the
  reader has to be able to decide "implementation defect or reference defect" from the output alone.
- The eight PNGs are **English LTR** and that is fine for this test: a hex does not mirror. The RTL set
  under `design/sunburst-pop/screens/rtl/` is produced by **E04** and becomes the comparison target for
  layout, not for colour. Say so in the file header so nobody re-samples the RTL PNGs for the same
  values later.

**Implementation.** No production code. If a sample disagrees, the order of investigation is fixed:
`system.html` wins on values; if the PNG is genuinely wrong, edit `app.html`, re-run
`design/sunburst-pop/capture-screens.sh`, and commit the regenerated PNGs as a deliberate design change
with the reason in the commit body — never adjust the Dart to match a stale render.

Then prove the gates:
1. Change one digit of `_P.ink`; confirm `check_raw_values.sh` still passes (it is not a value gate),
   `check_palette_contrast.sh` **fails**, `token_parity_test.dart` **fails**, `contrast_test.dart`
   **fails** and `reference_pixel_test.dart` **fails**. Revert.
2. Add `color: const Color(0xFF00FF00)` to a scratch file under `lib/` outside `theme/`; confirm
   `check_raw_values.sh` **fails**. Delete.
3. Add `padding: const EdgeInsets.only(left: 8)` to a scratch file under `lib/`; confirm
   `check_i18n_bans.sh lib` **fails** with the physical-side-geometry banner. Delete. This is the gate
   E05 will lean on for an entire component catalog, and it has never fired in this repo.
4. Delete one bundled Arabic `.ttf` from `assets/fonts/`; confirm `font_coverage_test.dart` **fails**
   rather than silently falling back. Restore.
5. Confirm E01's workflow runs `check_raw_values.sh`, `check_palette_contrast.sh` and
   `check_i18n_bans.sh`, and that all three now report a scanned target rather than a missing one.

**Files.** `test/theme/reference_pixel_test.dart`. (Plus a `.github/workflows/ci.yml` fix only if step
5 shows the gate loop skips any of the three scripts.)

**Skills.** `sunburst-tokens`, `i18n-rtl-l10n`, `ci-pipeline-and-gates`,
`widget-golden-and-a11y-testing`, `testing-strategy`.

**Screenshot check.** All eight PNGs in `design/sunburst-pop/screens/`. This task **is** the sampled-hex
step (step 5) of the comparison order in `screens/README.md`; structure, spacing rhythm, surface
construction and type role are checked by the epics that build the surfaces (E05, E08, E09, E10),
because there is nothing to lay out yet.

**Done when.**
- At least nine sampled pixels across all eight files match their slot exactly.
- Each of the five gate-proof steps was run and its result recorded in the PR body.
- The CI run on the PR shows all three source gates scanning `lib/` and passing.

**Commits.**
1. `test(theme): sample reference PNG pixels against the shipped slots`
2. `docs(epic): record the gate-proof results in the PR body` *(only if a workflow fix is needed;
   otherwise this task ships one commit)*

## Gates that must pass

From the repository root, with the branch checked out:

```bash
flutter pub get
flutter gen-l10n                                   # E01 shipped l10n.yaml and app_en.arb
dart format --output=none --set-exit-if-changed .
flutter analyze --fatal-infos --fatal-warnings
flutter test --test-randomize-ordering-seed random
flutter test --tags golden                         # T03.9's ckb specimen

# every skill gate, through the one runner E01 built
bash tool/skill_gates.sh

# Sunburst design gates — the two named in this epic's scope go green here first
.claude/skills/sunburst-tokens/scripts/check_raw_values.sh                lib
.claude/skills/sunburst-tokens/scripts/check_palette_contrast.sh \
  lib/theme/sunburst_colors.dart lib/theme/sunburst_primitives.dart
.claude/skills/sunburst-components/scripts/check_component_hygiene.sh     lib
.claude/skills/sunburst-shell-screens/scripts/check_shell_boundaries.sh   lib
.claude/skills/sunburst-game-surfaces/scripts/check_game_palette.sh       lib
.claude/skills/sunburst-motion-and-haptics/scripts/check_motion_tokens.sh lib

# i18n — the geometry half runs from this epic on; the ARB half cannot run yet
.claude/skills/i18n-rtl-l10n/scripts/check_i18n_bans.sh                   lib

# Structure, style and dependency gates
.claude/skills/design-system-structure/scripts/check_raw_values.sh        lib
.claude/skills/design-system-structure/scripts/check_font_bundling.sh     lib
.claude/skills/flutter-architecture/scripts/check_architecture.sh         lib
.claude/skills/project-structure-and-packages/scripts/check_import_boundaries.sh lib
.claude/skills/dart3-idioms-and-coding-standards/scripts/check-dart3-idioms.sh   lib
.claude/skills/widget-composition/scripts/check-widget-composition.sh     lib
.claude/skills/state-management-riverpod/scripts/ban-legacy-providers.sh  lib
.claude/skills/lint-and-style-config/scripts/lint-gates.sh                lib
.claude/skills/dependency-hygiene/scripts/audit-deps.sh
.claude/skills/testing-strategy/scripts/check_test_hygiene.sh             lib test
.claude/skills/widget-golden-and-a11y-testing/scripts/check-test-hygiene.sh lib test
.claude/skills/ci-pipeline-and-gates/scripts/ci-gates.sh                  lib
```

One deliberate omission, and one correction to an earlier draft of this section:

- **`flutter gen-l10n` runs here and belongs before `analyze`.** An earlier draft of this epic said
  there was no `l10n.yaml` and no ARB file yet — that was written against the old sequence. **E01 T01.9
  ships `l10n.yaml`, `lib/l10n/app_en.arb`, the generated `app_localizations*.dart` and the delegate
  wiring**, so the command runs, has something to generate, and `codegen-and-toolchain` requires it
  ahead of `analyze` exactly as every other epic from E01 on does. This epic adds no ARB key; T04.1 is
  what takes the catalog from one locale to four.
- **No `check_arb_parity.sh`.** It exits **2** on a directory holding only the template, which is
  still `lib/l10n`'s state here, so it stays in `tool/skill_gates.sh`'s **skip** table carrying E01's
  measured reason. E04 T04.1 moves it into the run table in the same commit that adds `app_de.arb`,
  `app_fa.arb` and `app_ckb.arb`.

`check_i18n_bans.sh` is the opposite case and is in the list: it also exits 2 on a missing target, but
`lib/` exists from E01, so it runs and must be green from this epic forward. E05 inherits it.

The list above is this epic's **named spot-checks** — the gates whose contracts this epic changes, run
individually so a failure names itself. `bash tool/skill_gates.sh` is the authoritative sweep and the
only sanctioned way to run the whole set: 29 of the 49 scripts fail argument-less, five can never pass
that way, and one exits 127 on macOS bash 3.2, so a `for s in .claude/skills/*/scripts/*.sh` loop is a
broken gate rather than a stricter one.

## Risks and open questions

1. **`_P` privacy vs. file split — decided.** `_P` is library-private, so a separate
   `sunburst_primitives.dart` library cannot expose it to `sunburst_colors.dart` without making it
   public. **Decision:** use `part`/`part of` — `sunburst_colors.dart` declares
   `part 'sunburst_primitives.dart';`. The hexes keep their own file (which the contrast gate reads by
   default), `_P` stays unreachable from every other library, and rule 2 holds. If review rejects
   `part`, the fallback is a single `sunburst_colors.dart` holding both tiers and passing that one file
   to `check_palette_contrast.sh`; do not make `_P` public.
2. **Sorani glyph coverage in the display face is the sharpest unknown in this epic.** Lalezar is the
   closest OFL analogue to Fredoka's personality, and **its Sorani coverage and its shipped weight set
   are both unverified until the file is on disk**. T03.7 decides it from the font's own `cmap` and
   `GSUB`, not from a foundry page. If it fails — missing `ڕ ڵ ۆ ێ ھ`, missing `ە`, missing the
   `۰`–`۹` block, or no shaping tables — the display face for `fa`/`ckb` becomes **Vazirmatn at its
   heaviest bundled weight** and Sunburst Pop's display voice in those locales is a heavy Persian sans
   rather than a chunky rounded one. **Record the outcome in this section when T03.7 lands**; do not
   leave the reader guessing which face shipped. A single-weight display face also means the Arabic
   display steps declare that one weight — never w600/w700 against a 400 file, which synthesizes a
   faux bold and mangles cursive joins.
3. **The Fredoka personality does not survive translation, and pretending otherwise is the failure
   mode to avoid.** In `fa` and `ckb` the identity is carried entirely by the **shape language** — the
   3px ink border, the hard offset shadow at zero blur, the press-down translate, the cream ground and
   the saturated pop palette — and not by the typeface. No Arabic-script face is "Fredoka in Arabic";
   the closest candidates share roundness and weight, not proportions, and Arabic's cursive baseline
   behaves nothing like a rounded Latin geometric sans. **Consequences to accept rather than argue
   with:** the RTL screens will read as a related product, not an identical one; a reviewer comparing
   `screens/*.png` to `screens/rtl/*.png` must judge structure, rhythm and colour, not letterforms; and
   nobody should spend a day font-shopping for a closer match, because the gap is structural. The
   compensating requirement is that every non-type token is bit-identical across locales, which T03.3,
   T03.5 and T03.6 each pin with a named test.
4. **`ckb` has no `flutter_localizations` delegate — verified, and it is E04's to solve.** Read on this
   machine at Flutter 3.44.6: `kMaterialSupportedLanguages` carries 85 languages including `fa`, `ar`
   and `de`, and **not** `ckb`; there is no `material_ckb.arb`. Switching to `ckb` with only the global
   delegates throws. E04's fix is a custom `LocalizationsDelegate` serving our ARB strings for `ckb`
   while delegating Material/Cupertino to the nearest script neighbour (`fa`, else `ar`). This epic's
   only obligations are to not hide the gap — T03.1's third test asserts the current failure is loud —
   and to make `scriptOf` already answer correctly for `ar`, so E04's neighbour choice does not need a
   type-layer change.
5. **Direction in this epic's tests is a stand-in.** `_WidgetsLocalizationsDelegate.isSupported` returns
   `true` for every locale and `DefaultWidgetsLocalizations.textDirection` is hardcoded
   `TextDirection.ltr`, so pumping `locale: fa` gives an **LTR** tree until `GlobalWidgetsLocalizations`
   lands in E04. The harness's explicit `textDirection` parameter exists for exactly that window and is
   documented as test-only; production code must never hardcode a root `Directionality`
   (`i18n-rtl-l10n` rule 4). E04 removes the stand-in.
6. **`arabicLineFactor` is DERIVED from a measurement against the faces this epic bundles.** Change the
   face and the number is void. Mitigations: the constant is measured against the tallest exemplar
   across all ten steps, the no-clip test re-measures on every run, and the doc comment records the
   exemplar set and the driving step. If a later epic finds a step clipping in `ckb`, raise the
   constant or give that step a named exception with its evidence — never shrink the text
   (`accessibility-as-code` rule 5 bans `FittedBox`, computed `fontSize` and ellipsis as fitting tools).
7. **Tabular figures on the Arabic face are unverified.** `FontFeature.tabularFigures()` requires the
   font to implement `tnum` for the digit block in use. T03.9 measures the ten Eastern digits' advance
   widths and either confirms it or inverts the test and hands E08's HUD a max-digit-width reservation.
   The failure mode if this is skipped is a HUD that jitters every second of a run in exactly two of
   four locales — visible only to someone playing in Persian.
8. **Translation quality is an open question and is not this epic's to close.** The faces, metrics and
   fallbacks can be proven mechanically; whether a Persian or — much more likely to be wrong — a Sorani
   string is idiomatic cannot. E04 authors the ARB files and E11's manual pass owns the sign-off, but
   the requirement belongs on the record from here: **a native reader of each script must review the
   shipped strings and the rendered specimen before release.** Machine-quality Sorani is a real risk
   and must not be presented as done.
9. **`sunburst_colors.dart` will exceed the ~300-line file limit** (34 fields x constructor + `copyWith`
   + `lerp` + `_props` + 26 `@contrast` lines), and `sunburst_type.dart` overruns the
   one-public-type-per-file rule twice (`SunburstScript`, `scriptOf`). Both are cohesive overruns of
   `dart3-idioms-and-coding-standards` rule 11 and `naming-conventions` rule 5, and must be justified in
   the PR body, not silenced. Splitting the const colour instance away from the class would break
   `check_palette_contrast.sh`, which resolves slots to primitives by matching both files line by line.
10. **`check_palette_contrast.sh` constrains formatting.** It matches `slot: _P.primitive,` one per
    line. If `dart format` ever collapses that block, the gate goes quiet rather than red. T03.4 must
    confirm the formatted output still yields 26 resolved pairs — a passing gate over zero pairs is the
    failure mode to watch for (the script fails on *no* declarations, but not on a partial resolution
    after a reformat).
11. **`title`/`button` weight: §04 (w600) vs §12 (w700).** `references/shape-and-type.md` calls §04 the
    winner and flags this as the one open question for the designer. This epic ships w600 and pins it
    with a named test. **Ask the designer**; do not change a call site in E05/E08 to 700 without
    changing `system.html` §04 first. Note that the question is moot in `fa`/`ckb` if the display face
    is single-weight — another reason the answer must come from the designer rather than from a call
    site.
12. **N-Back has no accent.** `gameNBack`/`gameNBackDeep` are absent from `system.html` and grape has no
    measured deep partner. `GameAccent` ships two cases. **Ask the designer** for a grape-deep primitive
    before a third game is scheduled; the exhaustive `switch` makes this a compile error rather than a
    surprise.
13. **Reference-pixel coordinates are brittle.** Re-running `capture-screens.sh` after an `app.html`
    edit can move a sampled region — and E04 *will* edit `app.html` to produce the RTL variant. If that
    edit changes the LTR render at all, re-deriving these coordinates is part of E04's change, and the
    5x5 uniformity assertion plus the coordinate-printing failure message are what make that cheap.
14. **App size.** The Arabic faces are large relative to the Latin ones and MindForge ships six faces
    for four locales. T03.7 records each file's byte size and the resulting bundle delta in the PR.
    Subsetting is the obvious lever and is deliberately **not** pulled here: a subset built without
    `--layout-features='*'` silently breaks cursive shaping, which is worse than a larger download.
    Revisit in E11 with a measured `.ipa` size, not before.
15. **Nunito ExtraBold ships and no step spends it**, and Vazirmatn ExtraBold may end up in the same
    position if Lalezar passes. Deliberate: `app.html` renders several strings at 800 and E08 must not
    need a re-bundle. It does **not** license an eleventh step invented at a call site — a genuine need
    earns a name in `system.html` §04 first.
16. **The ten-step rule is amended three times downstream, on purpose.** E05 adds `buttonLarge` and
    `chip` (both rendered specimens: `.btn--lg{font-size:21px}`, `.chip{14}`); E08 adds the six shell
    steps `titleBar`, `greeting`, `sectionLabel`, `heroTitle`, `countdownNumeral`, `statValue`; E09 adds
    **two** — `buttonCompact` (T09.5) and `stimulusCompact` (T09.7). **Twenty**, not ten, is the shipped
    number — and **every one of them must pass
    T03.9's Arabic no-clip assertion when it is added**, which is why that test iterates the source's
    field list rather than a literal. **Decision:** the count test names its expected steps in a list
    literal and derives the count from the source file, so each addition is a reviewed one-line test
    edit carrying its `DERIVED` evidence. Update `sunburst-tokens/references/shape-and-type.md`
    alongside the E05 additions so the two stop disagreeing. **Ask the repo owner** whether the skill's
    rule-10 wording should be amended rather than the exceptions documented.
17. **iOS-only, stated once so it is not mistaken for an omission.** There is no `android/` target, no
    Android device in any run command, and no Play-side work in this epic or any other until it is
    scheduled. `flutter run -d C13DDC02-375D-4E1B-8F81-44EB407D09A4` is the run command; the simulator
    is 390×844 precisely so its screenshots are diffable against `screens/*.png`. `Info.plist`'s
    `CFBundleLocalizations` (`en`, `de`, `fa`, `ckb`) and `CFBundleDevelopmentRegion` (`en`) were
    written by **E01 T01.9**, which created the iOS target and already knew the locale set; E04 T04.1
    re-asserts them in a policy test. Neither is this epic's to touch.

## Definition of done

- [ ] `lib/theme/` holds exactly eight files: `font_licences.dart` (E01's, extended here with the
      Arabic OFL entries), `sunburst_primitives.dart`, `sunburst_colors.dart`, `sunburst_shape.dart`,
      `sunburst_motion.dart`, `sunburst_type.dart`, `game_accent.dart`, `sunburst_theme.dart`. There is
      no `sunburst_fonts.dart` and no second `registerSunburst*` function — a duplicate licence
      registration is the thing this list exists to prevent.
- [ ] Every hex in `_P` matches `design/sunburst-pop/system.html`; anything derived rather than
      transcribed is marked `DERIVED` with its reason (`borderDisabled`, `displayFallback`,
      `arabicLineFactor`).
- [ ] No file outside the colour library names `_P`; no chrome slot binds to a `play*`/`cb*` slot.
- [ ] Every new slot appears in the constructor, `copyWith`, `lerp`, `_props`, the `const sunburstPop`
      instance and — where it sits under text or is a UI boundary — a `// @contrast` line.
- [ ] Every `BoxShadow` in the app comes from `SunburstShape.shadow()` with `blurRadius: 0` and
      `spreadRadius: 0`; there is no `e0` field; the shadow offset and `pressTranslate` are proven
      identical under LTR and RTL.
- [ ] Six faces bundled and licensed; `SunburstType.of(context)` resolves Fredoka/Nunito under `en`/`de`
      and the Arabic pair under `fa`/`ckb`; no font family string exists outside `lib/theme/`.
- [ ] The Arabic faces are proven — from their own `cmap` and `GSUB` — to cover `ڕ ڵ ۆ ێ ھ ە ڤ`, the
      Persian letter set and `۰۱۲۳۴۵۶۷۸۹`, and to ship shaping tables. The display-face outcome
      (Lalezar or Vazirmatn) is recorded in Risk 2 and in the PR body.
- [ ] Every Arabic step has `letterSpacing: 0` and a line box that clears the measured exemplar height;
      the tabular-figure result is recorded as working or as a width reservation handed to E08.
- [ ] Exactly one `ThemeData`, and `lib/app.dart` actually passes it with
      `themeAnimationStyle: AnimationStyle.noAnimation`; no `darkTheme`, no `themeMode`, no
      `Brightness.dark`, proven by `test/policy/light_only_test.dart`. `localizationsDelegates`,
      `supportedLocales` and `locale` are untouched — E04 owns them.
- [ ] The only `pubspec.yaml` change is the `flutter: fonts:` block; `pubspec.lock` shows no delta and
      `audit-deps.sh` is clean.
- [ ] `check_raw_values.sh`, `check_palette_contrast.sh` and `check_i18n_bans.sh` all green **over real
      code**, and each shown to fail on a deliberately introduced defect (recorded in the PR body).
- [ ] `dart format --set-exit-if-changed .`, `flutter analyze --fatal-infos --fatal-warnings` and
      `flutter test` all green; every gate script in the list above exits 0.
- [ ] `test/support/load_app_fonts.dart` and `dart_test.yaml`'s `golden` tag exist and are used by
      T03.9's `ckb` specimen; `flutter test --tags golden` passes on the pinned runner and the default
      lane excludes it. E04 and E05 extend this lane; neither recreates it.
- [ ] Reference-pixel test green against all eight PNGs in `design/sunburst-pop/screens/`.
- [ ] `flutter run -d C13DDC02-375D-4E1B-8F81-44EB407D09A4` shows a cream window on the 390×844
      simulator.
- [ ] `/simplify` run and its findings addressed.
- [ ] `/code-review` run and its findings addressed.
- [ ] PR opened against `main` from `epic/03-design-tokens-and-theme`, body stating what changed, why,
      how it was verified, which screens were sampled, the display-face decision with its evidence, the
      four open designer/owner questions (button weight, grape-deep for N-Back, the `part`/`part of`
      decision, the twenty-steps wording) and what was deliberately left out (no additional ARB locale,
      no delegates, no components, no screens — E04, E05 and E08).
- [ ] CI green on the PR (the pipeline E01 created).
- [ ] Merged preserving the granular commits, branch deleted, back on `main`, `git pull` done.
