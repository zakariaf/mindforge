---
name: sunburst-tokens
description: Enforces the Sunburst Pop token VALUES for MindForge — hexes transcribed from design/sunburst-pop/system.html onto SunburstColors, SunburstShape, SunburstMotion and SunburstType, primitives fenced in _P behind an asserting of(context); `border` always resolves to ink #2B1B4D, shadows are hard offsets e1 3/e2 5/e3 8/e4 10 at blurRadius 0, gameplay palette never paints chrome so the colour-blind swap cannot repaint `danger`, textDisabled #8E80AE is disabled-only, fonts bundled, light theme only, nothing over 240ms. Fixes the four durations and two press scales; which moment spends them is sunburst-motion-and-haptics'. Use when touching a colour, radius, shadow, duration, curve or type step, adding a token slot, editing lib/theme/**, wiring buildSunburstTheme(), or running check_raw_values.sh / check_palette_contrast.sh.
---

# Sunburst Pop tokens

Sunburst Pop is arcade-cabinet joy: chunky, physical, everything looks pressable. That personality is not a mood — it is roughly ninety numbers, and this skill owns every one of them. It owns the values and the Dart types that carry them: colour, size, radius, border width, shadow, duration, curve and type step. It does **not** own how a `ThemeExtension` works, what a component does with a token, or which moment spends which duration — those belong to the siblings named at the end.

The hex values in `design/sunburst-pop/system.html` are the truth. Read it before changing a value here; do not use a colour from memory, and do not improve one.

Read the reference for the task at hand:
- `references/palette-and-slots.md` — every primitive, semantic slot and gameplay colour as a table (name, hex, CSS var, Dart field, role, where used), plus measured WCAG ratios for every text/surface pair and the two hexes that deliberately appear twice.
- `references/shape-and-type.md` — the radius scale and what earns each step, the four hard-shadow steps and the press geometry, the spacing rhythm, all ten type steps with measured tracking, and the pubspec font bundling.
- `references/adding-a-token.md` — the six-step decision procedure for a new value, with a worked legitimate new slot and a worked request that should reuse one.

Run `scripts/check_raw_values.sh` and `scripts/check_palette_contrast.sh` before a PR.

## Non-negotiable rules

1. **Every aesthetic value lives in `lib/theme/**` and reaches a widget as a named slot.** A `Color(0x…)`, `Colors.*`, `Curves.*`, `Cubic(`, `Duration(milliseconds:`, `BorderRadius.circular(n)`, `fontSize:`, `fontFamily:`, `letterSpacing:`, a non-zero `blurRadius:`/`spreadRadius:`, or a `.withOpacity(` anywhere else fails `scripts/check_raw_values.sh`. A value you cannot express as a slot is a **new slot, never a `// ignore:`**. WHY: reskinning MindForge, or auditing what it actually renders, must be a diff of one directory.
2. **Widgets read `SunburstColors.of(context)`; nothing outside `lib/theme/sunburst_primitives.dart` may name `_P`.** The primitive tier answers "what value is this" (`sunshine`, `coral`); the slot tier answers "what is this for" (`accent`, `gameStroop`). A widget that reaches `_P.coral` has hardcoded Stroop Rush's identity into a shared surface. `of()` asserts on a missing extension — never `?? fallback`, which would ship a palette no golden has ever rendered.
3. **`border` is a semantic slot and it always resolves to ink `#2B1B4D`.** Not a tinted edge, not a lighter border on a light fill, never faded. Every surface in the app carries the same ink at the same 3px, and every hard shadow is painted in that same slot. WHY: the border is structural, not decorative — it is what makes every surface boundary survive greyscale, low vision and a 2-second App Store screenshot. Consistency *is* the style here; a "softer" border on one card breaks the whole direction, not just that card.
4. **The shadow is an ink rectangle offset down and right; `blurRadius` and `spreadRadius` are 0 at every step.** Offset scales with elevation — e1 `(3,3)`, e2 `(5,5)`, e3 `(8,8)`, e4 `(10,10)` — and blur never does, because there is none. There is no `e0` field: the absence of a shadow is `const <BoxShadow>[]`, named `PopElevation.flat` by `sunburst-components`, and `--sh-0` by system.html. `SunburstShape.shadow()` is the only `BoxShadow` constructor in the app. Material's own `elevation` is zeroed on every component theme. WHY: one blurred shadow turns a die-cut plastic object into a generic Material card, and the two never sit on the same screen convincingly.
5. **The gameplay palette is a separate tier: it never paints chrome, and chrome never paints an answer.** `danger` and `accentAlt` are wired to the **primitives** `_P.playRed` and `_P.grape`, not to the `playRed`/`playPurple` slots that share their hex. WHY: the colour-blind setting re-points the `red` answer to `cbPink`; a HUD alarm or a destructive-confirm button aliased to the gameplay slot would silently turn magenta for exactly the players who need the alarm most.
6. **`playYellow` at 1.76:1 on cream is never legal as bare text.** The Stroop stimulus is always three paint passes — an ink stroke, the answer hue, then the `PlayFill` pattern clipped to the glyph — so effective contrast is ink-on-cream 14.55:1 and the hue is decoration on an already-legible shape. Labels come from `answerLabel()`, never picked at the call site. WHY: a yellow dark enough to reach 4.5:1 reads as brown, and "which colour is this" is the entire game.
7. **`textSecondary` (`#5A4A7D`) is legal on `surface`, `surfaceSunk` and `surfaceRaised` only** — 7.34 / 6.82 / 7.75. On a saturated fill it collapses: 2.77 on coral, 3.66 on turquoise. On any fill the label is `textPrimary` or `textInvert`, and which one is stated in the token table, not decided per call site. WHY: this is the single most common way an on-brand screen ships illegible.
8. **`textDisabled` (`#8E80AE`, 3.40:1 on cream) is legal on a disabled control and nowhere else, and never alone.** A disabled surface also drops its border to `borderDisabled` and its shadow one step, repainted in `borderDisabled` — `.btn[disabled]{border-color:var(--ink-3);box-shadow:3px 3px 0 var(--ink-3)}`, so an e2 button disables to an e1 shadow in ink-3, not to no shadow at all. The shape changes, not just the colour; `sunburst-components` owns applying it. A tagline, a status line or a helper caption is `textSecondary`. WHY: 3.40:1 is below the body floor and only survives because WCAG 1.4.3 exempts disabled controls; borrowing it for live text quietly ships failing copy.
9. **Four durations and three curves, and `easePop` only drives transform.** `durTap` 120 / `durState` 160 / `durMove` 180 / `durCelebrate` 240 — nothing longer, because past 240ms this direction reads sluggish and cheap. `easePop` is `Cubic(0.2, 1.5, 0.4, 1)` and overshoots past 1.0, so it is legal on scale and translate only; every colour and opacity transition takes `easeOut`. Reduced motion collapses to `Duration.zero` via `SunburstMotion.resolve`, never to a shorter duration. WHY: a colour tween driven past its endpoint has no defined meaning, and a user who asked the OS to stop animations asked for stop.
10. **Ten type steps, no eleventh, and the fonts are bundled.** Fredoka 600/700 and Nunito 700/800 ship as assets; there is no `google_fonts`, no runtime fetch, no HTTP path in an offline app. `scoreHero` and `numericHud` carry `FontFeature.tabularFigures()`. Where `system.html` §04 and §12 disagree on a weight (`title`, `button`), §04 wins — it is the rendered specimen. WHY: a size not on the list is a design decision nobody made, and an HUD whose digits change width jitters every second of a run.
11. **Light theme only. There is no `darkTheme:`, no `themeMode`, no `Brightness.dark` `ColorScheme`.** `buildSunburstTheme()` returns exactly one `ThemeData`. WHY: the identity is ink-on-cream with ink shadows; inverting it makes ink a warm off-white and shadows a deeper plum, which is a different product wearing the same layout. If low-light use is ever requested, the honest answers are a screen-dimming overlay or a separate design direction — not a token flip. See below.
12. **Adding a value means adding a semantic slot, and touching four places plus the gate.** Field + constructor, `copyWith`, `lerp`, the `const sunburstPop` instance — and a `// @contrast` declaration. The compiler catches only the fourth. WHY: the classic design-system rot is a slot added to the constructor and forgotten in `lerp`, where it then never interpolates, silently, forever. Procedure and worked examples: `references/adding-a-token.md`.

## The two tiers, instantiated

`_P` (primitives) → `SunburstColors` (slots) → widgets. Eight chrome families plus the separate gameplay tier. Most chrome families carry a `-deep` partner so a two-tone stripe or ray can still hold an ink glyph; tangerine has none, because nothing in the system stripes in warning. A `-deep` is *not* a hover or pressed tint — press is a translate, not a tint.

| Family | Base / deep | Slot it feeds |
|---|---|---|
| cream | `#FFF8EC` / `#FFEEDA` / `#F6E3C6` / `#F2DFC0` | `surface`, `surfaceSunk`, `divider`, `dotPattern` |
| ink | `#2B1B4D` / `#5A4A7D` / `#8E80AE` | `textPrimary`, `textSecondary`, `textDisabled`, `border` |
| sunshine | `#FFC53D` / `#F2A81E` | `accent`, `accentDeep` |
| coral | `#FF6B5A` / `#E8452F` | `gameStroop`, `gameStroopDeep` |
| turquoise | `#22C7B8` / `#12A79A` | `gameSchulte`, `gameSchulteDeep` |
| grape | `#6A45E8` / `#7C5CFF` | `accentAlt`, `focusRing` |
| leaf | `#4CC86A` / `#2FA64F` | `success`, `successDeep` |
| tangerine | `#FF9330` | `warning` |
| gameplay | `#D81E2C` `#1F6BE0` `#157A39` `#F5B301` `#6A45E8` `#C24409` `#C2185B` | `playRed`…`cbPink` — and `danger` |

Full tables with every measured ratio: `references/palette-and-slots.md`. The complete Dart: `examples/sunburst_theme.dart`.

## The gameplay tier is not the UI palette

```dart
// WRONG — the hex is right today and the wiring is a time bomb.
// Turning on Settings → "Colour-blind friendly palette" re-points the red
// answer to cbPink, and this alarm goes magenta.
final fill = isAlarm ? colors.playRed : colors.surfaceRaised;

// RIGHT — `danger` reads the PRIMITIVE _P.playRed and cannot be re-pointed.
final fill = isAlarm ? colors.danger : colors.surfaceRaised;

// RIGHT — inside a board, the only place an answer colour is resolved.
// The flag is threaded in by the ViewModel; no widget branches on it.
final key = colors.answerColour(answer, colourBlind: cvd);
final label = colors.answerLabel(answer); // ink on yellow, paper on the rest
```

The grep gate cannot see this — it only knows raw values, not tier. It is a review finding, and `sunburst-game-surfaces` owns the board side of the boundary.

## Hard shadow, and press as geometry

```dart
// WRONG — three separate breaks: Material's own soft elevation, a blur, and a
// press expressed as a colour change instead of a movement.
Material(elevation: 4, child: ...)
BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))
color: isPressed ? colors.accentDeep : colors.accent

// RIGHT — the shadow is the border's own ink, offset, unblurred; the press is
// DERIVED from the resting elevation, so every surface moves by the same law
// and no component ever types its own travel distance.
final shape = SunburstShape.of(context);
final colors = SunburstColors.of(context);
final motion = SunburstMotion.of(context);
final rest = shape.e2;                    // a card or button
final travel = shape.pressTranslate(rest); // e2 -> 4px, e1 -> 2px

return AnimatedContainer(
  duration: motion.resolve(context, motion.durTap),
  curve: motion.easePop, // legal here: this drives a transform, not a colour
  transform: Matrix4.translationValues(
    isPressed ? travel.dx : 0,
    isPressed ? travel.dy : 0,
    0,
  ),
  decoration: BoxDecoration(
    color: colors.accent,
    borderRadius: BorderRadius.all(shape.radiusLg),
    border: Border.all(color: colors.border, width: shape.borderWidth),
    boxShadow: shape.shadow(
      isPressed ? SunburstShape.pressedShadow : rest, // (1,1) : (5,5)
      colors.border,
    ),
  ),
);
```

`sunburst-components` owns the `PopSurface` and the `PopElevation` enum that resolve a step to these
numbers; `sunburst-motion-and-haptics` owns `PressPhysics`, the one controller that animates them.
This skill owns only the numbers. The `AnimatedContainer` above is the mechanism shown bare — no
component writes it, because the two of them already did.

## Motion: the curve depends on the property

```dart
final motion = SunburstMotion.of(context);

// WRONG — easePop overshoots past 1.0. A colour driven beyond its endpoint is
// not a colour anyone chose, and 300ms is not one of the four durations.
AnimatedContainer(duration: const Duration(milliseconds: 300), curve: motion.easePop, color: ...)

// RIGHT — colour and opacity take easeOut at durState; easePop is for scale
// and translate. resolve() is the only place a widget asks whether to animate.
AnimatedContainer(
  duration: motion.resolve(context, motion.durState),
  curve: motion.easeOut,
  color: ...,
);
```

## Light only — and what to do instead

There is one `ThemeData`. `MaterialApp` gets `theme:` and nothing else; no `darkTheme`, no `themeMode`, no persisted theme setting, no `Brightness` branch anywhere in `lib/theme/`. `SunburstColors.lerp` is still implemented honestly because golden harnesses and previews drive it, but it never runs in production.

The reason is mechanical, not stylistic. Inverting this palette does not produce a dark Sunburst Pop — it produces a different product: `ink` would have to become a warm off-white, every hard shadow would have to become a deeper plum (a shadow the same colour as the text is only legible on a light ground), and the nine saturated fills would all need re-derivation to hold a light label. The measured ratios in `references/palette-and-slots.md` would all be void.

If low-light use is requested: offer a brightness/dimming overlay, or treat a dark variant as a **separate design direction** with its own `system.html`, its own measurements and its own review — never as a toggle over these tokens. Adding `Brightness.dark` to `_sunburstColorScheme` is the wrong answer no matter how much it looks like the cheap one.

## Definition of done

- [ ] `scripts/check_raw_values.sh` is clean over `lib/` — no raw aesthetic value outside `lib/theme/`, no `// ignore:` added to make it pass.
- [ ] `scripts/check_palette_contrast.sh` is clean — every text/surface pair the theme declares meets 4.5 (body) or 3.0 (large + UI), recomputed from the shipped hexes.
- [ ] Every value a widget renders traces to a slot on `SunburstColors` / `SunburstShape` / `SunburstMotion` / `SunburstType`, read via an asserting `of(context)`.
- [ ] No file outside `lib/theme/sunburst_primitives.dart` names `_P`; no chrome slot reads a `play*`/`cb*` field.
- [ ] Every hex in `_P` matches `design/sunburst-pop/system.html`; anything derived rather than transcribed is marked `DERIVED` with its reason.
- [ ] Any new slot appears in the constructor, `copyWith`, `lerp`, `_props`, the `const sunburstPop` instance, `references/palette-and-slots.md`, and a `// @contrast` line.
- [ ] Every `BoxShadow` in the app comes from `SunburstShape.shadow()` with `blurRadius: 0`.
- [ ] Fonts are bundled in `pubspec.yaml` with the OFL registered; no `google_fonts` import.
- [ ] Exactly one `ThemeData`; no `darkTheme`, no `themeMode`, no `Brightness.dark` scheme.

## Boundaries

- `design-system-structure` owns the **mechanism** — `ThemeExtension` semantics, the asserting `of()`, hand-authoring a `ColorScheme` instead of `fromSeed`, honest `lerp`, font bundling and `LicenseRegistry`, and the general no-raw-values gate. This skill fixes the values those mechanics carry.
- `sunburst-components` owns what a surface *does* with these numbers: `PopSurface`, `PopElevation` (the one elevation enum — this skill deliberately ships no `e0`), `kPopMinTarget` 48, the press chrome, per-component state, focus rendering.
- `sunburst-motion-and-haptics` owns the moment catalog — which moment spends `durTap` vs `durCelebrate`, the `FeedbackService` haptic map, `PressPhysics` (the one press controller), and each moment's reduced-motion fallback. This skill only fixes the four durations, three curves and two press scales.
- `sunburst-game-surfaces` owns the board: the accent contract for a new game, how the colour-blind flag is threaded, `PlayFill` painting, and tile states.
- `sunburst-shell-screens` owns where the 20pt gutter and 16pt stack gap are applied across the eight screens.
- `accessibility-as-code` owns the a11y floor itself — reading flags from `MediaQuery`, 44/48px targets, redundant non-colour channels, and the ban on `FittedBox`/clamped `textScaler` to make text fit.
- `widget-composition` owns const widget classes and directional geometry; `custom-canvas-and-gestures` owns snapshotting these tokens into a `CustomPainter` so `paint()` never touches `BuildContext`.
- `app-startup-and-bootstrap` owns injecting the built `ThemeData` once at the composition root; `lint-and-style-config` and `ci-pipeline-and-gates` own promoting both scripts into CI.

## References

- Design source of truth — `design/sunburst-pop/system.html` (§02 colour, §04 type, §05 spacing, §06 radius, §07 elevation, §09 motion, §12 Flutter mapping), `design/sunburst-pop/app.html`, `design/sunburst-pop/README.md`.
- Flutter API — `ThemeExtension`: https://api.flutter.dev/flutter/material/ThemeExtension-class.html
- Flutter API — `ColorScheme` (M3 role names): https://api.flutter.dev/flutter/material/ColorScheme-class.html
- Flutter API — `FontFeature.tabularFigures`: https://api.flutter.dev/flutter/dart-ui/FontFeature/FontFeature.tabularFigures.html
- Flutter cookbook — Use a custom font: https://docs.flutter.dev/cookbook/design/fonts
- W3C WAI — WCAG 2.2 SC 1.4.3 Contrast (Minimum): https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html
- W3C WAI — WCAG 2.2 SC 1.4.11 Non-text Contrast: https://www.w3.org/WAI/WCAG22/Understanding/non-text-contrast.html
