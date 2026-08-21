# E10 on-simulator sign-off: Schulte Grid, both directions

Run on the canonical device — `MindForge iPhone 14`,
`C13DDC02-375D-4E1B-8F81-44EB407D09A4`, iOS 18.6, exactly 390x844 at DPR 3.

```bash
xcrun simctl spawn <udid> defaults write .GlobalPreferences AppleLanguages -array fa
xcrun simctl launch <udid> io.applander.mindforge \
  --route='/game/schulte_grid/play?difficulty=classic&seed=42'
```

Screens compared: `screens/05-schulte-grid.png` and
`screens/rtl/05-schulte-grid.png`, region by region.

## What matched

Both directions: the top bar on cream, the turquoise band with its ray sweep
and dot lattice, three pills with NEXT on sunshine, the progress track, the ink
bottom border, the turquoise field with its own lattice, a 5x5 of cream tiles
with 3pt ink edges and e1 shadows at a 12pt gap, and the next tile on sunshine
carrying its double ring.

In `fa`: the chrome mirrors — pause at the right, difficulty chip at the left,
HUD order reversed so TIME sits on the right — while **the grid does not**, and
the hard offset shadow stays down-and-right on every tile.

The tiles render `۱`-`۲۵` in U+06F0-06F9, which is the thing no previous screen
could prove: E04 established that the chrome survives four locales, and only a
board whose payload is digits shows the numeral pipeline reaching the canvas.

## Two deliberate changes to the reference

Both RTL differences turned out to be CSS defaults rather than design decisions,
so `app.html` changed and `capture-screens.sh --rtl` regenerated the PNG. Only
`rtl/05-schulte-grid.png` moved.

**1. The grid mirrored.** CSS grid follows `dir`, so the RTL capture reversed
every row. A Schulte grid is a visual SEARCH FIELD, not a text flow: the
scramble is uniform over positions, so a mirrored board is just another
scramble. Mirroring costs three real things — `cells[0]` stops meaning a screen
position, so every geometry assertion and this PNG fork per direction; the board
interior, the one part of the screen meant to be identical everywhere, becomes
locale-dependent; and the numeral does not mirror anyway, since `۲۵` is written
most-significant-digit first exactly like `25`. `.grid5` is pinned `direction:
ltr` with that reasoning at the rule.

The counter-argument is recorded rather than dismissed: a Persian reader's
habitual first glance is top-right, so the eye starts on a different cell. That
is a difference in where a *bad* strategy starts — Schulte is practised with a
fixed central gaze — and if a native reviewer disagrees, the change is one
`Directionality` and a second PNG, and it is E11's to make.

**2. The FOUND pill read `۲۵ / ۶`.** Six found of twenty-five, drawn as
twenty-five of six. The spaces and the slash are neutrals that take the
paragraph direction, so an unisolated fraction reverses in an RTL line — the
exact failure the epic names. The pill is isolated now. The streak multiplier
deliberately is **not**: `x7` is meant to take the paragraph and read `۷×`.

## What the comparison found in the app

| # | Screen | Found | Fixed by |
|---|---|---|---|
| 1 | play | The board's background was painted behind the **whole column**, so turquoise ran up under the pause button and the game's name. Every top bar in the app sits on cream. | The background starts at the band |
| 2 | play | The field had **no dot lattice**. Both games were drawing their own inside the board. | It moved to the shell with the background |
| 3 | stats | Every chart drew **Stroop Rush's coral bars**, whatever game it was showing — a turquoise BEST card above coral bars. | `RunBarChart` takes the accent the screen already had |

Defect 1 is the argument for a second game in one sentence: it was invisible for
Stroop Rush, whose field is a shade of the same cream.

Defect 3 was found by `engine_seam_test` rather than by eye.

## Captures

- `e10-schulte-en.png` — English, `classic`, seed 42
- `e10-schulte-fa.png` — Persian, same run
