# E12 T12.9 — is False Light's depth delta actually perceivable?

The question the epic put first, because it was the one that could kill the
game: **a board mechanic made of shadow and offset is scanned peripherally under
time pressure, not looked at deliberately like a button.** If grey erases the
difference between a raised tile and a pressed one, False Light does not exist.

Measured on `epic/12-two-original-games`, 2026-08-29.

## What actually carries it — three channels, none of them hue

| | raised | pressed |
|---|---|---|
| shadow | hard offset at zero blur | **none** |
| position | at rest | translated into where the shadow was |
| fill | `surfaceRaised` (paper) | `gameFalseLightDeep` (leafDeep) |

WCAG relative luminance, computed rather than eyeballed:

| pair | ΔL |
|---|---|
| raised vs pressed fill | **0.716** |
| raised vs the board ground (`leaf`) | 0.561 |
| pressed vs the board ground | 0.154 |

The last row is the one worth reading: a pressed tile is *close* in value to the
board it sits on, which is what makes it read as a hole rather than as a
differently-coloured tile. That is the effect the game is named for.

## How it is held

- `test/games/false_light/ui/light_tile_states_test.dart` asserts all three
  channels differ, on values rather than on the image: shadow presence, summed
  `Transform` offset, and a computed luminance gap with a 0.2 floor.
- The same file renders a greyscale golden per direction, so the human question
  — *from this image alone, can you tell them apart?* — has an artifact to ask
  of.
- It also asserts the rendered fills are **identical** with the colour-blind
  palette on and off, because there is no answer colour on this board to
  re-point. That is the claim the 4.3(a) response rests on.

## The epic's own prediction, and what happened

T12.9 said the chrome offset would be too subtle for a board mechanic and that
the board would need a larger offset of its own, scaled by difficulty.

**It did not.** The tile takes `PopElevation.e2` — the ordinary raised step —
and the delta reads clearly at every difficulty on the canonical simulator,
including blitz at 5×6 on a 320pt device where the tile is 49.6pt. The reason is
the third channel: the epic's prediction reasoned about shadow and position
alone, and the fill's 0.716 luminance gap does most of the work. A larger
board-only offset would have been a token nothing else in the app uses, tuned to
a problem that turned out not to exist.

The prediction is recorded as wrong rather than deleted, because the *shape* of
the reasoning was right — it is why the game got a measured answer instead of an
assumed one.

## What this did not establish

- **Not on real hardware.** Same reason E11 recorded: no provisioned handset.
  The simulator renders the same Skia output, but perceived contrast at arm's
  length on a real panel at real brightness is a different measurement.
- **Not with a low-vision reader.** Luminance separation is a proxy for
  legibility, not a substitute for someone with reduced contrast sensitivity
  trying to play it. The board's non-visual channel — the three tile-state
  strings a screen reader announces — exists because that question has no
  automated answer.
