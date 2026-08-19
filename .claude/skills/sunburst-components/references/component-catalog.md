# The Sunburst component catalog

Thirteen classes under `lib/ui/components/`, each composing `PopSurface`. Every number is transcribed
from `system.html` §10 and `app.html`; the six *derived* values are listed in SKILL.md. Colours are
`SunburstColors` slots (`colors`), geometry is `SunburstShape` (`shape`), type is `SunburstType`.

| Class | File | Fill | Radius | Elev | Screens |
|---|---|---|---|---|---|
| `PopSurface` | `pop_surface.dart` | caller | caller | caller | all |
| `PopButton` | `pop_button.dart` | accent / success / surfaceRaised / none | Lg 22 (Xl 28 large) | e2 | 2, 4, 6, sheets |
| `PopCard` | `pop_card.dart` | surfaceRaised | Lg 22 | e2 (e1 dense, e3 hero) | 2, 6, 7, 8 |
| `GameCard` | `game_card.dart` | game accent | Lg 22 | e2 | 1 |
| `DifficultySegmented` | `difficulty_segmented.dart` | surfaceSunk track | Pill | flat track | 2 |
| `HudPill` | `hud_pill.dart` | surfaceRaised / accent / danger | Md 16 | e1 | 4, 5 |
| `TimerRing` | `timer_ring.dart` | conic sweep on surfaceSunk | Pill | e1 (e4 countdown) | 3, 4 |
| `PopProgressBar` | `pop_progress_bar.dart` | surfaceSunk track | Pill | flat | 4, 5 |
| `GridTile` | `grid_tile.dart` | surface | Md 16 | e1 | 5 |
| `PopToggle` | `pop_toggle.dart` | surfaceSunk / success | Pill | flat | 8 |
| `PopBadge` | `pop_badge.dart` | accent / surfaceRaised / surfaceSunk | Pill | e1 (e2 celebration) | 1, 6, 7 |
| `PopSheet` | `pop_sheet.dart` | surface | Xl top, Md bottom | e3 | 4, 5 |
| `PopBottomNav` | `pop_bottom_nav.dart` | surfaceRaised | none | top border only | 1, 7, 8 |

Two thin wrappers, not new contracts: `PopIconButton` (48×48, `surfaceRaised`, `radiusMd`, e1 — back,
pause, close; app.html draws radius 15, which snaps to 16) and `PopChip` (`surfaceRaised`, pill, e1,
padding `7/14`, `type.chip` 14 — the streak and difficulty chips).

## PopButton and PopCard

**Button**: optional 20px drawn glyph · 8px gap · label. Padding `15/20`, `type.button` (Fredoka **600**
18/22 — §04 wins over §12's `w700` and app.html's `.btn{font-weight:700}`; `sunburst-tokens` owns that
resolution, do not re-adjudicate it here), label `textPrimary` on every fill — sunshine 9.74:1, leaf
7.15:1, paper 15.37:1. Large (`Play`, `Play again`): padding `18/20`, `type.buttonLarge` 21 *(derived)*,
`radiusXl`, full width.

| Variant | Rest | Pressed | Disabled |
|---|---|---|---|
| primary / success / secondary | `accent` / `success` / `surfaceRaised`, e2 | +(4,4), `pressedShadow`, ×0.98 | `surfaceSunk`, `borderDisabled` edge, `textDisabled` label, e1 in ink-3 |
| ghost | no border, no shadow, 3px ink rule under the label | +(2,2), ×0.98 | `textDisabled` text only |

`success` is not a fourth style — it is the primary button wearing `success` for Play / Play again
(`.btn--leaf`). Ghost is the **only** surface allowed to break the outline rule: one dismissive action
per screen ("Skip tutorial"). Do not reach for it because a screen "has too many boxes".

**Card**: `surfaceRaised`, `radiusLg`, e2, 16px inner padding. Dense drops to e1 (`.statbox`, `.tri`);
hero rises to e3 with `radiusXl` (`.scoreslab`, `.stim`, `.hero`). Not pressable unless `onTap` is
passed, which turns on the full e2 press. Rows inside a card are divided by a **3px ink** rule, never
`divider` — cream-edge on paper is 1.1:1, which is no divider at all.

## GameCard

Fill is the game's accent (`gameStroop` coral, `gameSchulte` turquoise), `radiusLg`, e2, padding `15/16`,
12px gap. Title `type.title` 21 and subtitle `type.caption` 13, **both** `textPrimary` — not
`textSecondary`, which drops to 2.8:1 on coral. Best pill: `surface` fill, `borderWidthNested` 2, pill
radius, padding `3/10`, "BEST" in `type.label` `textSecondary` (legal — it sits on cream). Artwork tile
64×64, `surface`, 3px, `radiusMd`, e1.

Locked: `surfaceSunk`, **dashed** 3px ink edge, no shadow, `onTap: null`, `textSecondary` copy and a
locked badge. "Coming soon" is a status line, so it is `textSecondary` — `textDisabled` is for disabled
*controls* only. `BorderSide` cannot dash, so the edge is a `DashedInkBorder` foreground painter stroking
the RRect from `Path.computeMetrics()` at `dashOn` 9 / `dashOff` 7 *(derived — CSS defines no pitch)*.

## DifficultySegmented — Chill / Classic / Blitz

Track: `surfaceSunk`, 3px border, pill, 6px padding, 6px gap. Item: `Expanded`, 13px vertical padding (48
tall), pill radius, Fredoka 600 16, `textSecondary`, **3px transparent border** so selection adds no
layout shift. Selected: `accent`, `textPrimary`, ink border, `eChip`, `translate(-1,-1)` — it lifts.
Pressed: `accentDeep`, no shadow, `translate(1,1)`. Locked: `textDisabled` **plus a padlock glyph** —
never colour alone. Radio semantics: `Semantics(selected:)` per item and one group label, not buttons.

## HudPill, TimerRing, PopProgressBar

**Pill**: `Expanded` in an 8px-gap row, `surfaceRaised`, `radiusMd`, e1, padding `7/10/8`, centred. Label
`type.label` (Fredoka 600 10 · +14% tracking · UPPER) in `textSecondary`; value `type.numericHud` (700 22,
tabular). Never pressable, never focusable. The three tones are `HudTone.neutral | highlight | alarm`,
declared by `sunburst-shell-screens`: `surfaceRaised` with a `textSecondary` label · `accent` sunshine
with **both** lines in `textPrimary` · `danger` with **both** lines in `surfaceRaised`. The alarm is
`danger`, not the gallery's coral `.hstat.bad`: coral is `gameStroop`, which is also the fill of the
Stroop play band the HUD sits on, so a coral pill vanishes on the one screen that most needs it.
`sunburst-motion-and-haptics` owns that DERIVED call (`Moment.timerAlarm`) and the measurements behind
it — paper on `danger` 5.07:1, while the pill's default `textPrimary`/`textSecondary` measure 3.03:1
and 1.53:1 and both fail, which is why both lines invert together. Values cross-fade over `durState`
160 and are tabular, so nothing reflows. `MergeSemantics` label and value so it reads "Time, 0:23" once.

**Ring**: circle, 3px ink, e1, `surfaceSunk` track with the elapsed sweep in the game accent, crossing
to `danger` in the last 12% *(DERIVED — system.html §10 draws that sweep in coral; it takes `danger`
here for exactly the reason the alarm pill does, so chrome has one "running out" colour rather than
two)*; inner disc `surfaceRaised`, inset 13, with its own 3px border; value `type.numericHud`. The
countdown hero is the same class at 238px on `accent` with **e4 — one per screen, maximum** (§07).

**Bar**: height 16, 3px ink, pill, `surfaceSunk` track, fill a 45° stripe at `shape.stripePitch` 9
alternating the accent with its deep tone, plus a **3px ink right edge that disappears at 100%** — that
edge is the non-colour channel. Never animate width faster than `durState`; there is no indeterminate
variant. Both sweeps are `CustomPainter`s (`custom-canvas-and-gestures`); `PopSurface` still owns the
border and shadow.

## GridTile and PopToggle

**Tile**: 64×64 (60 at the smallest width), `radiusMd`, glyph Fredoka 700 24 tabular, idle fill `surface`
(cream, per app.html — the §10 gallery draws it on paper).

| State | Fill | Shadow | Transform | Extra channel |
|---|---|---|---|---|
| idle | `surface` | e1 | — | — |
| next | `accent` | e2 | ×1.02 | double ring: 2px `surface` then 3px `border` |
| found | `gameSchulteDeep` | none | +(2,2), permanent | sunk silhouette |
| wrong | `danger` | e1 | 240ms shake ×2, then rest | glyph flips to `surfaceRaised` |
| disabled | `surfaceSunk` | e1 **in `borderDisabled`** | — | edge + glyph to `borderDisabled`/`textDisabled` |

Five different *shapes*, so the board parses with no colour vision; found never uses opacity. `wrong`
is `danger` **only because Schulte declares `GameColourRole.decorative`** — on a `mechanic` board a
key keeps its hue and spends the strike bar instead (`sunburst-game-surfaces` rule 3). The shake and
its haptic belong to `sunburst-motion-and-haptics`; anything past these five states belongs to
`sunburst-game-surfaces`.

Note the one disabled exception in this catalog: `PopToggle`'s off state is an *inset* `2px 2px 0
cream-3` well that no `BoxShadow` can express, and `.tgl.disabled` sets `box-shadow: none`. Every
other disabled surface follows `.btn[disabled]` — one step shallower, repainted in `borderDisabled`,
never removed.

**Toggle**: track 66×34, 3px, pill, `surfaceSunk` off / `success` on. Thumb 26×26 `surfaceRaised`, 3px,
1px inset, sliding to `left: 33` over `durMove` 180 on `easePop`. **The word ON / OFF is printed inside
the track** — `textSecondary` right when off, `textPrimary` left when on — so state survives greyscale
and deuteranopia. Disabled: `borderDisabled` track and thumb, `textDisabled` word. The off track carries
an inset `2px 2px 0 cream-3` well; Flutter has no inset `BoxShadow`, so draw it as an inner top/start
border, never a second shadow. `onTap: null` and `minTarget: 0` — the 62px settings row is the target.

## PopBadge, PopSheet, PopBottomNav

**Badge**: pill, 3px, e1, padding `7/15`, `type.chip` 14, with a drawn glyph — never an emoji (§08 bans
platform glyphs). Variants: `celebration` (`accent`, e2, rotated −2.5°, star, padding `8/16`), `quiet`
(`surfaceRaised`), `locked` (`surfaceSunk`, `textSecondary`, dashed, no shadow). Never tappable; if it
needs a tap it is a `PopChip`.

**Sheet**: `surface`, `radiusXl` top / `radiusMd` bottom, 3px, e3, padding `14/18/18`, a 56×6 `border`
grab handle with 14 below. Title snaps to `type.title` 21 and body to `type.body` 15 — the mockup's 23/14
sit between scale steps. Actions stack full-width, 10px gap, primary first; enters over `durMove` 180 on
`easeInOut`.

**Bottom nav**: height 90, `surfaceRaised`, **a 3px ink top border only** — the one component with a
partial border, because the other three edges are the screen (`.tabs{border-top:…}`; the §10 demo boxes
it for display). Items 88 wide, `radiusMd`, 3px transparent border, icon 22 at stroke 2.6 over a Fredoka
600 11.5 label, `textSecondary`. Active: `accent` fill, `textPrimary`, ink border, e1. Three destinations
and never more; absent during a run.
