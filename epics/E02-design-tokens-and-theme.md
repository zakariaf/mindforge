# E02 · Design tokens and theme

| | |
|---|---|
| **Branch** | `epic/02-design-tokens-and-theme` |
| **Depends on** | E01 |
| **Unblocks** | E03, E04, E06, E07, E08, E09 |
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
Nunito), `game_accent.dart` (`GameAccent` + `GameColourRole` and the `GameAccentTokens` extension),
and `sunburst_theme.dart` (a hand-authored `ColorScheme` keeping M3 role names, all four extensions
attached, `buildSunburstTheme()`, and the two lines in `lib/app.dart` that actually spend it).

The eighth file in `lib/theme/` is `font_licences.dart`, which **E01 already shipped** along with the
four `.ttf` faces and both OFL texts. This epic names those faces in `SunburstType`; it does not
re-bundle them and does not add a second licence registration.

Each of the four extensions is a `ThemeExtension` with a `const` constructor, `copyWith`, an honest
`lerp` (except `SunburstMotion`, which snaps at the midpoint on purpose) and an asserting
`of(context)`. Behind them sits a test suite whose job is to make drift impossible: a token-parity
test that reads the hexes straight out of `system.html` and fails when Dart and the design file
disagree, field-count invariants that fail when a new slot is forgotten in `copyWith`/`lerp`/`_props`,
a WCAG contrast test on colour values, and a reference-pixel test that samples the eight shipped
PNGs and asserts the sampled hexes are the shipped slots.

## Why we need it

Every screen, component, board and animation in E03–E10 reads its colour, radius, shadow, duration,
curve and type step off these four extensions. Nothing above this layer may hold an aesthetic value —
`check_raw_values.sh` fails the build for it — so until `lib/theme/` exists there is literally no
legal way to paint a pixel in this repo. E03 cannot build `PopSurface` without `SunburstShape.shadow()`
and `pressTranslate()`; E04 cannot name a moment without the four durations; E07 cannot lay out a
screen without `gutter`/`cardGap` or a `GameAccent` to tint the play band.

The second reason is drift. A design system rots one forgotten `lerp` line and one "improved" hex at a
time. `system.html` is the authority for values and the eight PNGs are the implementation targets; if
the Dart is not mechanically pinned to both, six months from now nobody can tell which of the two is
wrong. The parity test and the reference-pixel test are the pins.

`check_raw_values.sh` and `check_palette_contrast.sh` have never scanned a line of Dart. Today they
print `note: 'lib' not found; nothing to scan.` and exit 0. This epic is the first time either gate
proves anything.

## Current state

Verified by `ls` on 2026-08-19, on `main` at `cb1c3e2` (4 commits, clean tree):

- **No Flutter app.** No `pubspec.yaml`, no `lib/`, no `test/`, no `.github/`. E01 creates them.
- `design/sunburst-pop/system.html` (1570 lines) — the `:root` block at lines 16–89 holds 30
  hex-valued CSS custom properties: 19 chrome primitives, 7 gameplay, 4 colour-blind (all four
  duplicating a gameplay hex). Below that: `--bw:3px`, `--r-sm|md|lg|xl|pill`, `--sh-0:none` plus
  `--sh-1..4`, `--dur-tap|state|move|celebrate`, `--ease-pop|out|inout`, `--display`, `--body`.
  Comment at line 14: *"All colour lives on `:root`. Nothing below `:root` uses a hex."*
- `design/sunburst-pop/screens/*.png` — eight PNGs, all `780 x 1688, 8-bit/color RGB` (390x844 @2x),
  plus `README.md` (the comparison procedure) and `contact-sheet.html`.
- `.claude/skills/sunburst-tokens/` — `SKILL.md`, three references
  (`palette-and-slots.md`, `shape-and-type.md`, `adding-a-token.md`), a 784-line worked
  `examples/sunburst_theme.dart` that carries the whole layer as one file, `templates/theme_file_template.dart`,
  and the two gate scripts.
- 49 gate scripts under `.claude/skills/*/scripts/`. **They do not all exit 0 on an absent target** —
  measured with no argument, 20 exit 0, 21 exit 2, 7 exit 1 and `check-scheduler-purity.sh` exits 127 on
  macOS bash 3.2. E01's *Current state* carries the full accounting and E01 T01.5 corrects `CLAUDE.md`
  working agreement 10 to match. The two this epic cares about — `check_raw_values.sh` and
  `check_palette_contrast.sh` — are in the 20: they print `note: 'lib' not found; nothing to scan.` and
  exit 0, which is why they have never proven anything yet.
- `tool/skill_gates.sh` exists from E01 T01.8 and is the only sanctioned way to run the skill gates.
- `.claude/skills/sunburst-components/examples/*.dart` import `package:mindforge/theme/...`, so the
  package name E01 must pick is **`mindforge`**.

Nothing in this epic exists yet, in any form.

## What we will achieve

- `lib/theme/` holds exactly eight files; `grep -rn 'Color(0x' lib/` returns hits in
  `sunburst_primitives.dart` and nowhere else.
- `.claude/skills/sunburst-tokens/scripts/check_raw_values.sh lib` prints
  `OK: no raw aesthetic values outside */theme/.` over real code.
- `.claude/skills/sunburst-tokens/scripts/check_palette_contrast.sh lib/theme/sunburst_colors.dart lib/theme/sunburst_primitives.dart`
  recomputes 26 declared pairs from the shipped hexes and prints `OK`. Deliberately corrupting one
  primitive hex makes it fail — proven and reverted, not assumed.
- `flutter test` runs a theme suite that fails if: a hex in Dart differs from `system.html`; a
  `SunburstColors` field is missing from `copyWith`, `lerp` or `_props`; `easePop` stops overshooting;
  `resolve()` returns anything but `Duration.zero` under `disableAnimations`; a `BoxShadow` gains blur;
  an eleventh type step appears; or a pixel sampled from `01-home.png` stops matching `colors.surface`.
- `SunburstType`'s ten steps name only the four faces **E01 already bundled and licensed**; a step that
  names a fifth face fails `check_font_bundling.sh`. This epic adds no asset and no `LicenseRegistry`
  call — `test/theme/font_licence_test.dart` (E01) remains the licence proof.
- `flutter run -d macos` shows a **cream** window instead of white: T02.9 sets `theme:` on the
  `MaterialApp` E01 built, so the app is themed from this epic onward rather than rendering unthemed
  Material through E03 and E04.
- A human can run `flutter test` and see the token suite green, then open `lib/theme/sunburst_colors.dart`
  beside `design/sunburst-pop/system.html` and find the same 30 values in the same order.
- `flutter analyze --fatal-infos --fatal-warnings` is clean with `public_member_api_docs` promoted to
  error: every public slot, method and enum case carries a `///`.
- PR merged into `main` with CI (created in E01) green.

## Skills to load

| Skill | Why, for this epic |
|---|---|
| `flutter-conventions-index` | The front door. Open first; it routes and carries the 14 house rules the tasks below inherit. |
| `sunburst-tokens` | Owns every value in this epic. `references/palette-and-slots.md` is the slot table with measured ratios, `references/shape-and-type.md` the radius/elevation/spacing/type tables, `references/adding-a-token.md` the four-places-plus-the-gate procedure, `examples/sunburst_theme.dart` the compiling target. |
| `design-system-structure` | Owns the mechanism the values ride on: two-tier tokens, `ThemeExtension`, the asserting `of()` with no `?? fallback`, hand-authored `ColorScheme` over `fromSeed`, honest `lerp`, `resolveMotion`. Read the pattern here, the number in `sunburst-tokens`. `references/typography-and-fonts.md` carries T02.7's font bundling, `LicenseRegistry.addLicense`, `FontWeight` driving `wght`, and why a redundant `FontVariation('opsz'\|'ital')` silently no-ops. |
| `sunburst-game-surfaces` | Declares `GameAccent` and `GameColourRole` in `lib/theme/game_accent.dart` (T02.8) and fixes the tier rule the whole colour file obeys: no `play*`/`cb*` slot may paint chrome. `references/accent-contract.md` carries the per-game table and the open N-Back request. |
| `sunburst-motion-and-haptics` | Fixes that there are four durations and three curves and no fifth, and states that `SunburstMotion.resolve` is Sunburst Pop's binding of `resolveMotion`. It decides who spends the durations (E04); this epic only ships them. |
| `dart3-idioms-and-coding-standards` | `PlayFill`/`PlayAnswer`/`GameAccent`/`GameColourRole` are payload-free closed sets, so they are enums (rule 3); `final` fields + `const` constructors + value equality (rule 5); exhaustive `switch` with no `default:` in `answerColour`/`base`/`deep` (rule 1); the file ≤ ~300-line limit the colour file will overrun and must justify (rule 11). |
| `naming-conventions` | `lowercase_with_underscores` file names matching their primary declaration, `lowerCamelCase` constants (`space5`, never `SPACE_5`), grouped-and-sorted directives. |
| `dartdoc-conventions` | `public_member_api_docs` is an error: 34 colour slots, 16 shape fields, 7 motion fields and 10 type steps each need a `///` that says the role, not the value — and rule 8 (restate the invariant at its enforcement point) is why `lerp`'s midpoint snap and `danger`'s primitive wiring carry comments. |
| `testing-strategy` | Test at the cheapest tier that can assert the behaviour: the parity, field-count and contrast tests are pure Dart, not `pumpWidget`. `scripts/check_test_hygiene.sh` runs before the PR. |
| `widget-golden-and-a11y-testing` | Owns `test/support/harness.dart` — **this epic creates it and it is the one app-level harness in the repo**: `Device`/`Device.all` at DPR 2 (the `capture-screens.sh` geometry), `useDevice` with `addTearDown(view.reset)`, `MediaQuery` layered **above** `MaterialApp` built from `.copyWith`, which is exactly what the `resolve()` and `of()` tests need. E03 and E07 extend this file; neither forks a second `Device` or a second `pumpApp`. Also owns the pure-Dart WCAG-on-colour-values pattern rather than `textContrastGuideline`. |
| `accessibility-as-code` | The 4.5 body / 3.0 large + non-text floors the `@contrast` block declares, and the rule that a11y state is read from `MediaQuery` — not app state — which is why `resolve()` takes a `BuildContext`. |
| `lint-and-style-config` | `flutter analyze --fatal-infos` is a hard gate; suppression is line-scoped only, and a raw value is a new slot, never an `// ignore:`. |
| `dependency-hygiene` | Read-only here: this epic adds no dependency and edits no `pubspec.yaml` line. It is listed so the standing refusal of `google_fonts` is in scope while `SunburstType` names two font families — reaching for it is the one temptation this task carries. |
| `ci-pipeline-and-gates` | T02.10 proves the two token gates are wired into E01's workflow and actually fail on a bad value; `references/policy-grep-gate.md` is the pattern for the light-only source grep. |

## Tasks

### T02.1 — Test support: device harness and the design-source parser

**Goal.** Ship the two test-support files every later task's tests import, pinned to the reference
render geometry.

**Tests first (TDD).** This is the one task in the epic that cannot state its tests first: a harness
has no behaviour of its own, and its first real assertion is T02.2's parity test. It is verified by
being used, and it is deliberately the smallest possible task so nothing hides in it.

**Implementation.**
- `test/support/harness.dart` per `widget-golden-and-a11y-testing`. **This is the one app-level harness
  in the repository.** E03 adds `pumpPopComponent` beside it, E07 adds `pumpShellApp` beside it; neither
  declares a second `Device` type, a second device-preset list or a second `pumpApp`.
  `final class Device { const Device(this.name, {required this.logicalSize, required this.dpr}); }`,
  with four presets named by their measured size and **all four at DPR 2** — the exact geometry
  `capture-screens.sh` rendered the eight PNGs at (780×1688 = 390×844 @2). A golden lane at DPR 3 cannot
  be laid beside a DPR-2 reference, so one number serves every consumer:
  ```dart
  static const compact320   = Device('320', logicalSize: Size(320, 640), dpr: 2);
  static const small360     = Device('360', logicalSize: Size(360, 800), dpr: 2);
  static const reference390 = Device('390', logicalSize: Size(390, 844), dpr: 2); // the PNG geometry
  static const large430     = Device('430', logicalSize: Size(430, 932), dpr: 2);
  static const all = <Device>[compact320, small360, reference390, large430];
  ```
  `Device.all` is the one matrix name — E03, E07, E08, E09 and E10 all iterate it.
  `void useDevice(Device d)` sets `view.devicePixelRatio`, `view.physicalSize = d.logicalSize * d.dpr`
  and `addTearDown(view.reset)`.
  `extension PumpApp on WidgetTester { Future<void> pumpApp(Widget child, {required ThemeData theme, bool disableAnimations = false, List<Override> overrides = const []}) }`
  builds `ProviderScope` → `MaterialApp(theme: theme)` → `Builder` +
  `MediaQuery.of(context).copyWith(...)` layered **above** `MaterialApp`, never a bare `MediaQueryData()`.
  **`theme` is a required parameter, not `buildSunburstTheme()`.** That function does not exist until
  T02.9, and a harness that calls it would leave every test in T02.2–T02.8 uncompilable. Call sites in
  those tasks pass an inline `ThemeData(extensions: [...])` carrying only the extension under test;
  T02.9 adds `ThemeData theme = _defaultTheme` defaulting to `buildSunburstTheme()` in the same commit
  that creates it, and E03/E07 onward rely on that default.
- `test/support/design_source.dart`: `final class DesignSource` with static readers that parse text,
  not Dart types — `cssRootHexes()` → `{'--cream': 'FFF8EC', ...}` from the `:root{}` block of
  `design/sunburst-pop/system.html`; `cssRootAliases()` → `{'--surface': '--cream', ...}`;
  `cssScalar(String name)` for `--bw`/`--r-*`/`--dur-*`/`--ease-*`; `dartPrimitiveHexes()` parsing
  `static const <name> = Color(0xFF<HEX>);` out of `lib/theme/sunburst_primitives.dart`;
  `dartSlotBindings()` parsing `<slot>: _P.<primitive>,` out of the const instance; and
  `dartFieldNames(File f, String className)` returning the `final <Type> a, b, c;` names declared in a
  class. It parses the same shapes `check_palette_contrast.sh` parses, on purpose — if the parser and
  the gate disagree, the gate is silently passing.
- Both read files with `dart:io` relative to the package root; add a `pathToRepoFile()` helper so a
  test never hardcodes a `../`.

**Files.** `test/support/harness.dart`, `test/support/design_source.dart`.

**Skills.** `widget-golden-and-a11y-testing`, `testing-strategy`, `naming-conventions`.

**Screenshot check.** n/a (no visual surface).

**Done when.**
- `Device.reference390` is 390x844 at DPR 2 and nothing else in the repo restates those numbers.
- `pumpApp` takes `theme` as a required parameter; `buildSunburstTheme` appears nowhere in this file
  until T02.9.
- `useDevice` calls `addTearDown(view.reset)`; no test file touches `tester.binding.window`.
- `DesignSource.cssRootHexes()` returns 30 entries when run against the shipped `system.html`.
- `.claude/skills/widget-golden-and-a11y-testing/scripts/check-test-hygiene.sh lib test` is clean.

**Commits.**
1. `test(support): device harness with Device.all pinned to the @2x reference geometry`
2. `test(support): DesignSource parser for system.html and the primitives file`

---

### T02.2 — `_P` primitives and the system.html parity gate

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

**Screenshot check.** n/a (no visual surface — the sampled-hex proof against the PNGs is T02.10).

**Done when.**
- 26 constants, each `static const <name> = Color(0xFF……);`, one per line.
- `flutter test test/theme/token_parity_test.dart` is green; changing one hex digit turns it red.
- `grep -rn '_P\.' lib/ | grep -v 'lib/theme/'` is empty.
- `check_raw_values.sh lib` is clean.

**Commits.**
1. `test(theme): primitive-to-system.html parity spec (red)`
2. `feat(theme): _P primitive tier transcribed from system.html`

---

### T02.3 — `SunburstColors`: chrome slots and the extension contract

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

### T02.4 — `SunburstColors`: gameplay tier, colour-blind swap, and the contrast gate

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
  - `'chrome slots are wired to primitives, not to gameplay slots'` — the tier tripwire. Parse the
    const instance with `DesignSource.dartSlotBindings()` and assert `danger` binds to `playRed` and
    `accentAlt` to `grape` **as primitive names**, and that no chrome slot name binds to a primitive
    that the `cbBlue`/`cbYellow`/`cbOrange`/`cbPink` slots also bind to. A grep gate cannot see tier;
    this test can.
  - The field-count, `copyWith`, `lerp` and equality coverage tests from T02.3 now cover 34 fields
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
- `.claude/skills/sunburst-game-surfaces/scripts/check_game_palette.sh lib` is clean.

**Commits.**
1. `test(theme): answer palette, colour-blind swap and tier-separation specs (red)`
2. `feat(theme): gameplay and colour-blind slots with PlayAnswer/PlayFill`
3. `test(theme): WCAG contrast test over colour values`
4. `feat(theme): 26 @contrast declarations, check_palette_contrast.sh green`

---

### T02.5 — `SunburstShape`

**Goal.** Land border width, radius scale, the four hard-shadow elevations, the press law, the focus
ring and the spacing rhythm — with blur and spread unrepresentable rather than merely unset.

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
- `'there is no e0 field'` — `DesignSource.dartFieldNames` contains no `e0`; the absence of a shadow is
  `const <BoxShadow>[]`, and an absent value must not be interpolable.
- `'pressTranslate is derived from the resting elevation'` — `e2` → `Offset(4, 4)`, `e1` → `Offset(2, 2)`,
  `e3` → `Offset(7, 7)`, `e4` → `Offset(9, 9)`; `pressedShadow == Offset(1, 1)`.
- `'two press scales ship'` — `pressScale == 0.98`, `pressScaleSmall == 0.97`, with the comment that
  §12's single 0.98 loses to the rendered gallery.
- `'the spacing rhythm is static and complete'` — `space1..space7` are 4/8/12/16/20/28/40;
  `gutter == space5`, `cardGap == space4`, `cardPadding == space4`; and they are `static`, asserted by
  the fact the test reads them off the class, not an instance.
- `of()` present/absent pair, and the `copyWith`/`lerp`/field-count coverage trio from T02.3 retargeted
  at `SunburstShape` (16 fields, mixed `double`/`Radius`/`Offset` — `lerp` uses `lerpDouble`,
  `Radius.lerp`, `Offset.lerp`).

**Implementation.** `lib/theme/sunburst_shape.dart` per `references/shape-and-type.md`.
`List<BoxShadow> shadow(Offset elevation, Color ink)` is the only `BoxShadow` constructor in MindForge
and hardcodes `blurRadius: 0, spreadRadius: 0`. `Offset pressTranslate(Offset elevation)` and
`static const Offset pressedShadow`. Spacing as `static const double`, because a gutter is layout
rhythm and interpolating one mid-animation is meaningless — state that in the doc comment.

**Files.** `lib/theme/sunburst_shape.dart`, `test/theme/sunburst_shape_test.dart`.

**Skills.** `sunburst-tokens`, `design-system-structure`, `dartdoc-conventions`,
`dart3-idioms-and-coding-standards`.

**Screenshot check.** n/a (no visual surface — E03 compares the first surfaces built on these numbers).

**Done when.**
- `.claude/skills/sunburst-components/scripts/check_component_hygiene.sh lib` is clean, including its
  blur/spread rule which applies inside `lib/theme/` too.
- `grep -rn 'BoxShadow(' lib/` matches only `sunburst_shape.dart`.
- 16 fields; no `e0`.

**Commits.**
1. `test(theme): SunburstShape scale, shadow and press-law specs (red)`
2. `feat(theme): SunburstShape with the only BoxShadow factory in the app`
3. `feat(theme): static spacing rhythm — space1..space7, gutter, cardGap, cardPadding`

---

### T02.6 — `SunburstMotion`

**Goal.** Land the four durations, three curves, the deliberate midpoint-snap `lerp`, and `resolve()` —
the single place a widget in MindForge asks whether to animate.

**Tests first (TDD).** `test/theme/sunburst_motion_test.dart`:
- `'durations match system.html'` — 120/160/180/240 ms against `--dur-tap|state|move|celebrate`.
- `'nothing exceeds durCelebrate'` — every duration `<= durCelebrate`; past 240ms this direction reads
  sluggish, and this is the ceiling E04 will be tempted to raise.
- `'curves match system.html'` — `easePop == Cubic(0.2, 1.5, 0.4, 1)`, `easeOut == Cubic(0.2, 0.8, 0.2, 1)`,
  `easeInOut == Cubic(0.6, 0, 0.3, 1)` against `--ease-pop|out|inout`.
- `'easePop overshoots past 1.0'` — sample `easePop.transform(t)` across `t` and assert
  `max > 1.0`, while `easeOut.transform(t)` and `easeInOut.transform(t)` stay within `[0, 1]`. This is
  the machine-checkable reason `easePop` is legal on transform and illegal on colour.
- `'resolve collapses to zero under disableAnimations'` — a widget test via `pumpApp(..., disableAnimations: true)`
  asserting `motion.resolve(context, motion.durMove) == Duration.zero`, and the mirror case asserting
  it returns the full 180ms when the flag is off. Reduced motion means stop, never "shorter".
- `'lerp snaps at the midpoint on purpose'` — `lerp(other, 0.49) == this`, `lerp(other, 0.5) == other`,
  `lerp(other, 1) == other`, `lerp(null, 0.5) == this`; the test name is the guard against a future
  reader "fixing" it into a per-field interpolation.
- `copyWith` field-count coverage over the 7 fields, and the `of()` present/absent pair.

**Implementation.** `lib/theme/sunburst_motion.dart`.
`Duration resolve(BuildContext context, Duration full) => MediaQuery.disableAnimationsOf(context) ? Duration.zero : full;`
— Sunburst Pop's binding of `design-system-structure`'s `resolveMotion`, reading the flag from
`MediaQuery` and never from app state (E04 folds the Settings row into `MediaQuery` at the composition
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

### T02.7 — `SunburstType`

**Goal.** Land the ten type steps over the four faces E01 already bundled.

**Ownership.** E01 T01.6 owns the assets, the `flutter: fonts:` block, both OFL texts,
`lib/theme/font_licences.dart` and the three tests that pin them. This task adds **no** `.ttf`, no
`OFL.txt` and no second `registerSunburst*` function — it names the faces and asserts they resolve.

**Tests first (TDD).**
- `test/theme/sunburst_type_test.dart`:
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
    literal of the expected step names** in the test, so a thirteenth step is a one-line, reviewed test
    edit rather than a silent addition. It is ten here; E03 T03.1 takes it to twelve, E07 T07.0 to
    eighteen and E08 T08.6 to nineteen, each amending this literal in the same commit with its reason.
    Do **not** hardcode `== 10` — see Risk 9.
  - `'only bundled families are named'` — every step's `fontFamily` is `Fredoka` or `Nunito`, matching
    the four (family, weight) pairs E01 declared in `pubspec.yaml`; a step naming a fifth face fails.
    `displayFallback == <String>['Nunito']` (DERIVED: the design names Baloo 2, which an offline app
    does not ship).
  - `'every family this scale names has a declared asset on disk'` — parse the `flutter: fonts:` block
    E01 wrote and assert each named family resolves to a file that exists. A missing `.ttf` silently
    falls back to Ahem and every golden after it is a lie; `check_font_bundling.sh` cannot see that.
  - `copyWith`/`lerp` field-count coverage and the `of()` present/absent pair.

**Implementation.**
- `lib/theme/sunburst_type.dart`: `static const String display = 'Fredoka'`, `bodyFace = 'Nunito'`,
  `displayFallback`, the ten `TextStyle` steps on the const instance, `copyWith`, `lerp` via
  `TextStyle.lerp`, asserting `of`.
- Nunito ExtraBold is bundled by E01 and no step here spends it — documented in this file, not silently
  dropped; `app.html` renders strings at 800 and E07 must not need a re-bundle.
- Nothing else. No asset, no `pubspec.yaml` edit, no licence registration.

**Files.** `lib/theme/sunburst_type.dart`, `test/theme/sunburst_type_test.dart`.

**Skills.** `sunburst-tokens`, `design-system-structure` (+ `references/typography-and-fonts.md`),
`dartdoc-conventions`.

**Screenshot check.** n/a (no visual surface). Type **role** is checked against the PNGs in E03/E07
when the first text renders; this task only pins the numbers.

**Done when.**
- `.claude/skills/design-system-structure/scripts/check_font_bundling.sh lib` is clean.
- Ten steps, and the count test reads the source file rather than a literal `10`.
- `grep -rn 'fontSize:\|fontFamily:' lib/ | grep -v 'lib/theme/'` is empty.
- `git diff --stat -- assets/ pubspec.yaml` is empty for this task — E01 owns both.

**Commits.**
1. `test(theme): ten type steps, tracking maths and tabular-figure specs (red)`
2. `feat(theme): SunburstType — the ten steps of the Sunburst Pop scale`

---

### T02.8 — `GameAccent` and `GameColourRole`

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
- `'GameColourRole has both cases'` — `decorative` and `mechanic`, with the doc stating the invariant
  E08/E09 must keep: `mechanic` ⇒ `BoardBackground.surfaceSunk`, `decorative` ⇒ `BoardBackground.gameAccent`.

**Implementation.** `lib/theme/game_accent.dart`:
`enum GameAccent { stroopCoral, schulteTurquoise }`, `enum GameColourRole { decorative, mechanic }`, and
`extension GameAccentTokens on GameAccent` with `base`, `deep` and `onAccent` as exhaustive `switch`
expressions with no `default:` — so adding a third game is a compile error until its slot pair exists.
The file lives in `lib/theme/` precisely so `lib/games/**` may import it while
`sunburst_primitives.dart` stays unreachable.

**Files.** `lib/theme/game_accent.dart`, `test/theme/game_accent_test.dart`.

**Skills.** `sunburst-game-surfaces` (+ `references/accent-contract.md`), `sunburst-tokens`,
`dart3-idioms-and-coding-standards`, `dartdoc-conventions`.

**Screenshot check.** n/a (no visual surface — the coral and turquoise bands are compared in E07
against `02-game-detail.png`, `04-stroop-rush.png` and `05-schulte-grid.png`).

**Done when.**
- Two enum cases, three extension methods, zero `default:` clauses.
- `check_game_palette.sh lib` is clean.
- The N-Back omission is recorded in the PR body as an open design request, not as an oversight.

**Commits.**
1. `test(theme): GameAccent resolution and tier-separation specs (red)`
2. `feat(theme): GameAccent and GameColourRole with token resolution`

---

### T02.9 — `buildSunburstTheme()`

**Goal.** Fold the four extensions and a hand-authored `ColorScheme` into the one `ThemeData` the app
will ever have, with Material's own soft elevation and ink splash switched off everywhere.

**Tests first (TDD).** `test/theme/sunburst_theme_test.dart`:
- `'all four extensions are attached and resolvable'` — `pumpApp` and assert
  `SunburstColors.of(ctx)`, `SunburstShape.of(ctx)`, `SunburstMotion.of(ctx)` and `SunburstType.of(ctx)`
  each return the corresponding `sunburstPop` const instance.
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
button themes stay at their defaults on purpose — MindForge's buttons are E03's custom widgets, and a
themed `ElevatedButton` would be an invitation to use one.

**Spend it in the same task.** Edit the `MaterialApp` E01 built in `lib/app.dart` to pass
`theme: buildSunburstTheme()` and `themeAnimationStyle: AnimationStyle.noAnimation` — Sunburst Pop has
one theme, so an implicit cross-fade between `ThemeData`s is 200ms of animation over a change that never
happens. A `ThemeData` that no call site reads is not a theme layer, it is a library: without this edit
`flutter run` renders unthemed Material through all of E03 and E04, and the first person to notice is
whoever compares a golden. Still **no `darkTheme:`**, no `themeMode:` — `test/policy/light_only_test.dart`
is the gate. E07 T07.4 changes only `MaterialApp` → `MaterialApp.router`; it does not re-wire the theme.

Also give `test/support/harness.dart`'s `pumpApp` its default in this commit:
`{ThemeData? theme}` resolving to `buildSunburstTheme()`. T02.1 made the parameter required precisely so
this default could not be forward-referenced; from here on E03/E07 call sites omit it.

**Files.** `lib/theme/sunburst_theme.dart`, `lib/app.dart` (edit), `test/support/harness.dart` (edit),
`test/theme/sunburst_theme_test.dart`, `test/policy/light_only_test.dart`.

**Skills.** `sunburst-tokens`, `design-system-structure`, `ci-pipeline-and-gates`,
`widget-golden-and-a11y-testing`, `dartdoc-conventions`.

**Screenshot check.** n/a (no screen is composed yet). The theme's ground truth against the PNGs is
T02.10; the first structural comparison is E03's component gallery.

**Done when.**
- `buildSunburstTheme()` is the only `ThemeData` constructor in `lib/`.
- `lib/app.dart` passes it, plus `themeAnimationStyle: AnimationStyle.noAnimation`.
- `flutter run -d macos` shows a cream window, not a white one.
- `pumpApp`'s `theme` parameter now has a default and every T02.2–T02.8 call site still compiles.
- `test/policy/light_only_test.dart` is green and fails if `darkTheme:` is added anywhere in `lib/`.
- `flutter analyze --fatal-infos --fatal-warnings` clean.

**Commits.**
1. `test(theme): extension wiring, ColorScheme role and component-theme specs (red)`
2. `feat(theme): buildSunburstTheme with a hand-authored ColorScheme`
3. `feat(app): paint MindForgeApp with the Sunburst theme and no theme animation`
4. `test(policy): light-theme-only grep gate`

---

### T02.10 — Reference-pixel verification and gate proof

**Goal.** Close the loop between the shipped tokens, `system.html` and the eight rendered PNGs — and
prove the two token gates fail on a bad value instead of passing vacuously.

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
3. Confirm E01's workflow runs both scripts, and that they now report a scanned target rather than
   `note: 'lib' not found`.

**Files.** `test/theme/reference_pixel_test.dart`. (Plus a `.github/workflows/ci.yml` fix only if step
3 shows the gate loop skips these two scripts.)

**Skills.** `sunburst-tokens`, `ci-pipeline-and-gates`, `widget-golden-and-a11y-testing`,
`testing-strategy`.

**Screenshot check.** All eight PNGs in `design/sunburst-pop/screens/`. This task **is** the sampled-hex
step (step 5) of the comparison order in `screens/README.md`; structure, spacing rhythm, surface
construction and type role are checked by the epics that build the surfaces (E03, E07, E08, E09), because
there is nothing to lay out yet.

**Done when.**
- At least nine sampled pixels across all eight files match their slot exactly.
- Each of the three gate-proof steps was run and its result recorded in the PR body.
- The CI run on the PR shows both token scripts scanning `lib/` and passing.

**Commits.**
1. `test(theme): sample reference PNG pixels against the shipped slots`
2. `docs(epic): record the gate-proof results in the PR body` *(only if a workflow fix is needed;
   otherwise this task ships one commit)*

## Gates that must pass

From the repository root, with the branch checked out:

```bash
flutter pub get
flutter gen-l10n
dart format --output=none --set-exit-if-changed .
flutter analyze --fatal-infos --fatal-warnings
flutter test --test-randomize-ordering-seed random

# every skill gate, through the one runner E01 T01.8 built
bash tool/skill_gates.sh

# Sunburst design gates — the two named in this epic's scope go green here first
.claude/skills/sunburst-tokens/scripts/check_raw_values.sh                lib
.claude/skills/sunburst-tokens/scripts/check_palette_contrast.sh \
  lib/theme/sunburst_colors.dart lib/theme/sunburst_primitives.dart
.claude/skills/sunburst-components/scripts/check_component_hygiene.sh     lib
.claude/skills/sunburst-shell-screens/scripts/check_shell_boundaries.sh   lib
.claude/skills/sunburst-game-surfaces/scripts/check_game_palette.sh       lib
.claude/skills/sunburst-motion-and-haptics/scripts/check_motion_tokens.sh lib

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
2. **The fonts are E01's, not this epic's.** E01 T01.6 downloads, commits, declares and licenses the
   four faces; this epic only names them. If they are missing when T02.7 starts, that is an E01 gap:
   stop and fix E01, do not bundle them here. `test/theme/sunburst_type_test.dart` asserts every named
   family resolves to a declared asset, so the gap fails loudly instead of falling back to Ahem.
3. **`sunburst_colors.dart` will exceed the ~300-line file limit** (34 fields x constructor + `copyWith`
   + `lerp` + `_props` + 26 `@contrast` lines). This is a cohesive overrun of
   `dart3-idioms-and-coding-standards` rule 11 and must be justified in the PR body, not silenced.
   Splitting the const instance away from the class would break `check_palette_contrast.sh`, which
   resolves slots to primitives by matching both files line by line.
4. **`check_palette_contrast.sh` constrains formatting.** It matches `slot: _P.primitive,` one per
   line. If `dart format` ever collapses that block, the gate goes quiet rather than red. T02.4 must
   confirm the formatted output still yields 26 resolved pairs — a passing gate over zero pairs is the
   failure mode to watch for (the script fails on *no* declarations, but not on a partial resolution
   after a reformat).
5. **`title`/`button` weight: §04 (w600) vs §12 (w700).** `references/shape-and-type.md` calls §04 the
   winner and flags this as the one open question for the designer. This epic ships w600 and pins it
   with a named test. **Ask the designer**; do not change a call site in E03/E07 to 700 without
   changing `system.html` §04 first.
6. **N-Back has no accent.** `gameNBack`/`gameNBackDeep` are absent from `system.html` and grape has no
   measured deep partner. `GameAccent` ships two cases. **Ask the designer** for a grape-deep primitive
   before a third game is scheduled; the exhaustive `switch` makes this a compile error rather than a
   surprise.
7. **Reference-pixel coordinates are brittle.** Re-running `capture-screens.sh` after an `app.html`
   edit can move a sampled region. Mitigations: the 5x5 uniformity assertion, a failure message that
   prints file + coordinate + sampled hex, and sampling large flat areas rather than small features.
   If a later epic edits `app.html`, re-deriving these coordinates is part of that change.
8. **Nunito ExtraBold ships and no step spends it.** Deliberate: `app.html` renders several strings at
   800 and E07 must not need a re-bundle. It does **not** license an eleventh step invented at a call
   site — a genuine need earns a name in `system.html` §04 first.
9. **The ten-step rule is amended three times downstream, on purpose.** E03 T03.1 adds `buttonLarge`
   and `chip` (both rendered specimens: `.btn--lg{font-size:21px}`, `.chip{14}`); E07 T07.0 adds the six
   shell steps `titleBar`, `greeting`, `sectionLabel`, `heroTitle`, `countdownNumeral`, `statValue`;
   E08 T08.6 adds `stimulusCompact`. Nineteen, not ten, is the shipped number. **Decision:** the count
   test names its expected steps in a list literal and derives the count from the source file, so each
   addition is a reviewed one-line test edit carrying its `DERIVED` evidence — never a silent
   thirteenth step, and never a hardcoded `== 10` that four epics have to fight. Update
   `sunburst-tokens/references/shape-and-type.md` alongside the E03 additions so the two stop
   disagreeing. **Ask the repo owner** whether rule 10's wording should be amended rather than the
   exceptions documented.

## Definition of done

- [ ] `lib/theme/` holds exactly eight files: `font_licences.dart` (shipped by E01, untouched here),
      `sunburst_primitives.dart`, `sunburst_colors.dart`, `sunburst_shape.dart`, `sunburst_motion.dart`,
      `sunburst_type.dart`, `game_accent.dart`, `sunburst_theme.dart`. There is no `sunburst_fonts.dart`
      — a second licence registration beside E01's is the duplication this list exists to prevent.
- [ ] Every hex in `_P` matches `design/sunburst-pop/system.html`; anything derived rather than
      transcribed is marked `DERIVED` with its reason (`borderDisabled`, `displayFallback`).
- [ ] No file outside the colour library names `_P`; no chrome slot binds to a `play*`/`cb*` slot.
- [ ] Every new slot appears in the constructor, `copyWith`, `lerp`, `_props`, the `const sunburstPop`
      instance and — where it sits under text or is a UI boundary — a `// @contrast` line.
- [ ] Every `BoxShadow` in the app comes from `SunburstShape.shadow()` with `blurRadius: 0` and
      `spreadRadius: 0`; there is no `e0` field.
- [ ] Exactly one `ThemeData`, and `lib/app.dart` actually passes it with
      `themeAnimationStyle: AnimationStyle.noAnimation`; no `darkTheme`, no `themeMode`, no
      `Brightness.dark`, proven by `test/policy/light_only_test.dart`.
- [ ] No asset and no `pubspec.yaml` line changed — E01 owns the fonts; `check_font_bundling.sh` green.
- [ ] `check_raw_values.sh` and `check_palette_contrast.sh` both green **over real code**, and both
      shown to fail on a deliberately corrupted value (recorded in the PR body).
- [ ] `dart format --set-exit-if-changed .`, `flutter analyze --fatal-infos --fatal-warnings` and
      `flutter test` all green; every gate script in the list above exits 0.
- [ ] Reference-pixel test green against all eight PNGs in `design/sunburst-pop/screens/`.
- [ ] `/simplify` run and its findings addressed.
- [ ] `/code-review` run and its findings addressed.
- [ ] PR opened against `main` from `epic/02-design-tokens-and-theme`, body stating what changed, why,
      how it was verified, which screens were sampled, the three open designer questions (button weight,
      grape-deep for N-Back, the `part`/`part of` decision) and what was deliberately left out
      (no components, no screens, no `MaterialApp` — E03 and E07).
- [ ] CI green on the PR (the pipeline E01 created).
- [ ] Merged preserving the granular commits, branch deleted, back on `main`, `git pull` done.
