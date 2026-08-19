---
name: sunburst-game-surfaces
description: >-
  Enforces the Sunburst Pop board contract for MindForge — one GameAccent case per game
  (stroopCoral #FF6B5A, schulteTurquoise #22C7B8, nBackGrape #6A45E8), never a Color under
  lib/games/; a tier split where no play*/cb*/answerColour read leaves a board and no
  accent/success/danger enters a GameColourRole.mechanic board; the colour-blind flag driving
  round GENERATION (red→cbPink, green→cbOrange), not paint; a PlayFill on the key AND in the
  three-pass stimulus glyph; idle/next/found/wrong/disabled split by shadow depth, ring,
  translate and glyph; cells derived against a 48px floor. Use when building a board, an answer
  key or a stimulus, picking a game's accent, or reviewing lib/games/.
---

# Sunburst Pop — game surfaces

MindForge is an engine: a game supplies rules, a board widget and one accent, and inherits all eight
shell screens. This skill owns the **board** — the rectangle below the play band's ink border — and
the rules that let a new game look like MindForge without becoming a clone of Stroop. The token
*values* are owned by `sunburst-tokens`, the chunky-surface *mechanics* by `sunburst-components`,
and everything above the border by `sunburst-shell-screens`. What is decided here is: which colour a
game gets, which tier that colour belongs to, and how a board state is legible without hue.

Read the reference for the task at hand:
- `references/accent-contract.md` — the per-game accent table, what the accent may and may not tint, how the shell consumes a `GameAccent`, and why the palette supports exactly three game identities.
- `references/gameplay-palette-and-cvd.md` — both palettes with hexes, measured contrast on cream and on paper, per-pair greyscale ratios, the deuteranope/protanope analysis, toggle semantics, and the test that pins it.
- `references/board-states-and-layout.md` — the tile/stimulus state matrix with redundant encodings, the square-cell maths, and the small-screen and large-text rules.
- `templates/new_game_visual_checklist.md` — copy into the game's PR description and tick it in order.
- `examples/stroop_board.dart` / `examples/schulte_board.dart` — the two shipped boards, end to end.

Run `scripts/check_game_palette.sh` before a PR.

## Non-negotiable rules

1. **A game declares a `GameAccent` enum case, never a `Color`.** `GameAccent.stroopCoral`,
   `GameAccent.schulteTurquoise`, `GameAccent.nBackGrape` live in `lib/theme/game_accent.dart` and
   resolve to `colors.gameStroop`/`gameSchulte`/`gameNBack` plus their `*Deep` partner —
   `gameNBack`/`gameNBackDeep` are **derived**, absent from `system.html` and still open requests to
   `sunburst-tokens`, so the N-Back case does not compile yet. Nothing under `lib/games/**` may hold
   a `Color(0x…)` or a `Colors.*`, and the only importable theme files are the slot files
   (`sunburst_colors`, `sunburst_shape`, `sunburst_motion`, `sunburst_type`, `game_accent`) — never
   `sunburst_primitives.dart`. WHY: an accent held as a `Color` is a hex that never gets re-measured;
   the enum makes "add a game colour" a one-line diff plus an automatic contrast-test entry.
2. **UI colour and gameplay colour are two tiers that never cross.** The `play*`/`cb*` slots and
   `answerColour()` may be read **only inside a board widget**; `accent`, `accentAlt`, `success`,
   `warning`, `danger` and the game's own accent may **never** be read inside the board region of a
   game whose declared `GameColourRole` is `mechanic`. The 3px ink border under the play band is the
   tier boundary: above it is chrome, below it is the answer surface. WHY: on the Stroop board the
   hue *is* the response the player is being timed on. A coral confirm button or a leaf "correct"
   flash inside that rectangle is a colour prime — the run no longer measures the Stroop effect, it
   measures your chrome, and no test will ever tell you.
3. **On a `mechanic` board, correct and wrong are never coloured.** `danger` **is** `playRed`
   (`#D81E2C`) — the same value the answer key uses — and `success` is leaf `#4CC86A`, a green that
   sits inside the answer concept. Feedback on a colour board is depth, transform, glyph and ink
   only: the wrong key sinks to `flat` with an ink strike bar and shakes; the right key lifts to e3
   and holds. Both keep their own fill — which is also why a resolved key stops taking taps by
   dropping its `onTap`, never by `PopSurface(enabled: false)`, whose disabled shape swaps the fill
   to `surfaceSunk` and would erase the answer. WHY: flashing red for "wrong" on a screen where red
   is a legal answer teaches the player the exact wrong association, and it is unfalsifiable in a
   golden because both look "correct-ish".
4. **The colour-blind flag is an input to round GENERATION, captured once at round start.** The
   toggle re-points four slots — red→`cbPink #C2185B`, green→`cbOrange #C24409`, blue and yellow
   unchanged — so with it on, the answer set is capped at those four. Store `isColourBlindPalette`
   in the immutable round state; the generator and `answerColour()` read the same captured value.
   WHY: a Blitz round generated as `{red, green, purple, orange}` and swapped at paint time renders
   `{pink, orange, purple, orange}` — two identical orange keys, one labelled "Green". And a setting
   read per frame lets a mid-run toggle silently change what the player is answering.
5. **Every answer colour carries its `PlayFill` on the key AND in the glyph, in both palettes.** The
   pattern is not part of the setting; it is always on, because it is the only channel that survives
   a black-and-white screenshot. Red↔blue sit at **1.02:1** in greyscale and red↔orange at
   **1.00:1**. WHY: the colour-blind palette fixes hue confusion, not luminance confusion — its own
   worst greyscale pair (blue↔orange) is still 1.03:1.
6. **The stimulus is a three-pass paint: ink stroke, hue fill, ink pattern clipped to the glyph.**
   Never a `Text` in an answer colour. `playYellow #F5B301` is **1.76:1** on cream and cannot be
   darkened without players calling it brown. WHY: the 6px ink stroke makes the effective contrast
   ink-on-cream (**14.55:1**) and demotes hue to decoration on an already-legible shape — without it
   the answer the player is being timed on is the least legible thing on the screen. (Both figures are
   `sunburst-tokens`' measured values; quote them from there, never re-round them here.)
7. **Every board state is separated by at least three non-hue channels.** Shadow depth, translate,
   ring, border colour, glyph colour — see the matrix in `references/board-states-and-layout.md`.
   Recede by changing the fill, never with `Opacity`. WHY: two states that differ only in hue are one
   state to a dichromat and to a greyscale golden, and element opacity fades the 3px ink border along
   with the fill — the border is the brand, and it is also the last channel low vision has.
8. **The board computes its cell from the slot's constraints, and the gap is derived from the tap
   floor.** Square side = `min(maxWidth, maxHeight)`; cell = `(side - (n-1) * gap) / n`; gap is the
   design's 12 unless `cell(12) < kPopMinTarget` (48, declared by `sunburst-components`), then 8. The
   slot the board is handed already has `sunburst-shell-screens`' 20pt gutter removed — the gutter is
   never part of this trade and a board must not re-apply or shrink it. WHY: at 320px with a 12px gap
   a Schulte cell is **46.4px** and breaks the 48px target floor; with an 8px gap it is 49.6px and
   clears it. Written as a width breakpoint the number is magic and a 6×6 board inherits the wrong
   answer; written against the floor it re-derives itself.
9. **Large text is absorbed by choosing a smaller BASE style, never by clamping the scaler.**
   `MediaQuery.withClampedTextScaling`, `FittedBox` and `TextOverflow.ellipsis` are banned outright
   by `accessibility-as-code`. A fixed-count grid cannot grow its cell, so the board picks between
   two token styles and lets the user's multiplier apply on top. WHY: clamping silently overrides an
   OS-level accessibility setting, and it fails exactly on the devices that asked for it.
10. **A board never owns run state and never draws a HUD.** Phase, clock, score persistence and
    routing belong to `RunNotifier` (`sunburst-shell-screens`). The board owns only
    `[Game]BoardNotifier` — the cells, the stimulus, the feedback flash — and publishes a
    `BoardSnapshot` the shell folds into `GameHud`. Its only upward path is that snapshot plus an
    intent (`ref.read(...notifier).tapCell(index)`). WHY: a board that also renders pills makes the
    shell's HUD and the board two sources of truth that drift by a frame under fast taps, and the
    play band's ray/dot layers stop being re-measurable as one composite.
11. **The game fills exactly three `GameHud` slots and one 0..1 `progress`.** Order is fixed —
    `[time (shell-authored), the game's primary counter, one highlighted value]` — and at most one
    slot may be `HudTone.highlight`. `HudTone.alarm` belongs to the shell's last-five-seconds rule;
    a game never sets it. The track's well is `surfaceSunk` and its fill is the 45°/9px
    accent→accentDeep stripe: the one place a game accent legitimately reaches a HUD element.
    WHY: a fourth pill or a second highlight turns the HUD into somewhere a game competes for
    attention, and the shell can no longer promise the row fits at 320px.
12. **Yellow is the only default answer legible in greyscale on its own.** Its relative luminance is
    0.517 against 0.13–0.16 for red, blue, green, purple and orange. WHY: it is the one slot you may drop from a
    set without losing separation — never a licence to ship the others bare, because every pair that
    does not include yellow sits between 1.00:1 and 1.07:1.

## The tier boundary, made structural

```dart
// WRONG — a coral confirm button inside the Stroop board region. Coral is chrome,
// but it is one hue step from playRed and it sits where the answer lives.
Container(color: colors.gameStroop, child: const Text('Next'));

// WRONG — "correct" as a leaf wash on a board where green is an answer.
AnimatedContainer(color: isCorrect ? colors.success : colors.surfaceSunk, …);

// RIGHT — the board region is neutral by construction: surfaceSunk field,
// surfaceRaised stimulus, ink border, and the only saturated colour in the
// rectangle is an answer the round actually offered.
ColoredBox(
  color: colors.surfaceSunk,            // #FFEEDA — app.html .playfill--stroop
  child: StroopBoard(config: config),
);
```

Schulte is the counter-example that proves the rule is about *role*, not about colour: its board
field **is** turquoise and its wrong tile **is** `danger`, because Schulte declares
`GameColourRole.decorative` — colour is never its answer. One flag, two completely different board
palettes; see `references/accent-contract.md`.

## The colour-blind swap changes the answer set

```dart
// WRONG — generate from the full palette, recolour at paint time.
final options = PlayAnswer.values.sample(4);                    // may include purple/orange
final fill = colors.answerColour(a, colourBlind: ref.watch(cvdProvider)); // read per frame

// RIGHT — one captured flag drives generation and paint alike.
final live = isColourBlindPalette          // captured into round state at round start
    ? const [PlayAnswer.blue, PlayAnswer.yellow, PlayAnswer.green, PlayAnswer.red]
    : PlayAnswer.values;                   // green/red RENDER as cbOrange/cbPink under the flag
final options = live.sample(4);
final fill = colors.answerColour(a, colourBlind: isColourBlindPalette);
```

`PlayAnswer.green` under the flag paints `cbOrange` and is labelled "Orange"; the enum case is the
*slot*, not the hue. Full semantics, both palettes, and the pinning test: `references/gameplay-palette-and-cvd.md`.

## Board sizing

```dart
// WRONG — a hardcoded tile, and a floor that fires exactly where large text needs room.
const cell = 64.0;
SizedBox(width: math.max(cell, 60), height: math.max(cell, 60), child: tile);

// RIGHT — square board from the slot; the gap step states its own reason.
LayoutBuilder(
  builder: (context, constraints) {
    final side = math.min(constraints.maxWidth, constraints.maxHeight);
    double cell(double gap) => (side - gap * 4) / 5;
    // 12 unless it would drop the cell under the 48px floor — only 320px devices.
    final gap = cell(12) >= kPopMinTarget ? 12.0 : 8.0;
    return SchulteGrid(gap: gap, …);   // 390px screen, 20px gutters -> cell 60.4
  },
);
```

At 390px the cell is 60.4px, inside the 60–64px the design specifies; at 320px the step fires and it
is 49.6px. Shadow and ring bleed are paint, not layout: the `next` tile's 5px double ring is a stroke
outside the box and never a spread `BoxShadow`. Full table in the layout reference.

## Adding a game's visual layer — in order

1. Claim a `GameAccent` case (or add one, with its `*Deep` partner, to `lib/theme/game_accent.dart`).
2. Declare `GameColourRole` — `mechanic` if hue is ever part of the answer, else `decorative` — and
   set `GameDefinition.boardBackground` to match.
3. Write the board's state matrix before any widget: every state × its non-hue channels.
4. Build the board as a `ConsumerWidget` reading one `[Game]BoardNotifier` slice via `.select`, and
   publish a `BoardSnapshot` — three `GameHud` slots plus `progress`; draw no pills yourself.
5. Verify at 320 / 360 / 390 / 430px and at text scale 1.0 / 1.3 / 2.0.
6. Take a greyscale golden and answer "what state is every element in?" from it alone, then run
   `scripts/check_game_palette.sh` and the palette test.
7. Compare the built board against its reference screenshot at 390×844 — `04-stroop-rush.png` and
   `05-schulte-grid.png` in `design/sunburst-pop/screens/`. A new game has no reference of its own:
   match the *shared* half (play band, HUD row, board inset, tile construction) to those two, and
   treat anything you invent inside the board rectangle as a design change that belongs in `app.html`
   before it belongs in Dart. Procedure: `design/sunburst-pop/screens/README.md`.

Full form with sign-off boxes: `templates/new_game_visual_checklist.md`.

## Anti-patterns

- **A `Color` or a `Colors.*` anywhere under `lib/games/**`** — declare a `GameAccent` case or read a token slot.
- **`play*`/`cb*`/`answerColour()` outside a board widget, or `success`/`danger`/`accent`/`warning` inside a `mechanic` board** — either direction crosses the tier, including as a "just for feedback" tint.
- **Reading the colour-blind setting during paint** — capture it into round state; the generator needs it too.
- **A new gameplay colour without an unclaimed `PlayFill`, or a bare `Text` stimulus in an answer colour** — Blitz's 6-set already collides, and an unstroked yellow glyph is 1.76:1 on cream.
- **`Opacity`/`withOpacity` to show a found or disabled tile, or `enabled: false` on an answer key** — both erase what the fill was saying; change the fill or drop the `onTap`.
- **A hardcoded cell size, a `math.max` size floor, `FittedBox`, or a clamped `textScaler`** — compute the cell, choose a smaller base style.
- **A board that builds HUD pills, a `Scaffold`/`AppBar`, a fourth slot, or an accent-tinted pill** — publish a `BoardSnapshot`; three slots, sunshine on the third only.
- **A game accent used as the primary-action colour** — primary is always `accent` (sunshine); the game accent is identity, not action.

## Definition of done

- [ ] `scripts/check_game_palette.sh` clean over `lib/`, and the palette + CVD test from `references/gameplay-palette-and-cvd.md` is in `test/theme/`.
- [ ] The game declares one `GameAccent` case and one `GameColourRole` matching its `boardBackground`; no `Color` under `lib/games/**`.
- [ ] The accent tints only the play band, its rays, the track fill, and the game's cards on Home/Detail/Stats.
- [ ] On a `mechanic` board: no chrome semantic slot appears in the board region; correct/wrong are depth + glyph + motion.
- [ ] `isColourBlindPalette` is captured into round state and read by the generator, not just the painter.
- [ ] Every answer key and every stimulus glyph carries its `PlayFill`; patterns are unique within the live set.
- [ ] Every board state carries ≥3 non-hue channels; a greyscale golden still answers "what state is this?".
- [ ] Cell computed from constraints and verified at 320/360/390/430px; text scale 1.0/1.3/2.0 verified with no clamp, `FittedBox` or ellipsis.
- [ ] The board publishes a `BoardSnapshot` and draws no HUD, `Scaffold` or `AppBar`; its only upward call is an intent.
- [ ] Compared at 390×844 against `design/sunburst-pop/screens/04-stroop-rush.png` / `05-schulte-grid.png`:
      the shared chrome is pixel-consistent with them, and any board-interior difference is a committed
      change to `app.html`, re-rendered via `capture-screens.sh` — never an undocumented drift.

## Boundaries

- `sunburst-tokens` owns the token values, the `SunburstColors`/`SunburstShape`/`SunburstMotion`/`SunburstType` extensions, `PlayAnswer`/`PlayFill`, and how a new slot is added — including the class names this skill's examples read through. `GameAccent` and `GameColourRole` are declared here, in `lib/theme/game_accent.dart`, because they are game-surface vocabulary that the theme layer only resolves.
- `sunburst-components` owns `PopSurface` and everything composed from it — the 3px ink border, the hard `blurRadius: 0` shadow, the press chrome (`translate = restingOffset − 1`, shadow to (1,1)), the focus ring, the `PopElevation` enum every board here names, and `kPopMinTarget` 48. Boards compose `PopSurface`; they never re-derive a border, a shadow or an elevation. It also honours this skill's answer-key exception: `enabled: false` swaps the fill to `surfaceSunk`, so a resolved key drops its `onTap` instead.
- `sunburst-shell-screens` owns everything above the board's ink border: `PlayScaffoldScreen`, `RunNotifier`, `RunPhase`, the three-slot `GameHud`, the progress track, the pause sheet, and the `GameDefinition.buildBoard` slot the board is handed. It also owns the ban on `go_router`, `Scaffold` and `AppBar` under `lib/games/**`.
- `sunburst-motion-and-haptics` owns every duration, curve, haptic and reduce-motion collapse referenced here — the 240ms×2 shake, `Moment.answerCorrect`/`answerWrong`/`tileFound`/`tileNextCue`, the personal-best celebration, and `PressPhysics`, the one press controller `PopSurface` composes. Its catalog states rule 3's split explicitly: a Schulte tile's wrong state is `danger` + paper glyph (transcribed `.tile.wrong`, legal because Schulte is `decorative`), while a Stroop answer key keeps its hue and spends depth, the strike bar and the shake.
- `accessibility-as-code` owns the 48px target floor, `Semantics` labelling, the never-clamp-textScaler ban, and the ≥3-channel rule this skill applies to boards.
- `custom-canvas-and-gestures` owns the painter/scene split, `shouldRepaint`, and hit-testing for the stimulus painter.
- `state-management-riverpod` owns the notifier and `select` mechanics; `widget-composition` owns the class-not-method and computed-cell-sizing rules; `widget-golden-and-a11y-testing` owns the greyscale golden harness.

## References

- `design/sunburst-pop/system.html` §02 Colour, §03 Stroop answer palette, §10 Components (Grid tile, Stroop answer buttons), §11 Accessibility, §12 Flutter mapping — the authoritative hex values; `app.html` screens 04–05 — the authoritative layout; `README.md` — "Hue is never the only channel" and the "Yellow, forever" risk.
- W3C WAI — WCAG 2.2 SC 1.4.1 Use of Color (https://www.w3.org/WAI/WCAG22/Understanding/use-of-color.html) and SC 1.4.3 Contrast Minimum (https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html).
- Viénot, Brettel & Mollon (1999) — digital video colourmaps for dichromats (the simulation the ΔE76 figures use).
