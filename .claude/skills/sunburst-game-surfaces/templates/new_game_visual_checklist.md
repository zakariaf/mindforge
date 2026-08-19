# New game visual layer — checklist

Copy into the game's PR description. Work top to bottom: each step's answer is an input to the next,
and steps 1–3 are design decisions that must be settled **before** a widget is written.

**Game:** ____________  **Author:** ____________  **Date:** ____________

## 1. Accent

- [ ] Claimed a `GameAccent` case: `_______________________`
- [ ] If it is a NEW case: base and `*Deep` primitives added in `sunburst-tokens`, with
      label contrast ≥ 4.5:1 recorded in the token table, `*Deep` ≥ 3:1 against its base, and
      ΔE76 ≥ 25 from every other accent under deuteranope **and** protanope simulation.
- [ ] The new accent is not within ΔE76 25 of `playRed`, `playOrange` or `playPink` — a
      near-answer hue on the play band is a hint on every screen.
- [ ] The exhaustive `switch` in `GameAccentTokens` compiles (a missing deep tone is a build
      error, not a grey band in the field).
- [ ] Label colour on the accent declared: `textPrimary` / `textInvert` (grape inverts).

> The palette holds exactly three game identities — coral, turquoise, grape. Game four needs a new
> measured primitive, never a tint of an existing one.

## 2. Colour role

- [ ] `GameColourRole` declared: `decorative` / `mechanic`
- [ ] If **mechanic**: the board field is `surfaceSunk` and `GameDefinition.boardBackground` is
      `BoardBackground.surfaceSunk` — the two must agree.
- [ ] If **mechanic**: no `accent`, `accentAlt`, `success`, `warning`, `danger` or game accent is
      read anywhere in the board region — feedback is depth, transform, glyph and ink only.
- [ ] If **decorative**: the board field may be the accent (`BoardBackground.gameAccent`);
      `danger`/`success` are legal.

## 3. Gameplay palette (mechanic games only — skip if decorative)

- [ ] The live answer set is listed: `____________________________________`
- [ ] Every slot in the set owns a **unique** `PlayFill`. (Blitz's six-set collides today — see
      `references/gameplay-palette-and-cvd.md`. Do not ship a seventh colour without a seventh pattern.)
- [ ] Every colour clears 4.5:1 as text on cream **or** ships with the ink stroke pass.
- [ ] The label colour for every fill comes from `answerLabel()`, never chosen at the call site.
- [ ] `isColourBlindPalette` is captured into round state **at round start**.
- [ ] The **generator** reads it and caps the set at `{red, green, blue, yellow}` when it is on.
- [ ] Generating with the flag on and rendering produces four distinct fills — no duplicate key.
- [ ] The `PlayFill` pattern is painted on the key **and** into the stimulus glyph, in both palettes.

## 4. State matrix

Fill this in before writing the widget. Every pair of states must differ in ≥3 columns.

| State | Fill | Border | Shadow | Transform | Glyph | Extra |
|---|---|---|---|---|---|---|
| | | | | | | |
| | | | | | | |
| | | | | | | |

- [ ] No state is distinguished by hue alone.
- [ ] No state uses `Opacity` / `withOpacity` — receding is a fill change, never a fade.
- [ ] The disabled state carries a shape change (`PopSurface(enabled: false)`: fill to `surfaceSunk`,
      border to `borderDisabled`, shadow one step shallower **and repainted in `borderDisabled`** —
      not removed) — **except** on a surface whose fill IS the answer, which stops taking taps by
      dropping `onTap` instead. Pass the tile's normal `PopElevation`, never `flat`.

## 5. Board widget

- [ ] A `ConsumerWidget` reading one `[Game]BoardNotifier` slice via `.select`.
- [ ] Composes `PopSurface`; no hand-rolled border, shadow or press physics.
- [ ] No `Scaffold`, no `AppBar`, no `go_router`, no HUD pills.
- [ ] Callbacks resolve a stable id / index, never a captured content value.
- [ ] `GridView`/`ListView` set `clipBehavior: Clip.none` so the hard shadow is not sheared off.

## 6. Shell hand-off

- [ ] `BoardSnapshot` published with `hud` (three slots), `progress` (0..1 or null), `outcome`.
- [ ] `slotA.value` left empty for a timed run — the shell authors the clock.
- [ ] At most one slot is `HudTone.highlight`; no slot is `HudTone.alarm`.
- [ ] `outcome` is non-null exactly when the run is over; the board never navigates.

## 7. Sizes verified

Record the measured cell/key size at each width. The 48pt tap floor is non-negotiable.

| Width | gap | cell / key | ≥48pt | Notes |
|---|---|---|---|---|
| 320 | | | ☐ | the gap step fires here for a 5x5 |
| 360 | | | ☐ | |
| 390 | | | ☐ | |
| 430 | | | ☐ | |

- [ ] Cell computed from constraints — no hardcoded size, no `math.max` floor.
- [ ] The gap step is written against the 48pt floor (`cell(12) >= 48 ? 12 : 8`), not a width breakpoint.
- [ ] Text scale 1.0 / 1.3 / 2.0 checked; no clamp, no `FittedBox`, no ellipsis.
- [ ] If a label stops fitting, a smaller **base** style was chosen (the user's multiplier still applies).
- [ ] Ring and shadow bleed do not overlap a neighbour or get clipped.

## 8. Gates

- [ ] `scripts/check_game_palette.sh` clean.
- [ ] The palette + CVD test from `references/gameplay-palette-and-cvd.md` is in `test/theme/`.
- [ ] `dart format` clean; `flutter analyze --fatal-infos` clean.

## Sign-off

- [ ] **Accent chosen** and recorded in the token table — signed: ________
- [ ] **Palette tier respected** — no gameplay colour as chrome, no chrome slot in a mechanic
      board region — signed: ________
- [ ] **CVD checked** — the flag drives generation, both palettes render four distinct fills, and
      the patterns are unique — signed: ________
- [ ] **States redundant** — greyscale golden reviewed, and it alone answers "what state is every
      element in?" — signed: ________
- [ ] **Sizes verified** at 320/360/390/430 and at 1.0/1.3/2.0 text scale — signed: ________
- [ ] **Compared against the reference screens** — the shared chrome matches
      `design/sunburst-pop/screens/04-stroop-rush.png` and `05-schulte-grid.png` at 390×844; every
      board-interior difference is a committed `app.html` change, re-rendered with
      `capture-screens.sh` — signed: ________

Anything unticked is a BLOCKER for `design-review-workflow`, not a follow-up ticket.
