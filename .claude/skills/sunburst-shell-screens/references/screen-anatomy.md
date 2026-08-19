# Screen anatomy — the eight shells

Transcribed from `design/sunburst-pop/app.html` (screens) and `design/sunburst-pop/system.html`
(components, elevations, type). Each screen below names the rendered PNG in
`design/sunburst-pop/screens/` that is its **sign-off target** — build from the wireframe here,
then compare against that image before calling the screen done (SKILL.md rule 13).

Frame is 390×844. `e1/e2/e3/e4` = the 3/5/8/10px hard ink offset shadows. Every surface carries a 3px ink border unless a row says otherwise. Anything marked `DERIVED`
is not in the sources. Colours are `SunburstColors` slots, geometry `SunburstShape`, type
`SunburstType` — all owned by `sunburst-tokens`.

**Status bar:** on seven of the eight screens app.html paints `.sb` on `--surface`, so the coloured
header or play band starts **below** the top inset and carries a 3px ink bottom border only. Only the
countdown (§3) covers the strip. Do not "improve" this by bleeding a header under the notch.

---

## 1 · Home / game hub — `HomeScreen`

**Reference:** `design/sunburst-pop/screens/01-home.png`

Pick a game or take the Daily Mix. The only screen that proves the engine grows.

```
┌───────────────────────────────┐
│ ▓ sunshine header, rays .5,   │ starts below the top inset; 3px ink bottom border only
│ ▓ dots .16   pad 6/20/22      │
│ ▓ [logo] MindForge  (4 day streak)   wordmark + PopChip (paper, e1, coral flame)
│ ▓ Good evening                │ 14/800 Nunito, INK — not ink-2 (composite is 3.2:1)
│ ▓ Ready to train?             │ displayL 33/1.02  ← the screen's only h1
├───────────────────────────────┤
│ pad 16/20/0, column gap 16    │
│ ┌ Daily Mix ──────────── (▶) ┐│ grape fill, cream text, r-lg, e2, pad 17/16
│ └ 3 games, 4 minutes ────────┘│ title 22, sub 13, 48pt sunshine circle e1
│  Your games        2 unlocked │ 15 Fredoka 600 · 12/800 ink-2
│ ┌ Stroop Rush ─────── [art]  ┐│ accent fill, r-lg, e2, pad 15/16
│ │ Tap the colour…  BEST 1,480││ art tile 64pt cream, r-md, e1
│ ┌ Schulte Grid ────── [art]  ┐│ same widget, turquoise
│ ┌╌ N-Back · Coming soon ────╌┐│ cream-2, 3px DASHED ink, NO shadow, ink-2 text
├───────────────────────────────┤
│  [Play]   Stats    Settings   │ 90pt, paper, 3px ink top border, active = sunshine chip e1
└───────────────────────────────┘
```

Composes `RayHeader`, `PopChip`, `DailyMixCard`, `GameCard`, `PopBottomNav`.

| Fixed by the shell | A game may vary |
|---|---|
| Header fill, rays, greeting, h1 copy | — |
| Card geometry, BEST pill, 64pt art frame (r-md, e1) | `accent`, `title`, `tagline`, `artwork` |
| Card order (registry order), locked rendering | `isLocked` |
| BEST value formatted via `ScoreFormat` | which format (`points` / `duration`) |
| Daily Mix card, section label, nav bar | nothing |

Shell needs `GameDefinition{ id, accent, artwork, scoreFormat, isLocked }` (title/tagline come from
ARB by id) and `bestScoreProvider(id)`.

## 2 · Game detail + difficulty — `GameDetailScreen`

**Reference:** `design/sunburst-pop/screens/02-game-detail.png`

State the rules, show history, choose a difficulty, start. Renders `RunPhase.idle`. No bottom nav.

```
┌───────────────────────────────┐
│ (‹)  Stroop Rush              │ PopIconButton 48pt (paper, r 15, e1) + 17 title; pad 2/20/16
│ ┌ hero — accent fill ────────┐│ r-xl, e3, pad 20, dot layer at .08 (ink label needs 4.5:1)
│ │ REACTION · FOCUS           ││ label 10 / +.16em upper
│ │ Stroop                     ││ 38/0.98 ← the h1
│ │ Rush                       ││
│ │ Tap the colour, not the…   ││ 15/800
│ │ [▨][▧][▩][▤]  answer keys  ││ 38pt squares, r 12, 2px shadow, hue + PlayFill
│ ├ Your best │ Games played ──┤│ 2-col gap 12; sunshine StatBox (ink label) + paper StatBox, e1
│ │  1,480    │     128        ││ value 26 tabular
│  DIFFICULTY                   │ label 10 upper ink-2, 10 below
│ [ Chill ][ Classic ][ Blitz ] │ cream-2 track, pill, pad 6; selected sunshine, 2px shadow, ↖(1,1)
│ ┌ Daily Mix (paper) ──── (▶) ┐│ same card, paper variant, grape circle
│                     ⟨spacer⟩  │
│ [        ▶  Play           ]  │ leaf, r-xl, pad 18/20, 21pt, full width, margin-top auto
└───────────────────────────────┘
```

Composes `PopIconButton`, `GameHeroPanel`, `StatBox`, `DifficultySegmented`, `DailyMixCard`, `PopButton`.

| Fixed by the shell | A game may vary |
|---|---|
| Top bar, hero geometry, stat row, segmented control, Play button | `accent`, `kicker`, `title`, `tagline`, `swatches` |
| Segmented shape and selection behaviour | the `difficulties` list, and which are locked |
| "Your best" / "Games played" slots | their values, from the stats repository |
| Play → `RunNotifier.start(config)` | nothing |

Shell needs `GameDefinition{ accent, swatches, difficulties }`, the ARB strings, and
`gameStatsProvider(id)`.

## 3 · Countdown — `CountdownScreen`

**Reference:** `design/sunburst-pop/screens/03-countdown.png`

Hand attention from menu to game. Renders `RunPhase.countdown`. The **one** edge-to-edge screen:
`.count` is `inset: 0` grape and holds its own status glyphs, tinted cream — so this screen sets
`SystemUiOverlayStyle.light`, skips the top `SafeArea` and insets its own content. No nav, no back gesture.

```
┌───────────────────────────────┐
│ ▓▓ grape, grape-pop rays .55  │ 1000pt conic disc, centred; status-bar glyphs tinted cream
│ ▓ Stroop Rush · Classic   (✕) │ 16 cream + PopIconButton 48pt; pad 2/20/0
│ ▓                             │
│ ▓        ╭─────────╮          │ 238pt sunshine ring, 3px ink, e4 — §07 caps e4 at one per screen
│ ▓        │    3    │          │ numeral 132/700 tabular
│ ▓        ╰─────────╯          │
│ ▓          gap 26             │
│ ▓        Get ready            │ 30/700 cream + 4px ink hard text shadow ← the h1
│ ▓        ● ○ ○                │ 3 dots, 14pt, grape-pop / current sunshine; pad-bottom 52
└───────────────────────────────┘
```

Three dots ⇒ three steps; cadence is `DERIVED` at 1000ms per step (system.html's 240ms ceiling governs
*animation*, not dwell). `sunburst-motion-and-haptics` owns the ring pop and the per-tick haptic.

| Fixed by the shell | A game may vary |
|---|---|
| Grape fill, ring, numeral, dot row, ✕ | nothing |
| The subtitle `"<title> · <difficulty>"` | its two words |

`✕` → `RunNotifier.abandon()` → back to game detail, nothing written.

## 4 · Play scaffold — `PlayScaffoldScreen`

**Reference:** `design/sunburst-pop/screens/04-stroop-rush.png` and `05-schulte-grid.png` (the same scaffold with two different boards — the chrome must be identical between them)

Run the game. Renders `playing`, and `paused` with the sheet over it. The critical screen.

```
┌───────────────────────────────┐
│ (‖)  Stroop Rush     (Classic)│ pause PopIconButton · title flex · difficulty PopChip; pad 2/20/10
├───────────────────────────────┤
│ ▓ play band — accent fill     │ rays .45 + dots .16, 3px ink bottom border; sits under the top bar
│ ▓ ┌ TIME ┐┌ SCORE ┐┌ STREAK ┐ │ HUD: 3 equal-flex HudPills, gap 8, pad 2/20/12
│ ▓ │ 0:23 ││ 1,240 ││   x7   │ │ paper e1 r-md · tone highlight = sunshine + ink label
│ ▓ ▬▬▬▬▬▬▬▬▬▬░░░░░░░░░░░░░░░░ │ PopProgressBar 16pt, pill, cream-2 well, 45°/9pt accent stripes
├───────────────────────────────┤ pad 0/20/14
│ board pane — pad 0/20/26,     │ Stroop: surfaceSunk bg · Schulte: accent bg · dots .14
│ top 20, vertically centred    │
│ ╔═══════════════════════════╗ │
│ ║   THE GAME'S RECTANGLE    ║ │ ← definition.buildBoard(context, config)
│ ║                           ║ │   inside Expanded + RepaintBoundary
│ ╚═══════════════════════════╝ │   no Scaffold, no SafeArea, no gutter of its own
└───────────────────────────────┘  no bottom nav — gameplay owns the screen
```

Composes `PopIconButton`, `PopChip`, `PlayBand`, `HudPill` ×3, `PopProgressBar`, the board slot and
`PauseSheet` (which composes `PopSheet`). The countdown is a route, not an overlay.

| Fixed by the shell | A game may vary |
|---|---|
| Top bar, pause button, difficulty chip, play band, HUD, track, board padding | — |
| Three HUD slots, their geometry and tones | each slot's `label`, `value`, `tone` |
| Track geometry; fill = accent stripes | `progress` 0..1 (`null` hides the track entirely) |
| Pause, lifecycle handling, results hand-off, back interception | nothing |
| Board pane background is one of two values | `boardBackground`: `surfaceSunk` or the game accent |

Shell needs `BoardSnapshot{ hud, progress, outcome }` plus `GameDefinition.buildBoard`.

## 5 · Pause sheet — `PauseSheet` (a state of screen 4)

**Reference:** _not captured — it is a state of screen 4. Build it from the wireframe below and the `PopSheet` entry in `sunburst-components`._

`DERIVED PLACEMENT`: app.html has no pause screen; the sheet is transcribed from system.html §10
"Modal sheet", whose live copy is exactly the copy below.

```
        the play scaffold, frozen, behind an ink scrim
┌───────────────────────────────┐
│  ░░░░ scrim: ink @ 55% ░░░░░  │ DERIVED — system.html declares no scrim token
│ ┌───────────────────────────┐ │ cream fill, 3px ink, r-xl top / r-md bottom, e3, pad 14/18/18
│ │          ▁▁▁▁▁            │ │ grab handle 56×6 ink, 14 below
│ │  Leave the run?           │ │ 23/700 ← the sheet's h1; focus lands here on open
│ │  Your score for this run  │ │ 14/700 ink-2, margins 6 / 16
│ │  will not be saved. Your  │ │
│ │  4 day streak is safe…    │ │
│ │  [    Keep playing     ]  │ │ sunshine PopButton, full width, 16pt, pad 13/18
│ │  [      Leave run      ]  │ │ paper secondary, gap 10
│ └───────────────────────────┘ │
└───────────────────────────────┘
```

| Fixed by the shell | A game may vary |
|---|---|
| Sheet shape, both actions, the copy, the scrim, the grab handle | nothing |
| Barrier tap and system back both mean "Keep playing" (`PopScope`) | nothing |
| Exactly two actions — a third is a design change, not an implementation detail | nothing |

Keep playing → `paused → countdown → playing`. Leave run → `paused → over` with
`RunOutcome.abandoned()`: nothing written, streak untouched, results shows the abandoned variant.

## 6 · Results — `ResultsScreen`

**Reference:** `design/sunburst-pop/screens/06-results.png`

Pay off the run. Renders `RunPhase.over`. No bottom nav.

```
┌───────────────────────────────┐
│ ▓ leaf header, leaf-deep rays │ .55; centred; pad 10/20/26
│ ▓  STROOP RUSH · CLASSIC      │ label 10 upper, INK
│ ▓  Nice run!                  │ displayXl 42/700 ← the h1; focus lands here
│ ▓  ★ New personal best        │ sunshine PopBadge, e2, rotate −2.5°, star glyph
├───────────────────────────────┤
│ pad 20/20/26, centred, gap 16 │
│ ┌ FINAL SCORE ──────────────┐ │ ScoreSlab: paper, r-xl, e3, pad 18/20/20
│ │          1,240            │ │ scoreHero 76/700 + 5px SUNSHINE hard text shadow
│ ┌ Accuracy ┬ Avg reac ┬ Strk┐ │ 3-col gap 10, r-md, e1; #1 turquoise, #2 paper, #3 coral
│ │   92%    │  640ms   │ x11 │ │ labels 10 upper — INK on the two saturated tiles
│ [    ▶  Play again        ]   │ leaf PopButton, r-xl, 21pt
│ [         Home            ]   │ paper secondary; gap 12, margin-top 6
└───────────────────────────────┘
```

| Fixed by the shell | A game may vary |
|---|---|
| Header, h1 copy, badge, slab, trio geometry, both buttons | — |
| Score rendered via `ScoreFormat` | the three `ResultStat(label, value)` entries |
| Personal-best detection, badge, its celebration | nothing — the repository decides |
| Play again → a fresh `RunConfig` at the same difficulty | nothing |

Shell needs `RunOutcome{ score, stats (exactly 3), isPersonalBest }`. Fewer than three stats is a
`GameDefinition` bug, not a layout case — the trio is a fixed 3-column grid.

## 7 · Stats — `StatsScreen`

**Reference:** `design/sunburst-pop/screens/07-stats.png`

Lifetime totals and a per-game history. The tightest fit of the eight — the README's risk note says a
leaderboard or 30-day history needs a quieter card variant first.

```
┌───────────────────────────────┐
│ ▓ turquoise header, dots only │ no rays here; pad 10/20/18
│ ▓  All time                   │ 14/800 INK
│ ▓  Stats                      │ 33/700 ← the h1
├───────────────────────────────┤
│ pad 16/20/0, gap 16           │
│ ┌ BEST SCORE Stroop Rush│1,480┐ BestCard: accent fill, r-lg, e2, pad 13/15
│ ┌ BEST TIME Schulte Grid│18.6s┐ value chip: cream, r 14, 2px shadow, 28/700
│ ┌ Games played ┬ Time trained ┐ duo StatBoxes, gap 12
│ ┌ chart card ────────────────┐ │ paper, r-lg, e2, pad 14/15/12
│ │ Last 7 runs      best 1,480│ │ 15 Fredoka 600 · 11/800 ink-2
│ │    ▁  ▃  ▅  ▂  ▆  ▅  █     │ │ 164pt band, striped accent/accentDeep, r 8/8/3/3, 2px shadow
│ │ ─────────────────────────  │ │ best bar = sunshine stripes; the 3px ink axis IS true zero
│ │ Oldest              Latest │ │ 10.5/800 ink-2
├───────────────────────────────┤
│   Play    [Stats]   Settings  │
└───────────────────────────────┘
```

Bar height: app.html hard-codes `value / 10.5` px (1480 → 141) from the ink axis; the shipped rule is
`value / max × 149` (the 164 band less the 10pt label and 5pt gap) because a fixed divisor clips any
score over ~1560 (`DERIVED`). Either way the axis is true zero, so no bar can overstate its run.

| Fixed by the shell | A game may vary |
|---|---|
| Header, card order, chart geometry, the zero axis, nav | — |
| One `BestCard` per unlocked game, in registry order | `accent`, `title`, best-value label |
| Chart accent = the charted game's accent | which game the chart shows (`DERIVED`: a segmented pick when >2 games ship) |

## 8 · Settings — `SettingsScreen`

**Reference:** `design/sunburst-pop/screens/08-settings.png`

The four feel/accessibility switches, language, about. No game-specific rows, ever.

```
┌───────────────────────────────┐
│ ▓ grape header, grape-pop rays│ at .3 — NOT .55; cream label needs 5.0:1; pad 10/20/18
│ ▓  MindForge                  │ cream
│ ▓  Settings                   │ 33/700 cream ← the h1
├───────────────────────────────┤
│ pad 16/20/0, gap 16           │
│ ┌ group (paper, r-lg, e2) ───┐│ rows split by 3px INK (never cream-3: 1.1:1 is no divider)
│ │ [♪] Sound            [ ON ]││ row pad 14/15; 36pt icon chip (cream-2, 2px, r 11)
│ │ [▯] Haptics          [ ON ]││ label 16 Fredoka 600; PopToggle 66×34, target = the whole row
│ │ [◷] Reduce motion    [OFF ]││ OR-ed with the platform flag into a root MediaQuery override
│ │ [◐] Colour-blind          .││ two-line label + a 4-swatch preview of what it swaps IN
│ │     friendly palette [OFF ]││ swatches 24×16, r 5, each keeping its ink PlayFill
│ ┌ group ─────────────────────┐│
│ │ [⊕] Language   English   › ││ value 14 ink-2 + chevron
│ │ [ⓘ] About MindForge      › ││
│                     ⟨spacer⟩  │
│          MindForge            │ 13 ink-2, centred, margin-top auto, pad 14/10/20
│   Train your brain. No wifi…  │ 12/800 ink-2 — a tagline, so ink-2, never ink-3
├───────────────────────────────┤
│   Play     Stats   [Settings] │
└───────────────────────────────┘
```

| Fixed by the shell | A game may vary |
|---|---|
| Every row, both groups, the footer, the colour-blind preview | **nothing** |
| The toggle prints ON/OFF inside its track, so state survives greyscale | — |

A game that wants a per-game option does not get a Settings row — it belongs on game detail, beside
the difficulty control, scoped to the run being configured.
