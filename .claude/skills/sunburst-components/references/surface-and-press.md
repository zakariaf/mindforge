# Surface geometry and the press

The whole direction is one rectangle drawn three times: a fill, a 3px ink edge on top of it, and an
ink copy of the silhouette offset down-and-right with no blur. Light comes from the top-left, always.
Slots below are `SunburstColors` (`colors`) and `SunburstShape` (`shape`).

## The three layers, in paint order

| Layer | Value | Notes |
|---|---|---|
| Hard shadow | `shape.shadow(offset, ink)` → `BoxShadow(color: ink, offset:, blurRadius: 0, spreadRadius: 0)` | The only `BoxShadow` factory in the app; it lives in `lib/theme/`. `ink` is `colors.border`, or `colors.borderDisabled` when disabled. |
| Fill | one semantic slot | `surfaceRaised` (paper), `surface` (cream), `surfaceSunk` (cream-2), `accent`, `success`, `danger`, or a game accent. Never a primitive. |
| Border | `Border.all(color: colors.border, width: shape.borderWidth)` | `BorderSide` defaults to `strokeAlign: inside`, so the layout box *is* the outer edge and the shadow offset is measured from it. |

## The elevation steps

`--sh-0` … `--sh-4` from system.html §07, and what each is spent on:

| Step | Offset | Press travel | Press scale | Spent on |
|---|---|---|---|---|
| `flat` | none | — | — | Pressed surfaces, found grid tiles, the ghost button, the locked card, the locked badge. |
| `e1` | `Offset(3, 3)` | `Offset(2, 2)` | `shape.pressScaleSmall` 0.97 | HUD pills, chips, grid tiles, icon buttons, badges, stat boxes, the active nav chip. |
| `e2` | `Offset(5, 5)` | `Offset(4, 4)` | `shape.pressScale` 0.98 | The default raised surface: buttons, cards, game cards, answer keys, settings groups. |
| `e3` | `Offset(8, 8)` | `Offset(7, 7)` | `shape.pressScale` 0.98 | Hero panels, the Stroop stimulus card, the results score slab, `PopSheet`. |
| `e4` | `Offset(10, 10)` | `Offset(9, 9)` | `shape.pressScale` 0.98 | **One per screen, maximum**: the countdown ring. Nothing else may claim e4. |
| `eChip` | `Offset(2, 2)` | n/a | n/a | *Derived.* The half-step under a selected segmented item, the hero swatch row and the stats value chip. |

Travel is `shape.pressTranslate(o)` = `Offset(o.dx - 1, o.dy - 1)`. The pressed shadow is always
`SunburstShape.pressedShadow` = `Offset(1, 1)` regardless of the rest step — a pressed e3 panel and a
pressed e1 tile both keep exactly 1px of ink, which is what makes "pressed" read as one state
everywhere. Never type the travel: an e3 surface that moves 4 instead of 7 looks broken, not custom.

## The press, frame by frame

```dart
// Rest → pressed, over motion.durTap (120ms) on motion.easePop — Cubic(0.2, 1.5, 0.4, 1.0).
boxShadow : shape.shadow(shape.e2, ink)  →  shape.shadow(SunburstShape.pressedShadow, ink)
transform : Matrix4.identity()           →  translate(4, 4) · scale(0.98) about the centre
fill      : unchanged                    →  unchanged (except DifficultySegmented, below)
```

`easePop` overshoots (control point 1.5), so the surface arrives slightly past its mark and settles —
that spring is the whole personality, and it is why `easeOut` is wrong here. `easePop` is legal on
transform and scale only; it returns values above 1.0, and a colour tween driven past its endpoint is
not a meaningful value. Release runs the same transition backwards over the same 120ms.

Two components deviate, deliberately:

- **`DifficultySegmented`** — the *selected* item lifts instead of pressing: `translate(-1, -1)` with
  `eChip` and a border that appears from transparent. Its pressed state fills with `accentDeep`
  (`#F2A81E`), drops the shadow entirely and moves `translate(1, 1)`. So selected ≠ pressed ≠ rest:
  three distinct silhouettes in one control.
- **`GridTile` found** — sinks to `translate(2, 2)` with no shadow and *stays there*. It is a
  permanent pressed state, not a transient one, which is why the found tile needs no glyph change to
  read as "done".

## Disabled

```dart
fill   : colors.surfaceSunk       // #FFEEDA — still cream, never a foreign grey
border : colors.borderDisabled    // #8E80AE ink-3 at 3px — the shape survives
label  : colors.textDisabled      // #8E80AE — disabled controls only, nothing else
shadow : shape.shadow(shape.e1, colors.borderDisabled)   // 3px 3px in ink-3
press  : none — no translate, no scale, no haptic
```

Transcribed from `.btn[disabled]{background:var(--cream-2);color:var(--text-disabled);
border-color:var(--ink-3);box-shadow:3px 3px 0 var(--ink-3);transform:none}`. The drop from e2 to e1
*is* the shape change §11 demands — disabled is never a colour swap alone. The ghost variant is the
exception: no fill, no border, no shadow, just `textDisabled` text.

Never `Opacity`. A 40%-opacity `PopSurface` fades its 3px border to a 40% ink measuring 4.9:1 against
cream instead of 14.55:1, and the border is the one element that may never lose contrast.

A Stroop answer key is the one surface that must **not** reach for `enabled: false` at all: the
`surfaceSunk` substitution would erase the hue that is the answer. It drops its `onTap` instead —
`sunburst-game-surfaces` rule 3 owns that exception, and `PopSurface` honours it by gating the fill
substitution on `borderStyle != none`.

## Reduced motion

`MediaQuery.disableAnimationsOf(context)` is read once per `PopSurface` build, and the duration comes
from `motion.resolve(context, motion.durTap)`. It changes two things and only two:

1. `durTap` → `Duration.zero`, so the state applies on the same frame.
2. The press **transform** is dropped: no translate, no scale.

The pressed **shadow** and any pressed **fill** still apply. system.html §09 is explicit — "the
pressed colour and shadow state still applies instantly, so feedback survives". A press that becomes
invisible under reduced motion is a lost acknowledgement, and the user taps again.

## Clipping and layout room

A hard offset shadow paints *outside* the layout box and is not hit-testable. Two consequences:

- Any ancestor with `Clip.hardEdge` / `ClipRRect`, or a `ListView`/`GridView` at its default
  `clipBehavior`, amputates the shadow on the trailing and bottom edges — pass `Clip.none`. The
  screens allow for the bleed: the 20px gutter and 16px card gap in `sunburst-shell-screens` exist
  partly to hold 5–8px of shadow.
- The focus ring extends further still: `focusGap` 3 + `focusWidth` 4 = 7px beyond the border, on all
  four sides. A component flush against a container edge shows a clipped ring only when focused —
  exactly the state nobody screenshots.
