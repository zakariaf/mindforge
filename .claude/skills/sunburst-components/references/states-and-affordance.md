# States, affordance and targets

Five states exist in this system: **rest · pressed · disabled · selected · focused**. A component that
cannot answer what each of its five looks like is not finished. Colour is never the answer on its own —
every state changes at least one of *shadow depth, translation, border weight, glyph, label or
position*.

## The state matrix

| Component | Rest | Pressed | Disabled | Selected | Focused |
|---|---|---|---|---|---|
| `PopButton` primary | `accent`, e2 | +(4,4), `pressedShadow`, ×0.98 | `surfaceSunk`, `borderDisabled` edge, `textDisabled` label, e1 in ink-3 | — | ring, e2 kept |
| `PopButton` ghost | 3px ink rule under the label | +(2,2), ×0.98 | `textDisabled` text only | — | ring around the text box |
| `PopCard` | `surfaceRaised`, e2 | only if `onTap` | n/a (cards do not disable) | — | ring if tappable |
| `GameCard` | accent, e2 | +(4,4), `pressedShadow`, ×0.98 | locked: dashed edge, no shadow, padlock badge | — | ring, e2 kept |
| `DifficultySegmented` | `textSecondary`, transparent border | `accentDeep`, no shadow, +(1,1) | `textDisabled` + padlock glyph | `accent`, ink border, `eChip`, −(1,1) | ring around the item |
| `HudPill` | `surfaceRaised`, e1, `textSecondary` label | not pressable | n/a | highlight: `accent` + both lines `textPrimary` · alarm: `danger` + both lines `surfaceRaised` | not focusable |
| `TimerRing` | e1 (e4 countdown) | not pressable | n/a | low: sweep crosses to `danger` *(DERIVED, same reason as the alarm pill)* | not focusable |
| `PopProgressBar` | track + striped fill + 3px ink right edge | not pressable | n/a | complete: right edge gone | not focusable |
| `GridTile` | `surface`, e1 | +(2,2), `pressedShadow`, ×0.97 | found is terminal, not disabled | next: e2, ×1.02, double ring | ring, e1 kept |
| `PopToggle` | track + "OFF" right | row press, +(2,2) | `borderDisabled` track and thumb, `textDisabled` word | on: `success`, thumb at 33, "ON" left | ring on the row |
| `PopBadge` | e1 (e2 celebration) | not pressable | locked: dashed, no shadow | — | not focusable |
| `PopSheet` | e3 | — | — | — | first action autofocused |
| `PopBottomNav` item | `textSecondary`, transparent border | +(2,2), `pressedShadow`, ×0.97 | never disabled | `accent` chip, ink border, e1 | ring around the chip |

## Non-colour redundancy, per state

| State | Primary channel | Redundant channels it must also carry |
|---|---|---|
| rest | shadow at its step | — |
| pressed | shadow → `pressedShadow` | translation toward the shadow, scale ×0.97/0.98 (dropped under reduced motion — the shadow change then carries it alone) |
| disabled | fill → `surfaceSunk` | border → `borderDisabled`, label → `textDisabled`, shadow ink → `borderDisabled` and one step shallower, no press response, `Semantics(enabled: false)` |
| selected | fill → `accent` | a border that appears from transparent, an elevation change, a translate, and — where the item can be locked — a glyph |
| focused | `focusRing` stroke | additive: the rest shadow, fill and border are all still there |

The acceptance test is the greyscale golden: render the component in all five states, desaturate, and
the states must still be distinguishable. `accessibility-as-code` owns the general never-colour-alone
rule and the ≥3-signal floor; this file only fixes which channels Sunburst spends.

## Focus: a stroke outside the border, never a replacement

```
     ┌──────────────────────────────┐  ← focusRing #7C5CFF, 4px stroke   (shape.focusWidth)
     │  ┌────────────────────────┐  │  ← surface gap,       3px          (shape.focusGap)
     │  │ ┏━━━━━━━━━━━━━━━━━━━━┓ │  │  ← colors.border,     3px          (shape.borderWidth)
     │  │ ┃  fill + child      ┃ │  │
```

- The ring is painted **outside** the layout box: inflate by `focusGap + focusWidth / 2` = 5 and stroke
  at width 4, corner radius + 5. It contributes no layout size, exactly like the shadow.
- Never swap the ink border out for the focus ring, and never drop the rest shadow while focused —
  system.html's rule is `box-shadow: <rest>, 0 0 0 3px cream, 0 0 0 7px focus`, additive.
- The 3px cream gap is load-bearing: grape-pop measured directly against a sunshine fill is 2.8:1;
  against the cream gap it is 4.1:1, clearing the 3:1 non-text floor. Never let the gap take the fill
  colour "so it blends".
- Paint it as a stroke, not a `BoxShadow(spreadRadius: 7)`, so the hygiene gate can ban spread with no
  exceptions.
- Focus is driven by `FocusableActionDetector.onShowFocusHighlight`, so it appears for keyboard and
  switch control and not for touch — a touch press must never leave a ring behind.

## Tap targets

- **48 logical px minimum**, the house floor from system.html §11, above the 44px platform floor that
  `accessibility-as-code` owns. Shipped sizes: icon buttons 48×48, segmented items 48 tall, Stroop
  answer keys 92, grid tiles 60–64, nav items 88 wide, buttons 48+ by padding.
- Measure the target on the **fill box**. The 5px offset shadow is paint, not a hit region — a surface
  that looks 69px wide is 64px of target.
- The 3px border is *inside* the fill box (`strokeAlign.inside`), so it does not add target size
  either: a 48px button is 42px of interior plus two 3px edges.
- The target must not move with the press: the `GestureDetector` and the `ConstrainedBox(minWidth: 48,
  minHeight: 48)` are both outside the transform. See SKILL.md rule 5.
- Where the drawn control is smaller than 48 — the 66×34 `PopToggle` — the **enclosing row** is the
  target (62px in Settings) and the control renders with `minTarget: 0`, `onTap: null` and no gesture
  of its own. Shrinking the target to match the art, or padding the art up to 48, are both wrong.
- Adjacent targets keep the 8px `space2` gap the grid and answer keys use; two 3px borders touching
  read as one 6px rule and the tap ambiguity is real.

## Semantics per component

`PopSurface` emits one node: `Semantics(button: onTap != null, enabled:, selected:, container: true)`
wrapping a `MergeSemantics`, so "Stroop Rush, tap the colour not the word, best 1,480" is announced as
one card rather than three fragments. Components that compose their own label pass `semanticLabel` and
let `PopSurface` exclude the children. Decorative artwork inside a component — the `GameCard` quad, the
swatch row, the nav icon beside its label — is `ExcludeSemantics`. `accessibility-as-code` owns roles,
ordering and announcement rules; what is fixed here is that the *component*, not the screen, declares
them.
