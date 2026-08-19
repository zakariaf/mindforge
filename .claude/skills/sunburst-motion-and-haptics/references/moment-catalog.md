# The Sunburst Pop moment catalog — exact values

The eight-column summary table lives in `SKILL.md`. This file carries the numbers an implementer needs
and the reasoning behind the rows that are not obvious. Everything is transcribed from
`design/sunburst-pop/system.html` unless marked **DERIVED** — not in the source, chosen here, reason
stated.

| Moment | Exact geometry / value | Latch |
|---|---|---|
| `buttonPress` | e2: translate(4,4) scale .98, shadow (1,1) · e1: translate(2,2) scale .97, shadow (1,1) · ghost: translate(2,2), no shadow | — |
| `buttonCommit` | back to the e2 (5,5) or e1 (3,3) shadow at scale 1.0 | — |
| `homeCardEnter` | dy 12 → 0, opacity 0 → 1, stagger 40ms, index clamped to 3 (**DERIVED**) | — |
| `difficultySelect` | selected: translate(−1,−1), shadow (2,2), fill `accent` · pressed: fill `accentDeep`, translate(1,1), no shadow | — |
| `countdownBeat` | 3 beats 1000ms apart (**DERIVED**); numeral scale .86 → 1.06 → 1.00 (**DERIVED** reuse of the celebrate amplitude — no tilt); next of 3 dots fills `accent` | `beatIndex` |
| `runStart` | grape countdown pane opacity 1 → 0, play scaffold 0 → 1 | — |
| `answerCorrect` | tapped key lifts e2 → e3 and holds, fill **unchanged**; stimulus opacity cross-swap in place; Score pill text swap | — |
| `answerWrong` | translateX 0 → −4 → +4 → 0, two cycles of 240ms. Schulte tile: fill → `danger`, glyph → `surfaceRaised` (transcribed, `.tile.wrong`). Stroop answer key (**DERIVED**): fill **unchanged**, shadow → none, held at translate(2,2), 6px ink strike bar across the key panel | `wrongKeyId` |
| `tileFound` | fill → `gameSchulteDeep` `#12A79A`, shadow → none, held at translate(2,2) | — |
| `tileNextCue` | fill → `accent`, shadow → e2 (5,5) plus a 2px `surface` gap and a 3px `border` ring | — |
| `streakMilestone` | every 5th streak; pill scale .86 → 1.06 → 1.00. The pill is `accent` at rest and stays `accent` | `lastMilestone` |
| `timerAlarm` | at `secondsLeft == 5`: Time pill fill → `danger` `#D81E2C`, label → `surfaceRaised` (**DERIVED**) | `hasAlarmed` |
| `runEnd` | no motion at all | — |
| `resultsReveal` | 3 cards, dy 12 → 0, stagger 40ms (**DERIVED**) | — |
| `personalBest` | scale .86 → 1.06 → 1.00, over a static −2.5° tilt, e2 shadow | `hasPlayed` |
| `toggleFlip` | knob left 1 → 33 (32px travel); track fill `surfaceSunk` → `success`; inset highlight → none; ON/OFF word swaps side | — |
| `sheetTransition` | dy = sheet height → 0; radius `radiusXl` top / `radiusMd` bottom; e3 shadow | — |
| `routeTransition` | dx = ±width → 0, direction from `Directionality` | — |

## Why `difficultySelect` uses a (2,2) shadow

`.seg-i.on` is the one shadow offset in the system that is not on the e-scale: the selected item lifts
to translate(−1,−1) and takes `2px 2px 0 ink`. Lift plus shadow is 1 + 2 = 3, so the selected item's
total footprint is exactly e1's — it grows out of the well without growing the control. Do not "fix"
it to `shape.e1`; that would push the segmented control 1px taller the moment a tab is selected.

## Why the wrong-answer shake is 480ms in a 240ms system

`system.html` sets a hard 240ms ceiling and then explicitly sanctions
`animation: shake var(--dur-celebrate) var(--ease-out) 2`. The ceiling governs a single animation
*cycle*, not a sequence — one 480ms sweep would feel like a slow drag, whereas two 240ms cycles read
as a firm "no, no". Write it as two awaited `forward(from: 0)` calls, never `repeat(count: 2)`: the
absence of a third line is the stop condition, and the file cannot drift into an unbounded loop.

The wrong *state* is specified for the Schulte tile only (`.tile.wrong`: `danger` fill, paper glyph).
A wrong Stroop answer key is **DERIVED**, and it deliberately does **not** copy that fill. Schulte
declares `GameColourRole.decorative` — hue is never its answer, so `danger` is free. Stroop declares
`mechanic`, and `danger` **is** `playRed #D81E2C`, a colour the answer key itself may be painted in:
recolouring the wrong key would flash a legal answer at the player and teach the exact wrong
association. The key therefore keeps its hue and spends the other three channels — depth (e2 → flat),
transform (held at translate(2,2)) and a 6px ink strike bar — plus the shake, which both share.
`sunburst-game-surfaces` rule 3 owns that boundary; this catalog states the timing for both.

That is not "two vocabularies for a mistake": both are *sink, hold, shake*. Only the fourth channel
differs, because on one board the fill is decoration and on the other it is the question.

## Why `tileFound` barely animates

A tile at rest sits at e1 with no offset; pressed, at translate(2,2) with a (1,1) shadow. *Found* is
translate(2,2) with **no** shadow and a `gameSchulteDeep` fill — the press already performed the whole
movement, and "found" only removes the last 1px of shadow and crosses the fill. The tile never springs
back. That is the trick: the board's most frequent event costs one fill cross and reads as the tile
being stamped into the page. Never fade it with `Opacity` — the 3px ink border fades with it, and the
border is the brand. Recede by changing fill.

## Why `tileNextCue` is a declared silence

`tileFound` and `tileNextCue` are two visual consequences of **one** committed event — the player
tapped the right number. A haptic for each would turn every tap on a 25-tile board into a rattle.
`tileFound` owns the `selectionClick`; `tileNextCue` declares `—`, and that `—` is a recorded
decision, not a line someone forgot.

## Why the timer alarm is `danger`, not the gallery's coral

`system.html` §10 offers two HUD pill variants: `.hstat.hot` (sunshine) and `.hstat.bad` (coral).
`app.html` uses neither by that name — its third HUD slot is permanently sunshine (`.hstat.streak`),
which is `.hstat.hot`. `.hstat.bad` is therefore unassigned, and it cannot be the alarm as drawn:
coral is `#FF6B5A`, which is the `gameStroop` slot **and** the fill of the play band the HUD sits on,
so a coral alarm pill would disappear into Stroop's own background. It would also put a `game*` slot
into chrome, which `sunburst-game-surfaces` forbids.

**DERIVED:** the alarm pill takes `danger` `#D81E2C` with a `surfaceRaised` label, following the
`.tile.wrong` precedent (paper on `danger`). Paper on `danger` measures **5.07:1**. The pill's default
inks both fail on it: `textPrimary` is **3.03:1** (large-text only, and the 22px value is the only
large text on the pill) and `textSecondary` is **1.53:1** on the 10px uppercase caption. Both lines
invert together, or the pill does not change fill at all. If a coral alarm is ever wanted it needs a
new semantic slot in `sunburst-tokens`, not a `game*` read.

Note what does *not* change: the progress track. `system.html` labels the coral striped track
"Timer · 57%" and the turquoise striped track "6 / 25 · 24%" — coral is what a *time* track always
looks like, not what an expiring one looks like. Do not recolour it at the boundary.

## Why `streakMilestone` has no fill change

The Streak pill is already `accent` in `app.html` screen 04. The milestone is the "streak bump" named
on system.html's celebrate card — a scale bump, nothing else. Its residue with all three switches off
is the pill's new value (`x5` → `x10`), which is legitimate under rule 8: a word is a residue. Do not
add a fill cross to manufacture one.

## Why the countdown beat is 1000ms apart but only 240ms of motion

The 240ms ceiling applies to motion, not to waiting. A beat is 240ms of numeral entrance and then
760ms of the numeral sitting still — the stillness is the point; it resets attention before the run.
The interval is **DERIVED**: `app.html` screen 03 shows three progress dots with the first filled,
fixing the beat count at 3 but not the cadence. 1000ms is the conventional one-per-second read.

## Stagger: 40ms, first four only — and no count-up

**DERIVED** — `system.html` names no stagger step. 40ms is one third of `durTap`, small enough to read
as one gesture rather than a queue. Clamp the index at 3 so a Home screen with twelve games still
finishes in `180 + 3 × 40 = 300ms`; without the clamp, MindForge's own premise — one engine, many small
games — turns Home into a progressively slower load animation as the app succeeds.

The result *values* never animate. A ticker running 0 → 1,480 would exceed 240ms, and a number only
correct once its animation finishes is the "motion that IS the state" failure. Cards stagger in; the
numbers print at their final value on the first frame.

## Sound slots are named, not shipped

`app.html` screen 08 has a Sound settings row; nothing in the design source specifies an asset, a
format or a mix level. The `Sound` column is a slot name so the moment is fully specified and the audio
decision has somewhere to land. Do not invent a file, and never let a moment depend on its sound.
