# Board states and layout

A board state must be readable with no colour vision, in a greyscale screenshot, and with animations
off. That means every state differs from every other in **at least three non-hue channels**. Values
are from `system.html` §10 (Grid tile, Stroop answer buttons) and `app.html` screens 04–05; anything
marked **derived** is not in the design source.

## Grid tile state matrix — Schulte

| State | Fill | Border | Shadow | Transform | Glyph | Extra |
|---|---|---|---|---|---|---|
| idle | `surface` `#FFF8EC` | 3px `border` | e1 (3,3) | none | `textPrimary` 24px | — |
| next | `accent` `#FFC53D` | 3px `border` | e2 (5,5) | `scale 1.02` | `textPrimary` 24px | double ring: 2px `surface` spread, then 3px `border` spread |
| found | `gameSchulteDeep` `#12A79A` | 3px `border` | **none** | translate (2,2) | `textPrimary` 24px (5.1:1) | — |
| wrong | `danger` `#D81E2C` | 3px `border` | e1 (3,3) | shake ±4px, 240ms ×2 | `surfaceRaised` | shake omitted under reduce-motion |
| disabled **(derived)** | `surfaceSunk` `#FFEEDA` | 3px `borderDisabled` `#8E80AE` | e1 (3,3) **in `borderDisabled`** | none | `textDisabled` | not a control: no `onTap` |

The disabled row is `PopSurface`'s own disabled shape, not a second implementation of it: passing
`enabled: false` swaps the fill to `surfaceSunk`, the edge to `borderDisabled`, and drops the shadow
one step *and repaints it in `borderDisabled`* — `.btn[disabled]{box-shadow:3px 3px 0 var(--ink-3)}`
is an e1 shadow in ink-3, not the absence of one. Pass the tile's normal `PopElevation`, never
`flat`, or this tile disagrees with every other disabled surface in the app.
`sunburst-components` owns that behaviour — the board's job is to know that it fires and to
never reach for `Opacity` instead.

Channel audit — every pair differs in ≥3 of {shadow depth, transform, border colour, glyph colour, ring}:

- idle ↔ next: shadow e1→e2, ring absent→present, scale 1.00→1.02, fill.
- idle ↔ found: shadow present→absent, translate 0→(2,2), fill.
- idle ↔ wrong: glyph ink→paper, motion none→shake, fill.
- idle ↔ disabled: shadow ink→ink-3, border ink→ink-3, glyph ink→ink-3, fill.
- found ↔ disabled: shadow absent→e1 in ink-3, translate (2,2)→0, border ink→ink-3, glyph ink→ink-3.
- wrong ↔ next: shadow e1→e2, ring absent→present, glyph paper→ink.

**Never use `Opacity` or `withOpacity` for found or disabled.** Element opacity fades the 3px ink
border along with the fill, and the border is the brand — `system.html` §11 lists it under "never
allowed". Recede by changing the fill.

## Stroop answer key and stimulus states

| State | Fill | Shadow | Transform | Extra | Notes |
|---|---|---|---|---|---|
| idle | `answerColour(a, …)` | e2 (5,5) | none | 56px ink key panel painted with `a.fill` | label `answerLabel(a)` |
| pressed | unchanged | (1,1) | translate (4,4) + `scale 0.98` | — | `sunburst-components` owns the physics |
| accepted **(derived)** | unchanged | e3 (8,8) | none | — | lifts and holds for `durState`; **never `success`** |
| rejected **(derived)** | unchanged | none | translate (2,2), shake 240ms ×2 | 6px ink strike bar across the key panel | **never `danger`** |
| locked **(derived)** | unchanged | none | none | — | between rounds; `onTap` dropped, whole set at once |

Every one of those keeps its own hue — and that is why an answer key is the one surface in the app
that must **not** use `PopSurface(enabled: false)` to stop taking taps: the disabled shape swaps the
fill to `surfaceSunk`, which would erase the answer. A resolved key drops its `onTap` instead. On a
`mechanic` board, feedback that recolours the surface is banned: the fill *is* the question. Depth,
the strike bar, the transform and the ink glyph are the channels — four of them, all hue-free.
`locked` is the one state that does not need to be told apart from another key, because it is applied
to the whole set at once between rounds; depth alone carries it.

The stimulus card is `surfaceRaised`, 3px `border`, `radiusXl` (28), shadow **e3 (8,8)**, with a 14%
ink dot layer over it, a 12px uppercase `textSecondary` prompt, then the word. The word is three
passes (`system.html` §12):

1. `Paint()..style = PaintingStyle.stroke..strokeWidth = 6..color = colors.border`
2. filled with `colors.answerColour(a, colourBlind: …)`
3. the `a.fill` pattern in `colors.border`, masked to the glyph

Pass 1 is what makes the colour game legible (effective contrast is ink-on-cream, 14.55:1). Pass 3 is
what makes it playable with no colour vision. Neither is optional; a single `Text` widget in an
answer colour is a 1.76:1 bug the moment the answer is yellow.

## Sizing — the square-cell maths

The board is handed a slot by `PlayScaffoldScreen` and sizes itself into it. It never assumes a
screen size and never hardcodes a cell.

```
side = min(constraints.maxWidth, constraints.maxHeight)
cell(gap) = (side - gap * (n - 1)) / n          // n = 5 for Schulte
gap  = cell(12) >= 48 ? 12 : 8                  // 4/8/12/16/20/28/40 scale
```

The gap step is derived from the **tap-target floor**, not from a device width. Keep app.html's 12px
gap unless it would put the cell under 48px, then step to 8px — the next value down the spacing
scale. With the shell's 20px gutter on each side:

| Screen width | Board width | gap | cell | ≥48px target? |
|---|---|---|---|---|
| 320 | 280 | 8 | **49.6** | yes (12px gap would give 46.4 — **fails**, which is what triggers the step) |
| 360 | 320 | 12 | **54.4** | yes |
| 390 | 350 | 12 | **60.4** | yes — inside the design's 60–64 |
| 430 | 390 | 12 | **68.4** | yes |

Writing the step as `cell(12) >= 48 ? 12 : 8` rather than as a width breakpoint means the rule
carries its own reason: the only screen it fires on today is 320px, and a future board with a
different cell count re-derives the answer instead of inheriting a magic number. The 48px floor
itself belongs to `accessibility-as-code`.

**Shadow and ring bleed are not laid out.** The e1 shadow paints 3px outside the box, so the gap must
stay ≥ the shadow offset (8 ≥ 3 ✓). The `next` tile's double ring bleeds 5px on every side and its
`scale 1.02` bleeds ~0.6px more — the ring is a `CustomPaint` **stroke** outside the layout box (2px
cream at 0–2, then 3px ink at 2–5, the same construction `PopSurface` uses for the focus ring) and
the scale is a `Transform`. Neither adds layout size, so the grid geometry is identical whichever
tile is next. Do **not** express the ring as a spread `BoxShadow`: `sunburst-tokens` bans a non-zero
`spreadRadius` outright and the gate greps for it. The focus ring bleeds 7px (3px cream gap + 4px
stroke); only one tile is ever focused, so it never meets another ring.

The grid itself must set `clipBehavior: Clip.none` — `GridView` clips to its own box by default, and
the default would shear off both the hard shadow and the ring.

## Large text

A fixed-count grid cannot grow its cell — the count is the game's rule. So text scale is absorbed by
**choosing a smaller base style**, and the user's multiplier still applies on top. This is not
clamping: `MediaQuery.withClampedTextScaling`, `FittedBox` and `TextOverflow.ellipsis` are banned
outright.

At 360px the cell is 54.4px; minus 2×3px border and 2×2px inner padding the label box is **44.4px**.
A 2-digit label at the 24px display size needs ~48px at scale 2.0 — it overflows. So:

```dart
// DERIVED: SunburstType has no tile slot at all. system.html §10 draws the tile at
// 24px display/700/tabular, so sunburst-tokens owes `tileGlyph` (24) and
// `tileGlyphCompact` (18). Until they land, `numericHud` (22, tabular) and `button`
// (18) are the nearest shipped slots — which is what examples/schulte_board.dart
// uses, and it renders 2px small.
final type = SunburstType.of(context);
final scaler = MediaQuery.textScalerOf(context);
final style = scaler.scale(type.numericHud.fontSize!) <= innerBox
    ? type.numericHud
    : type.button;                     // 18 × 2.0 = 36 <= 45.6
```

The same shape applies to the Stroop stimulus: the `stimulus` slot is 78px, and a 6-letter word
("YELLOW", "PURPLE") at scale 2.0 needs roughly 580px of width against ~320px available. It needs a
`stimulusCompact` (**derived**, ~54px) chosen by the same measured rule, and the word may wrap to two
lines — it must never be shrunk to fit or truncated.

Both `tileGlyphCompact` and `stimulusCompact` are additions to `SunburstType`, owned by
`sunburst-tokens`. They do not exist in `system.html` today; adding a board without them means the
board is only verified to about 1.5× scale, and that must be logged as a BLOCKER in
`design-review-workflow` rather than papered over.

## Small screens, other levers

If a board still does not fit at 320px after the gap step: drop the board slot's gutter from 20 to 16,
then its top padding from 20 to 12 (both on the 4/8/12/16/20 scale). Collapsing the play band to buy
height is `sunburst-shell-screens`' call, not the board's — it changes every game.

Never a lever: a smaller tap target, a clamped scaler, an ellipsis, or a scrollable Schulte grid.
The whole point of the grid is that all 25 cells are visible at once.
