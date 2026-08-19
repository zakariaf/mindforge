> **SUPERSEDED — do not build from this file.** It plans the old ten-epic sequence, written
> before the four-locale/two-direction and iOS-only requirements landed. It is superseded by
> [`../E05-component-library.md`](../E05-component-library.md) — **E05 · Component library**. Kept for the record only; the live set is the
> eleven files in `epics/`, indexed by [`../README.md`](../README.md).

# E03 · Component library

| | |
|---|---|
| **Branch** | `epic/03-component-library` |
| **Depends on** | E01, E02 |
| **Unblocks** | E04, E06, E07, E08, E09 |
| **Status** | Not started |

## The epic

Build `lib/ui/components/` and `lib/ui/glyphs/`: the fourteen-class Sunburst Pop catalog, all of it
composed from one primitive, plus the drawn icon set. `PopSurface` comes first — fill, a 3px
`colors.border` edge, one hard offset shadow at `blurRadius`/`spreadRadius` 0, the press translate
toward that shadow while a 48px hit area holds still, the disabled resolution that stays inside the
palette, and a 4px `focusRing` stroke outside a 3px `surface` gap. Then the catalog on top of it:
`PopButton`, `PopIconButton`, `PopChip`, `PopCard`, `GameCard`, `DifficultySegmented`, `HudPill`,
`TimerRing`, `PopProgressBar`, `PopGridTile`, `PopToggle`, `PopBadge`, `PopSheet`, `PopBottomNav`.
`lib/ui/glyphs/` supplies the seventeen inline stroke glyphs at the two weights the design uses —
2.6 at 22pt, 3.0 at 18–20pt — painted on canvas: no emoji, no icon font, no `IconData`.

Verification is where this epic earns its keep. Every component ships golden tests per state
(rest / pressed / disabled / selected / focused) through one shared harness, an a11y test per
interactive component (tap target ≥ 48 measured with `getSize`, `Semantics` role and label asserted
with `isSemantics`), an overflow-and-fit matrix at text scale 1.0 / 1.3 / 2.0 across widths
320 / 360 / 390 / 430, and a greyscale golden of the full state matrix proving no state is carried by
hue alone. The epic ends with `check_component_hygiene.sh` green over real code rather than over an
empty tree.

## Why we need it

E07, E08 and E09 all assume a catalog exists. Without it every screen invents its own
`BoxDecoration` with a border and a shadow, and the Sunburst contract — one fill, one 3px ink edge,
one hard shadow, one press law — stops being true within a sprint. `sunburst-components` rule 1 and
rule 11 exist precisely because thirteen hand-rolled copies of one decoration drift, and the
fourteenth reads as generic Material.

Concretely, without E03:

- `check_component_hygiene.sh` passes today only because `lib/` does not exist. It has never run over
  a single line of real code, so it is not yet evidence of anything.
- There is no press implementation, so E04 would have nothing to time and every screen in E07 would
  grow its own `GestureDetector` + `Transform` — the exact pairing that moves the hit area under the
  finger and eats taps.
- There is no glyph set, so the first screen that needs a back arrow reaches for `Icons.arrow_back`,
  and a Material icon font on a hand-drawn cream surface is visible from across the room.
- There is no component harness, so a11y, text-scale and greyscale checks would be re-invented per
  screen, unevenly, and the never-colour-alone rule would go unverified.

## Current state

Verified by `ls` at the time of writing:

- **No Flutter app.** No `pubspec.yaml`, no `lib/`, no `test/`, no `.github/`. Four commits on
  `main` (`cb1c3e2` is the head); the working tree holds `CLAUDE.md`, `design/`,
  `50-apps-challenge-slides.html` and `.claude/`.
- `.claude/skills/` — 45 skills. The ones this epic lives inside are `sunburst-components`
  (SKILL.md + `references/component-catalog.md`, `references/surface-and-press.md`,
  `references/states-and-affordance.md` + `templates/component_template.dart` +
  `examples/pop_surface.dart`, `examples/pop_button.dart`, `examples/game_card.dart` +
  `scripts/check_component_hygiene.sh`) and `widget-golden-and-a11y-testing`
  (`examples/harness.dart`, `examples/overflow_matrix_test.dart`, `examples/a11y_test.dart`).
- `design/sunburst-pop/system.html` — the authority for this epic. §07 Elevation, §08 Iconography
  (three subsections: *22px · stroke 2.6*, *18–20px · stroke 3*, *Badge glyphs*), §10 Components
  (fourteen named `<h3 class="sub">` gallery entries), §11 Accessibility.
- `design/sunburst-pop/app.html` — component geometry as actually shipped; wins over §10 on geometry.
- `design/sunburst-pop/screens/*.png` — the eight screen targets. **This epic does not compare against
  them**; see the screenshot rule under *What we will achieve*.
- `.claude/skills/sunburst-tokens/examples/sunburst_theme.dart` — the worked theme E02 transcribes.
  Checked field by field: it ships `stripePitch` 9 and `stripeAngle` 45, and it does **not** ship
  `eChip`, `borderWidthNested`, `dashOn`, `dashOff`, `type.buttonLarge` or `type.chip`. Those are the
  derived slots `sunburst-components` requests, and this epic must add them (T03.1).

Assumed present from E02 and asserted by T03.1's first test: `lib/theme/sunburst_colors.dart`,
`sunburst_shape.dart`, `sunburst_motion.dart`, `sunburst_type.dart`, `sunburst_primitives.dart` and
`buildSunburstTheme()`, each with an asserting `of(context)`; plus `test/support/harness.dart` with
`Device`, `Device.all` (four presets at DPR 2) and `pumpApp`. From E01: the four bundled `.ttf` faces
under `assets/fonts/` — without them `loadAppFonts()` silently falls back to Ahem and every real-font
golden in this epic is a lie (see Risk 8).

## What we will achieve

**The screenshot rule, as it applies to this epic.** The comparison target is the component gallery in
`design/sunburst-pop/system.html`, rendered in a browser — **not** the eight PNGs in
`design/sunburst-pop/screens/`. Those PNGs are whole screens; they are E07's targets and no task here
compares against them. `capture-screens.sh` renders `app.html`'s eight `<figure>` elements only and
produces no gallery image, so the gallery comparison is manual: open `system.html`, screenshot the named
`<h3>` subsection, and put the component's real-font golden beside it. E04's component comparisons
follow the same policy for the same reason. Compare in the project's fixed order, every time:
**structure → spacing rhythm → surface construction (3px ink edge, correct hard-shadow step, blur 0) →
type role → sampled hex.** A difference is an implementation defect. If the reference is genuinely
wrong, the change goes into `system.html` (and, where geometry is at stake, `app.html` +
`./capture-screens.sh`) and is committed as a deliberate design change with the token values updated to
match and `check_palette_contrast.sh` re-run — never a silent divergence. Golden images and browser
screenshots capture **end states only**: the press travel, the release, the 120ms `durTap` tween and
every haptic are asserted by widget tests here and re-verified on a device in E04 and E10.

A reader can tell this epic is done by running the checks below.

- `lib/ui/components/` holds fifteen files (fourteen catalog classes plus `dashed_ink_border.dart`)
  and `lib/ui/glyphs/` holds the seventeen-glyph set. No other directory in `lib/` contains a
  `BoxDecoration` that carries both a border and a shadow.
- `.claude/skills/sunburst-components/scripts/check_component_hygiene.sh lib` prints
  `OK: hard shadows only, ink borders only, no Material elevation, no raw press timing.` **over real
  code** — the first time that sentence means anything.
- `flutter test` is green, including: one golden per component per applicable state, one greyscale
  golden of each component's full state matrix, one a11y test per interactive component, and the
  overflow-and-fit matrix (4 widths × 3 text scales × 2 bold settings, one `testWidgets` per tuple).
- `flutter test --tags golden` regenerates nothing: the committed goldens under
  `test/ui/components/goldens/` and `test/ui/glyphs/goldens/` match.
- Opening `design/sunburst-pop/system.html` §10 beside `test/ui/components/goldens/catalog_contact_sheet.png`
  shows the same fourteen components in the same construction: 3px ink edge, hard shadow at the right
  step, no blur, correct radius, correct type role.
- A human can grep and find zero `Icons.`, zero `IconData`, zero emoji, zero
  `ElevatedButton`/`FilledButton`/`TextButton`/`Card(`/`Material(elevation:` under `lib/ui/`.
- The PR is merged to `main`, CI (created in E01) green on it.

## Skills to load

| Skill | Why, for this epic |
|---|---|
| `flutter-conventions-index` | The front door and the routing table; open first for anything the table below does not obviously cover. |
| `sunburst-components` | The contract this epic *is*: `PopSurface`, `PopElevation`, `kPopMinTarget`, the press chrome, the fourteen-class catalog, the five derived slots, the state matrix and the ≥48px floor. Read all three `references/` files and the three `examples/`. |
| `sunburst-tokens` | Every value a component reads is a slot on `SunburstColors`/`SunburstShape`/`SunburstMotion`/`SunburstType`; T03.1 adds slots by its four-places-plus-the-gate procedure (`references/adding-a-token.md`). |
| `sunburst-motion-and-haptics` | Owns `PressPhysics`/`PressGeometry`/`PressBuilder` — the one press controller `PopSurface` composes — the `Moment` catalog, and the reduce-motion split (transform dropped, pressed shadow kept). Its `examples/press_physics.dart` is the seam T03.3 builds. |
| `sunburst-shell-screens` | Declares that `SunburstGlyph` in `lib/ui/glyphs/` is shell-owned and lists the catalog E07 will compose; T03.4 must match the names its `examples/home_screen.dart` and `examples/play_scaffold.dart` already call. |
| `widget-golden-and-a11y-testing` | The harness rules T03.2 implements: pin `physicalSize = logical × dpr`, `MediaQuery` above `MaterialApp` built from `.copyWith`, one `testWidgets` per (width, scale, bold) tuple, `isSemantics`, explicit `getSize` tap-target loops, two golden lanes with `loadAppFonts`, never suppress overflow. |
| `accessibility-as-code` | Authoring side of the same floor: `Semantics(button:, label:)` on every interactive node, `ExcludeSemantics` on decorative art, never colour alone, never `FittedBox`/`ellipsis`/clamped `TextScaler` to make a label fit, honour `boldText`. |
| `widget-composition` | Const widget classes never `Widget _buildX()`, one responsibility per widget, `StatelessWidget` by default, dispose every controller, `EdgeInsetsDirectional` only, `build()` ≤ 80 lines / widget nesting ≤ 5. |
| `custom-canvas-and-gestures` | Four painters live here — the focus ring, `DashedInkBorder`, `TimerRing`'s sweep, `PopProgressBar`'s stripe — plus every glyph. Enforces the View/Painter/Scene split, `shouldRepaint` as one value compare, zero allocation in `paint()`, `ExcludeSemantics` over drawn pixels. |
| `dart3-idioms-and-coding-standards` | `enum` vs `sealed` for the variant sets (`PopElevation`, `PopButtonVariant`, `PopGridTileState`, `HudTone`, `PopBadgeVariant`), exhaustive `switch` with no `default:`, `@immutable` scene types, and the complexity limits every other skill cites. |
| `naming-conventions` | File = primary declaration, `lowercase_with_underscores` files, booleans as `is`/`has`/`can`, no `get`-prefixed accessors, grouped-and-sorted imports. |
| `dartdoc-conventions` | `lib/ui/components/` is a public surface consumed by three later epics: `///` on every public class, constructor and field, never a restatement of the name, `[bracket]` cross-links. `public_member_api_docs` is an analyzer error. |
| `testing-strategy` | Fakes over mocks for the `FeedbackService` seam T03.3 introduces, and the doctrine that anything expressible as `f(input) -> output` (press geometry, glyph stroke selection) is a unit test, not a `pumpWidget`. |
| `i18n-rtl-l10n` | A component never touches `AppLocalizations` — labels arrive as already-localized `String`s — and all geometry is `EdgeInsetsDirectional`/`AlignmentDirectional` so the catalog mirrors by construction. `PopToggle`'s printed ON/OFF word is the one string a component renders, and it arrives from the caller. |
| `adaptive-layout` | The width axis of the matrix and the one size that genuinely adapts: the grid tile is 64 and drops to 60 at the smallest width, decided from constraints via `LayoutBuilder`, never from a device check. |

## Tasks

### T03.1 — Derived and transcribed token slots the catalog needs
**Goal.** Add the six slots `sunburst-components` requests plus the two glyph stroke widths to
`lib/theme/`, so no component ever types a literal.

**Tests first (TDD).** In `test/theme/sunburst_shape_test.dart` and `test/theme/sunburst_type_test.dart`:
- `'eChip is the half-step (2,2)'` — `SunburstShape.sunburstPop.eChip == const Offset(2, 2)`.
- `'nested border width is 2 and the primary edge is 3'` — asserts `borderWidthNested == 2` and
  `borderWidth == 3` together, so a future edit cannot collapse them.
- `'dash pitch is 9 on / 7 off'` — `dashOn == 9`, `dashOff == 7`.
- `'glyph strokes are 2.6 at nav size and 3.0 at control size'` — `glyphStrokeNav == 2.6`,
  `glyphStrokeControl == 3`.
- `'copyWith replaces each new slot independently'` — one expectation per new field; catches the
  classic constructor-updated-lerp-forgotten rot.
- `'lerp interpolates every new slot'` — `lerp(a, b, 0.5)` on a shape whose new fields all differ,
  asserting each midpoint; a field missing from `lerp` returns `a`'s value and fails.
- `'buttonLarge is Fredoka 21/24 and chip is Fredoka 600 14/18'` — asserts `fontSize`, `height` and
  `fontWeight`, and that both use `SunburstType.display` with `displayFallback`.
- `'the type scale ships exactly the steps its source file declares'` — E02 T02.7's existing count test,
  amended in **this** commit: its named list literal gains `buttonLarge` and `chip`, taking it from ten
  to twelve, and the count still derives from `DesignSource.dartFieldNames(typeFile, 'SunburstType')`
  rather than a hardcoded number. E07 T07.0 and E08 T08.6 amend the same literal the same way. An
  unreviewed thirteenth step fails; a reviewed one is a one-line edit carrying its `DERIVED` evidence.

**Implementation.** Add to `SunburstShape`: `eChip` `Offset(2, 2)`, `borderWidthNested` `2`,
`dashOn` `9`, `dashOff` `7`, `glyphStrokeNav` `2.6`, `glyphStrokeControl` `3`. Add to `SunburstType`:
`buttonLarge` (Fredoka w600 21 / 24) and `chip` (Fredoka w600 14 / 18). Each touches five places per
`sunburst-tokens` rule 12: field, constructor, `copyWith`, `lerp`, the `const sunburstPop` instance —
plus the step-name literal in E02's count test, which is the sixth place and the one that gets forgotten.
Also add `enum HudTone { neutral, highlight, alarm }` to **`lib/core/hud_tone.dart`** — not beside
`HudPill`, and not in `lib/features/play/domain/`. Both sides need it: E03's `HudPill` renders a tone
and E06's `GameHud`/`HudSlot` carries one, and under the downward-only DAG `lib/features/` may import
`lib/ui/` but `lib/ui/` may never import `lib/features/`. `lib/core/` is the only layer both can reach.
Declaring it twice would produce two enums with one name that never unify (see Risk 4).
Mark the first four shape slots and both type steps `// DERIVED` with the evidence from
`sunburst-components` SKILL.md's derived table; mark `glyphStrokeNav`/`glyphStrokeControl` as
transcribed from `system.html` §08 (`stroke-width="2.6"` × 40 sites, `stroke-width="3"` × 14 sites in
`app.html`). Add a `// @contrast textPrimary accent 4.5` line covering the chip label.

**Files.** `lib/theme/sunburst_shape.dart`, `lib/theme/sunburst_type.dart`, `lib/core/hud_tone.dart`,
`test/theme/sunburst_shape_test.dart`, `test/theme/sunburst_type_test.dart`,
`test/core/hud_tone_test.dart`.

**Skills.** `sunburst-tokens`, `sunburst-components`, `dart3-idioms-and-coding-standards`,
`dartdoc-conventions`.

**Screenshot check.** n/a (no visual surface).

**Done when.**
- [ ] Both test files green; each new slot has a `copyWith` and a `lerp` expectation.
- [ ] `check_raw_values.sh lib` and `check_palette_contrast.sh lib/theme/sunburst_colors.dart` green.
- [ ] Every new slot carries `DERIVED` + evidence, or a `system.html` §-reference.
- [ ] `flutter analyze --fatal-infos` clean, including `public_member_api_docs`.

**Commits.**
1. `test(theme): pin the six derived slots and two glyph strokes`
2. `feat(theme): add eChip, borderWidthNested, dash pitch and glyph strokes to SunburstShape`
3. `feat(theme): add buttonLarge and chip steps to SunburstType`
4. `feat(core): add HudTone where both the UI and the engine can reach it`

---

### T03.2 — The component test harness
**Goal.** One harness every component test imports: a themed pump, the four width presets, the
greyscale filter, the state-matrix builder and a recording feedback fake.

**Tests first (TDD).** The harness is test infrastructure, so its tests are meta-tests in
`test/support/component_harness_test.dart` — written before the harness:
- `'pumpPopComponent installs all four Sunburst extensions'` — reads
  `SunburstColors/Shape/Motion/Type.of(context)` from inside the pumped subtree; each `of()` asserts,
  so a missing extension throws rather than silently falling back.
- `'useDevice pins the logical width and resets it'` — asserts
  `tester.view.physicalSize == logical * dpr` for each `Device` in `Device.all` and that the tear-down
  restores the default (a leaked size poisons every later test in the file).
- `'loadAppFonts registers the bundled faces'` — after `loadAppFonts()`, a `Text` styled
  `type.displayL` measures wider than the same string under the default test font. If E01's `.ttf`
  files are missing this is the test that says so, loudly, instead of every golden below quietly
  rendering Ahem (Risk 8).
- `'MediaQuery sits above MaterialApp and preserves view size'` — pumps with
  `textScaler: TextScaler.linear(2)` and asserts `MediaQuery.sizeOf` inside the app still reports the
  pinned size; a bare `MediaQueryData()` would report `Size.zero` and pass a broken layout.
- `'greyscale wrapper desaturates'` — renders two swatches of equal luminance and different hue and
  asserts the two goldens are byte-identical under the filter, so the greyscale lane can actually
  detect hue-only states.
- `'FakeFeedbackService records each fired moment once'` — a plain unit test.

**Implementation.** `test/support/component_harness.dart` **extends E02's `test/support/harness.dart`;
it does not fork it.** It imports `Device`, `Device.all` and `useDevice` from there and declares no
second device type and no second `pumpApp`. E02's presets are all DPR 2 — the geometry
`capture-screens.sh` rendered the eight PNGs at — and a component golden blessed at DPR 3 cannot be laid
beside a DPR-2 reference, so this epic uses the same number.
- `extension PopHarness on WidgetTester { Future<void> pumpPopComponent(Widget child, {Device? device, TextScaler textScaler, bool boldText, List<Override> overrides, TextDirection textDirection}); }`
  — `pumpPopComponent` calls `useDevice`, then wraps in `ProviderScope` → `Builder` →
  `MediaQuery(data: MediaQuery.of(context).copyWith(...))` → `MaterialApp(theme: buildSunburstTheme(), home: Scaffold(backgroundColor: surface, body: Center(child: child)))`
  and ends in a single `pump()`, never `pumpAndSettle`.
- `Widget popStateMatrix({required String label, required List<PopComponentState> states, required Widget Function(PopComponentState) build})`
  laying the five states out in one column with the state name beside each, for the per-component
  matrix golden.
- `class Greyscale extends StatelessWidget` — a `ColorFiltered` saturation-zero matrix for the
  greyscale lane.
- `test/support/fake_feedback_service.dart` — `final class FakeFeedbackService implements FeedbackService
  { final List<Moment> fired; }` (the interface itself lands in T03.3; commit this file with T03.3 if
  the ordering is inconvenient). **One path, one name, for the whole project**: E08 T08.5 and E09 T09.2
  both consume this file and must not add `test/support/fakes/fake_feedback_service.dart` or a
  `RecordingFeedbackService` beside it.
- `test/support/load_app_fonts.dart` — `Future<void> loadAppFonts()`, five lines over `FontLoader`,
  registering the Fredoka and Nunito `.ttf` files E01 bundled. **It is created here, not in E07**: this
  epic is the first real-font golden lane and calls it in `setUpAll` in T03.2 and T03.10, so the bold
  and character-width axes are not inert under Ahem. E07, E08, E09 and E10 all import this file.
- `dart_test.yaml` with the `golden` tag. **Owned here** — E03 is the first epic with a golden lane, so
  no later epic needs a conditional "add the golden tag if it does not exist".

**Files.** `test/support/component_harness.dart`, `test/support/fake_feedback_service.dart`,
`test/support/load_app_fonts.dart`, `test/support/component_harness_test.dart`,
`dart_test.yaml` (the `golden` tag).

**Skills.** `widget-golden-and-a11y-testing`, `testing-strategy`, `adaptive-layout`.

**Screenshot check.** n/a (no visual surface).

**Done when.**
- [ ] `flutter test test/support/` green.
- [ ] No `pumpAndSettle`, no `takeException()` in a `tearDown`, no `ignoreOverflowErrors`, no
      `FlutterError.onError` assignment anywhere under `test/`.
- [ ] `check-test-hygiene.sh lib test` green.
- [ ] `pumpApp`, `Device` and `useDevice` are **imported from E02's `test/support/harness.dart`**, not
      re-declared here — this harness pumps a component, not the app.
- [ ] `loadAppFonts()` proves the real faces loaded; `grep -rn 'PopWidth' test/` returns nothing.

**Commits.**
1. `test(support): meta-tests for the component harness`
2. `test(support): add loadAppFonts over the bundled faces`
3. `test(support): add pumpPopComponent over the shared Device presets and the greyscale wrapper`
4. `test(support): add the state-matrix builder and FakeFeedbackService`

---

### T03.3 — `PopSurface`, `PopElevation`, the press seam and the dashed edge
**Goal.** The one primitive and the one press implementation, with the hit area provably still.

**Tests first (TDD).** `test/ui/components/pop_surface_test.dart`:
- `'restOffset resolves each elevation step'` — pure test over `PopElevation`: `flat` → `null`,
  e1 → `(3,3)`, e2 → `(5,5)`, e3 → `(8,8)`, e4 → `(10,10)`.
- `'pressScale is 0.97 at e1 and 0.98 above'` — pure test over `PopElevation.pressScale(shape)`.
- `'travel is the resting offset minus one on both axes'` — `shape.pressTranslate` over all four steps.
- `'every shadow the surface paints has blur and spread 0'` — walks the rendered
  `BoxDecoration.boxShadow` and asserts both are `0`, at rest and while held.
- `'the pressed shadow is (1,1) from every step'` — parameterised over e1..e4.
- `'the hit area does not move during the press'` — the regression test for the whole design:
  `tester.getRect(find.byType(GestureDetector))` (or the `ConstrainedBox`) captured at rest, then a
  `TestGesture` held down, `pump(durTap)`, rect re-measured and asserted **identical**, while the
  painted `Transform` has moved by `travel`. Then release at the target's original edge and assert
  `onTap` fired.
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
  (equal config → `false`, one field changed → `true`) and a golden of a dashed rounded rect asserting
  the 9/7 pitch.
- Goldens: `pop_surface_states.png` (rest / pressed / disabled / focused, e1–e4) and
  `pop_surface_states_greyscale.png`.

**Implementation.**
- `lib/ui/components/pop_surface.dart` — `const double kPopMinTarget = 48;`,
  `enum PopElevation { flat, e1, e2, e3, e4 }` with `Offset? restOffset(SunburstShape)` and
  `double pressScale(SunburstShape)`, `enum PopBorderStyle { solid, dashed, none }`, and
  `class PopSurface extends StatefulWidget` with the constructor from
  `sunburst-components/examples/pop_surface.dart` (`fill`, `radius`, `child`, `elevation`,
  `borderStyle`, `padding`, `onTap`, `enabled`, `selected`, `minTarget`, `pressScaleOverride`,
  `commitMoment`, `semanticLabel`). Private `_FocusRingPainter` paints the gap and the ring as
  strokes outside the layout box — never a `BoxShadow` with spread.
- `lib/ui/components/dashed_ink_border.dart` — `DashedInkBorder extends CustomPainter`, stroking the
  RRect from `Path.computeMetrics()` at `shape.dashOn`/`dashOff`, with `shouldRepaint` as one value
  compare and every `Paint` precomputed as a field.
- **The press seam.** `PopSurface` composes `PressPhysics`; that widget belongs to
  `sunburst-motion-and-haptics` and therefore to E04, but E03 cannot ship a pressable surface without
  it and rule 2 forbids a second press implementation. Decision recorded in *Risks*: this task creates
  `lib/shared/motion/press_physics.dart` (`PressGeometry`, `PressBuilder`, `PressPhysics` — geometry,
  one interruptible `AnimationController` at `motion.resolve(context, motion.durTap)`, `animateTo`
  never `forward`, the reduce-motion split, `minTarget` between the gesture and the transform),
  `lib/shared/feedback/moment.dart` (the `Moment` enum, all eighteen values transcribed from
  `sunburst-motion-and-haptics`' catalog table, no behaviour) and
  `lib/shared/feedback/feedback_service.dart` (`abstract interface class FeedbackService { void fire(Moment moment); }`,
  a `SilentFeedbackService` no-op and `feedbackServiceProvider`). **E04 replaces the implementation
  and owns the moment → haptic map; it does not rewrite the seam and must not add a second press
  controller.**

**Files.** `lib/ui/components/pop_surface.dart`, `lib/ui/components/dashed_ink_border.dart`,
`lib/shared/motion/press_physics.dart`, `lib/shared/feedback/moment.dart`,
`lib/shared/feedback/feedback_service.dart`, `test/ui/components/pop_surface_test.dart`,
`test/ui/components/dashed_ink_border_test.dart`, `test/ui/components/goldens/pop_surface_*.png`.

**Skills.** `sunburst-components`, `sunburst-motion-and-haptics`, `sunburst-tokens`,
`custom-canvas-and-gestures`, `accessibility-as-code`, `widget-golden-and-a11y-testing`,
`dart3-idioms-and-coding-standards`, `dartdoc-conventions`.

**Screenshot check.** `design/sunburst-pop/system.html` §07 *Elevation* (the five steps and the press
rule) and §10 → *Primary button* / *Secondary button* as the rendered instance of the surface.
Compare structure → spacing → surface construction → type → sampled hex. Not against
`screens/*.png`.

**Done when.**
- [ ] Every test above green, including the hit-area-does-not-move regression.
- [ ] `check_component_hygiene.sh lib` and `check_raw_values.sh lib` green.
- [ ] `check_motion_tokens.sh lib` green — no `Duration(`, no `Curves.`, no `Cubic(` outside `lib/theme/`.
- [ ] `check_painter_hygiene.sh lib` green: no allocation inside `paint()`, `shouldRepaint` is a value
      compare, `ExcludeSemantics` over drawn pixels.
- [ ] No `Opacity` anywhere in `lib/ui/components/`; no `elevation:` with a numeric argument; no
      `ClipRRect` around a `PopSurface`.
- [ ] `flutter analyze --fatal-infos` clean.

**Commits.**
1. `test(ui): pin PopElevation geometry and the press law`
2. `feat(shared): add the Moment enum and the FeedbackService seam`
3. `feat(shared): add PressPhysics, the one press controller`
4. `feat(ui): add PopSurface with the focus ring and the disabled resolution`
5. `feat(ui): add DashedInkBorder for the locked edge`
6. `test(ui): golden and greyscale matrices for PopSurface`

---

### T03.4 — The drawn glyph set
**Goal.** Seventeen inline stroke glyphs in `lib/ui/glyphs/` at the two design weights, painted on
canvas — no emoji, no icon font, no `IconData`.

**Tests first (TDD).** `test/ui/glyphs/sunburst_glyph_test.dart`:
- `'every SunburstGlyph value resolves to a path'` — iterates `SunburstGlyph.values` and asserts the
  painter produces a non-empty path for each; a value added without artwork fails immediately.
- `'stroke weight follows the requested size'` — pure test over the resolver: ≥ 22 → `glyphStrokeNav`
  2.6, 18–20 → `glyphStrokeControl` 3.0, with the boundary cases named.
- `'a glyph is excluded from semantics'` — `find.byType(SunburstGlyphIcon)` renders no semantics node
  of its own; the label belongs to the enclosing component.
- `'shouldRepaint is a single value compare'` — same scene → `false`, different glyph/colour/stroke →
  `true`.
- `'paint allocates no Paint or Path'` — asserted structurally by `check_painter_hygiene.sh`, plus a
  test that two consecutive paints of the same scene reuse the same `Paint` instance via an injected
  recording canvas.
- Golden `glyph_sheet.png`: all seventeen at 22 and at 18 on cream, ink stroke; plus
  `glyph_sheet_greyscale.png`.

**Implementation.** `lib/ui/glyphs/sunburst_glyph.dart` declares
`enum SunburstGlyph { navPlay, navStats, navSettings, go, back, pause, close, sound, haptics, motion, contrast, language, info, chevronRight, lock, star, flame }`
— the exact set drawn in `system.html` §08 plus the four `app.html` settings-row glyphs (`haptics`,
`contrast`, `language`, `info`) and `chevronRight`. The status-bar wifi and battery marks are **not**
included: they are mockup device chrome, drawn by the OS on a real device.
`class SunburstGlyphIcon extends StatelessWidget` takes `(SunburstGlyph glyph, {double size, Color? colour})`,
wraps `CustomPaint` in `ExcludeSemantics`, and defaults `colour` to `colors.textPrimary`.
`lib/ui/glyphs/sunburst_glyph_painter.dart` holds `@immutable class GlyphScene` (glyph, colour,
strokeWidth, size) and `SunburstGlyphPainter extends CustomPainter` with every `Path` precomputed as a
`static final` keyed by glyph and scaled by one shared transform from its authored viewBox. Path
coordinates are artwork, not tokens, and stay in this file; the two stroke widths are read from
`SunburstShape` (T03.1). `strokeCap`/`strokeJoin` are `round` per the SVG source. `go` and `star` are
the two filled glyphs — filled *and* stroked, as in the source.

**Files.** `lib/ui/glyphs/sunburst_glyph.dart`, `lib/ui/glyphs/sunburst_glyph_painter.dart`,
`test/ui/glyphs/sunburst_glyph_test.dart`, `test/ui/glyphs/goldens/glyph_sheet*.png`.

**Skills.** `custom-canvas-and-gestures`, `sunburst-shell-screens`, `sunburst-tokens`,
`accessibility-as-code`, `widget-golden-and-a11y-testing`, `naming-conventions`.

**Screenshot check.** `system.html` §08 *Iconography*, all three subsections: *22px · stroke 2.6*,
*18–20px · stroke 3* and *Badge glyphs — drawn, not typed*. Put `glyph_sheet.png` beside the rendered
gallery and check shape, terminal caps, stroke weight and optical size per glyph.

**Done when.**
- [ ] Seventeen glyphs render and match the gallery.
- [ ] `grep -rn "Icons\.\|IconData\|Icon(" lib/` returns nothing.
- [ ] No emoji anywhere in `lib/` (`check_component_hygiene.sh` plus a review grep).
- [ ] `check_painter_hygiene.sh lib` and `check_raw_values.sh lib` green.

**Commits.**
1. `test(ui): pin the glyph set, stroke resolution and semantics exclusion`
2. `feat(ui): add SunburstGlyph and the glyph painter`
3. `test(ui): golden sheets for the glyph set at both weights`

---

### T03.5 — `PopButton`, `PopIconButton`, `PopChip`, `PopCard`
**Goal.** The four text-and-fill components, all four button variants and both button sizes.

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
- `'PopIconButton is 48×48 and speaks its semanticLabel'` — `getSize` plus
  `isSemantics(isButton: true, label: 'Pause')`.
- `'PopChip renders a glyph, 7/14 padding and type.chip'`.
- `'PopCard is not pressable without onTap'` — no button role, no press response; and
  `'PopCard with onTap presses at e2'`.
- `'PopCard density maps to elevation'` — `dense` → e1, `standard` → e2, `hero` → e3 + `radiusXl`.
- `'a card row divider is a 3px ink rule, never colors.divider'`.
- a11y per component: tap target `getSize` ≥ 48 both axes; `isSemantics` role/label/enabled.
- Goldens per component: rest / pressed / disabled / focused (+ the card's three densities), plus one
  greyscale matrix each.

**Implementation.** `lib/ui/components/pop_button.dart` (`PopButton`,
`enum PopButtonVariant { primary, success, secondary, ghost }`,
`enum PopButtonSize { regular, large }`, `label`, `onPressed`, `leading`, `expand`),
`pop_icon_button.dart` (`PopIconButton` — 48×48, `surfaceRaised`, `radiusMd`, e1, required
`semanticLabel`, `SunburstGlyph glyph`), `pop_chip.dart` (`PopChip` — `surfaceRaised`, pill, e1,
padding 7/14, `type.chip`, optional `glyph`), `pop_card.dart` (`PopCard`,
`enum PopCardDensity { dense, standard, hero }`, `padding` default `SunburstShape.cardPadding`,
optional `onTap`). All four compose `PopSurface` and construct no decoration of their own. All labels
are already-localized `String`s.

**Files.** the four `lib/ui/components/*.dart` above, their four test files, and
`test/ui/components/goldens/pop_{button,icon_button,chip,card}_*.png`.

**Skills.** `sunburst-components`, `sunburst-tokens`, `widget-composition`,
`accessibility-as-code`, `widget-golden-and-a11y-testing`, `i18n-rtl-l10n`, `dartdoc-conventions`.

**Screenshot check.** `system.html` §10 → *Primary button*, *Secondary button*, *Ghost button*; the
chip and card as they appear in `app.html` screens 01 and 02 (the streak chip, the stat card). Order:
structure → spacing rhythm → surface construction → type role → sampled hex.

**Done when.**
- [ ] All four components green on their state goldens and their a11y test.
- [ ] `grep -rn "ElevatedButton\|FilledButton\|TextButton\|OutlinedButton\|Card(" lib/` returns nothing.
- [ ] `check_component_hygiene.sh lib`, `check_raw_values.sh lib`, `check-widget-composition.sh lib`
      green.
- [ ] No `Widget _buildX()` method anywhere in `lib/ui/`.

**Commits.**
1. `test(ui): pin PopButton variants, sizes and states`
2. `feat(ui): add PopButton on PopSurface`
3. `feat(ui): add PopIconButton and PopChip`
4. `feat(ui): add PopCard with its three densities`
5. `test(ui): golden and greyscale matrices for the button family`

---

### T03.6 — `GameCard` and `DifficultySegmented`
**Goal.** The home hub card (with its best pill, artwork tile and locked variant) and the three-item
segmented control whose selected item lifts instead of pressing.

**Tests first (TDD).** `test/ui/components/game_card_test.dart`,
`test/ui/components/difficulty_segmented_test.dart`:
- `'the card fills with the accent it is given'` — the accent arrives as a constructor argument; a
  test asserts the widget reads no global and no `switch (gameId)`.
- `'title and subtitle are both textPrimary'` — the 2.8:1 trap on coral; asserted on the resolved
  `TextStyle.color`, not by eye.
- `'the best pill uses borderWidthNested 2 and a surface fill'` and
  `'BEST is textSecondary, legal because it sits on cream'`.
- `'locked renders a dashed edge, no shadow, no tap and a locked badge'` — plus
  `'locked copy is textSecondary, not textDisabled'` (a status line is not a disabled control).
- `'the artwork quad is excluded from semantics'` and
  `'the card speaks one merged label'` — "Stroop Rush, tap the colour not the word, best 1,480".
- `'the selected segment lifts to (−1,−1) with the eChip shadow'`.
- `'the pressed segment fills accentDeep, drops the shadow and moves (1,1)'` — three distinct
  silhouettes: selected ≠ pressed ≠ rest.
- `'a locked segment shows a padlock glyph as well as textDisabled'` — the never-colour-alone check.
- `'items are radio semantics, not buttons'` — `isSemantics(isSelected: true, isInMutuallyExclusiveGroup: true)`
  per item and one group label.
- `'a 3px transparent border on the rest item prevents layout shift on selection'` — asserts the item
  rect is identical selected and unselected.
- `'each segment is at least 48 tall'` — `getSize` loop over the three items.
- Goldens: `game_card_{rest,pressed,locked,focused}.png`,
  `difficulty_segmented_{rest,selected,pressed,locked,focused}.png`, plus greyscale matrices.

**Implementation.** `lib/ui/components/game_card.dart` — `GameCard` with `title`, `subtitle`,
`accent`, `bestLabel`, `artwork`, `onTap`, `isLocked`; `PopElevation.e2`, `radiusLg`, padding 15/16,
12px gap, 64×64 artwork tile at `radiusMd`/e1; locked uses `PopBorderStyle.dashed` and `onTap: null`.
`lib/ui/components/difficulty_segmented.dart` — `DifficultySegmented` over a
`List<DifficultyOption>` (`label`, `isLocked`), `selectedIndex`, `onSelected`; `surfaceSunk` track,
3px border, pill, 6px padding and 6px gap, each item `Expanded` with 13px vertical padding.

**Files.** `lib/ui/components/game_card.dart`, `lib/ui/components/difficulty_segmented.dart`, their
two test files, `test/ui/components/goldens/game_card_*.png`,
`test/ui/components/goldens/difficulty_segmented_*.png`.

**Skills.** `sunburst-components`, `sunburst-tokens`, `accessibility-as-code`,
`widget-golden-and-a11y-testing`, `widget-composition`, `i18n-rtl-l10n`.

**Screenshot check.** `system.html` §10 → *Game card* and *Difficulty segmented control*.

**Done when.**
- [ ] Both components green on all their state goldens, including greyscale.
- [ ] The accent is a constructor argument; `grep -rn "gameStroop\|gameSchulte" lib/ui/` returns
      nothing.
- [ ] `check_component_hygiene.sh lib` and `check_game_palette.sh lib` green.

**Commits.**
1. `test(ui): pin GameCard states and the locked variant`
2. `feat(ui): add GameCard with the best pill and dashed locked edge`
3. `test(ui): pin the segmented control's three silhouettes and radio semantics`
4. `feat(ui): add DifficultySegmented`

---

### T03.7 — `HudPill`, `TimerRing`, `PopProgressBar`
**Goal.** The three HUD components, two of which paint on canvas.

**Tests first (TDD).** `test/ui/components/hud_pill_test.dart`, `timer_ring_test.dart`,
`pop_progress_bar_test.dart`:
- `'each HudTone paints its fill and both its text slots'` — neutral `surfaceRaised` +
  `textSecondary` label; highlight `accent` with **both** lines `textPrimary`; alarm `danger` with
  **both** lines `surfaceRaised`. Asserted on resolved colours.
- `'the alarm tone is danger, never gameStroop'` — the coral-on-coral trap; asserts the fill is not
  any `game*` slot.
- `'the pill is neither pressable nor focusable'` — no button role, no tap action, no focus node.
- `'label and value are merged into one announcement'` — `MergeSemantics`, "Time, 0:23".
- `'the value is tabular so a digit change does not reflow'` — measures the pill rect at `0:23` and
  `0:11` and asserts equal width.
- `'the ring sweep crosses to danger in the last 12%'` — pure test on the scene builder, with the
  boundary asserted at 0.88 and 0.87.
- `'the countdown ring is the same class at e4'` and `'nothing else in the diff claims e4'` — a grep
  assertion over `lib/`.
- `'the progress bar keeps a 3px ink right edge until 100%'` — the non-colour channel; asserted at
  0.5 (edge present) and 1.0 (edge gone).
- `'both painters repaint only on a scene change'` — `shouldRepaint` value-compare tests.
- `'both painters allocate nothing in paint()'` — recording-canvas test plus
  `check_painter_hygiene.sh`.
- `'the ring and bar are ExcludeSemantics with a sibling node speaking the display value'`.
- Goldens: `hud_pill_{neutral,highlight,alarm}.png`, `timer_ring_{rest,low,countdown}.png`,
  `pop_progress_bar_{empty,half,full}.png`, plus one greyscale matrix each.

**Implementation.** `lib/ui/components/hud_pill.dart` — `HudPill` (`label`, `value`, `tone`), importing
`HudTone` from `lib/core/hud_tone.dart` (T03.1). The enum is **not** declared here and **not** in
`lib/features/play/domain/`: E06's `GameHud`/`HudSlot` carries the same tone, `lib/ui/` may not import
`lib/features/`, and two enums with one name never unify (see *Risks*). The shell (E07) owns *which*
tone is chosen when. `lib/ui/components/timer_ring.dart` — `TimerRing` (`progress`, `label`, `accent`,
`elevation`), `@immutable class TimerRingScene`, `TimerRingPainter`. `lib/ui/components/pop_progress_bar.dart`
— `PopProgressBar` (`progress`, `accent`), `@immutable class ProgressBarScene`,
`StripedFillPainter` using `shape.stripePitch` 9 at `shape.stripeAngle` 45. All three compose
`PopSurface` for the border and shadow; the painters draw only the sweep and the stripe. Value
cross-fades run at `motion.durState` on `motion.easeOut` — never `easePop` on a colour.

**Files.** `lib/ui/components/hud_pill.dart`, `lib/ui/components/timer_ring.dart`,
`lib/ui/components/pop_progress_bar.dart`, three test files,
`test/ui/components/goldens/{hud_pill,timer_ring,pop_progress_bar}_*.png`.

**Skills.** `sunburst-components`, `custom-canvas-and-gestures`, `sunburst-tokens`,
`accessibility-as-code`, `widget-golden-and-a11y-testing`, `dart3-idioms-and-coding-standards`.

**Screenshot check.** `system.html` §10 → *HUD stat pill*, *Progress bar*, *Timer ring*.

**Done when.**
- [ ] All three green on their goldens and greyscale matrices.
- [ ] `check_painter_hygiene.sh lib`, `check_component_hygiene.sh lib`, `check_motion_tokens.sh lib`
      green.
- [ ] Exactly one component in `lib/` can render `PopElevation.e4`, and it is `TimerRing`.

**Commits.**
1. `test(ui): pin HudPill tones and the merged announcement`
2. `feat(ui): add HudPill over the shared HudTone`
3. `test(ui): pin the timer sweep, the danger crossover and the striped fill`
4. `feat(ui): add TimerRing and its painter`
5. `feat(ui): add PopProgressBar with the vanishing ink edge`

---

### T03.8 — `PopGridTile`, `PopToggle`, `PopBadge`
**Goal.** The five-state board tile, the 66×34 toggle whose row owns the gesture, and the three badge
variants.

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
  `Device.reference390`, size read with `getSize`; decided from constraints, never a device check.
- `'the glyph is tabular Fredoka 700 24'`.
- `'the toggle renders the ON/OFF word inside the track'` — asserts the word is present and swaps side
  and colour with the value; the state survives greyscale.
- `'the toggle takes no gesture of its own'` — `onTap: null`, `minTarget: 0`; and
  `'the enclosing 62px row is the target'` — a row harness whose `getSize` is ≥ 48 and whose tap
  toggles.
- `'the off track draws an inner well as a border, never a second BoxShadow'` — counts the shadows in
  the rendered decoration.
- `'disabled paints track, thumb and word in borderDisabled/textDisabled'`.
- `'a badge is never tappable'` — no button role, no tap action, for all three variants.
- `'the celebration badge is accent at e2 with a −2.5° tilt and a star glyph'`.
- `'the locked badge is dashed with no shadow'`.
- Goldens: one matrix per component plus greyscale.

**Implementation.** `lib/ui/components/pop_grid_tile.dart` — `PopGridTile`,
`enum PopGridTileState { idle, next, found, wrong, disabled }` and the pure resolver
`PopGridTileVisual visualFor(PopGridTileState, SunburstColors, SunburstShape)` returning
`(elevation, offset, scale, fill, borderColour, glyphColour, hasRing)`. **Named `PopGridTile`, not
`GridTile`**, because `package:flutter/material.dart` already exports `GridTile` and every widget file
imports material; see *Risks* for the deviation and the fallback.

**Its consumer is E09.** The five states are the Schulte machine exactly, so `SchulteTile` composes this
widget and maps `SchulteTileState` onto `PopGridTileState` 1:1 rather than composing `PopSurface`
directly with a second visual resolver. That is why the resolver is public and pure: E09 T09.6's
"every state pair differs in ≥3 non-hue channels" test asserts against **this** function, and the
greyscale state-collision golden below is the same proof E09 would otherwise have to rebuild.
`lib/ui/components/pop_toggle.dart` — `PopToggle` (`isOn`, `onLabel`, `offLabel`, `isEnabled`), track
66×34, thumb 26×26 sliding at `motion.durMove` on `motion.easePop`, `onTap: null`, `minTarget: 0`.
`lib/ui/components/pop_badge.dart` — `PopBadge` and
`enum PopBadgeVariant { celebration, quiet, locked }`, pill, 3px, `type.chip`, `SunburstGlyph`
leading, never an emoji.

**Files.** `lib/ui/components/pop_grid_tile.dart`, `lib/ui/components/pop_toggle.dart`,
`lib/ui/components/pop_badge.dart`, three test files, their goldens.

**Skills.** `sunburst-components`, `accessibility-as-code`, `adaptive-layout`,
`widget-golden-and-a11y-testing`, `sunburst-tokens`, `dart3-idioms-and-coding-standards`.

**Screenshot check.** `system.html` §10 → *Grid tile*, *Toggle switch*, *Badge*.

**Done when.**
- [ ] Five tile states render five distinguishable greyscale images.
- [ ] The toggle's enclosing row, not the toggle, is the ≥48px target.
- [ ] `check_component_hygiene.sh lib` and `check_raw_values.sh lib` green.
- [ ] The `GridTile` naming deviation is stated in the PR body with its reason.

**Commits.**
1. `test(ui): pin the five grid-tile states and their non-colour channels`
2. `feat(ui): add PopGridTile`
3. `test(ui): pin the toggle word, the inner well and the row-owns-the-gesture rule`
4. `feat(ui): add PopToggle`
5. `feat(ui): add PopBadge with its three variants`

---

### T03.9 — `PopSheet` and `PopBottomNav`
**Goal.** The two chrome containers: the bottom sheet the pause state uses, and the three-destination
nav bar with the one partial border in the system.

**Tests first (TDD).** `test/ui/components/pop_sheet_test.dart`,
`test/ui/components/pop_bottom_nav_test.dart`:
- `'the sheet is surface, radiusXl top / radiusMd bottom, e3, with a 56×6 grab handle'`.
- `'the sheet title snaps to type.title and its body to type.body'` — the mockup's 23/14 sit between
  scale steps and must not be reproduced.
- `'actions stack full width with a 10px gap, primary first'`.
- `'the first action is autofocused'`.
- `'the sheet enters over durMove on easeInOut and reduced motion lands on the end state'` — asserts
  the settled geometry is identical with `disableAnimations: true`.
- `'the nav has a 3px ink top border and no other edge'` — reads the rendered `Border` and asserts
  `left`, `right`, `bottom` are `BorderSide.none`.
- `'an item is 88 wide with a 3px transparent border at rest'` — no layout shift when it activates.
- `'the active item is an accent chip with an ink border at e1 and textPrimary'`.
- `'the icon is 22 at stroke 2.6 over an 11.5 label'`.
- `'items are selected-tab semantics with one label each'`.
- `'the nav accepts exactly three destinations'` — a fourth is an assertion failure, not a silent
  overflow.
- `'every nav item is at least 48 tall'` — `getSize` loop.
- Goldens: `pop_sheet_{rest,focused}.png`, `pop_bottom_nav_{index0,index1,index2,pressed}.png`, plus
  greyscale.

**Implementation.** `lib/ui/components/pop_sheet.dart` — `PopSheet` (`title`, `body`, `actions`) and a
`showPopSheet` helper that pushes it with `clipBehavior: Clip.none` so the e3 shadow and the 7px focus
ring are not amputated. `lib/ui/components/pop_bottom_nav.dart` — `PopBottomNav`
(`items`, `currentIndex`, `onSelected`) and `class PopBottomNavItem` (`glyph`, `label`); height 90,
`surfaceRaised`, a top-only `Border`, items 88 wide at `radiusMd`. Neither widget navigates: routing
is E07's.

**Files.** `lib/ui/components/pop_sheet.dart`, `lib/ui/components/pop_bottom_nav.dart`, two test
files, their goldens.

**Skills.** `sunburst-components`, `widget-composition`, `accessibility-as-code`,
`widget-golden-and-a11y-testing`, `sunburst-tokens`, `i18n-rtl-l10n`.

**Screenshot check.** `system.html` §10 → *Modal sheet* and *Bottom navigation*. Note that §10 boxes
the nav on all four sides for display; `app.html` `.tabs{border-top:…}` is the shipped geometry and
wins.

**Done when.**
- [ ] Both components green on their goldens and greyscale matrices.
- [ ] No `go_router` or `Navigator` import in `lib/ui/`.
- [ ] `check_shell_boundaries.sh lib` and `check_component_hygiene.sh lib` green.
- [ ] No `ClipRRect`/`Clip.hardEdge` around a `PopSurface` anywhere in the diff.

**Commits.**
1. `test(ui): pin the sheet anatomy, type snapping and autofocus`
2. `feat(ui): add PopSheet and showPopSheet`
3. `test(ui): pin the nav's top-only border and selected-tab semantics`
4. `feat(ui): add PopBottomNav`

---

### T03.10 — The matrix sweep, the greyscale proof and the gallery contact sheet
**Goal.** Prove the whole catalog survives text scale, width, bold and greyscale together, and
produce the single image the design comparison is done against.

**Tests first (TDD).** This task is tests; the only production change is whatever they red.
`test/ui/components/overflow_matrix_test.dart`:
- One `testWidgets` per `(Device, textScale, bold)` tuple over `Device.all` — 4 × 3 × 2 = 24 — never a loop inside a
  test, because overflow is reported once per `RenderObject` and a loop silently under-reports every
  scale after the first. Scales are 1.0 / 1.3 / 2.0; `setUpAll(loadAppFonts)` so the bold axis is not
  inert under Ahem.
- Each pumps a column of all fourteen components with realistic labels and asserts
  `tester.takeException()` is null **and** a fit assertion per label: `getRect(text)` is contained by
  `getRect(its surface)`. The fit assertion is the real gate — a clipped `Text` reports nothing.
- No `FittedBox`, no `TextOverflow.ellipsis`, no `withClampedTextScaling` may be used to green a red
  tuple; the fix is the layout.
`test/ui/components/greyscale_matrix_test.dart`:
- One test per component: renders its full state matrix under `Greyscale` and asserts the golden;
  plus a pixel-difference assertion that no two states within one component produce the same image.
`test/ui/components/a11y_matrix_test.dart`:
- A `getSize` loop over every interactive component asserting ≥ 48 on both axes.
- An `isSemantics` assertion per interactive component for role, label, enabled and selected.
- `await expectLater(tester, meetsGuideline(androidTapTargetGuideline))` kept only as an advisory
  tripwire, never as the gate.
`test/ui/components/catalog_contact_sheet_test.dart` (`@Tags(['golden'])`):
- Renders the fourteen components in catalog order at `Device.reference390` on `surface` into
  `goldens/catalog_contact_sheet.png` — the real-font lane, the image the gallery comparison uses.
Also a `test/ui/components/rtl_test.dart` golden pumping the catalog under
`Directionality(textDirection: TextDirection.rtl)` to prove the directional insets mirror.

**Implementation.** Fix whatever the matrix reds — expected candidates: the segmented control's three
labels at scale 2.0 on a 320 width, the HUD pill row, and the nav label at 11.5 with `boldText`. Fixes
are layout changes (wrap, `Flexible`, taller rows), never clamps.

**Files.** `test/ui/components/overflow_matrix_test.dart`,
`test/ui/components/greyscale_matrix_test.dart`, `test/ui/components/a11y_matrix_test.dart`,
`test/ui/components/catalog_contact_sheet_test.dart`, `test/ui/components/rtl_test.dart`,
`test/ui/components/goldens/catalog_contact_sheet.png`, plus any component files the matrix reds.

**Skills.** `widget-golden-and-a11y-testing`, `accessibility-as-code`, `adaptive-layout`,
`i18n-rtl-l10n`, `sunburst-components`.

**Screenshot check.** `goldens/catalog_contact_sheet.png` beside `design/sunburst-pop/system.html`
§10 *Components*, rendered in a browser at a 390px viewport. Compare structure → spacing rhythm →
surface construction → type role → sampled hex, component by component, and record the result in the
PR body naming which §10 entries were compared. Explicitly **not** compared against
`design/sunburst-pop/screens/*.png`; those are E07's targets.

**Done when.**
- [ ] 24 overflow tuples green, each with a fit assertion; nothing suppressed anywhere in `test/`.
- [ ] Every interactive component measured ≥ 48 by an explicit `getSize` loop.
- [ ] No two states of any component collide in greyscale.
- [ ] RTL golden matches; no hardcoded `left`/`right` in `lib/ui/`.
- [ ] `check-test-hygiene.sh lib test` and `check_test_hygiene.sh lib test` green.
- [ ] The contact sheet is committed and the §10 comparison is written into the PR body.

**Commits.**
1. `test(ui): add the overflow and fit matrix across four widths and three text scales`
2. `fix(ui): resolve the overflows the matrix found` (only if it finds any)
3. `test(ui): add the greyscale state-collision proof`
4. `test(ui): add the a11y target and semantics matrix`
5. `test(ui): add the RTL golden and the catalog contact sheet`

## Gates that must pass

Run from the repo root, in this order, before every commit and again before the PR.

```bash
dart format --set-exit-if-changed .
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
.claude/skills/flutter-architecture/scripts/check_architecture.sh          lib
.claude/skills/project-structure-and-packages/scripts/check_import_boundaries.sh lib
.claude/skills/state-management-riverpod/scripts/ban-legacy-providers.sh   lib
.claude/skills/widget-golden-and-a11y-testing/scripts/check-test-hygiene.sh lib test
.claude/skills/testing-strategy/scripts/check_test_hygiene.sh              lib test
```

Plus the review greps this epic is responsible for:

```bash
grep -rn "Icons\.\|IconData\|ElevatedButton\|FilledButton\|TextButton\|Material(elevation" lib/   # must be empty
grep -rn "Opacity(\|ClipRRect\|FittedBox\|withClampedTextScaling" lib/ui/                         # must be empty
grep -rn "\.left\|\.right\|EdgeInsets\.only(left\|EdgeInsets\.only(right" lib/ui/                 # must be empty
```

The block above is this epic's **named spot-checks**. The authoritative sweep — locally and in CI — is
the one runner E01 T01.8 built:

```bash
bash tool/skill_gates.sh
```

Never `for s in .claude/skills/*/scripts/*.sh; do bash "$s"; done`: 29 of the 49 scripts fail
argument-less and five can never pass that way, so the loop is a broken gate, not a stricter one.

## Risks and open questions

1. **`PressPhysics` belongs to E04 but E03 cannot ship without it.** `sunburst-motion-and-haptics`
   owns the press *controller*; `sunburst-components` owns the *chrome*, and rule 2 of both skills
   forbids a second press implementation. **Decision (this epic):** T03.3 creates
   `lib/shared/motion/press_physics.dart`, `lib/shared/feedback/moment.dart` (the enum only) and
   `lib/shared/feedback/feedback_service.dart` (the interface plus a `SilentFeedbackService` no-op).
   E04 supplies the real `HapticGateway`-backed implementation, the moment → haptic map, the latches
   and the sound slots, and **must not create a second press controller**. Stated in the PR body so
   E04's author inherits the constraint. If the repo owner would rather E04 own the whole file,
   the alternative is to reorder E03 after E04 — but E04's own moment catalog needs components to
   animate, so the dependency runs this way.
2. **`GridTile` collides with `package:flutter/material.dart`.** Material exports a `GridTile`
   widget, so a file importing both material and the catalog gets an ambiguous-import error on every
   use. **Decision:** ship it as `PopGridTile` in `lib/ui/components/pop_grid_tile.dart`, consistent
   with the eleven other `Pop*` names, and record the one-line deviation from
   `references/component-catalog.md` in the PR. Fallback if the owner prefers the catalog name
   verbatim: keep `GridTile` and require every consumer to write
   `import 'package:flutter/material.dart' hide GridTile;`, which is one forgotten import away from a
   confusing error in E09. **Ask:** repo owner.
3. **`type.buttonLarge` and `type.chip` are an eleventh and twelfth type step, and `sunburst-tokens`
   rule 10 says "ten type steps, no eleventh".** `sunburst-components` requests both as derived
   slots. **Decision:** add them, because both are rendered specimens (`.btn--lg{font-size:21px}` and
   `.chip{14}`), and rule 12 of the same skill supplies the procedure for a new slot. Mark both
   `DERIVED` with the evidence and update `sunburst-tokens/references/shape-and-type.md` in the same
   PR so the two skills stop disagreeing. **Ask:** repo owner, if the rule-10 wording should be
   amended rather than the exception documented.
4. **`HudTone` has no home that satisfies both skills.** `sunburst-components` says the enum is
   "declared by `sunburst-shell-screens`", but `lib/ui/` may not import `lib/features/`, and E06's
   `BoardSnapshot`/`GameHud` contract needs the same enum on the domain side — a game
   (`lib/games/**`) sets a tone, and the pill (`lib/ui/**`) renders it. Declaring it in either place
   forces the other to declare its own, and two same-named enums never unify.
   **Decision:** declare it once in **`lib/core/hud_tone.dart`** (T03.1), beside `ScoreFormat` and the
   other pure vocabulary. `lib/core/` is the only layer both `lib/ui/` and `lib/features/` may import
   under the downward-only DAG, and `check_import_boundaries.sh` keeps it Flutter-free — an enum
   qualifies. E06 T06.4 imports it rather than redeclaring it; the shell still owns *which* tone is
   chosen when, which is the part that actually belongs to E07.
5. **`sunburst-components/examples/pop_button.dart` says `lib/ui/icons/`; `CLAUDE.md` and
   `sunburst-shell-screens` say `lib/ui/glyphs/`.** **Decision:** `lib/ui/glyphs/` — `CLAUDE.md`'s
   target layout wins. Note it in the PR so the example comment can be corrected later.
6. **The gallery comparison is manual and unrepeatable by a script.** `capture-screens.sh` renders
   `app.html` figures only; there is no §10 capture. The contact-sheet golden gives us a stable
   Flutter-side image, but the browser side is a person with a screenshot. Accepted for this epic;
   if the drift becomes real, the honest fix is to add a `system.html` §10 target to
   `capture-screens.sh` — a design-tooling change, out of scope here.
7. **The real-font golden lane is host-sensitive.** Goldens must be blessed in one pinned environment
   or CI reds on font rasterization differences. E01 pins the runner; this epic must bless its
   goldens on that same toolchain and never pass `--update-goldens` in CI.
8. **Fonts.** The golden lanes assume Fredoka and Nunito are bundled in `pubspec.yaml` by **E01 T01.6**
   (`check_font_bundling.sh`). If they are not, `loadAppFonts()` falls back to Ahem, the bold and
   character-width axes go inert, and every type-role comparison against the gallery is meaningless.
   T03.2's `'loadAppFonts registers the bundled faces'` test fails loudly rather than letting the epic
   proceed. `test/support/load_app_fonts.dart` is created here, in T03.2 — it is a five-line
   `FontLoader` and this is the first epic that needs it; E07/E08/E09/E10 import it.
9. **`PopGridTile` must not be built twice.** E03 ships it with the five Schulte states and a public
   pure resolver; E09 is its only consumer. If E09 instead composes `PopSurface` with its own
   `schulte_tile_visual.dart`, the catalog carries a fourteenth class nothing uses and the greyscale
   state-collision proof exists in two places that can disagree. **Decision:** E09 T09.5 composes
   `PopGridTile` and maps its state enum 1:1; the deviation, if E09's author disagrees, is an E03
   change (drop the class from the catalog and the contact sheet), never a silent second tile.

## Definition of done

- [ ] Branch `epic/03-component-library` cut from `main`, all commits granular, tests committed with
      the code they cover.
- [ ] Fourteen catalog classes in `lib/ui/components/` plus `dashed_ink_border.dart`; seventeen
      glyphs in `lib/ui/glyphs/`. Every raised surface renders through `PopSurface`; no second
      `BoxDecoration` carrying border + shadow exists outside `pop_surface.dart`.
- [ ] Every component has: a golden per applicable state, a greyscale matrix golden with no two
      states colliding, and — if interactive — a tap-target and `Semantics` test.
- [ ] The 24-tuple overflow-and-fit matrix is green with nothing suppressed.
- [ ] `check_component_hygiene.sh lib` green **over real code**, alongside every other gate listed
      above.
- [ ] `catalog_contact_sheet.png` compared against `system.html` §10 in a browser, in the order
      structure → spacing rhythm → surface construction → type role → sampled hex; the result and the
      §10 entries compared are written into the PR body. Any reference change went into
      `system.html`/`app.html` with `capture-screens.sh` re-run and committed as a deliberate design
      change.
- [ ] `/simplify` run and its findings addressed.
- [ ] `/code-review` run and its findings addressed.
- [ ] `test/support/harness.dart` is extended, not forked: no `PopWidth`, no second `Device`, no second
      `pumpApp`; `loadAppFonts()`, `FakeFeedbackService` and `dart_test.yaml`'s `golden` tag all live
      here and no later epic re-creates them.
- [ ] `HudTone` exists once, in `lib/core/hud_tone.dart`.
- [ ] `dart format --set-exit-if-changed .`, `flutter analyze --fatal-infos`, `flutter test` and
      `bash tool/skill_gates.sh` green locally.
- [ ] PR opened explaining what changed, why, how it was verified, which gallery entries were
      compared, the `PopGridTile` naming deviation, and what was deliberately left out (motion timing →
      E04, screens → E07, board semantics → E08/E09).
- [ ] CI green on the PR.
- [ ] Merged preserving the granular commits, branch deleted, back on `main`, pulled.
