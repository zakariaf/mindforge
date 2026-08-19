# Palette and slots

Every hex MindForge ships. Transcribed from `design/sunburst-pop/system.html` §02/§03; the ratios are recomputed from these exact hexes with `scripts/check_palette_contrast.sh`, so where they differ from the rounded figures printed in the design doc (ink-on-cream reads 14.55, the doc says 14.4) the number here is the measured one.

## Tier 1 — primitives (`_P`, `lib/theme/sunburst_primitives.dart`)

| Primitive | Hex | CSS var | Role |
|---|---|---|---|
| `cream` | `#FFF8EC` | `--cream` | The page everything is printed on |
| `creamSunk` | `#FFEEDA` | `--cream-2` | Inset wells: segmented track, progress track, toggle track |
| `creamEdge` | `#F6E3C6` | `--cream-3` | The toggle-track inset line, and nothing else |
| `dot` | `#F2DFC0` | `--dot` | Halftone ground behind decorative surfaces |
| `paper` | `#FFFFFF` | `--paper` | Cards, HUD pills, grid tiles, sheets |
| `ink` | `#2B1B4D` | `--ink` | All text, all borders, all shadows. Never pure black |
| `inkSoft` | `#5A4A7D` | `--ink-2` | Secondary text on unsaturated surfaces only |
| `inkMuted` | `#8E80AE` | `--ink-3` | Disabled controls only |
| `sunshine` / `sunshineDeep` | `#FFC53D` / `#F2A81E` | `--sunshine`, `--sunshine-deep` | Primary action; the dark half of every ray and stripe |
| `coral` / `coralDeep` | `#FF6B5A` / `#E8452F` | `--coral`, `--coral-deep` | Stroop Rush identity; its timer stripes and chart bars |
| `turquoise` / `turquoiseDeep` | `#22C7B8` / `#12A79A` | `--turquoise`, `--turquoise-deep` | Schulte Grid identity; its found-tile fill |
| `grape` / `grapePop` | `#6A45E8` / `#7C5CFF` | `--grape`, `--grape-pop` | Daily Mix and countdown; the focus ring |
| `leaf` / `leafDeep` | `#4CC86A` / `#2FA64F` | `--leaf`, `--leaf-deep` | Success, Play, toggle ON; the results ray burst |
| `tangerine` | `#FF9330` | `--tangerine` | Warning — held apart from sunshine so caution ≠ primary |

Each `-deep` variant exists for one reason: a two-tone stripe or ray needs a second value of the same hue that still holds an ink glyph. They are **not** "hover" or "pressed" colours — press is a translate, not a tint.

## Tier 2 — semantic slots (`SunburstColors`)

| Dart field | Maps to | Hex | Role and where it appears |
|---|---|---|---|
| `surface` | cream | `#FFF8EC` | Every screen background, all eight screens |
| `surfaceSunk` | creamSunk | `#FFEEDA` | Segmented-control track, progress track, timer-ring remainder |
| `surfaceRaised` | paper | `#FFFFFF` | Cards, HUD pills, grid tiles, sheets, answer labels |
| `surfaceInvert` | ink | `#2B1B4D` | Snackbars, tooltips, badge counters |
| `textPrimary` | ink | `#2B1B4D` | Everything readable |
| `textSecondary` | inkSoft | `#5A4A7D` | Captions, HUD labels — unsaturated surfaces only |
| `textDisabled` | inkMuted | `#8E80AE` | Disabled controls only, always with a shape change |
| `textInvert` | cream | `#FFF8EC` | Text on grape and ink fills |
| `border` | ink | `#2B1B4D` | The 3px edge on every surface, and every shadow |
| `borderDisabled` | inkMuted | `#8E80AE` | **DERIVED** — §11 says a disabled border drops to ink-3 and its shadow to "soft-ink", which has no token; the shadow reuses this slot |
| `divider` | creamEdge | `#F6E3C6` | The toggle-track inset only — 1.26:1 on paper, so row dividers are `border` |
| `dotPattern` | dot | `#F2DFC0` | Decorative halftone |
| `accent` / `accentDeep` | sunshine | `#FFC53D` / `#F2A81E` | Primary action, selected state, streaks |
| `accentAlt` | grape | `#6A45E8` | Daily Mix, countdown, Settings header |
| `success` / `successDeep` | leaf | `#4CC86A` / `#2FA64F` | Correct answer, toggle ON, Play |
| `warning` | tangerine | `#FF9330` | Time running out, unsaved run |
| `danger` | **primitive** playRed | `#D81E2C` | Wrong answer, destructive confirm |
| `focusRing` | grapePop | `#7C5CFF` | 4px ring outside a 3px cream gap |
| `gameStroop` / `gameStroopDeep` | coral | `#FF6B5A` / `#E8452F` | Stroop Rush identity |
| `gameSchulte` / `gameSchulteDeep` | turquoise | `#22C7B8` / `#12A79A` | Schulte Grid identity |

## Tier 3 — the gameplay palette (never chrome)

| Dart field | Hex | `PlayFill` | As text on cream | Under a label |
|---|---|---|---|---|
| `playRed` | `#D81E2C` | stripe | **4.80:1** | paper — 5.07:1 |
| `playBlue` | `#1F6BE0` | solid | **4.69:1** | paper — 4.96:1 |
| `playGreen` | `#157A39` | dot | **5.13:1** | paper — 5.42:1 |
| `playYellow` | `#F5B301` | ring | **1.76:1 — fails** | ink — 8.29:1 |
| `playPurple` (Blitz) | `#6A45E8` | solid | **5.48:1** | cream — 5.48:1 |
| `playOrange` (Blitz) | `#C24409` | stripe | **4.82:1** | paper — 5.09:1 |

Colour-blind palette, re-pointed by `answerColour(a, colourBlind: true)`: `cbBlue #1F6BE0`, `cbYellow #F5B301`, `cbOrange #C24409`, `cbPink #C2185B` (paper label 5.87:1). The swap takes the worst deuteranope pair from ΔE76 27.0 to 37.7 and the worst protanope pair from 17.2 to 49.0. It deliberately does **not** substitute orange for red — those simulate to within ΔE76 5.2.

Fill patterns are **not** part of the setting. They are always on in both palettes, because a pattern is the only channel that survives a black-and-white screenshot.

## Measured contrast — the pairs that decide a design question

| Pair | Ratio | Verdict |
|---|---|---|
| ink on cream / paper / creamSunk | 14.55 / 15.37 / 13.53 | Body text anywhere |
| inkSoft on cream / paper / creamSunk | 7.34 / 7.75 / 6.82 | Captions on unsaturated surfaces |
| **inkSoft on coral / turquoise / sunshine** | **2.77 / 3.66 / 4.91** | Fails on two of three — on a saturated fill the label goes full ink |
| **inkMuted on cream / paper** | **3.40 / 3.59** | Disabled only; SC 1.4.3 exempts disabled controls, and the shape changes too |
| ink on sunshine / leaf / tangerine / coral | 9.74 / 7.15 / 6.93 / 5.49 | Every chrome fill holds an ink label |
| ink on turquoiseDeep | 5.14 | The found-tile glyph |
| **ink on coralDeep** | **3.90** | Below body floor — `gameStroopDeep` is stripes and bars, and never carries a label |
| cream on grape | 5.48 | The only dark chrome fill |
| **cream on grapePop** | **4.12** | Large text and UI only. `focusRing` clears SC 1.4.11's 3:1 |
| creamEdge on paper | 1.26 | Why row dividers are ink at 3px, not a hairline |

## Two hexes that appear twice on purpose

`#6A45E8` is both `accentAlt` (Daily Mix, countdown) and `playPurple` (the Blitz answer). `#D81E2C` is both `danger` and `playRed`. They are **separate slots holding the same value**, not aliases:

- `danger` is wired to the primitive `_P.playRed`, so flipping the colour-blind setting — which re-points the `red` answer to `cbPink` — cannot repaint a destructive-confirm button.
- If a designer ever re-tints Daily Mix, `accentAlt` moves and `playPurple` does not.

Aliasing one to the other is a one-character change that silently couples the chrome palette to a gameplay accessibility setting. Don't.

**A third claim on `#6A45E8` is open.** `sunburst-game-surfaces` reserves `GameAccent.nBackGrape` for the third game, resolving to `gameNBack` / `gameNBackDeep`. Neither slot exists on `SunburstColors` yet and neither is in `system.html`, so that enum case does not compile today — this is a live token request, marked `DERIVED` at every mention in that skill. Two things must be true before it lands: it takes a **fourth** slot wired to `_P.grape` (never an alias of `accentAlt`, by the rule above), and `system.html` grows a grape-deep primitive — `grapePop #7C5CFF` is *lighter* than grape and is already spent on `focusRing`, so it cannot be the deep partner. Until the designer supplies that value, N-Back has no accent.
