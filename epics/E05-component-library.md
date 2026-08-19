# E05 · Component library

| | |
|---|---|
| **Branch** | `epic/05-component-library` |
| **Depends on** | E03, E04 |
| **Unblocks** | E06, E08 |
| **Status** | Not started |

## The epic

Build `lib/ui/components/` and `lib/ui/glyphs/`: the fourteen-class Sunburst Pop catalog, all of it
composed from one primitive, plus the drawn icon set — and build all of it **once**, correct in four
locales and two writing directions, because E04 landed first precisely so no component is written
twice. `PopSurface` comes first — fill, a 3px `colors.border` edge, one hard offset shadow at
`blurRadius`/`spreadRadius` 0, the press translate toward that shadow while a 48px hit area holds
still, the disabled resolution that stays inside the palette, and a 4px `focusRing` stroke outside a
3px `surface` gap. Then the catalog on top of it: `PopButton`, `PopIconButton`, `PopChip`, `PopCard`,
`GameCard`, `DifficultySegmented`, `HudPill`, `TimerRing`, `PopProgressBar`, `PopGridTile`,
`PopToggle`, `PopBadge`, `PopSheet`, `PopBottomNav`. `lib/ui/glyphs/` supplies the seventeen inline
stroke glyphs at the design's two weights — 2.6 at 22pt, 3.0 below 22pt — painted on canvas: no emoji,
no icon font, no `IconData`.

Localization changes what "done" means for every one of them:

- **Geometry is directional only.** `EdgeInsetsDirectional`, `AlignmentDirectional`,
  `PositionedDirectional`, `BorderRadiusDirectional`, `TextAlign.start/end`. `EdgeInsets.only(left:)`,
  `Alignment.centerLeft` and `TextAlign.left` are gate failures, not review notes —
  `check_i18n_bans.sh lib` runs over real component code here for the first time.
- **The golden matrix gains a locale axis.** Every component is goldened in `en` (LTR) and `fa` (RTL);
  every text-bearing component adds `de`, the length stress case. `ckb` gets the contact sheet and the
  glyph-coverage lane.
- **Numeral-bearing components are tested with Eastern Arabic digits.** `HudPill`, `PopBadge`,
  `PopGridTile`, `TimerRing` and `PopProgressBar` are handed `۱۸٫۶` and `۲۵`, not `18.6` and `25`.
  Glyph widths, line boxes and the tabular-figure assumption all change; the tile that Schulte draws
  its numbers on is 64 logical px and the digits inside it are a different script.
- **What mirrors and what does not is an explicit, tested table.** The back chevron, the disclosure
  chevron, the sound glyph, the progress fill, the segmented order and the nav order mirror. The
  **hard offset shadow does not** — it is a light-source constant, not a reading-direction property —
  and neither does the timer sweep, which is a clock. Both non-mirrors are asserted, because both are
  the first thing a reviewer will query.
- **Nothing shrinks to fit.** No `FittedBox`, no `TextOverflow.ellipsis` on a value, no clamped
  `TextScaler`. A label that stops fitting in German or Persian takes a smaller BASE style from
  `lib/theme/` or a different layout — and this epic names the three places that actually happens.

Verification is where this epic earns its keep. Every component ships golden tests per state
(rest / pressed / disabled / selected / focused) through one shared harness, an a11y test per
interactive component (tap target ≥ 48 measured with `getSize`, `Semantics` role and label asserted
with `isSemantics`), an overflow-and-fit matrix at locale × text scale × width × bold, and a greyscale
golden of the full state matrix proving no state is carried by hue alone. The epic ends with
`check_component_hygiene.sh` and `check_i18n_bans.sh` green over real code rather than over an empty
tree.

**iOS is the only shipping target.** Android is deferred and nothing here is written for parity with
it. The one device geometry that matters is 390×844 at DPR 2 — `Device.reference390`, the geometry
`capture-screens.sh` rendered the reference PNGs at, and the geometry of the canonical simulator
`MindForge iPhone 14` (`C13DDC02-375D-4E1B-8F81-44EB407D09A4`, iOS 18.6). No iPhone 16-class simulator
matches it (iPhone 16 is 393×852, 16 Pro is 402×874), so any comparison run on one of those is not
honest.

## Why we need it

E08, E09 and E10 all assume a catalog exists. Without it every screen invents its own `BoxDecoration`
with a border and a shadow, and the Sunburst contract — one fill, one 3px ink edge, one hard shadow,
one press law — stops being true within a sprint. `sunburst-components` rule 1 and rule 11 exist
precisely because thirteen hand-rolled copies of one decoration drift, and the fourteenth reads as
generic Material.

It also has to happen **after** E04 and not before. A component library written against a single LTR
locale is written twice: once with `EdgeInsets.only(left:)` and a fixed 66px toggle track, and again
six weeks later when the Persian build shows the toggle word clipped and the back chevron pointing the
wrong way. Retrofitting direction into fourteen components and seventeen glyphs is not a find-replace —
it changes which geometry is authored, which strings a component is allowed to compose, and what its
goldens are blessed against.

Concretely, without E05:

- `check_component_hygiene.sh` and `check_i18n_bans.sh` pass today only because `lib/` does not exist.
  Neither has ever run over a single line of real code, so neither is yet evidence of anything.
- There is no press implementation, so E06 would have nothing to time and every screen in E08 would
  grow its own `GestureDetector` + `Transform` — the exact pairing that moves the hit area under the
  finger and eats taps.
- There is no glyph set, so the first screen that needs a back arrow reaches for `Icons.arrow_back` —
  which is both a Material icon font on a hand-drawn cream surface (visible from across the room) and
  a `check_i18n_bans.sh` failure, because it does not mirror.
- There is no component harness, so a11y, text-scale, locale and greyscale checks would be re-invented
  per screen, unevenly, and the never-colour-alone rule would go unverified.

## Current state

Verified by `ls` and `git log` at the time of writing:

- **No Flutter app.** No `pubspec.yaml`, no `lib/`, no `test/`, no `.github/`. Five commits on `main`
  (`ddcb79d` is the head); the working tree holds `CLAUDE.md`, `design/`, `epics/`,
  `50-apps-challenge-slides.html` and `.claude/`.
- `.claude/skills/` — 45 skills. The ones this epic lives inside are `sunburst-components`
  (SKILL.md + `references/component-catalog.md`, `references/surface-and-press.md`,
  `references/states-and-affordance.md` + `templates/component_template.dart` +
  `examples/pop_surface.dart`, `examples/pop_button.dart`, `examples/game_card.dart` +
  `scripts/check_component_hygiene.sh`), `widget-golden-and-a11y-testing`
  (`examples/harness.dart`, `examples/overflow_matrix_test.dart`, `examples/a11y_test.dart`,
  `references/golden-two-lanes.md`) and `i18n-rtl-l10n` (`references/rtl-and-bidi.md`,
  `references/numerals-and-calendars.md`, `scripts/check_i18n_bans.sh`,
  `scripts/check_arb_parity.sh`).
- `design/sunburst-pop/system.html` — the authority for this epic. §07 Elevation, §08 Iconography
  (three subsections: *22px · stroke 2.6*, *18–20px · stroke 3*, *Badge glyphs*), §10 Components
  (fourteen named `<h3 class="sub">` gallery entries), §11 Accessibility.
- `design/sunburst-pop/app.html` — component geometry as actually shipped; wins over §10 on geometry.
  Read for the four settings-row glyphs and the 16px disclosure chevron, which §08 does not show.
- `design/sunburst-pop/screens/*.png` — the eight LTR screen targets, and (from E04)
  `design/sunburst-pop/screens/rtl/*.png`, the Persian `dir="rtl"` counterparts. **This epic compares
  against neither**; both sets are E08's targets. See the screenshot rule under *What we will achieve*.
- `.claude/skills/sunburst-tokens/examples/sunburst_theme.dart` — the worked theme E03 transcribes.
  Checked field by field: it ships `stripePitch` 9 and `stripeAngle` 45, and it does **not** ship
  `eChip`, `borderWidthNested`, `dashOn`, `dashOff`, `type.buttonLarge` or `type.chip`. Those are the
  derived slots `sunburst-components` requests, and this epic must add them (T05.1).

Toolchain, verified on this machine and not to be re-derived: Flutter **3.44.6** stable, Dart
**3.12.2**, Xcode **26.6** (17F113), CocoaPods **1.15.2**; simulator runtimes iOS 18.0, 18.6, 26.5;
canonical device `MindForge iPhone 14` / `C13DDC02-375D-4E1B-8F81-44EB407D09A4` / iOS 18.6 /
390×844 logical.

**Assumed present from E03 (design tokens), asserted by T05.1's first test:**
`lib/theme/sunburst_colors.dart`, `sunburst_shape.dart`, `sunburst_motion.dart`, `sunburst_type.dart`,
`sunburst_primitives.dart` and `buildSunburstTheme()`, each with an asserting `of(context)`;
`SunburstScript`, `scriptOf`, `forScript`, `arabicLineFactor` and the per-script `fontFamilyFallback`
cascade on every display and body step; **the bundled faces themselves** — Fredoka and Nunito from E01,
Vazirmatn and whichever display face T03.7's cmap measurement selected — with every OFL text registered
through the one `registerSunburstFontLicences()`; plus the test support E03 owns:
`test/support/harness.dart` with `Device`, `Device.all` (four presets at DPR 2) and `pumpApp`,
`test/support/font_tables.dart`, **`test/support/load_app_fonts.dart`** and **`dart_test.yaml`'s
`golden` tag** (E03 T03.7 created both; T03.9's `ckb` specimen is the repo's first golden).

**Assumed present from E04 (localization and RTL), asserted by T05.2's first test:**
`l10n.yaml` with `nullable-getter: false`, the four ARBs `lib/l10n/app_en.arb`, `app_de.arb`,
`app_fa.arb`, `app_ckb.arb`, the generated `AppLocalizations`, `lib/l10n/supported_locales.dart`
(derived from E02's `SupportedLocale`), the custom `ckb` `LocalizationsDelegate` that keeps a switch to
Sorani from throwing, **`LocaleNumbers`** (`of(context)` / `forLocale(locale)` / `localeNumbersProvider`),
**`AsciiNumerals.normalize`**, the one FSI/PDI helper **`Bidi`** (`Bidi.isolateLtr` / `Bidi.isolateRtl` /
`isolate` / `strip`), `appLocalizationsProvider`, the persisted locale override, and the test harness
`LocaleCase` / `LocaleCase.all` / `pumpLocalized`.

**Import the names above; do not invent parallel ones.** A second formatter, a second supported-locale
list, a second isolate helper or a second locale list in `test/support/` is a defect this epic must not
commit — the same rule that already forbids forking `test/support/harness.dart`. In particular there is
no `LocaleNumbers`, no `localeNumbersProvider`, no free `AsciiNumerals.normalize`, no `supportedLocales` and
no `LocaleCase.all`: if a draft of this epic reaches for one of those, it is naming a symbol the
repository does not contain.

Without the bundled faces `loadAppFonts()` silently falls back to Ahem and every real-font golden in
this epic is a lie, and every Persian and Sorani golden is a field of identical boxes that will never
fail (see Risk 9).

## What we will achieve

**The screenshot rule, as it applies to this epic.** The comparison target is the component gallery in
`design/sunburst-pop/system.html`, rendered in a browser — **not** the eight PNGs in
`design/sunburst-pop/screens/` and **not** their RTL counterparts in
`design/sunburst-pop/screens/rtl/`. Those are whole screens; they are E08's targets and no task here
compares against them. `capture-screens.sh` (extended by E04 to emit the RTL set) renders `app.html`'s
eight `<figure>` elements only and produces no gallery image, in either direction, so the gallery
comparison is manual: open `system.html`, screenshot the named `<h3>` subsection, and put the
component's real-font golden beside it. The RTL gallery comparison is the same manual step with
`dir="rtl" lang="fa"` set on `<html>` in devtools — the mockup's own CSS is written in logical
properties for the parts that matter, and where it is not, that is a finding for the PR body, not a
silent divergence. Compare in the project's fixed order, every time:
**structure → spacing rhythm → surface construction (3px ink edge, correct hard-shadow step, blur 0) →
type role → sampled hex.** A difference is an implementation defect. If the reference is genuinely
wrong, the change goes into `system.html` (and, where geometry is at stake, `app.html` +
`./capture-screens.sh`) and is committed as a deliberate design change with the token values updated to
match and `check_palette_contrast.sh` re-run — never a silent divergence. Golden images and browser
screenshots capture **end states only**: the press travel, the release, the 120ms `durTap` tween and
every haptic are asserted by widget tests here and re-verified on the simulator in E06 and E11.

**The golden lane policy, stated once.** Goldens live under `test/ui/components/goldens/<locale>/` and
`test/ui/glyphs/goldens/<locale>/`.

| Lane | Locales | What it proves |
|---|---|---|
| Per-component state matrix | `en`, `fa` | Construction and mirroring in both directions. |
| Per-component rest state | `de` | Text expansion at the base scale. |
| Greyscale state matrix | `en` only | State collision is hue-dependent, not locale-dependent; running it four times proves nothing new. |
| Catalog contact sheet | `en`, `de`, `fa`, `ckb` | The four images a human actually looks at, including Sorani glyph coverage. |
| Glyph sheet | `en`, `fa` | The mirror table, rendered. |

Every lane calls `loadAppFonts()`; the Persian and Sorani lanes are meaningless without it.

**The numeral seam, stated once.** **No component formats a number.** Components receive
already-localized `String`s — `'۱٬۴۸۰'`, `'۱۸٫۶ ثانیه'`, `'۲۵'` — from the shell (E08) which owns
`LocaleNumbers.of(locale)`. A component's contract is that it renders whatever digits arrive without
tofu, without reflow and without clipping. That is why `NumberFormat` does not appear in `lib/ui/`
(`widget-composition` rule 5 forbids formatting in `build()` anyway) and why every numeral test in this
epic is a *rendering* test, not a formatting test. Seeded generation and golden vectors are unaffected:
nothing here consumes a seed.

A reader can tell this epic is done by running the checks below.

- `lib/ui/components/` holds fifteen files (fourteen catalog classes plus `dashed_ink_border.dart`)
  and `lib/ui/glyphs/` holds the seventeen-glyph set. No other directory in `lib/` contains a
  `BoxDecoration` that carries both a border and a shadow.
- `.claude/skills/sunburst-components/scripts/check_component_hygiene.sh lib` prints
  `OK: hard shadows only, ink borders only, no Material elevation, no raw press timing.` **over real
  code** — the first time that sentence means anything.
- `.claude/skills/i18n-rtl-l10n/scripts/check_i18n_bans.sh lib` prints `i18n bans: PASS` over real
  code — likewise the first time.
- `flutter test` is green, including: one golden per component per applicable state in `en` and `fa`,
  a `de` rest golden per text-bearing component, one greyscale golden of each component's full state
  matrix, one a11y test per interactive component, the mirroring table test, and the
  overflow-and-fit matrix (4 locales × 4 widths × 3 text scales × 2 bold settings, one `testWidgets`
  per tuple).
- `flutter test --tags golden` regenerates nothing: the committed goldens match.
- Opening `design/sunburst-pop/system.html` §10 beside
  `test/ui/components/goldens/en/catalog_contact_sheet.png` shows the same fourteen components in the
  same construction: 3px ink edge, hard shadow at the right step, no blur, correct radius, correct type
  role. Opening the same page with `dir="rtl"` beside `goldens/fa/catalog_contact_sheet.png` shows the
  same fourteen mirrored the same way, with the shadow still down-and-right.
- `tool/gallery_main.dart` runs on `C13DDC02-375D-4E1B-8F81-44EB407D09A4` and its locale switcher shows
  Arabic-script letter joining rendered by iOS itself — the one thing the host-side golden lane cannot
  prove.
- A human can grep and find zero `Icons.`, zero `IconData`, zero emoji, zero
  `ElevatedButton`/`FilledButton`/`TextButton`/`Card(`/`Material(elevation:` under `lib/ui/`, and zero
  physical-side geometry anywhere in `lib/`.
- The PR is merged to `main`, CI (created in E01) green on it.

## Skills to load

| Skill | Why, for this epic |
|---|---|
| `flutter-conventions-index` | The front door and the routing table; open first for anything the table below does not obviously cover. |
| `sunburst-components` | The contract this epic *is*: `PopSurface`, `PopElevation`, `kPopMinTarget`, the press chrome, the fourteen-class catalog, the five derived slots, the state matrix and the ≥48px floor. Read all three `references/` files and the three `examples/`. |
| `i18n-rtl-l10n` | Rule 5 (directional-only geometry) is now a per-component definition-of-done and a gate. `references/rtl-and-bidi.md` supplies the allow/ban table, the mirror-the-directional-never-the-absolute rule the glyph table in T05.4 is built from, the manual `Matrix4.rotationY` flip for glyphs `Icons.adaptive` cannot cover, and the "do not auto-mirror a painter" rule that keeps the shadow and the timer sweep still. `references/numerals-and-calendars.md` supplies the Persian-vs-Arabic digit-block distinction the numeral goldens assert. |
| `sunburst-tokens` | Every value a component reads is a slot on `SunburstColors`/`SunburstShape`/`SunburstMotion`/`SunburstType`; T05.1 adds slots by its four-places-plus-the-gate procedure (`references/adding-a-token.md`). Rule 10's `FontFeature.tabularFigures()` on `numericHud`/`scoreHero` is the assumption T05.7 has to re-verify under Vazirmatn. |
| `sunburst-motion-and-haptics` | Owns `PressPhysics`/`PressGeometry`/`PressBuilder` — the one press controller `PopSurface` composes — the `Moment` catalog, and the reduce-motion split (transform dropped, pressed shadow kept). Its `examples/press_physics.dart` is the seam T05.3 builds. |
| `sunburst-shell-screens` | Declares that `SunburstGlyph` in `lib/ui/glyphs/` is shell-owned and lists the catalog E08 will compose; T05.4 must match the names its `examples/home_screen.dart` and `examples/play_scaffold.dart` already call. |
| `widget-golden-and-a11y-testing` | The harness rules T05.2 implements: pin `physicalSize = logical × dpr`, `MediaQuery` above `MaterialApp` built from `.copyWith`, one `testWidgets` per tuple, `isSemantics`, explicit `getSize` tap-target loops, two golden lanes with `loadAppFonts`, never suppress overflow. `references/golden-two-lanes.md` also fixes the RTL-golden shape: derive direction from the locale, never from the LTR default. |
| `accessibility-as-code` | Authoring side of the same floor: `Semantics(button:, label:)` on every interactive node, `ExcludeSemantics` on decorative art, never colour alone, never `FittedBox`/`ellipsis`/clamped `TextScaler` to make a label fit, honour `boldText`. Rule 5 is what forbids "solve German by shrinking". |
| `widget-composition` | Const widget classes never `Widget _buildX()`, one responsibility per widget, `StatelessWidget` by default, dispose every controller, rule 5 (no `NumberFormat` in `build()`) is the numeral seam, rule 12 is directional geometry, `build()` ≤ 80 lines / nesting ≤ 5. |
| `custom-canvas-and-gestures` | Four painters live here — the focus ring, `DashedInkBorder`, `TimerRing`'s sweep, `PopProgressBar`'s stripe — plus every glyph. Enforces the View/Painter/Scene split, `shouldRepaint` as one value compare, zero allocation in `paint()`, `ExcludeSemantics` over drawn pixels, and rule 11: geometry is direction-agnostic, only chrome mirrors — which is exactly why the glyph painter stays LTR and the *widget* applies the flip. |
| `dart3-idioms-and-coding-standards` | `enum` vs `sealed` for the variant sets (`PopElevation`, `PopButtonVariant`, `PopGridTileState`, `HudTone`, `PopBadgeVariant`), exhaustive `switch` with no `default:` — which is what makes the glyph mirror table impossible to extend without a decision — `@immutable` scene types, and the complexity limits every other skill cites. |
| `naming-conventions` | File = primary declaration, `lowercase_with_underscores` files, booleans as `is`/`has`/`can`, no `get`-prefixed accessors, grouped-and-sorted imports. It is also why `chevronRight` is renamed: a name carrying a physical side is wrong in half the shipped locales. |
| `dartdoc-conventions` | `lib/ui/components/` is a public surface consumed by three later epics: `///` on every public class, constructor and field, never a restatement of the name, `[bracket]` cross-links. `public_member_api_docs` is an analyzer error. |
| `testing-strategy` | Fakes over mocks for the `FeedbackService` seam T05.3 introduces, and the doctrine that anything expressible as `f(input) -> output` (press geometry, glyph stroke selection, the mirror predicate) is a unit test, not a `pumpWidget`. |
| `adaptive-layout` | The width axis of the matrix and the sizes that genuinely adapt: the grid tile is 64 and drops to 60 at the smallest width; the toggle track and the nav item now size from their content because a German or Persian word does not fit a number transcribed from an English mockup. Every one of those decisions is made from constraints via `LayoutBuilder`, never from a device check. |

## Tasks

### T05.1 — Derived and transcribed token slots the catalog needs
**Goal.** Add the six slots `sunburst-components` requests plus the two glyph stroke widths to
`lib/theme/`, so no component ever types a literal — and assert that E03's per-locale font cascade
actually reaches the two new display steps.

**Tests first (TDD).** In `test/theme/sunburst_shape_test.dart` and `test/theme/sunburst_type_test.dart`:
- `'eChip is the half-step (2,2)'` — `SunburstShape.sunburstPop.eChip == const Offset(2, 2)`.
- `'nested border width is 2 and the primary edge is 3'` — asserts `borderWidthNested == 2` and
  `borderWidth == 3` together, so a future edit cannot collapse them.
- `'dash pitch is 9 on / 7 off'` — `dashOn == 9`, `dashOff == 7`.
- `'glyph strokes are 2.6 at nav size and 3.0 below it'` — `glyphStrokeNav == 2.6`,
  `glyphStrokeControl == 3`.
- `'copyWith replaces each new slot independently'` — one expectation per new field; catches the
  classic constructor-updated-lerp-forgotten rot.
- `'lerp interpolates every new slot'` — `lerp(a, b, 0.5)` on a shape whose new fields all differ,
  asserting each midpoint; a field missing from `lerp` returns `a`'s value and fails.
- `'buttonLarge is Fredoka 21/24 and chip is Fredoka 600 14/18'` — asserts `fontSize`, `height` and
  `fontWeight`, and that both use `SunburstType.display` with `displayFallback`.
- `'buttonLarge and chip carry the Arabic-script fallback'` — asserts `fontFamilyFallback` on both new
  steps is non-empty and contains the family **E03 T03.7** bundled for `fa`/`ckb`. Fredoka covers no Arabic
  script at all, so a display step without a fallback renders a chip label as tofu in half the shipped
  locales. This asserts E03/E04's cascade rather than redefining it; if it fails, the fix lands in
  `lib/theme/`, not here.
- `'the type scale ships exactly the steps its source file declares'` — E03's existing count test
  (`test/theme/sunburst_type_test.dart`, task **T03.8**), amended in **this** commit: its named list
  literal gains `buttonLarge` and `chip`, taking it from ten to twelve, and the count still derives
  from `DesignSource.dartFieldNames(typeFile, 'SunburstType')` rather than a hardcoded number. E08
  T08.0 takes it to eighteen and **E09 T09.5 (`buttonCompact`) and T09.7 (`stimulusCompact`)** take it
  to twenty, each amending the same literal the same way. An unreviewed extra step fails; a reviewed
  one is a one-line edit carrying its `DERIVED` evidence.

**Implementation.** Add to `SunburstShape`: `eChip` `Offset(2, 2)`, `borderWidthNested` `2`,
`dashOn` `9`, `dashOff` `7`, `glyphStrokeNav` `2.6`, `glyphStrokeControl` `3`. Add to `SunburstType`:
`buttonLarge` (Fredoka w600 21 / 24) and `chip` (Fredoka w600 14 / 18). Each touches five places per
`sunburst-tokens` rule 12: field, constructor, `copyWith`, `lerp`, the `const sunburstPop` instance —
plus the step-name literal in E03's count test, which is the sixth place and the one that gets forgotten.
**`HudTone` is imported here, not declared.** `enum HudTone { neutral, highlight, alarm }` lives in
**`lib/core/hud_tone.dart`** and is **E02 T02.2's** — not beside `HudPill`, and not in
`lib/features/play/domain/`. Both sides need it: this epic's `HudPill` renders a tone and E07's
`GameHud`/`HudSlot` carries one, and under the downward-only DAG `lib/features/` may import `lib/ui/`
but `lib/ui/` may never import `lib/features/`, so `lib/core/` is the only layer both can reach. It is
declared in E02 rather than here because **E07's header names E02, E03 and E04 and not E05** — putting
it in this epic would make E07 import from an epic it does not depend on. Declaring it twice would
produce two enums with one name that never unify (see Risk 4). If it is missing when this branch opens,
that is an E02 gap and it is fixed there.
Mark the first four shape slots and both type steps `// DERIVED` with the evidence from
`sunburst-components` SKILL.md's derived table; mark `glyphStrokeNav`/`glyphStrokeControl` as
transcribed from `system.html` §08 (`stroke-width="2.6"` × 40 sites, `stroke-width="3"` × 14 sites in
`app.html`, including the 16px disclosure chevron in the settings rows — the case that makes the
resolver's rule `< 22 → 3.0`, not `18–20 → 3.0`). Add a `// @contrast textPrimary accent 4.5` line
covering the chip label.

**Files.** `lib/theme/sunburst_shape.dart`, `lib/theme/sunburst_type.dart`,
`test/theme/sunburst_shape_test.dart`, `test/theme/sunburst_type_test.dart`. **Not**
`lib/core/hud_tone.dart` — that is E02's.

**Skills.** `sunburst-tokens`, `sunburst-components`, `dart3-idioms-and-coding-standards`,
`dartdoc-conventions`, `i18n-rtl-l10n`.

**Screenshot check.** n/a (no visual surface).

**Done when.**
- [ ] Both test files green; each new slot has a `copyWith` and a `lerp` expectation.
- [ ] `check_raw_values.sh lib` and `check_palette_contrast.sh lib/theme/sunburst_colors.dart` green.
- [ ] Every new slot carries `DERIVED` + evidence, or a `system.html` §-reference.
- [ ] The two new display steps resolve a non-empty `fontFamilyFallback`.
- [ ] `flutter analyze --fatal-infos` clean, including `public_member_api_docs`.

**Commits.**
1. `test(theme): pin the six derived slots and two glyph strokes`
2. `feat(theme): add eChip, borderWidthNested, dash pitch and glyph strokes to SunburstShape`
3. `feat(theme): add buttonLarge and chip steps to SunburstType`
4. `feat(core): add HudTone where both the UI and the engine can reach it`

---

### T05.2 — The locale-aware component test harness
**Goal.** One harness every component test imports: a themed pump driven by a **locale**, the four
width presets, the four-locale specimen strings, the greyscale filter, the state-matrix builder and a
recording feedback fake.

**Tests first (TDD).** The harness is test infrastructure, so its tests are meta-tests in
`test/support/component_harness_test.dart` — written before the harness:
- `'E04's l10n surface exists under the names this harness imports'` — the integration canary. Reads
  the supported-locale list, `LocaleNumbers` and the bidi isolate helper from `lib/l10n/` and asserts
  the locale list is exactly `en`, `de`, `fa`, `ckb` in that order. A rename in E04 fails here, loudly,
  instead of appearing as fourteen mystery compile errors later in the epic.
- `'pumpPopComponent installs all four Sunburst extensions'` — reads
  `SunburstColors/Shape/Motion/Type.of(context)` from inside the pumped subtree; each `of()` asserts,
  so a missing extension throws rather than silently falling back.
- `'pumping every supported locale does not throw'` — one expectation per locale, `ckb` included. This
  is the E05-side canary for E04's custom `ckb` delegate: a missing
  `GlobalMaterialLocalizations`/`GlobalCupertinoLocalizations` entry throws on locale resolution, and
  discovering that in T05.11 with 96 red tuples is worse than discovering it here with one.
- `'direction is resolved from the locale, never passed in'` — `Directionality.of` inside the pumped
  subtree is `ltr` for `en`/`de` and `rtl` for `fa`/`ckb`; and `grep` asserts `pumpPopComponent`
  exposes no `textDirection` parameter at all. Direction is a locale consequence
  (`i18n-rtl-l10n` rule 4); a harness that takes a direction lets a test claim RTL while the locale,
  the fonts and the numerals stay English.
- `'useDevice pins the logical width and resets it'` — asserts
  `tester.view.physicalSize == logical * dpr` for each `Device` in `Device.all` and that the tear-down
  restores the default (a leaked size poisons every later test in the file).
- `'loadAppFonts registers the bundled Latin faces'` — after `loadAppFonts()`, a `Text` styled
  `type.displayL` measures wider than the same string under the default test font. If E01's `.ttf`
  files are missing this is the test that says so, loudly, instead of every golden below quietly
  rendering Ahem (Risk 9).
- `'loadAppFonts registers a face that covers Arabic script'` — measures each of `ا ب ژ` plus the five
  Sorani-specific letters `ڕ ڵ ۆ ێ ھ` with a `TextPainter` at the resolved body style and asserts each
  width differs from the width of `U+FFFF`, a permanently-unassigned codepoint that always renders as
  the last-resort box. Equal widths mean the glyph is missing and the "Persian" golden is a field of
  notdef boxes that will match itself forever. Heuristic, not proof — the eye check on the `ckb`
  contact sheet in T05.11 is the proof.
- `'MediaQuery sits above MaterialApp and preserves view size'` — pumps with
  `textScaler: TextScaler.linear(2)` and asserts `MediaQuery.sizeOf` inside the app still reports the
  pinned size; a bare `MediaQueryData()` would report `Size.zero` and pass a broken layout.
- `'greyscale wrapper desaturates'` — renders two swatches of equal luminance and different hue and
  asserts the two goldens are byte-identical under the filter, so the greyscale lane can actually
  detect hue-only states.
- `'the de specimen is at least 1.25x the en specimen'` and `'the fa and ckb specimens are Arabic
  script'` — over `sampleStrings`, per field: the German string is the expansion stress case by
  construction, and each RTL specimen contains only codepoints in the Arabic blocks
  (`U+0600–U+06FF`, `U+0750–U+077F`), with the `ckb` specimen containing at least one of
  `ڕ ڵ ۆ ێ ھ`. A specimen set that quietly holds English text makes every locale golden a duplicate of
  the `en` one.
- `'FakeFeedbackService records each fired moment once'` — a plain unit test.

**Implementation.** `test/support/component_harness.dart` **extends E03's `test/support/harness.dart`;
it does not fork it.** It imports `Device`, `Device.all` and `useDevice` from there and declares no
second device type and no second `pumpApp`. E03's presets are all DPR 2 — the geometry
`capture-screens.sh` rendered the eight PNGs at, and the geometry of the canonical simulator — so a
component golden blessed at DPR 3 could not be laid beside either. This epic uses the same number.
- `extension PopHarness on WidgetTester { Future<void> pumpPopComponent(Widget child, {Device? device, Locale locale = const Locale('en'), TextScaler textScaler = TextScaler.noScaling, bool boldText = false, List<Override> overrides = const <Override>[]}); }`
  — calls `useDevice`, then wraps in `ProviderScope` → `Builder` →
  `MediaQuery(data: MediaQuery.of(context).copyWith(...))` →
  `MaterialApp(theme: buildSunburstTheme(), locale: locale, localizationsDelegates: <E04's list>, supportedLocales: <E04's list>, home: Scaffold(backgroundColor: surface, body: Center(child: child)))`
  and ends in a single `pump()`, never `pumpAndSettle`. **There is no `textDirection` parameter** — the
  direction arrives through `GlobalWidgetsLocalizations` from the locale, which is also what makes the
  RTL goldens honest rather than a `Directionality` wrapper over English text.
- `String popGolden(String name, Locale locale) => 'goldens/${locale.languageCode}/$name.png';` — one
  naming function so no test hand-splices a golden path and no locale directory is invented twice.
- `test/support/sample_strings.dart` — `SampleStrings` (button, chip, cardTitle, cardSubtitle,
  hudLabel, difficulty×3, navLabel×3, toggleOn, toggleOff, score, duration, tile) and
  `const Map<String, SampleStrings> sampleStrings` keyed by language code. These are **specimens
  chosen for length and script**, not translations, and their doc comment says so: they exist to stress
  layout, and the real strings arrive from ARB in E08. The numeral fields carry Eastern Arabic digits
  for `fa`/`ckb` (`'۱٬۴۸۰'`, `'۱۸٫۶'`, `'۲۵'`) and Latin digits with German grouping for `de`
  (`'1.480'`).
- `Widget popStateMatrix({required String label, required List<PopComponentState> states, required Widget Function(PopComponentState) build})`
  laying the states out in one column with the state name beside each, for the per-component matrix
  golden.
- `class Greyscale extends StatelessWidget` — a `ColorFiltered` saturation-zero matrix for the
  greyscale lane.
- `test/support/fake_feedback_service.dart` — `final class FakeFeedbackService implements FeedbackService
  { final List<Moment> fired; }` (the interface itself lands in T05.3; commit this file with T05.3 if
  the ordering is inconvenient). **One path, one name, for the whole project**: E09 T09.5 and E10 T10.2
  both consume this file and must not add `test/support/fakes/fake_feedback_service.dart` or a
  `RecordingFeedbackService` beside it.
- `test/support/load_app_fonts.dart` and `dart_test.yaml`'s `golden` tag are **E03 T03.7's, imported
  and not re-created.** They landed beside the Arabic faces because E03 T03.9's metric measurements are
  meaningless under Ahem's fixed em-square and its `type_specimen_arabic_test.dart` is the repo's first
  golden — two epics before this one. This task calls `loadAppFonts()` in `setUpAll` in T05.2, T05.10
  and T05.11 so the bold, character-width and script-shaping axes are not inert, and **extends** the
  registered family list only if a face was somehow missed. E07, E08, E09 and E10 import the same file.

**`pumpPopComponent` takes a `LocaleCase`, not a bare `Locale`, and delegates to `pumpLocalized`.**
E04 T04.10 owns `LocaleCase`, `LocaleCase.all` and `pumpLocalized` in E03's one
`test/support/harness.dart`; this wrapper adds the component-sized surface and nothing else. It does
**not** build its own `ProviderScope` → `MaterialApp` chain — `pumpLocalized` already asserts the
resolved `Directionality` matches the case's declared direction, and a second chain would skip that
assertion silently. E08 T08.1's `pumpShellApp` follows the same rule; those two are the only sanctioned
wrappers in the repository.

**Files.** `test/support/component_harness.dart`, `test/support/sample_strings.dart`,
`test/support/fake_feedback_service.dart`, `test/support/component_harness_test.dart`.

**Skills.** `widget-golden-and-a11y-testing`, `i18n-rtl-l10n`, `testing-strategy`, `adaptive-layout`.

**Screenshot check.** n/a (no visual surface).

**Done when.**
- [ ] `flutter test test/support/` green, including the four-locale pump and the Sorani glyph probe.
- [ ] No `pumpAndSettle`, no `takeException()` in a `tearDown`, no `ignoreOverflowErrors`, no
      `FlutterError.onError` assignment anywhere under `test/`.
- [ ] `check-test-hygiene.sh lib test` green.
- [ ] `pumpApp`, `Device` and `useDevice` are **imported from E03's `test/support/harness.dart`**, not
      re-declared here — this harness pumps a component, not the app.
- [ ] The supported-locale list, `LocaleNumbers` and the bidi helper are **imported from
      `lib/l10n/`**; `grep -rn 'LocaleNumbers\|supportedLocales' test/support/` shows imports, not
      declarations.
- [ ] `grep -rn 'textDirection:' test/support/` returns nothing outside a comment explaining why.
- [ ] `loadAppFonts()` proves the real faces loaded, Latin and Arabic — **imported from E03's
      `test/support/load_app_fonts.dart`**, and `grep -rn 'FontLoader' test/` matches only that file;
      `dart_test.yaml` was not re-created; `grep -rn 'PopWidth' test/` returns nothing.
- [ ] `pumpPopComponent` takes a `LocaleCase` and delegates to `pumpLocalized`;
      `grep -rn 'MaterialApp(' test/support/` matches only `harness.dart`.

**Commits.**
1. `test(support): meta-tests for the locale-aware component harness`
2. `test(support): assert E03's loadAppFonts covers the Latin and Arabic faces`
3. `test(support): add pumpPopComponent driven by locale over the shared Device presets`
4. `test(support): add the four-locale specimen strings, the state matrix and FakeFeedbackService`

---

### T05.3 — `PopSurface`, `PopElevation`, the press seam, the dashed edge and the mirroring law
**Goal.** The one primitive and the one press implementation, with the hit area provably still and the
shadow provably unmirrored.

**Tests first (TDD).** `test/ui/components/pop_surface_test.dart`:
- `'restOffset resolves each elevation step'` — pure test over `PopElevation`: `flat` → `null`,
  e1 → `(3,3)`, e2 → `(5,5)`, e3 → `(8,8)`, e4 → `(10,10)`.
- `'pressScale is 0.97 at e1 and 0.98 above'` — pure test over `PopElevation.pressScale(shape)`.
- `'travel is the resting offset minus one on both axes'` — `shape.pressTranslate` over all four steps.
- `'every shadow the surface paints has blur and spread 0'` — walks the rendered
  `BoxDecoration.boxShadow` and asserts both are `0`, at rest and while held.
- `'the pressed shadow is (1,1) from every step'` — parameterised over e1..e4.
- **`'the hard offset shadow is (5,5) in fa exactly as in en'`** — the reviewer's question, answered by
  a test. Pumps the same e2 surface at `Locale('en')` and `Locale('fa')`, reads the rendered
  `BoxShadow.offset` from both and asserts they are identical and positive on both axes. The shadow is
  a light source fixed at the top-start of the *page*, not a reading-direction property; a mirrored
  shadow would put the light behind the reader in half the shipped locales and would make every RTL
  golden disagree with `system.html` §07 for no reason anyone could name. Parameterised over e1..e4.
- **`'press travel keeps its sign under rtl'`** — the same surface held down under `fa` translates
  `(+4, +4)`, not `(−4, +4)`. The press moves the object toward its shadow; the shadow did not move.
- **`'directional padding mirrors'`** — a surface with
  `padding: EdgeInsetsDirectional.only(start: 20, end: 8)` measures its child 20 from the left under
  `en` and 20 from the right under `fa`, with `getRect` on both sides. This is the positive control for
  the negative controls above: if this fails, the mirroring is not happening at all and the shadow
  tests above are green for the wrong reason.
- `'the hit area does not move during the press'` — the regression test for the whole design:
  `tester.getRect(find.byType(GestureDetector))` (or the `ConstrainedBox`) captured at rest, then a
  `TestGesture` held down, `pump(durTap)`, rect re-measured and asserted **identical**, while the
  painted `Transform` has moved by `travel`. Then release at the target's original edge and assert
  `onTap` fired. Run under `en` and `fa`.
- `'the minimum target is 48 on both axes'` — a `PopSurface` around a 12×12 child; `getSize` ≥ 48.
- `'minTarget 0 lets an ancestor own the gesture'` — asserts the surface does not inflate.
- `'disabled resolves fill, edge, label ink and shadow inside the palette'` — `surfaceSunk` fill,
  `borderDisabled` edge, shadow at the e1 offset painted in `borderDisabled`, and no `Opacity` widget
  anywhere in the subtree (`find.byType(Opacity)`, `findsNothing`).
- `'a borderless surface keeps its fill when disabled'` — the ghost/answer-key carve-out:
  `borderStyle: PopBorderStyle.none` + `enabled: false` keeps `fill`.
- `'reduced motion drops the transform and keeps the pressed shadow'` — pumped with
  `MediaQuery(disableAnimations: true)`: transform stays identity through the press, shadow is
  `(1,1)` on the same frame, `motion.resolve` returned `Duration.zero`.
- `'focus shows a 4px ring outside a 3px gap and keeps the rest shadow'` — drives
  `FocusableActionDetector` via `onShowFocusHighlight`, asserts the ring painter is installed and the
  rest shadow is unchanged; plus `'a touch press leaves no focus ring'`.
- `'semantics declare button, enabled and selected'` — `isSemantics(isButton: true, hasEnabledState: true, isEnabled: false, isSelected: true, hasTapAction: true)`.
- `'a null onTap is not a button'` — `isButton: false`, no tap action, no press response.
- `'the commit moment fires exactly once per tap'` — `FakeFeedbackService.fired` has length 1.
- `test/ui/components/dashed_ink_border_test.dart` — `'shouldRepaint is a single value compare'`
  (equal config → `false`, one field changed → `true`), `'the dash pitch is 9 on / 7 off'` as a golden
  of a dashed rounded rect, and `'the dash phase starts at the same corner in rtl'` — the dashed edge
  is a closed path drawn from a fixed origin and is not a directional affordance; the `en` and `fa`
  goldens are byte-identical.
- Goldens: `goldens/en/pop_surface_states.png` and `goldens/fa/pop_surface_states.png` (rest /
  pressed / disabled / focused, e1–e4) and `goldens/greyscale/pop_surface_states.png`.

**Implementation.**
- `lib/ui/components/pop_surface.dart` — `const double kPopMinTarget = 48;`,
  `enum PopElevation { flat, e1, e2, e3, e4 }` with `Offset? restOffset(SunburstShape)` and
  `double pressScale(SunburstShape)`, `enum PopBorderStyle { solid, dashed, none }`, and
  `class PopSurface extends StatefulWidget` with the constructor from
  `sunburst-components/examples/pop_surface.dart` (`fill`, `radius`, `child`, `elevation`,
  `borderStyle`, `padding`, `onTap`, `enabled`, `selected`, `minTarget`, `pressScaleOverride`,
  `commitMoment`, `semanticLabel`). `padding` is typed **`EdgeInsetsDirectional`**, not
  `EdgeInsetsGeometry` — the narrower type makes a physical inset a compile error at every one of the
  fourteen call sites, which is stronger than a grep. `radius` is `BorderRadiusDirectional`. Private
  `_FocusRingPainter` paints the gap and the ring as strokes outside the layout box — never a
  `BoxShadow` with spread.
- `lib/ui/components/dashed_ink_border.dart` — `DashedInkBorder extends CustomPainter`, stroking the
  RRect from `Path.computeMetrics()` at `shape.dashOn`/`dashOff`, with `shouldRepaint` as one value
  compare and every `Paint` precomputed as a field.
- **The press seam.** `PopSurface` composes `PressPhysics`; that widget belongs to
  `sunburst-motion-and-haptics` and therefore to E06, but E05 cannot ship a pressable surface without
  it and rule 2 of both skills forbids a second press implementation. Decision recorded in *Risks*:
  this task creates `lib/shared/motion/press_physics.dart` (`PressGeometry`, `PressBuilder`,
  `PressPhysics` — geometry, one interruptible `AnimationController` at
  `motion.resolve(context, motion.durTap)`, `animateTo` never `forward`, the reduce-motion split,
  `minTarget` between the gesture and the transform), `lib/shared/feedback/moment.dart` (the `Moment`
  enum, all eighteen values transcribed from `sunburst-motion-and-haptics`' catalog table, no
  behaviour) and `lib/shared/feedback/feedback_service.dart`
  (`abstract interface class FeedbackService { void fire(Moment moment); }`, a `SilentFeedbackService`
  no-op and `feedbackServiceProvider`). `PressGeometry` holds no `TextDirection` and derives no sign
  from one: the travel is `(+dx, +dy)` in every locale. **E06 replaces the implementation and owns the
  moment → haptic map; it does not rewrite the seam and must not add a second press controller.**

**Files.** `lib/ui/components/pop_surface.dart`, `lib/ui/components/dashed_ink_border.dart`,
`lib/shared/motion/press_physics.dart`, `lib/shared/feedback/moment.dart`,
`lib/shared/feedback/feedback_service.dart`, `test/ui/components/pop_surface_test.dart`,
`test/ui/components/dashed_ink_border_test.dart`,
`test/ui/components/goldens/{en,fa,greyscale}/pop_surface_*.png`.

**Skills.** `sunburst-components`, `sunburst-motion-and-haptics`, `sunburst-tokens`,
`custom-canvas-and-gestures`, `i18n-rtl-l10n`, `accessibility-as-code`,
`widget-golden-and-a11y-testing`, `dart3-idioms-and-coding-standards`, `dartdoc-conventions`.

**Screenshot check.** `design/sunburst-pop/system.html` §07 *Elevation* (the five steps and the press
rule) and §10 → *Primary button* / *Secondary button* as the rendered instance of the surface, in the
browser at default `dir` and again with `dir="rtl" lang="fa"` on `<html>`; the RTL pass exists to
confirm the shadow still falls down-and-right. Compare structure → spacing → surface construction →
type → sampled hex. Not against `screens/*.png` or `screens/rtl/*.png`.

**Done when.**
- [ ] Every test above green, including the hit-area-does-not-move regression in both directions and
      the shadow-does-not-mirror assertion.
- [ ] `check_component_hygiene.sh lib`, `check_raw_values.sh lib` and `check_i18n_bans.sh lib` green.
- [ ] `check_motion_tokens.sh lib` green — no `Duration(`, no `Curves.`, no `Cubic(` outside `lib/theme/`.
- [ ] `check_painter_hygiene.sh lib` green: no allocation inside `paint()`, `shouldRepaint` is a value
      compare, `ExcludeSemantics` over drawn pixels.
- [ ] `PopSurface.padding` is `EdgeInsetsDirectional` and `radius` is `BorderRadiusDirectional`.
- [ ] No `Opacity` anywhere in `lib/ui/components/`; no `elevation:` with a numeric argument; no
      `ClipRRect` around a `PopSurface`.
- [ ] `flutter analyze --fatal-infos` clean.

**Commits.**
1. `test(ui): pin PopElevation geometry and the press law`
2. `test(ui): pin the shadow as a light-source constant that does not mirror`
3. `feat(shared): add the Moment enum and the FeedbackService seam`
4. `feat(shared): add PressPhysics, the one press controller`
5. `feat(ui): add PopSurface with directional padding, the focus ring and the disabled resolution`
6. `feat(ui): add DashedInkBorder for the locked edge`
7. `test(ui): golden and greyscale matrices for PopSurface in en and fa`

---

### T05.4 — The drawn glyph set and the mirror table
**Goal.** Seventeen inline stroke glyphs in `lib/ui/glyphs/` at the two design weights, painted on
canvas — no emoji, no icon font, no `IconData` — each one carrying an explicit, tested answer to
"does this mirror in RTL?".

**Tests first (TDD).** `test/ui/glyphs/sunburst_glyph_test.dart`:
- `'every SunburstGlyph value resolves to a path'` — iterates `SunburstGlyph.values` and asserts the
  painter produces a non-empty path for each; a value added without artwork fails immediately.
- `'stroke weight follows the requested size'` — pure test over the resolver: ≥ 22 → `glyphStrokeNav`
  2.6, < 22 → `glyphStrokeControl` 3.0, with the boundary cases named, **including 16** (the settings
  disclosure chevron in `app.html` is 16px at `stroke-width="3"`; a resolver written as "18–20 → 3.0"
  gives it 2.6 and it renders visibly thinner than the row it sits in).
- **`'every glyph declares whether it mirrors'`** — an exhaustive `switch` over `SunburstGlyph.values`
  with no `default:`, comparing `glyph.mirrorsInRtl` against a literal table in the test. Adding an
  eighteenth glyph fails to compile until someone decides. The table:

  | Mirrors | Does not mirror |
  |---|---|
  | `back` (chevron pointing to the start edge) | `navPlay`, `navStats`, `navSettings` — tab marks are brand marks; mirroring them changes recognition and adds no meaning |
  | `chevronForward` (row disclosure) | `go` — a filled play triangle, and `i18n-rtl-l10n` lists media play among the fixed-meaning glyphs (open question, see *Risks*) |
  | `sound` (cone at the start edge, wave arc at the end edge) | `pause`, `close`, `haptics` (symmetric), `contrast`, `language`, `info`, `lock`, `star`, `flame` |
  |  | `motion` — the artwork is a **clock** (circle plus hands, `app.html` settings row 3), and a clock never mirrors |

- **`'a mirroring glyph flips under fa and a fixed one does not'`** — golden pair per class: `back` and
  `motion` rendered at `Locale('en')` and `Locale('fa')`; `back`'s two images differ, `motion`'s two are
  byte-identical.
- `'the painter itself is direction-agnostic'` — `GlyphScene` has no `TextDirection` field and
  `SunburstGlyphPainter.paint` reads none. The flip is a `Transform` applied by the widget
  (`custom-canvas-and-gestures` rule 11: geometry is direction-agnostic, only chrome mirrors), which
  keeps `shouldRepaint` a pure value compare and keeps one path per glyph rather than two.
- `'a glyph is excluded from semantics'` — `find.byType(SunburstGlyphIcon)` renders no semantics node
  of its own; the label belongs to the enclosing component.
- `'shouldRepaint is a single value compare'` — same scene → `false`, different glyph/colour/stroke →
  `true`.
- `'paint allocates no Paint or Path'` — asserted structurally by `check_painter_hygiene.sh`, plus a
  test that two consecutive paints of the same scene reuse the same `Paint` instance via an injected
  recording canvas.
- Goldens `goldens/en/glyph_sheet.png` and `goldens/fa/glyph_sheet.png`: all seventeen at 22 and at 18
  on cream, ink stroke; plus `goldens/greyscale/glyph_sheet.png`.

**Implementation.** `lib/ui/glyphs/sunburst_glyph.dart` declares
`enum SunburstGlyph { navPlay, navStats, navSettings, go, back, pause, close, sound, haptics, motion, contrast, language, info, chevronForward, lock, star, flame }`
— the exact set drawn in `system.html` §08 plus the four `app.html` settings-row glyphs (`haptics`,
`contrast`, `language`, `info`) and the disclosure chevron. **`chevronForward`, not `chevronRight`**: a
name carrying a physical side is wrong in `fa` and `ckb` and invites the physical geometry the gate
bans (`naming-conventions` rule 9 — the semantics belong in the name). The status-bar wifi and battery
marks are **not** included: they are mockup device chrome, drawn by the OS on a real device.
The enum carries `bool get mirrorsInRtl` as an exhaustive `switch` with no `default:`.
`class SunburstGlyphIcon extends StatelessWidget` takes `(SunburstGlyph glyph, {double size, Color? colour})`,
wraps `CustomPaint` in `ExcludeSemantics`, defaults `colour` to `colors.textPrimary`, and — when
`glyph.mirrorsInRtl && Directionality.of(context) == TextDirection.rtl` — wraps the paint in
`Transform(alignment: Alignment.center, transform: Matrix4.rotationY(math.pi))`, the manual flip
`i18n-rtl-l10n` prescribes for a directional glyph `Icons.adaptive` cannot cover.
`lib/ui/glyphs/sunburst_glyph_painter.dart` holds `@immutable class GlyphScene` (glyph, colour,
strokeWidth, size) and `SunburstGlyphPainter extends CustomPainter` with every `Path` precomputed as a
`static final` keyed by glyph and scaled by one shared transform from its authored viewBox. Path
coordinates are artwork, not tokens, and stay in this file; the two stroke widths are read from
`SunburstShape` (T05.1). `strokeCap`/`strokeJoin` are `round` per the SVG source. `go` and `star` are
the two filled glyphs — filled *and* stroked, as in the source.

**Files.** `lib/ui/glyphs/sunburst_glyph.dart`, `lib/ui/glyphs/sunburst_glyph_painter.dart`,
`test/ui/glyphs/sunburst_glyph_test.dart`, `test/ui/glyphs/goldens/{en,fa,greyscale}/glyph_sheet.png`.

**Skills.** `custom-canvas-and-gestures`, `i18n-rtl-l10n`, `sunburst-shell-screens`, `sunburst-tokens`,
`accessibility-as-code`, `widget-golden-and-a11y-testing`, `naming-conventions`,
`dart3-idioms-and-coding-standards`.

**Screenshot check.** `system.html` §08 *Iconography*, all three subsections: *22px · stroke 2.6*,
*18–20px · stroke 3* and *Badge glyphs — drawn, not typed*, plus the settings rows in `app.html`
screen 08 for the four glyphs §08 does not show. Put `goldens/en/glyph_sheet.png` beside the rendered
gallery and check shape, terminal caps, stroke weight and optical size per glyph; put
`goldens/fa/glyph_sheet.png` beside the same page under `dir="rtl"` and check that exactly three marks
moved.

**Done when.**
- [ ] Seventeen glyphs render and match the gallery.
- [ ] Every glyph has an explicit `mirrorsInRtl` answer and the table test is exhaustive.
- [ ] `grep -rn "Icons\.\|IconData\|Icon(" lib/` returns nothing.
- [ ] `grep -rn "chevronRight" .` returns nothing.
- [ ] No emoji anywhere in `lib/` (`check_component_hygiene.sh` plus a review grep).
- [ ] `check_painter_hygiene.sh lib`, `check_raw_values.sh lib` and `check_i18n_bans.sh lib` green.

**Commits.**
1. `test(ui): pin the glyph set, stroke resolution and semantics exclusion`
2. `test(ui): pin which glyphs mirror in rtl and which must not`
3. `feat(ui): add SunburstGlyph with the mirror predicate and the glyph painter`
4. `test(ui): golden sheets for the glyph set at both weights in en and fa`

---

### T05.5 — `PopButton`, `PopIconButton`, `PopChip`, `PopCard`
**Goal.** The four text-and-fill components, all four button variants and both button sizes — and the
first four components to meet German.

**Tests first (TDD).** `test/ui/components/pop_button_test.dart`,
`pop_icon_button_test.dart`, `pop_chip_test.dart`, `pop_card_test.dart`:
- `'each variant paints its fill slot'` — primary `accent`, success `success`, secondary
  `surfaceRaised`, ghost `Colors.transparent`; parameterised over `PopButtonVariant`.
- `'the label is textPrimary on every fill'` — including success and secondary; only disabled moves to
  `textDisabled`.
- `'ghost draws no border and no shadow but keeps a 3px ink rule under the label'`.
- `'ghost travels 2px on press'` — the `pressScaleOverride`/e1 derivation.
- `'large uses buttonLarge, radiusXl and 18/20 padding'`.
- `'a null onPressed disables and there is no second enabled flag'` — asserts the constructor exposes
  no `enabled` parameter that could disagree.
- `'the leading glyph sits at the start edge in every locale'` — `getRect(glyph).left < getRect(label).left`
  under `en`, and the reverse under `fa`. This is the test that catches `EdgeInsets.only(left:)` in a
  place a grep would have caught it too — kept because the grep cannot see a `Row` whose child order
  was hardcoded for LTR.
- `'the German label wraps rather than shrinking'` — pumped at `Locale('de')` with
  `sampleStrings['de']!.button` on `Device.compact320`: `takeException()` is null, `getRect(text)` is
  contained by `getRect(surface)`, the resolved `TextStyle.fontSize` equals `type.button.fontSize`
  (nothing shrank), and `find.byType(FittedBox)` is `findsNothing`.
- `'PopIconButton is 48×48 and speaks its semanticLabel'` — `getSize` plus
  `isSemantics(isButton: true, label: <the caller's already-localized string>)`.
- `'PopIconButton with the back glyph mirrors its chevron'` — the composed check that T05.4's flip
  survives being wrapped in a surface.
- `'PopChip renders a glyph, 7/14 padding and type.chip'`, plus `'a chip carrying Persian digits
  renders no notdef box'` — the `fa` specimen through the chip's display step, width-probed against
  `U+FFFF` as in T05.2.
- `'PopCard is not pressable without onTap'` — no button role, no press response; and
  `'PopCard with onTap presses at e2'`.
- `'PopCard density maps to elevation'` — `dense` → e1, `standard` → e2, `hero` → e3 + `radiusXl`.
- `'a card row divider is a 3px ink rule, never colors.divider'`.
- a11y per component: tap target `getSize` ≥ 48 both axes; `isSemantics` role/label/enabled.
- Goldens per component: `goldens/en/` and `goldens/fa/` rest / pressed / disabled / focused (+ the
  card's three densities), `goldens/de/` rest only, plus one `goldens/greyscale/` matrix each.

**Implementation.** `lib/ui/components/pop_button.dart` (`PopButton`,
`enum PopButtonVariant { primary, success, secondary, ghost }`,
`enum PopButtonSize { regular, large }`, `label`, `onPressed`, `leading`, `expand`),
`pop_icon_button.dart` (`PopIconButton` — 48×48, `surfaceRaised`, `radiusMd`, e1, required
`semanticLabel`, `SunburstGlyph glyph`), `pop_chip.dart` (`PopChip` — `surfaceRaised`, pill, e1,
padding 7/14, `type.chip`, optional `glyph`), `pop_card.dart` (`PopCard`,
`enum PopCardDensity { dense, standard, hero }`, `padding` default `SunburstShape.cardPadding`,
optional `onTap`). All four compose `PopSurface` and construct no decoration of their own. All labels
are already-localized `String`s and every label is `TextAlign.start` with `softWrap: true`,
`maxLines: 2` and **no** `overflow:` — a label that does not fit is a matrix failure in T05.11, not a
silently truncated string on someone's phone.

**Files.** the four `lib/ui/components/*.dart` above, their four test files, and
`test/ui/components/goldens/{en,fa,de,greyscale}/pop_{button,icon_button,chip,card}_*.png`.

**Skills.** `sunburst-components`, `sunburst-tokens`, `widget-composition`, `i18n-rtl-l10n`,
`accessibility-as-code`, `widget-golden-and-a11y-testing`, `dartdoc-conventions`.

**Screenshot check.** `system.html` §10 → *Primary button*, *Secondary button*, *Ghost button*; the
chip and card as they appear in `app.html` screens 01 and 02 (the streak chip, the stat card), both at
default `dir` and under `dir="rtl"`. Order: structure → spacing rhythm → surface construction → type
role → sampled hex.

**Done when.**
- [ ] All four components green on their `en`/`fa`/`de` goldens and their a11y test.
- [ ] `grep -rn "ElevatedButton\|FilledButton\|TextButton\|OutlinedButton\|Card(" lib/` returns nothing.
- [ ] `check_component_hygiene.sh lib`, `check_raw_values.sh lib`, `check_i18n_bans.sh lib`,
      `check-widget-composition.sh lib` green.
- [ ] No `Widget _buildX()` method anywhere in `lib/ui/`; no `overflow:` argument on any `Text`.

**Commits.**
1. `test(ui): pin PopButton variants, sizes and states`
2. `feat(ui): add PopButton on PopSurface`
3. `test(ui): pin leading-glyph placement and German wrapping`
4. `feat(ui): add PopIconButton and PopChip`
5. `feat(ui): add PopCard with its three densities`
6. `test(ui): golden and greyscale matrices for the button family in en, fa and de`

---

### T05.6 — `GameCard` and `DifficultySegmented`
**Goal.** The home hub card (with its best pill, artwork tile and locked variant) and the three-item
segmented control whose selected item lifts instead of pressing — the first component whose *order*
has to mirror.

**Tests first (TDD).** `test/ui/components/game_card_test.dart`,
`test/ui/components/difficulty_segmented_test.dart`:
- `'the card fills with the accent it is given'` — the accent arrives as a constructor argument; a
  test asserts the widget reads no global and no `switch (gameId)`.
- `'title and subtitle are both textPrimary'` — the 2.8:1 trap on coral; asserted on the resolved
  `TextStyle.color`, not by eye.
- `'the best pill uses borderWidthNested 2 and a surface fill'` and
  `'BEST is textSecondary, legal because it sits on cream'`.
- `'the best pill renders Eastern Arabic digits without reflow'` — pumped at `Locale('fa')` with
  `'۱٬۴۸۰'` and `'۹۹۹'`; the pill's `getRect` width is asserted against the same pair rendered under
  `en` as `'1,480'`/`'999'` only for *non-collision* (they will differ — Persian digits are wider in
  Vazirmatn than Latin digits in Nunito), and asserted for containment inside the card.
- `'the artwork quad sits at the end edge and mirrors'` — `getRect(artwork).left > getRect(title).left`
  under `en`, the reverse under `fa`.
- `'locked renders a dashed edge, no shadow, no tap and a locked badge'` — plus
  `'locked copy is textSecondary, not textDisabled'` (a status line is not a disabled control).
- `'the artwork quad is excluded from semantics'` and
  `'the card speaks one merged label'` — "Stroop Rush, tap the colour not the word, best 1,480"; the
  three fragments arrive as already-localized strings and are joined by the caller, not spliced here.
- **`'no bidi isolate character reaches a Semantics label'`** — walks the card's merged semantics node
  and asserts no codepoint in `U+2066`–`U+2069`. Isolates are a visual-order device for a rendered
  paragraph; a screen reader linearises, and shipping control characters into a spoken label is the
  kind of thing that produces one confused bug report and no reproduction. The *visible* mixed-script
  run (a Latin game title inside a Persian sentence) is isolated by the caller through E04's helper;
  the semantics label is the raw string.
- `'the selected segment lifts to (−1,−1) with the eChip shadow'` — and the lift is `(−1,−1)` under
  `fa` too: the selected segment rises toward the same light source (see T05.3).
- `'the pressed segment fills accentDeep, drops the shadow and moves (1,1)'` — three distinct
  silhouettes: selected ≠ pressed ≠ rest.
- **`'segment order follows the reading direction'`** — with items `[easy, medium, hard]`,
  `getRect(easy).left < getRect(hard).left` under `en` and the reverse under `fa`, and the
  `selectedIndex` still addresses the same logical item in both. Index is logical; layout is
  directional. A control that renders the same order in both directions has hardcoded child order and
  will read backwards to every Persian and Sorani player.
- `'a locked segment shows a padlock glyph as well as textDisabled'` — the never-colour-alone check.
- `'items are radio semantics, not buttons'` — `isSemantics(isSelected: true, isInMutuallyExclusiveGroup: true)`
  per item and one group label.
- `'a 3px transparent border on the rest item prevents layout shift on selection'` — asserts the item
  rect is identical selected and unselected.
- `'each segment is at least 48 tall'` — `getSize` loop.
- `'three German labels stack instead of clipping below 360'` — at `Locale('de')` on
  `Device.compact320` the control lays its three items out in a column (decided from `LayoutBuilder`
  constraints, never a device or locale check), each item still ≥ 48 tall, `takeException()` null,
  every label fully contained. The same assertion at `Device.reference390` keeps the row.
- Goldens: `goldens/{en,fa}/game_card_{rest,pressed,locked,focused}.png`,
  `goldens/{en,fa}/difficulty_segmented_{rest,selected,pressed,locked,focused}.png`,
  `goldens/de/` rest for both, plus greyscale matrices.

**Implementation.** `lib/ui/components/game_card.dart` — `GameCard` with `title`, `subtitle`,
`accent`, `bestLabel`, `artwork`, `onTap`, `isLocked`; `PopElevation.e2`, `radiusLg`, padding 15/16,
12px gap, 64×64 artwork tile at `radiusMd`/e1; locked uses `PopBorderStyle.dashed` and `onTap: null`.
`lib/ui/components/difficulty_segmented.dart` — `DifficultySegmented` over a
`List<DifficultyOption>` (`label`, `isLocked`), `selectedIndex`, `onSelected`; `surfaceSunk` track,
3px border, pill, 6px padding and 6px gap, each item `Expanded` with 13px vertical padding, wrapped in
a `LayoutBuilder` that switches to a column when the widest item's intrinsic width × 3 exceeds the
available track. Layout order comes from the `Row`'s natural directional flow — there is no
`textDirection:` argument and no `.reversed` anywhere.

**Files.** `lib/ui/components/game_card.dart`, `lib/ui/components/difficulty_segmented.dart`, their
two test files, `test/ui/components/goldens/{en,fa,de,greyscale}/game_card_*.png` and
`.../difficulty_segmented_*.png`.

**Skills.** `sunburst-components`, `sunburst-tokens`, `i18n-rtl-l10n`, `adaptive-layout`,
`accessibility-as-code`, `widget-golden-and-a11y-testing`, `widget-composition`.

**Screenshot check.** `system.html` §10 → *Game card* and *Difficulty segmented control*, at default
`dir` and under `dir="rtl" lang="fa"`.

**Done when.**
- [ ] Both components green on all their state goldens in `en` and `fa`, plus `de` rest and greyscale.
- [ ] The accent is a constructor argument; `grep -rn "gameStroop\|gameSchulte" lib/ui/` returns
      nothing.
- [ ] Segment order mirrors; `selectedIndex` addresses the same logical item in both directions.
- [ ] No isolate codepoint reaches a semantics label.
- [ ] `check_component_hygiene.sh lib`, `check_game_palette.sh lib` and `check_i18n_bans.sh lib` green.

**Commits.**
1. `test(ui): pin GameCard states, the locked variant and the merged label`
2. `feat(ui): add GameCard with the best pill and dashed locked edge`
3. `test(ui): pin the segmented control's three silhouettes, radio semantics and mirrored order`
4. `feat(ui): add DifficultySegmented with a constraint-driven column fallback`

---

### T05.7 — `HudPill`, `TimerRing`, `PopProgressBar`
**Goal.** The three HUD components, two of which paint on canvas — and the three components most
exposed to a digit block that is not Latin.

**Tests first (TDD).** `test/ui/components/hud_pill_test.dart`, `timer_ring_test.dart`,
`pop_progress_bar_test.dart`:
- `'each HudTone paints its fill and both its text slots'` — neutral `surfaceRaised` +
  `textSecondary` label; highlight `accent` with **both** lines `textPrimary`; alarm `danger` with
  **both** lines `surfaceRaised`. Asserted on resolved colours.
- `'the alarm tone is danger, never gameStroop'` — the coral-on-coral trap; asserts the fill is not
  any `game*` slot.
- `'the pill is neither pressable nor focusable'` — no button role, no tap action, no focus node.
- `'label and value are merged into one announcement'` — `MergeSemantics`, "Time, 0:23".
- **`'the value does not reflow when a digit changes, in every locale'`** — the old tabular test, now
  parameterised: `en` `0:23`→`0:11`, `de` `1.480`→`9.999`, `fa` `۰:۲۳`→`۰:۱۱`, `ckb` the same. Each
  pair must produce an identical pill width. `FontFeature.tabularFigures()` is a property of the
  *font*, and `sunburst-tokens` rule 10 put it on `numericHud` for Fredoka; whether Vazirmatn honours
  `tnum` for `U+06F0`–`U+06F9` is not something to assume. If the `fa`/`ckb` case reds, the fix is
  `_TabularSlot` — a private widget that measures the ten digits of the active locale once per
  (style, textScaler) with a `TextPainter` and pins the value box to the widest — never a `FittedBox`
  and never a clamp. Record which branch was taken in the PR.
- `'the label sits at the start edge and the value at the end edge'` — mirrored under `fa`.
- `'the ring sweep crosses to danger in the last 12%'` — pure test on the scene builder, with the
  boundary asserted at 0.88 and 0.87.
- **`'the ring sweeps clockwise in every locale'`** — the second explicit non-mirror. A ring that
  drains anticlockwise in Persian is a clock running backwards; `i18n-rtl-l10n` names the clock among
  the fixed-meaning marks that must never mirror. Asserted on the scene's start angle and sweep sign
  under `en` and `fa`, and by the `fa` golden being identical to the `en` one apart from the label.
- `'the countdown ring is the same class at e4'` and `'nothing else in the diff claims e4'` — a grep
  assertion over `lib/`.
- **`'the progress bar fills from the start edge'`** — at `progress: 0.3`, the filled region's rect
  starts at the track's left under `en` and at its right under `fa`. A progress bar is chrome, not
  plotted data: it reads along the reading direction and mirrors.
- `'the progress bar keeps a 3px ink right edge until 100%'` — restated as an **end** edge: the ink
  rule sits at the leading edge of the *unfilled* remainder, which is the visual right under `en` and
  the visual left under `fa`. Asserted at 0.5 (edge present) and 1.0 (edge gone), both directions.
- `'the stripe angle does not mirror'` — 45° in both directions; the stripe is texture, not direction,
  and flipping it would make the two locales' progress bars look like different components.
- `'both painters repaint only on a scene change'` — `shouldRepaint` value-compare tests.
- `'both painters allocate nothing in paint()'` — recording-canvas test plus
  `check_painter_hygiene.sh`.
- `'the ring and bar are ExcludeSemantics with a sibling node speaking the display value'` — and the
  spoken value is the already-localized string the caller passed, not a re-derived `'${progress * 100}%'`.
- Goldens: `goldens/{en,fa}/hud_pill_{neutral,highlight,alarm}.png`,
  `goldens/{en,fa}/timer_ring_{rest,low,countdown}.png`,
  `goldens/{en,fa}/pop_progress_bar_{empty,half,full}.png`, `goldens/de/hud_pill_neutral.png`, plus one
  greyscale matrix each.

**Implementation.** `lib/ui/components/hud_pill.dart` — `HudPill` (`label`, `value`, `tone`), importing
`HudTone` from `lib/core/hud_tone.dart` (T05.1). The enum is **not** declared here and **not** in
`lib/features/play/domain/`: E07's `GameHud`/`HudSlot` carries the same tone, `lib/ui/` may not import
`lib/features/`, and two enums with one name never unify (see *Risks*). The shell (E08) owns *which*
tone is chosen when, and owns turning an `int` into `'۱٬۴۸۰'`. `lib/ui/components/timer_ring.dart` —
`TimerRing` (`progress`, `label`, `accent`, `elevation`), `@immutable class TimerRingScene`,
`TimerRingPainter`; the scene holds no `TextDirection`. `lib/ui/components/pop_progress_bar.dart`
— `PopProgressBar` (`progress`, `accent`), `@immutable class ProgressBarScene` **which does carry a
`TextDirection`**, because the fill origin is chrome and mirrors; the painter reads it from the scene
rather than from a `BuildContext` it does not have. `StripedFillPainter` uses `shape.stripePitch` 9 at
`shape.stripeAngle` 45 in both directions. All three compose `PopSurface` for the border and shadow;
the painters draw only the sweep and the stripe. Value cross-fades run at `motion.durState` on
`motion.easeOut` — never `easePop` on a colour.

**Files.** `lib/ui/components/hud_pill.dart`, `lib/ui/components/timer_ring.dart`,
`lib/ui/components/pop_progress_bar.dart`, three test files,
`test/ui/components/goldens/{en,fa,de,greyscale}/{hud_pill,timer_ring,pop_progress_bar}_*.png`.

**Skills.** `sunburst-components`, `custom-canvas-and-gestures`, `i18n-rtl-l10n`, `sunburst-tokens`,
`accessibility-as-code`, `widget-golden-and-a11y-testing`, `dart3-idioms-and-coding-standards`.

**Screenshot check.** `system.html` §10 → *HUD stat pill*, *Progress bar*, *Timer ring*, at default
`dir` and under `dir="rtl"`; the RTL pass is where the progress fill's origin and the ring's sweep
direction are confirmed by eye against the reasoning above.

**Done when.**
- [ ] All three green on their `en`/`fa` goldens and greyscale matrices.
- [ ] The no-reflow assertion passes in all four locales, and the PR states whether `_TabularSlot` was
      needed.
- [ ] The progress fill mirrors; the ring sweep and the stripe angle do not.
- [ ] `check_painter_hygiene.sh lib`, `check_component_hygiene.sh lib`, `check_motion_tokens.sh lib`,
      `check_i18n_bans.sh lib` green.
- [ ] Exactly one component in `lib/` can render `PopElevation.e4`, and it is `TimerRing`.

**Commits.**
1. `test(ui): pin HudPill tones, the merged announcement and per-locale digit stability`
2. `feat(ui): add HudPill over the shared HudTone`
3. `test(ui): pin the timer sweep as clockwise in every locale`
4. `feat(ui): add TimerRing and its painter`
5. `test(ui): pin the progress fill to the start edge and the stripe angle to 45`
6. `feat(ui): add PopProgressBar with the vanishing ink edge`

---

### T05.8 — `PopGridTile`, `PopToggle`, `PopBadge`
**Goal.** The five-state board tile that Schulte prints numbers on, the toggle whose printed word is
its non-colour channel, and the three badge variants.

**Tests first (TDD).** `test/ui/components/pop_grid_tile_test.dart`, `pop_toggle_test.dart`,
`pop_badge_test.dart`:
- `'each tile state has a distinct silhouette'` — parameterised over
  `PopGridTileState { idle, next, found, wrong, disabled }`, asserting fill, shadow step, transform
  and extra channel per the catalog table; plus the greyscale golden that fails if two states render
  identical images.
- `'next carries a double ring: 2px surface then 3px border'`.
- `'found is permanent: (2,2) with no shadow and no opacity'` — `find.byType(Opacity)`, `findsNothing`.
- `'disabled paints its e1 shadow in borderDisabled'`.
- `'the tile is 64 and drops to 60 at the smallest width'` — pumped at `Device.compact320` and
  `Device.reference390`, size read with `getSize`; decided from constraints, never a device check, and
  **not** from the locale: the cell is a grid unit, identical in all four.
- **`'a two-digit Eastern Arabic label fits the 64 cell at every text scale'`** — the number the
  Schulte board is made of. Pumped at `Locale('fa')` and `Locale('ckb')` with `'۲۵'` at text scale
  1.0 / 1.3 / 2.0 on both widths: `getRect(label)` is contained by `getRect(tile)`, `takeException()`
  is null, and the resolved `fontSize` equals the tile's base step at every scale. `۲۵` in Vazirmatn is
  not the width of `25` in Fredoka and its line box is taller; if this reds, the fix is a smaller BASE
  step for the tile glyph requested from E03, or a taller cell — never a `FittedBox`, never
  `maxLines: 1` with an ellipsis on a number the player has to read.
- `'the tile glyph is centred by AlignmentDirectional.center and does not shift under rtl'` — a
  centred number is centred in both directions; this is the control that proves the cell itself is not
  accidentally asymmetric.
- `'the glyph is tabular Fredoka 700 24'` under `en`, and the same step with the Arabic-script
  fallback resolved under `fa`/`ckb`.
- **`'the toggle track fits its printed word in every locale'`** — the sharpest geometry finding in the
  epic. `system.html` gives the track as 66×34 with `ON`/`OFF` printed inside; German `EIN`/`AUS`
  still fits, Persian `روشن`/`خاموش` does not, at any text scale. The word is the non-colour channel
  (`accessibility-as-code` rule 6) so it cannot be dropped, and it cannot shrink. **Decision:** 66 is a
  **minimum**, not a fixed width — the track measures the wider of `onLabel`/`offLabel` at the active
  style and scale and grows; the thumb travel is `trackWidth − thumbWidth − 2 × inset`, computed, never
  literal. Tests: the `en` track measures exactly 66×34 (so the reference golden is unchanged); the
  `fa` track is wider than 66; the thumb lands flush against the correct inset in both states in all
  four locales; the word is fully contained at text scale 2.0.
- `'the toggle renders the ON/OFF word inside the track'` — asserts the word is present and swaps side
  and colour with the value; the state survives greyscale; the ON side is the **start** side under
  `en` and the end side under `fa`.
- `'the toggle takes no gesture of its own'` — `onTap: null`, `minTarget: 0`; and
  `'the enclosing 62px row is the target'` — a row harness whose `getSize` is ≥ 48 and whose tap
  toggles.
- `'the off track draws an inner well as a border, never a second BoxShadow'` — counts the shadows in
  the rendered decoration.
- `'disabled paints track, thumb and word in borderDisabled/textDisabled'`.
- `'a badge is never tappable'` — no button role, no tap action, for all three variants.
- `'the celebration badge is accent at e2 with a −2.5° tilt and a star glyph'` — and
  `'the tilt does not mirror'`: a −2.5° rotation is a hand-placed-sticker affectation, not a
  directional cue, and it is the same −2.5° in `fa`.
- `'the streak badge renders its count in the locale's digits'` — `'x7'` / `'×۷'` arrive already
  formatted; asserted for containment and for no notdef box.
- `'the locked badge is dashed with no shadow'`.
- Goldens: one `goldens/en/` and one `goldens/fa/` matrix per component, `goldens/de/` rest, plus
  greyscale.

**Implementation.** `lib/ui/components/pop_grid_tile.dart` — `PopGridTile`,
`enum PopGridTileState { idle, next, found, wrong, disabled }` and the pure resolver
`PopGridTileVisual visualFor(PopGridTileState, SunburstColors, SunburstShape)` returning
`(elevation, offset, scale, fill, borderColour, glyphColour, hasRing)`. **Named `PopGridTile`, not
`GridTile`**, because `package:flutter/material.dart` already exports `GridTile` and every widget file
imports material; see *Risks* for the deviation and the fallback. The tile's `label` is a `String` the
caller has already localized — the tile does not know what a number is.

**Its consumer is E10.** The five states are the Schulte machine exactly, so `SchulteTile` composes this
widget and maps `SchulteTileState` onto `PopGridTileState` 1:1 rather than composing `PopSurface`
directly with a second visual resolver. That is why the resolver is public and pure: E10 T10.6's
"every state pair differs in ≥3 non-hue channels" test asserts against **this** function, and the
greyscale state-collision golden below is the same proof E10 would otherwise have to rebuild.
`lib/ui/components/pop_toggle.dart` — `PopToggle` (`isOn`, `onLabel`, `offLabel`, `isEnabled`), track
`max(66, measuredWordWidth + thumb + insets)` × 34, thumb 26×26 sliding at `motion.durMove` on
`motion.easePop`, `onTap: null`, `minTarget: 0`. The 66 stays a token-derived constant marked
`// DERIVED` with `system.html`'s specimen as evidence and a note that it is now a floor.
`lib/ui/components/pop_badge.dart` — `PopBadge` and
`enum PopBadgeVariant { celebration, quiet, locked }`, pill, 3px, `type.chip`, `SunburstGlyph`
leading, never an emoji.

**Files.** `lib/ui/components/pop_grid_tile.dart`, `lib/ui/components/pop_toggle.dart`,
`lib/ui/components/pop_badge.dart`, three test files, their goldens under
`test/ui/components/goldens/{en,fa,de,greyscale}/`.

**Skills.** `sunburst-components`, `i18n-rtl-l10n`, `accessibility-as-code`, `adaptive-layout`,
`widget-golden-and-a11y-testing`, `sunburst-tokens`, `dart3-idioms-and-coding-standards`.

**Screenshot check.** `system.html` §10 → *Grid tile*, *Toggle switch*, *Badge*, at default `dir` and
under `dir="rtl"`. The toggle's RTL pass is where the widened track is judged against the mockup — and
where the deviation gets written down rather than argued about later.

**Done when.**
- [ ] Five tile states render five distinguishable greyscale images.
- [ ] `۲۵` fits the tile at every width × scale in `fa` and `ckb`, with no shrinking.
- [ ] The `en` toggle track measures exactly 66×34; the `fa` track is wider and its word is contained.
- [ ] The toggle's enclosing row, not the toggle, is the ≥48px target.
- [ ] `check_component_hygiene.sh lib`, `check_raw_values.sh lib`, `check_i18n_bans.sh lib` green.
- [ ] The `PopGridTile` naming deviation and the toggle-track derivation are both stated in the PR body
      with their reasons.

**Commits.**
1. `test(ui): pin the five grid-tile states and their non-colour channels`
2. `test(ui): pin a two-digit Persian label inside the 64 cell`
3. `feat(ui): add PopGridTile`
4. `test(ui): pin the toggle word, the inner well and the row-owns-the-gesture rule`
5. `feat(ui): add PopToggle with a content-measured track`
6. `feat(ui): add PopBadge with its three variants`

---

### T05.9 — `PopSheet` and `PopBottomNav`
**Goal.** The two chrome containers: the bottom sheet the pause state uses, and the three-destination
nav bar with the one partial border in the system — and the one component whose fixed item width does
not survive German.

**Tests first (TDD).** `test/ui/components/pop_sheet_test.dart`,
`test/ui/components/pop_bottom_nav_test.dart`:
- `'the sheet is surface, radiusXl top / radiusMd bottom, e3, with a 56×6 grab handle'` — expressed in
  `BorderRadiusDirectional`; the radii are top-vs-bottom, which has no handedness, so the `en` and `fa`
  goldens differ only in their text.
- `'the sheet title snaps to type.title and its body to type.body'` — the mockup's 23/14 sit between
  scale steps and must not be reproduced.
- `'actions stack full width with a 10px gap, primary first'` — vertical order, so it does not mirror;
  asserted identical in both directions so nobody "fixes" it later.
- `'the first action is autofocused'`.
- `'the sheet enters over durMove on easeInOut and reduced motion lands on the end state'` — asserts
  the settled geometry is identical with `disableAnimations: true`.
- `'the nav has a 3px ink top border and no other edge'` — reads the rendered `Border` and asserts
  `left`, `right`, `bottom` are `BorderSide.none`. A top border is not a directional property.
- `'the active chip is 88 wide with a 3px transparent border at rest'` — no layout shift when it
  activates, and the reference geometry is unchanged at `en`/390.
- **`'nav destination order follows the reading direction'`** — with `[play, stats, settings]`,
  `getRect(play).left < getRect(settings).left` under `en` and the reverse under `fa`, while
  `currentIndex` addresses the same logical destination in both.
- **`'a German label wraps to two lines and the bar grows'`** — `Einstellungen` at 11.5 does not fit an
  88px chip. **Decision:** each item is an `Expanded` cell with the accent chip constrained to a
  **minimum** of 88 and free to grow to its label; the label is `maxLines: 2`, `softWrap: true`,
  `TextAlign.center`, no ellipsis; the bar's height is intrinsic with 90 as a floor. Tests: at `en`/390
  the chip measures 88 and the bar 90 (reference geometry preserved); at `de`/320 the label occupies
  two lines, the bar is taller than 90, nothing overflows and no label is truncated.
- `'the active item is an accent chip with an ink border at e1 and textPrimary'`.
- `'the icon is 22 at stroke 2.6 over the nav label step'`.
- `'items are selected-tab semantics with one label each'`.
- `'the nav accepts exactly three destinations'` — a fourth is an assertion failure, not a silent
  overflow.
- `'every nav item is at least 48 tall'` — `getSize` loop, at every locale and scale in the matrix.
- Goldens: `goldens/{en,fa}/pop_sheet_{rest,focused}.png`,
  `goldens/{en,fa}/pop_bottom_nav_{index0,index1,index2,pressed}.png`,
  `goldens/de/pop_bottom_nav_index2.png` (the two-line case), plus greyscale.

**Implementation.** `lib/ui/components/pop_sheet.dart` — `PopSheet` (`title`, `body`, `actions`) and a
`showPopSheet` helper that pushes it with `clipBehavior: Clip.none` so the e3 shadow and the 7px focus
ring are not amputated. `lib/ui/components/pop_bottom_nav.dart` — `PopBottomNav`
(`items`, `currentIndex`, `onSelected`) and `class PopBottomNavItem` (`glyph`, `label`); minimum height
90, `surfaceRaised`, a top-only `Border`, chip minimum width 88 at `radiusMd` inside an `Expanded`
cell. Neither widget navigates: routing is E08's. Neither takes a `textDirection` and neither reverses
a child list — order comes from the `Row`.

**Files.** `lib/ui/components/pop_sheet.dart`, `lib/ui/components/pop_bottom_nav.dart`, two test
files, their goldens under `test/ui/components/goldens/{en,fa,de,greyscale}/`.

**Skills.** `sunburst-components`, `widget-composition`, `adaptive-layout`, `i18n-rtl-l10n`,
`accessibility-as-code`, `widget-golden-and-a11y-testing`, `sunburst-tokens`.

**Screenshot check.** `system.html` §10 → *Modal sheet* and *Bottom navigation*, at default `dir` and
under `dir="rtl"`. Note that §10 boxes the nav on all four sides for display; `app.html`
`.tabs{border-top:…}` is the shipped geometry and wins.

**Done when.**
- [ ] Both components green on their `en`/`fa` goldens and greyscale matrices, plus the `de` nav case.
- [ ] Destination order mirrors; `currentIndex` stays logical.
- [ ] At `en`/390 the chip is 88 and the bar is 90 — the reference geometry did not move to make German
      fit.
- [ ] No `go_router` or `Navigator` import in `lib/ui/`.
- [ ] `check_shell_boundaries.sh lib`, `check_component_hygiene.sh lib`, `check_i18n_bans.sh lib` green.
- [ ] No `ClipRRect`/`Clip.hardEdge` around a `PopSurface` anywhere in the diff.

**Commits.**
1. `test(ui): pin the sheet anatomy, type snapping and autofocus`
2. `feat(ui): add PopSheet and showPopSheet`
3. `test(ui): pin the nav's top-only border, mirrored order and selected-tab semantics`
4. `feat(ui): add PopBottomNav with a growable chip and a wrapping label`

---

### T05.10 — The mirroring proof: one table, everything that flips and everything that must not
**Goal.** Collect every directional decision made across T05.3–T05.9 into one table-driven test, so a
future change cannot quietly flip something that must not flip, or un-flip something that must.

**Tests first (TDD).** This task is tests; the only production change is whatever they red.
`test/ui/components/mirroring_test.dart`:
- One `testWidgets` per row of a `const List<MirrorCase>` naming the widget, the probe and the
  expectation. **Mirrors:** `PopButton`'s leading glyph, `PopIconButton`'s `back` chevron, `PopChip`'s
  glyph, `PopCard`'s directional padding, `GameCard`'s artwork quad, `DifficultySegmented`'s item
  order, `HudPill`'s label/value order, `PopProgressBar`'s fill origin, `PopBottomNav`'s destination
  order, `SunburstGlyphIcon(back)`, `SunburstGlyphIcon(chevronForward)`, `SunburstGlyphIcon(sound)`.
  **Does not mirror:** every `PopSurface` hard shadow at e1–e4, the press travel sign, the selected
  segment's `(−1,−1)` lift, `TimerRing`'s sweep direction, `PopProgressBar`'s 45° stripe angle,
  `DashedInkBorder`'s dash phase, `PopBadge`'s −2.5° tilt, `PopGridTile`'s centred glyph,
  `PopSheet`'s vertical action order, `PopBottomNav`'s top-only border, and the twelve non-directional
  glyphs from T05.4's table.
- Each mirroring case is proved by a geometry probe (`getRect` under `en` vs `fa`), not by a golden —
  a golden cannot say *why* it changed. Each non-mirroring case is proved by an equality assertion on
  the rendered value (offset, angle, sign) so the failure message names the property.
- `'the table covers every component in the catalog'` — asserts the case list mentions all fourteen
  class names plus `SunburstGlyphIcon`; a fifteenth component added without a row fails here.
- `'no widget in lib/ui reads Directionality except the four that are allowed to'` — a source scan
  asserting `Directionality.of` appears only in `sunburst_glyph.dart` (the manual flip),
  `pop_progress_bar.dart` (the fill origin fed into the scene) and nowhere else. Every other component
  mirrors by construction, and a fifth reader is a sign someone is patching direction instead of
  authoring it.

**Implementation.** Fix whatever the table reds. Expected candidates: a `Row` whose children were
ordered for LTR, an `Offset` sign derived from direction where it should not be, a painter that read
`Directionality` when its scene should have carried the value.

**Files.** `test/ui/components/mirroring_test.dart`, plus any component files it reds.

**Skills.** `i18n-rtl-l10n`, `custom-canvas-and-gestures`, `widget-golden-and-a11y-testing`,
`sunburst-components`, `dart3-idioms-and-coding-standards`.

**Screenshot check.** n/a (geometry assertions, no new image). The visual counterpart is the `fa`
contact sheet in T05.11.

**Done when.**
- [ ] Every row of the table green; the coverage assertion names all fourteen components.
- [ ] `Directionality.of` appears in at most two files under `lib/ui/`.
- [ ] `check_i18n_bans.sh lib` green.

**Commits.**
1. `test(ui): add the mirroring table covering every component and glyph`
2. `fix(ui): correct the directional geometry the table found` (only if it finds any)

---

### T05.11 — The locale matrix sweep, the greyscale proof and the four contact sheets
**Goal.** Prove the whole catalog survives locale, text scale, width, bold and greyscale together;
produce the four images the design comparison is done against; and put Arabic-script shaping in front
of a human on the canonical simulator, because the host golden lane cannot prove it.

**Tests first (TDD).** This task is tests; the only production change is whatever they red.
`test/ui/components/overflow_matrix_test.dart`:
- One `testWidgets` per `(locale, Device, textScale, bold)` tuple — 4 × 4 × 3 × 2 = **96**, up from the
  24 an English-only catalog needed — never a loop inside a test, because overflow is reported once per
  `RenderObject` and a loop silently under-reports every scale after the first. Locales are
  `en`, `de`, `fa`, `ckb`; widths are `Device.all`; scales are 1.0 / 1.3 / 2.0;
  `setUpAll(loadAppFonts)` so the bold, width and shaping axes are not inert under Ahem.
- Each pumps a column of all fourteen components fed from `sampleStrings[locale]` and asserts
  `tester.takeException()` is null **and** a fit assertion per label: `getRect(text)` is contained by
  `getRect(its surface)`. The fit assertion is the real gate — a clipped `Text` reports nothing.
- No `FittedBox`, no `TextOverflow.ellipsis`, no `withClampedTextScaling` may be used to green a red
  tuple; the fix is the layout, or a smaller BASE style requested from E03.
`test/ui/components/greyscale_matrix_test.dart`:
- One test per component: renders its full state matrix under `Greyscale` at `Locale('en')` and asserts
  the golden; plus a pixel-difference assertion that no two states within one component produce the
  same image. `en` only, deliberately: state collision is a hue property and does not vary by script,
  and four copies of this lane would quadruple the blessing cost while proving nothing new.
`test/ui/components/a11y_matrix_test.dart`:
- A `getSize` loop over every interactive component asserting ≥ 48 on both axes, run at all four
  locales — a German label that wraps to two lines changes a height, and a height is a tap target.
- An `isSemantics` assertion per interactive component for role, label, enabled and selected.
- `'no semantics label anywhere in the catalog contains a bidi isolate'` — the T05.6 assertion promoted
  to a sweep over every component.
- `await expectLater(tester, meetsGuideline(androidTapTargetGuideline))` kept only as an advisory
  tripwire, never as the gate.
`test/ui/components/catalog_contact_sheet_test.dart` (`@Tags(['golden'])`):
- Renders the fourteen components in catalog order at `Device.reference390` on `surface` into
  `goldens/en/catalog_contact_sheet.png`, `goldens/de/…`, `goldens/fa/…` and `goldens/ckb/…` — the
  real-font lane, the four images the gallery comparison uses. The `ckb` sheet exists for one reason:
  it is where a missing Sorani glyph (`ڕ ڵ ۆ ێ ھ`) is visible as a box to a human, which T05.2's width
  probe can only suggest.

**Implementation.** Fix whatever the matrix reds. Expected candidates, in rough order of likelihood:
the segmented control's three German labels at scale 2.0 on 320 (T05.6's column fallback should already
hold it); the nav label at 11.5 with `boldText` in `de`; the HUD pill row with a four-digit Persian
score at 1.3; the toggle word in `ckb` (Sorani `چالاک`/`ناچالاک` is longer than Persian). Fixes are
layout changes (wrap, `Flexible`, taller rows, the measured track from T05.8) or a smaller base type
step in `lib/theme/` — never clamps.

Also `tool/gallery_main.dart`: a dev-only entry point, not imported by `lib/main.dart` and not part of
any shipped route, that renders the same fourteen components in a scrollable column with a four-way
locale switcher and a text-scale slider. It exists because a golden blessed on macOS proves the glyph
*table* was consulted, not that iOS CoreText joins Arabic letters correctly at 11.5pt inside an 88px
chip. Run it with:

```bash
xcrun simctl boot C13DDC02-375D-4E1B-8F81-44EB407D09A4
flutter run -d C13DDC02-375D-4E1B-8F81-44EB407D09A4 -t tool/gallery_main.dart
```

**Files.** `test/ui/components/overflow_matrix_test.dart`,
`test/ui/components/greyscale_matrix_test.dart`, `test/ui/components/a11y_matrix_test.dart`,
`test/ui/components/catalog_contact_sheet_test.dart`,
`test/ui/components/goldens/{en,de,fa,ckb}/catalog_contact_sheet.png`, `tool/gallery_main.dart`, plus
any component files the matrix reds.

**Skills.** `widget-golden-and-a11y-testing`, `i18n-rtl-l10n`, `accessibility-as-code`,
`adaptive-layout`, `sunburst-components`.

**Screenshot check.** `goldens/en/catalog_contact_sheet.png` beside `design/sunburst-pop/system.html`
§10 *Components*, rendered in a browser at a 390px viewport; then `goldens/fa/catalog_contact_sheet.png`
beside the same page with `dir="rtl" lang="fa"` on `<html>`. Compare structure → spacing rhythm →
surface construction → type role → sampled hex, component by component, and record the result in the
PR body naming which §10 entries were compared in which direction. The `de` and `ckb` sheets have no
browser counterpart and are reviewed on their own terms: `de` for fit, `ckb` for glyph coverage and
letter joining. Explicitly **not** compared against `design/sunburst-pop/screens/*.png` or
`design/sunburst-pop/screens/rtl/*.png`; those are E08's targets. The on-simulator pass on
`MindForge iPhone 14` is recorded in the PR as a sentence per locale, and any Sorani letter that
renders as a box is a BLOCKER that goes back to E04's font decision, not a note.

**Done when.**
- [ ] 96 overflow tuples green, each with a fit assertion; nothing suppressed anywhere in `test/`.
- [ ] Every interactive component measured ≥ 48 by an explicit `getSize` loop, in all four locales.
- [ ] No two states of any component collide in greyscale.
- [ ] Four contact sheets committed; the `ckb` one shows no notdef boxes.
- [ ] `tool/gallery_main.dart` runs on `C13DDC02-375D-4E1B-8F81-44EB407D09A4` and the four locales were
      viewed on it.
- [ ] `check-test-hygiene.sh lib test` and `check_test_hygiene.sh lib test` green.
- [ ] The §10 comparison, both directions, is written into the PR body.

**Commits.**
1. `test(ui): expand the overflow and fit matrix to four locales`
2. `fix(ui): resolve the overflows the matrix found` (only if it finds any)
3. `test(ui): add the greyscale state-collision proof`
4. `test(ui): add the a11y target, semantics and bidi-isolate matrix`
5. `test(ui): add the four catalog contact sheets`
6. `chore(tool): add the dev-only component gallery entry point`

## Gates that must pass

Run from the repo root, in this order, before every commit and again before the PR.

```bash
dart format --set-exit-if-changed .
flutter gen-l10n
flutter analyze --fatal-infos --fatal-warnings
flutter test
flutter test --tags golden          # verify only; never --update-goldens

.claude/skills/sunburst-components/scripts/check_component_hygiene.sh      lib
.claude/skills/sunburst-tokens/scripts/check_raw_values.sh                 lib
.claude/skills/sunburst-tokens/scripts/check_palette_contrast.sh           lib/theme/sunburst_colors.dart
.claude/skills/sunburst-motion-and-haptics/scripts/check_motion_tokens.sh  lib
.claude/skills/sunburst-shell-screens/scripts/check_shell_boundaries.sh    lib
.claude/skills/sunburst-game-surfaces/scripts/check_game_palette.sh        lib
.claude/skills/custom-canvas-and-gestures/scripts/check_painter_hygiene.sh lib
.claude/skills/widget-composition/scripts/check-widget-composition.sh      lib
.claude/skills/dart3-idioms-and-coding-standards/scripts/check-dart3-idioms.sh lib
.claude/skills/adaptive-layout/scripts/check_adaptive.sh                   lib
.claude/skills/i18n-rtl-l10n/scripts/check_i18n_bans.sh                    lib
.claude/skills/i18n-rtl-l10n/scripts/check_arb_parity.sh                   lib/l10n
.claude/skills/flutter-architecture/scripts/check_architecture.sh          lib
.claude/skills/project-structure-and-packages/scripts/check_import_boundaries.sh lib
.claude/skills/state-management-riverpod/scripts/ban-legacy-providers.sh   lib
.claude/skills/widget-golden-and-a11y-testing/scripts/check-test-hygiene.sh lib test
.claude/skills/testing-strategy/scripts/check_test_hygiene.sh              lib test
```

`check_i18n_bans.sh` and `check_arb_parity.sh` are new to this epic's list and both are now meaningful:
the first has real component geometry to scan, and the second has E04's three sibling ARBs to compare
against the template (it exits 2 with "no locale ARB files" when there is only one, which is why
earlier epics skipped it). This epic adds no ARB keys; it runs parity to prove it did not disturb them.

Plus the review greps this epic is responsible for:

```bash
grep -rn "Icons\.\|IconData\|ElevatedButton\|FilledButton\|TextButton\|Material(elevation" lib/   # must be empty
grep -rn "Opacity(\|ClipRRect\|FittedBox\|withClampedTextScaling\|TextOverflow" lib/ui/           # must be empty
grep -rn "EdgeInsets\.only(\|Alignment\.center\(Left\|Right\)\|TextAlign\.\(left\|right\)" lib/ui/ # must be empty
grep -rn "NumberFormat\|DateFormat" lib/ui/                                                        # must be empty
grep -rn "Directionality(" test/                                                                   # must be empty
grep -rn "chevronRight" .                                                                          # must be empty
```

The last two are specific to the localization delta. A `Directionality` wrapper in a test is the
standard way to fake RTL without wiring a locale — it renders English text right-to-left, proves
nothing about fonts, numerals or shaping, and makes a green suite that hides every real bug. The
harness resolves direction from the locale (T05.2) and there is no reason for any test to build one by
hand.

The block above is this epic's **named spot-checks**. The authoritative sweep — locally and in CI — is
the one runner E01 T01.11 built:

```bash
bash tool/skill_gates.sh
```

Never `for s in .claude/skills/*/scripts/*.sh; do bash "$s"; done`: 29 of the 49 scripts fail
argument-less and five can never pass that way, so the loop is a broken gate, not a stricter one.

## Risks and open questions

1. **`PressPhysics` belongs to E06 but E05 cannot ship without it.** `sunburst-motion-and-haptics`
   owns the press *controller*; `sunburst-components` owns the *chrome*, and rule 2 of both skills
   forbids a second press implementation. **Decision (this epic):** T05.3 creates
   `lib/shared/motion/press_physics.dart`, `lib/shared/feedback/moment.dart` (the enum only) and
   `lib/shared/feedback/feedback_service.dart` (the interface plus a `SilentFeedbackService` no-op).
   E06 supplies the real `HapticGateway`-backed implementation, the moment → haptic map, the latches
   and the sound slots, and **must not create a second press controller**. Stated in the PR body so
   E06's author inherits the constraint.
2. **Sorani glyph coverage is not verified and this epic cannot verify it alone.** E04 decides the
   Arabic-script faces: Vazirmatn for body (full Persian + Sorani coverage), and Lalezar for display
   *if* it covers `ڕ ڵ ۆ ێ ھ`, else Vazirmatn Bold. E05 consumes whatever E04 landed and has two
   detectors: T05.2's `U+FFFF`-width probe, which is a heuristic, and T05.11's `ckb` contact sheet,
   which is a human looking at boxes. **A missing Sorani glyph found here is an E04 defect, not an E05
   workaround** — do not swap a font inside `lib/ui/`. **Ask:** repo owner, if the display face has to
   fall back and the Sorani UI therefore loses the chunky-display voice entirely.
3. **The Fredoka personality does not survive translation, and this epic is where that becomes
   visible.** No Latin display face covers Arabic script, so in `fa` and `ckb` the wordmark voice is
   gone. What carries the identity there is the SHAPE language — the 3px ink border, the hard offset
   shadow, the press-down, the radius scale and the palette — every one of which this epic implements
   identically in all four locales. The `fa` and `ckb` contact sheets will not look like the `en` one
   at the type level and that is not a bug to fix; it is the honest consequence of shipping Arabic
   script, and the PR body should say so rather than letting a reviewer file it as a defect.
4. **`ckb` may have no `GlobalMaterialLocalizations` delegate.** E04 owns the custom delegate that
   serves our ARB strings for `ckb` while delegating Material/Cupertino strings to `fa` (else `ar`),
   and owns verifying the actual delegate list rather than assuming it. E05's exposure is that
   `pumpPopComponent(locale: Locale('ckb'))` is called by roughly a third of the tests in this epic; if
   the delegate is missing or wrong, every one of them throws at resolution. T05.2's
   `'pumping every supported locale does not throw'` is the canary that isolates the failure to one
   named test instead of ninety-six. Likewise `intl`'s number-symbol data for `ckb`: `NumberFormat` has
   no `ckb` symbols and falls back to Latin silently, which is why E04 pins `ckb` to the `fa`
   formatter — E05 never calls `NumberFormat` and so cannot re-introduce the bug, but its specimen
   strings hardcode the Eastern Arabic digits that pinning is supposed to produce, and if E04's pin is
   wrong the shell will disagree with these goldens in E08.
5. **Translation quality is not verified and must not be presented as done.** `sampleStrings` are
   length-and-script specimens, explicitly not translations, and the real ARB copy is E04's. Nothing in
   this epic constitutes review of Persian or Sorani wording. Machine-quality Sorani in particular is a
   real risk; a native speaker has to read the shipped strings before release, and that review belongs
   to E11's sweep. **Ask:** repo owner, for a native `fa` and `ckb` reviewer.
6. **`HudTone` has no home that satisfies both skills.** `sunburst-components` says the enum is
   "declared by `sunburst-shell-screens`", but `lib/ui/` may not import `lib/features/`, and E07's
   `BoardSnapshot`/`GameHud` contract needs the same enum on the domain side — a game
   (`lib/games/**`) sets a tone, and the pill (`lib/ui/**`) renders it. Declaring it in either place
   forces the other to declare its own, and two same-named enums never unify.
   **Decision:** declare it once in **`lib/core/hud_tone.dart`** (T05.1), beside `ScoreFormat` and the
   other pure vocabulary. `lib/core/` is the only layer both `lib/ui/` and `lib/features/` may import
   under the downward-only DAG, and `check_import_boundaries.sh` keeps it Flutter-free — an enum
   qualifies. E07 T07.4 imports it rather than redeclaring it; the shell still owns *which* tone is
   chosen when, which is the part that actually belongs to E08.
7. **`GridTile` collides with `package:flutter/material.dart`.** Material exports a `GridTile`
   widget, so a file importing both material and the catalog gets an ambiguous-import error on every
   use. **Decision:** ship it as `PopGridTile` in `lib/ui/components/pop_grid_tile.dart`, consistent
   with the eleven other `Pop*` names, and record the one-line deviation from
   `references/component-catalog.md` in the PR. Fallback if the owner prefers the catalog name
   verbatim: keep `GridTile` and require every consumer to write
   `import 'package:flutter/material.dart' hide GridTile;`, which is one forgotten import away from a
   confusing error in E10. **Ask:** repo owner.
8. **`type.buttonLarge` and `type.chip` are an eleventh and twelfth type step, and `sunburst-tokens`
   rule 10 says "ten type steps, no eleventh".** `sunburst-components` requests both as derived
   slots. **Decision:** add them, because both are rendered specimens (`.btn--lg{font-size:21px}` and
   `.chip{14}`), and rule 12 of the same skill supplies the procedure for a new slot. Mark both
   `DERIVED` with the evidence and update `sunburst-tokens/references/shape-and-type.md` in the same
   PR so the two skills stop disagreeing. A related, unresolved question: if T05.11's matrix cannot fit
   a label in `de` or `ckb` without a smaller base step, the honest fix is a **thirteenth** step (or a
   per-locale resolution of an existing one), which is an E03 change, not an E05 one. **Ask:** repo
   owner, if rule 10's wording should be amended rather than the exception documented twice.
9. **Fonts.** The golden lanes assume Fredoka and Nunito are bundled by **E01 T01.7** and the
   Arabic-script faces by **E03 T03.7** (`check_font_bundling.sh`). If any are missing, `loadAppFonts()`
   falls back to Ahem, the bold, width and shaping axes go inert, and every type-role comparison
   against the gallery is meaningless — and the `fa`/`ckb` goldens become fields of identical boxes
   that match themselves forever. T05.2's two `loadAppFonts` tests fail loudly rather than letting the
   epic proceed. **`test/support/load_app_fonts.dart` and `dart_test.yaml` are E03 T03.7's files**, not
   this epic's: E03 T03.9 ships the repo's first golden and needs real faces to measure Arabic metrics
   at all. This epic and E07–E10 import them.
10. **The real-font golden lane is host-sensitive, and Arabic script makes it more so.** Goldens must
    be blessed in one pinned environment or CI reds on font rasterization differences; complex-script
    shaping (letter joining, contextual forms, mark positioning) is more sensitive to the shaping
    engine version than Latin is. E01 pins the runner; this epic blesses on that same toolchain
    (Flutter 3.44.6 / Dart 3.12.2) and never passes `--update-goldens` in CI. The host lane still
    cannot prove iOS CoreText renders the same joins, which is why `tool/gallery_main.dart` exists and
    why the simulator pass is a named deliverable rather than an optional nicety.
11. **The RTL gallery comparison is manual and less repeatable than the LTR one.**
    `capture-screens.sh` renders `app.html` figures only — E04 extended it to produce the RTL screen
    set, but there is still no §10 gallery capture in either direction. The four contact-sheet goldens
    give us stable Flutter-side images; the browser side is a person with devtools and a `dir`
    attribute. Accepted for this epic; if the drift becomes real, the honest fix is to add a
    `system.html` §10 target (LTR and RTL) to `capture-screens.sh` — a design-tooling change, out of
    scope here.
12. **Vazirmatn's tabular figures are unverified.** `sunburst-tokens` rule 10 puts
    `FontFeature.tabularFigures()` on `numericHud`/`scoreHero` so an HUD does not jitter every second.
    Whether Vazirmatn ships `tnum` for `U+06F0`–`U+06F9` is a font question nobody has answered.
    T05.7's per-locale no-reflow test answers it empirically, and `_TabularSlot` is the named fallback.
    Recorded here because "the HUD is stable" is a claim that has only been tested in Latin.
13. **The toggle track and the nav chip both deviate from `system.html`'s fixed pixel widths in
    non-`en` locales.** 66×34 and 88 wide are transcribed specimens measured from an English mockup;
    a printed Persian word does not fit either. **Decision:** both become minimums with content-driven
    growth (T05.8, T05.9), the `en` rendering is unchanged and still matches the reference, and the
    deviation is recorded in the PR. The alternative — dropping the printed ON/OFF word in RTL locales
    — was rejected: the word is the non-colour channel that `accessibility-as-code` rule 6 requires,
    and removing it in exactly the locales with the least design attention is the wrong trade.
14. **`go` may need to mirror after all.** T05.4 classifies the filled play triangle as a fixed-meaning
    mark that does not mirror, on the authority of `i18n-rtl-l10n`'s "never mirror media play". But
    `go` is spent as a *start / proceed* affordance on the home CTA, not as a media transport control,
    and RTL UI convention for a proceed arrow is to mirror. **Decision for this epic:** do not mirror,
    because the artwork is a play triangle and consistency with the tab-bar play mark matters more than
    the abstract reading. **Ask:** the native `fa`/`ckb` reviewer in E11 — it is a one-line change to
    `mirrorsInRtl` plus one golden, and it is exactly the kind of judgement that should be made by
    someone who uses an RTL phone.
15. **`PopGridTile` must not be built twice.** E05 ships it with the five Schulte states and a public
    pure resolver; E10 is its only consumer. If E10 instead composes `PopSurface` with its own
    `schulte_tile_visual.dart`, the catalog carries a fourteenth class nothing uses and the greyscale
    state-collision proof exists in two places that can disagree. **Decision:** E10 T10.5 composes
    `PopGridTile` and maps its state enum 1:1; the deviation, if E10's author disagrees, is an E05
    change (drop the class from the catalog and the contact sheets), never a silent second tile.
16. **96 matrix tuples is a real runtime cost.** Four times the tuples of the English-only design, each
    pumping fourteen components with real fonts loaded. If the sweep becomes the slowest thing in CI,
    the honest trims are (a) drop the `bold` axis for `fa`/`ckb`, where `boldText` affects advance
    widths least, taking it to 72, or (b) move the whole matrix behind the `golden` tag and run it on
    PR label plus nightly. Do **not** trim the locale axis — that is the axis this epic exists for.

## Definition of done

- [ ] Branch `epic/05-component-library` cut from `main`, all commits granular, tests committed with
      the code they cover.
- [ ] Fourteen catalog classes in `lib/ui/components/` plus `dashed_ink_border.dart`; seventeen
      glyphs in `lib/ui/glyphs/`. Every raised surface renders through `PopSurface`; no second
      `BoxDecoration` carrying border + shadow exists outside `pop_surface.dart`.
- [ ] Every component's geometry is directional: `PopSurface.padding` is `EdgeInsetsDirectional`,
      `radius` is `BorderRadiusDirectional`, and `check_i18n_bans.sh lib` is green over real code.
- [ ] Every component has: a golden per applicable state in `en` and `fa`, a `de` rest golden if it
      bears text, a greyscale matrix golden with no two states colliding, and — if interactive — a
      tap-target and `Semantics` test at all four locales.
- [ ] The mirroring table (T05.10) covers all fourteen components plus the seventeen glyphs, and
      asserts both what flips and what must not — the hard offset shadow, the press travel sign, the
      timer sweep, the stripe angle and the badge tilt among the latter.
- [ ] Numeral-bearing components render Eastern Arabic digits with no notdef box, no reflow on a digit
      change and no clipping at text scale 2.0; no component calls `NumberFormat`.
- [ ] The 96-tuple overflow-and-fit matrix is green with nothing suppressed, nothing shrunk and no
      ellipsis on a value.
- [ ] `check_component_hygiene.sh lib` green **over real code**, alongside every other gate listed
      above.
- [ ] `goldens/en/catalog_contact_sheet.png` compared against `system.html` §10 in a browser and
      `goldens/fa/catalog_contact_sheet.png` against the same page under `dir="rtl"`, in the order
      structure → spacing rhythm → surface construction → type role → sampled hex; both results and the
      §10 entries compared are written into the PR body. The `de` and `ckb` sheets reviewed for fit and
      for Sorani glyph coverage. Any reference change went into `system.html`/`app.html` with
      `capture-screens.sh` re-run and committed as a deliberate design change.
- [ ] `tool/gallery_main.dart` run on `MindForge iPhone 14`
      (`C13DDC02-375D-4E1B-8F81-44EB407D09A4`, iOS 18.6, 390×844) in all four locales, and the
      Arabic-script letter joining confirmed by eye. Android is not built, not tested and not claimed.
- [ ] `/simplify` run and its findings addressed.
- [ ] `/code-review` run and its findings addressed.
- [ ] `test/support/harness.dart` is extended, not forked: no `PopWidth`, no second `Device`, no second
      `pumpApp`, no second locale list. `sampleStrings` and `FakeFeedbackService` are this epic's and
      no later epic re-creates them; `loadAppFonts()` and `dart_test.yaml`'s `golden` tag are **E03
      T03.7's**, imported here. E04's `supportedLocales`, `LocaleNumbers`, `AsciiNumerals`, `Bidi`,
      `LocaleCase.all` and `pumpLocalized` are imported, never redeclared.
- [ ] `HudTone` exists once, in **E02's** `lib/core/hud_tone.dart`; this epic declared no enum there.
- [ ] `dart format --set-exit-if-changed .`, `flutter gen-l10n`, `flutter analyze --fatal-infos`,
      `flutter test` and `bash tool/skill_gates.sh` green locally.
- [ ] PR opened explaining what changed, why, how it was verified, which gallery entries were compared
      in which direction, the `PopGridTile` naming deviation, the toggle-track and nav-chip
      derivations, whether `_TabularSlot` was needed, and what was deliberately left out (motion timing
      → E06, screens → E08, board semantics → E09/E10, translation review → E11).
- [ ] CI green on the PR.
- [ ] Merged preserving the granular commits, branch deleted, back on `main`, pulled.
