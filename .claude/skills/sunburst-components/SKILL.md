---
name: sunburst-components
description: Enforces the Sunburst Pop component contract under lib/ui/components/ — every raised surface is a fill, a 3px `colors.border` edge and one hard `shape.shadow(offset, ink)` at blur and spread 0, built from one `PopSurface`: `PopButton`, `GameCard`, `DifficultySegmented`, `HudPill`, `GridTile`, `PopToggle`, `PopBadge`, `PopSheet`, `PopBottomNav`. Declares `PopElevation` and `kPopMinTarget`, and owns the press CHROME — `pressTranslate(offset)` to `pressedShadow` (1,1) while the 48px hit area holds still — which `PressPhysics` times. Material `elevation`, blur, spread, non-ink borders and `Opacity` fades are banned; focus is a 4px `focusRing` stroke outside a 3px gap. Use when building or reviewing a Sunburst surface, its states, or its press chrome.
---

# Sunburst Pop components

Sunburst Pop is one visual idea repeated without exception: **every surface is an ink-outlined object printed on top of the page, and it presses down when you touch it.** A component here is not a decoration recipe — it is `PopSurface` plus a fill, a radius, an elevation and a child. This skill owns *how a Sunburst surface is constructed and how it behaves under touch*, and the catalog of the thirteen classes the app is built from. It does not own the token values (`sunburst-tokens`), the screens the components sit on (`sunburst-shell-screens`), the board a game plugs in (`sunburst-game-surfaces`), or the timing of any moment that is not the press (`sunburst-motion-and-haptics`).

The authoritative source is `design/sunburst-pop/system.html` §07 Elevation, §10 Components and §11 Accessibility, plus `design/sunburst-pop/app.html` for how each component is actually spent on a screen. Where the two disagree, app.html wins on geometry — it is the shipped layout — and that is called out per component. Read them before changing a number here.

Read the reference for the task at hand:
- `references/component-catalog.md` — every component: purpose, anatomy, exact fill/radius/elevation/padding tokens, all states, dos and don'ts, and the screens it appears on.
- `references/surface-and-press.md` — the geometry of border + hard offset shadow + press translation, the rest/pressed/disabled triples per elevation step, and reduced-motion degradation.
- `references/states-and-affordance.md` — the full state matrix, the non-colour redundancy each state must carry, the ≥48px target rule and the focus-ring construction.

Run `scripts/check_component_hygiene.sh` and `sunburst-tokens`' `scripts/check_raw_values.sh` before a PR. Start a new component from `templates/component_template.dart`.

## The token surface this skill consumes

`sunburst-tokens` splits system.html §12's single `MindforgeTokens` into four extensions, and that split is the API: `SunburstColors.of(context)` (`border`, `borderDisabled`, `surfaceSunk`, `accent`, …), `SunburstShape.of(context)` (`borderWidth`, `radiusSm…Pill`, `e1…e4`, `shadow(offset, ink)`, `pressTranslate(offset)`, `pressScale`, `pressScaleSmall`, `focusGap`, `focusWidth`, plus the `static const` `pressedShadow`, `space1…space7`, `gutter`, `cardGap`, `cardPadding`), `SunburstMotion.of(context)` (`durTap`, `easePop`, `resolve(context, duration)`) and `SunburstType.of(context)` (`title`, `button`, `label`, `numericHud`, …). Local names in this skill are always `colors` / `shape` / `motion` / `type`, matching `sunburst-game-surfaces`, `sunburst-shell-screens` and `sunburst-motion-and-haptics`.

`PopElevation` (`flat`, `e1`…`e4`) is declared **here**, in `pop_surface.dart`, and is the app-wide vocabulary for "how high does this sit": `sunburst-game-surfaces`, `sunburst-shell-screens` and `sunburst-motion-and-haptics` all name it. There is no second elevation enum anywhere; `SunburstShape` deliberately has no `e0` field, because the absence of a shadow is `PopElevation.flat`, not a value to interpolate.

### Values this skill derives (they are NOT in system.html)

Everything else below is transcribed. These five are derivations — each is needed to build the components as drawn, and each is a **request to `sunburst-tokens`** for a new slot, never a literal typed into a widget. None of them exists on the shipped extensions yet. (`shape.pressScaleSmall` 0.97 used to be on this list; it is transcribed, not derived — `.tile/.tgl/.tab/.seg-i:active` state it — and `sunburst-tokens` now ships it alongside `pressScale`.)

| Derived slot | Value | Evidence |
|---|---|---|
| `shape.eChip` | `Offset(2, 2)` | The half-step shadow on `.seg-i.on`, `.swatchrow i` and `.bestcard .bv` — three sites, no constant. |
| `shape.borderWidthNested` | `2` | Every decorative sub-element ≤38px inside an already-bordered surface: `.bestpill`, `.srow .si`, `.gart .quad i`, `.cbprev i`, `.lg i`. |
| `shape.dashOn` / `dashOff` | `9` / `7` | The locked card's `border:3px dashed`. CSS defines no dash pitch and Flutter's `BorderSide` has none at all, so the edge is stroked by hand; 9-on/7-off matches the mockup at 3px. |
| `type.buttonLarge` | Fredoka 21 / 24 | `.btn--lg{font-size:21px}` on the two full-width Play buttons; the type scale stops at `button` 18. |
| `type.chip` | Fredoka 600 · 14 / 18 | `.chip` 14, `.badge` 14, `.pbadge` 15, `.bestpill` 12.5 all want one small display label; the scale jumps from `label` 10 straight to `button` 18. |

Off-scale radii in the mockups are drawing artifacts, not tokens: `.iconbtn` 15, `.bestcard .bv` 14, `.srow .si` 11, `.swatchrow i` 12 all snap to `radiusMd` (16) or `radiusSm` (10). The scale is 10 / 16 / 22 / 28 / 999 and nothing else.

## Non-negotiable rules

1. **Every raised surface is `fill + 3px border + one hard offset shadow`, produced by `PopSurface`.** The decoration is `BoxDecoration(color: fill, border: Border.all(color: colors.border, width: shape.borderWidth), borderRadius: …, boxShadow: shape.shadow(offset, ink))`. No component builds that map itself. WHY: the identity is a printed sticker; thirteen hand-rolled copies of one `BoxDecoration` drift within a sprint and the fourteenth reads as generic Material.

2. **`blurRadius` and `spreadRadius` are 0 everywhere, and Material `elevation` is banned.** No `elevation:` above `0` on `Card`/`Material`/`ElevatedButton`/`AppBar`/`FloatingActionButton`, no `PhysicalModel`, no `kElevationToShadow`. Material's own elevation is zeroed once, in the component themes in `lib/theme/`. WHY: a single `blurRadius: 4` stops the surface being die-cut card stock, and there is no visual state between "hard shadow" and "generic Material" — it reads as a bug, not a variation.

3. **The border colour is `colors.border` at `borderWidth` 3 on every fill.** The only legal alternatives are `colors.borderDisabled` (disabled) and no border at all (`PopButtonVariant.ghost`, the one sanctioned exception, reserved for a single dismissive action per screen). A decorative sub-element ≤38px nested inside an already-bordered surface uses `borderWidthNested` 2 of the same ink. WHY: the border is the brand — it is what survives greyscale, low vision and a 2-second App Store screenshot.

4. **Press translates by `shape.pressTranslate(offset)` and collapses the shadow to `pressedShadow` (1,1).** e1 moves 2, e2 moves 4, e3 moves 7, e4 moves 9; the surface also scales `shape.pressScale` 0.98 at e2+ and `shape.pressScaleSmall` 0.97 at e1, about its centre, over `motion.durTap` 120ms on `motion.easePop`. `PopElevation.pressScale(shape)` is the only place that picks between the two. Never write a `4`, a `2`, a `.98` or a `.97` — derive it. Disabled and non-interactive surfaces never move. This skill owns the *chrome* of the press; `sunburst-motion-and-haptics` owns its timing, its interruption rules and the commit haptic. WHY: the object must appear to be pushed *into* the page. A press that only changes colour is the fastest way to make this direction look like a web page.

5. **The hit area does not move with the visual press.** The `GestureDetector` and the ≥48px `ConstrainedBox` sit *outside* the transform that moves. WHY: 4px of travel under a fingertip resting near the edge slides the pointer off a target that moved, the tap is cancelled, and the user reports "the button ate my tap" — an untraceable bug from a purely visual change.

6. **Disabled stays inside the palette and changes shape, not just tone.** `surfaceSunk` fill, `borderDisabled` edge, `textDisabled` label, the shadow dropped to the e1 offset drawn in `borderDisabled` (`.btn[disabled]{box-shadow:3px 3px 0 var(--ink-3)}` — an e1 shadow in ink-3, never `flat`), no press response. Never `Colors.grey`, never `Theme.of(context).disabledColor`, never an `Opacity` wrapper. The **one** surface that must not use `enabled: false` is a Stroop answer key, because the `surfaceSunk` substitution would erase the hue that *is* the answer — it stops taking taps by dropping its `onTap` instead (`sunburst-game-surfaces` rule 3 owns that exception; `PopSurface` honours it by gating the fill substitution on `borderStyle != none`). WHY: `Opacity` fades the 3px ink border along with the fill, and the border is the one thing that must never fade; a grey from outside the palette is instantly a foreign object on cream.

7. **Recede by changing the fill, never by fading the element.** The found grid tile becomes `gameSchulteDeep` and drops to flat; it does not become a 40%-opacity idle tile. WHY: same as rule 6, and an opacity-faded surface is unmeasurable for contrast because its rendered colour depends on whatever is behind it.

8. **The focus ring is a 4px `colors.focusRing` stroke outside a 3px `colors.surface` gap, drawn outside the border and never replacing it.** It is painted as a stroke by `PopSurface`'s ring painter, not as a spread `BoxShadow`. WHY: the cream gap is what holds grape-pop at 4.1:1 against a sunshine fill instead of 2.8:1 measured directly — and painting it as a stroke lets rule 2 ban `spreadRadius > 0` absolutely, with no "except focus" carve-out for the gate to miss.

9. **Under reduced motion the press transform is dropped, but the pressed fill and shadow still apply, instantly.** `motion.resolve(context, motion.durTap)` collapses the duration to zero; the translate and scale go to identity; `pressedShadow` still replaces the rest shadow. WHY: a user who turned off animation still needs to know the tap registered — the acknowledgement survives on the channel that is not motion (system.html §09 says so explicitly).

10. **Every tap target is ≥48 logical px measured on the fill box, not on the shadow.** 48 is the house floor (system.html §11), above the 44px platform minimum owned by `accessibility-as-code`. The offset shadow is paint, not a hit region, and makes an object look 5px bigger than it is. Where the art must stay smaller — the 66×34 `PopToggle` — the enclosing 62px settings row owns the gesture and the toggle renders with `onTap: null`. WHY: a switch that looks like a target but is 34px tall fails every one-handed thumb test on a phone.

11. **Components are named `const` widget classes from the catalog; a surface that is not in the catalog is not a component.** `PopSurface`, `PopButton`, `PopCard`, `GameCard`, `DifficultySegmented`, `HudPill`, `TimerRing`, `PopProgressBar`, `GridTile`, `PopToggle`, `PopBadge`, `PopSheet`, `PopBottomNav`, plus the thin wrappers `PopIconButton` and `PopChip`. One file each under `lib/ui/components/`. The general no-`_buildX()` rule is owned by `widget-composition`; what is fixed *here* is the list. WHY: a fourteenth bespoke card invented inside a feature is the first place the 3px/hard-shadow contract silently stops being true.

12. **A component never constructs a `BoxShadow`, a `Duration`, a `Curve` or a `Color`.** It reads the four extensions and calls `shape.shadow(...)`. A value that does not exist yet is a new token slot in `lib/theme/`, added by `sunburst-tokens` — never a literal with an `// ignore`. WHY: the hygiene gate is a grep; the moment one component is allowed a literal, the gate stops being evidence of anything.

## The construction rule, in code

```dart
// WRONG — Material's elevation model. Blurred, ambient, and not this design system.
Card(
  elevation: 4,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
  child: child,
);

// WRONG — the right shape, hand-rolled: the day e2 changes, this copy does not.
Container(
  decoration: BoxDecoration(
    color: colors.surfaceRaised,
    border: Border.all(color: colors.border, width: 3),
    borderRadius: const BorderRadius.all(Radius.circular(22)),
    boxShadow: const [BoxShadow(color: Color(0xFF2B1B4D), offset: Offset(5, 5))],
  ),
  child: child,
);

// RIGHT — one primitive, one elevation step, one fill slot.
PopSurface(
  fill: colors.surfaceRaised,
  elevation: PopElevation.e2,
  radius: shape.radiusLg,
  padding: const EdgeInsetsDirectional.all(16),
  child: child,
);
```

## The press formula

```dart
// offsets: e1 (3,3) · e2 (5,5) · e3 (8,8) · e4 (10,10) · flat = no shadow
final rest    = elevation.restOffset(shape);       // PopElevation.e2 -> Offset(5, 5)
final travel  = shape.pressTranslate(rest);        // Offset(4, 4)  == (o.dx - 1, o.dy - 1)
final pressed = SunburstShape.pressedShadow;       // Offset(1, 1)  — every step lands here
final scale   = elevation.pressScale(shape);       // pressScaleSmall .97 at e1, else .98
```

`PopSurface` resolves those four values and hands them to `PressPhysics`
(`sunburst-motion-and-haptics`), which owns the controller, the interruption rules and the commit
haptic; the builder it calls back paints the chrome above. One press implementation, two owners, no
duplicated `GestureDetector`.

Rest → pressed is therefore: shadow `e2 → pressedShadow`, transform `identity → translate(4,4) · scale(0.98)`, duration `durTap` 120ms, curve `easePop`. The full per-step table — including why the *selected* segmented item moves the other way (`translate(-1,-1)` with `eChip`) — is in `references/surface-and-press.md`.

## The hit area never moves

```dart
// WRONG — the transform wraps the gesture: the target slides 4px on tap-down.
Transform.translate(
  offset: pressed ? const Offset(4, 4) : Offset.zero,
  child: GestureDetector(onTap: onTap, child: surface),
);

// RIGHT — gesture and minimum target on the outside; only the paint moves.
// This is PressPhysics' own shape: the opaque GestureDetector wraps the
// ConstrainedBox, which wraps the Transform. PopSurface passes `minTarget`
// down rather than applying it, because it is the only slot where the
// constraint is both outside the transform and inside the gesture.
PressPhysics(
  restShadow: rest, pressedShadow: SunburstShape.pressedShadow,
  travel: shape.pressTranslate(rest).dx,
  scale: elevation.pressScale(shape),
  minTarget: kPopMinTarget,               // 48
  commitMoment: Moment.buttonCommit,
  onPressed: onTap,
  builder: (context, press, child) => DecoratedBox(
    decoration: decorationFor(press.shadow, press.isDown),
    child: child,
  ),
  child: child,
);
```

Full primitive — press physics, disabled resolution, the focus-ring painter, the dashed edge and `Semantics` — in `examples/pop_surface.dart`. The button variants are in `examples/pop_button.dart`; the per-game home card with its best-score pill and locked variant is in `examples/game_card.dart`.

## Anti-patterns

- **`elevation:`, `Card`, `Material(elevation:)`, `PhysicalModel`, `kElevationToShadow`** — Material's ambient shadow model has no representation in this system.
- **`BoxShadow(blurRadius: 4)` "to soften it"** — there is no soft variant; flat/e1–e4 are the whole vocabulary.
- **`Border.all(color: colors.accent)`** — the border is always ink (or `borderDisabled`). A coloured edge is a different design system.
- **`Opacity(opacity: .4, child: PopSurface(...))`** for disabled or receded states — it fades the border; change the fill.
- **A `Transform` that wraps the `GestureDetector`** — moves the target under the finger.
- **A focus ring implemented as `BoxShadow(spreadRadius: 7)`** — it works, but it forces the hygiene gate to allow spread and it vanishes the moment a parent clips.
- **`ClipRRect` / `Clip.hardEdge` around a `PopSurface`**, or a scroll view with default `clipBehavior` — clips the 5px shadow and the 7px focus ring, and the bug only shows on the last row.
- **A shorter duration or a gentler curve under reduced motion** — collapse the transform to zero and keep the shadow change.
- **A `_buildCard()` helper inside a screen** instead of composing a catalog component — see `widget-composition`.
- **A component reading a game's colour from a global** — the accent arrives as a constructor argument; `sunburst-game-surfaces` owns that contract.

## Definition of done

- [ ] `scripts/check_component_hygiene.sh` and `check_raw_values.sh` are clean over `lib/`.
- [ ] Every raised surface in the diff renders through `PopSurface`; no second `BoxDecoration` carrying a border + shadow exists outside `lib/ui/components/pop_surface.dart`.
- [ ] Every pressable surface presses: translate `pressTranslate(offset)`, shadow `pressedShadow`, scale 0.98/0.97, `durTap`, `easePop`.
- [ ] The gesture and the ≥48px constraint sit outside the moving transform; verified by a tap test at the target's edge *during* the press.
- [ ] Disabled = `surfaceSunk` fill + `borderDisabled` edge + `textDisabled` label + e1 shadow in `borderDisabled`; no `Opacity`, no off-palette grey.
- [ ] Focus renders a 4px `focusRing` stroke outside a 3px `surface` gap on every interactive component, on light *and* saturated fills.
- [ ] Reduced motion drops the transform, keeps the pressed shadow and fill, and the end state is identical.
- [ ] Every state in the component's row of `references/states-and-affordance.md` carries at least one non-colour channel.
- [ ] A greyscale golden of the component still answers "which state is this?" (`widget-golden-and-a11y-testing` owns the harness).

## Boundaries

- `sunburst-tokens` owns the token values, the four `ThemeExtension`s that carry them and the no-raw-values gate. Every number here is read from it; the six derived slots above are *requests* to that skill, not local constants.
- `sunburst-shell-screens` owns which components appear on each of the eight screens, their order, the 20px gutter / 16px card gap rhythm around them, the `HudTone` enum this skill's `HudPill` renders, the screen-shaped composites that merely *compose* `PopSurface` (`RayHeader`, `HalftoneDots`, `PlayBand`, `GameHeroPanel`, `DailyMixCard`, `StatBox`, `ScoreSlab`, `BestCard`, `Wordmark`), and the drawn glyph set `SunburstGlyph` in `lib/ui/glyphs/`. None of those is a component in this catalog; adding a new visual vocabulary to one is this skill's problem, placing it is theirs.
- `sunburst-game-surfaces` owns the accent contract a `GameCard` and a play band consume, the gameplay palette, the `PlayFill` patterns and the board/tile semantics beyond `GridTile`'s four visual states.
- `sunburst-motion-and-haptics` owns the press *controller* — `PressPhysics`, which `PopSurface` composes: the `durTap` tween, `animateTo`-not-`forward` interruption, and the single commit haptic through `FeedbackService`. It also owns every moment that is not the press: correct, wrong, found, countdown, personal best, the wrong-tile shake, `Moment.timerAlarm`. This skill owns the *chrome* that controller drives — fill, border, shadow, radius, focus ring — and `PopElevation`, which resolves an elevation to the offsets and scale `PressPhysics` is handed. There is exactly one press implementation in the app.
- `design-system-structure` owns `ThemeExtension` mechanics, the asserting `of(context)` and the reduced-motion resolve helper; this skill only fixes what components do with them.
- `widget-composition` owns const widget classes, the `_buildX()` ban, key policy and lean `build()`; this skill only fixes the catalog.
- `accessibility-as-code` owns `Semantics` roles, the 44px platform floor, redundant-encoding theory and traversal order; this skill fixes the 48px house floor and the per-state channels.
- `custom-canvas-and-gestures` owns the painters behind `TimerRing`'s sweep, the striped `PopProgressBar` fill and the Stroop stimulus glyph.
- `widget-golden-and-a11y-testing` owns the golden and a11y harness the state matrix is verified with.

## References

- `design/sunburst-pop/system.html` — §07 Elevation (the press rule), §10 Components (every state, rendered live), §11 Accessibility, §12 Flutter mapping.
- `design/sunburst-pop/app.html` — the eight screens; component geometry as actually shipped.
- Flutter API — [`BoxShadow`](https://api.flutter.dev/flutter/painting/BoxShadow-class.html) · [`FocusableActionDetector`](https://api.flutter.dev/flutter/widgets/FocusableActionDetector-class.html) · [`AnimatedContainer`](https://api.flutter.dev/flutter/widgets/AnimatedContainer-class.html) · [`MediaQuery.disableAnimationsOf`](https://api.flutter.dev/flutter/widgets/MediaQuery/disableAnimationsOf.html)
