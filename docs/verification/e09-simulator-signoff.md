# E09 on-simulator sign-off: Stroop Rush, chrome and board interior

Run on the canonical device — `MindForge iPhone 14`,
`C13DDC02-375D-4E1B-8F81-44EB407D09A4`, iOS 18.6, exactly 390x844 logical points
at DPR 3. Debug build, installed with `simctl install`, launched once per locale:

```bash
xcrun simctl spawn <udid> defaults write .GlobalPreferences AppleLanguages -array fa
xcrun simctl launch <udid> io.applander.mindforge \
  --route='/game/stroop_rush/play?difficulty=classic&seed=42'
```

**A correction to E08's note on the language argument.** Passing
`-AppleLanguages "(fa)"` in the same launch as `--route` silently dropped the
route and opened Home. Writing the language into the device's
`.GlobalPreferences` domain and launching with `--route` alone does both. The
uninstall-first rule from E08 still holds for the app's own argument domain.

Screens compared: `screens/04-stroop-rush.png` (en) and
`screens/rtl/04-stroop-rush.png` (fa), region by region in the order the epic
states — structure, spacing rhythm, surface construction, type role, sampled
hex. `de` and `ckb` were captured at `blitz` for fit rather than for pixel
equality.

## What matched

Both directions: the top bar, the play band with its ray sweep and dot lattice,
the three HUD pills, the progress track inside the band, the ink bottom border,
the `surfaceSunk` field and its lattice, the stimulus card at `radiusXl` with an
e3 shadow and its own dots, the 2x2 grid at the token key height, the 56pt
pattern panel with its ink divider, and paper labels on red/green/blue with ink
on yellow.

Measured against the reference at the same fractions of 390x844: key height
92.5pt against 93.7pt, pattern panel 56pt against 55pt, card-to-grid gap 16pt
against 16pt, card height 27.2% against 29.3% in `fa`.

The three deliberate RTL deltas the epic names all hold: the key order runs
right-to-left starting top-right, the pattern panel sits on the right of each
key, and **the hard offset shadow is unchanged** — still down and to the right
on every surface, including the pause button and the four keys.

Two things the comparison could not settle and that a test settles better:

- The **streak pill's sunshine fill** appears in the reference at `x7` and not
  in a capture at round 0, where the multiplier is `x1`. `catalog_test` asserts
  `HudTone.highlight` resolves to `accent` with ink in both text slots, and
  `stroop_board_notifier_test` asserts the tone flips only above `x1`. That is
  a stronger statement than a screenshot of one round.
- The **stimulus step**. The reference draws `BLUE`; `YELLOW` at seed 42 does
  not fit the full step on one line at 390 — 326pt of ink for 318pt of room —
  so the board takes `stimulusCompact`, which is the tier mechanism working
  rather than a difference from the design.

## What the comparison found

Five defects, none of them visible to the 2,155 tests passing at the time.

| # | Screen | Found | Fixed by |
|---|---|---|---|
| 1 | play | The stimulus card was **stretched to fill the field** by an `Expanded`, about twice the reference height, leaving the word floating in a sea of paper. | A content-sized card, centred with the grid, per `.playfill{justify-content:center}` |
| 2 | play | **No top bar at all.** `app.html` draws `.topbar` here, so the difficulty the player chose one screen ago was visible nowhere during a run — and the pause sat in the band, which the design keeps as three pills and a track. | `TopBar`, extracted rather than written twice: game detail had the same row inline |
| 3 | play | The HUD read **`Time Score Streak`** beside a reference reading `TIME SCORE STREAK`. Thirteen ARB keys already carried authored case; these four missed it. | Cased in `en` and `de`; a test now lists all seventeen against the CSS rule each answers to |
| 4 | play, results | The streak multiplier drew **`x1` in Persian** where the reference draws the digit first. An FSI isolate had been wrapped around it with a comment claiming it produced the reverse. | The isolate dropped — FSI resolves LTR on a run with no strong character |
| 5 | home | Stroop Rush's 64pt artwork tile drew as an **empty cream square with two dark hairlines** at its bottom edge. | Two rows of two instead of a `GridView` |

Defect 5 is the one worth reading twice. A widget test measured all four quads
at 22x22 inside the frame and passed, on the same commit where the device drew
nothing: a scroll viewport resolves its own constraints, and it did not resolve
them the same way under the test binding. The guard added with the fix asserts
the **mechanism** — the artwork contains no `Scrollable` — because the geometry
assertion is exactly the one that passed while the screen was wrong.

Defect 1 is the reason the board now degrades in a stated order. Sizing the card
to its content is what makes it able to overflow at all, so it gives up its own
whitespace first, at the design's 52:18:58 proportion, then the glyph box, and
the answer keys yield toward the 48pt tap floor rather than taking a fixed
height out of a cramped field. The prompt is bounded to the two lines it is
measured at, because a `Text` free to take a third made that budget a fiction.

## Captures

- `e09-play-en.png` — English, `classic`, seed 42
- `e09-play-fa.png` — Persian, same run, mirrored
