# The accent contract

Each game owns exactly one hue. That hue is its identity across Home, Detail, the play band, the
progress stripe and Stats — and it is the only thing about the shell that changes when a new game
ships. Everything below is transcribed from `system.html` §02/§12 and `app.html` screens 01–05,
except where marked **derived**.

## Assignment

| Game | Accent case | Base slot | Base hex | Deep slot | Deep hex | Colour role |
|---|---|---|---|---|---|---|
| Stroop Rush | `GameAccent.stroopCoral` | `gameStroop` | `#FF6B5A` | `gameStroopDeep` | `#E8452F` | `mechanic` |
| Schulte Grid | `GameAccent.schulteTurquoise` | `gameSchulte` | `#22C7B8` | `gameSchulteDeep` | `#12A79A` | `decorative` |
| N-Back | `GameAccent.nBackGrape` | `gameNBack` **(derived)** | `#6A45E8` | `gameNBackDeep` **(derived)** | **not yet authored** | `decorative` |

`gameStroop`/`gameSchulte` and their `*Deep` partners exist on `SunburstColors` today. **`gameNBack`
and `gameNBackDeep` do not** — neither slot appears in `system.html` §12, and the `#6A45E8` above is
the existing `grape` primitive, quoted because that is the hue the direction reserves for N-Back. Both
slots are requests to `sunburst-tokens`, not shipped values, and the `switch` below will not compile
until they are added.

Coral carries ink at 5.4:1, turquoise at 7.2:1, grape carries cream at 5.5:1 — so grape is the only
accent whose band labels invert to `textInvert`. `gameSchulteDeep` carries ink at 5.1:1, which is
what makes it legal as a found-tile fill.

**Two open items on N-Back, both derived:**

1. `system.html` has **no `grape-deep` primitive**. `grape-pop #7C5CFF` is *lighter* than grape and is
   already spent on the focus ring and decoration — reusing it for the ray/stripe layer would make a
   focused control indistinguishable from a decorative ray. A new measured primitive is required
   before N-Back's play band can be built.
2. Grape is already `accentAlt` — Daily Mix, the countdown, the Settings header. Giving it to N-Back
   means an N-Back countdown is grape-on-grape. That is acceptable (it is the only screen where the
   two meanings meet, and it reads as "the game is starting" either way) but it must be a recorded
   decision, not a discovery.

## The next game

`sunshine` is the primary-action slot, `leaf` is success, `tangerine` is warning, `grape-pop` is the
focus ring, `ink`/`cream`/`paper` are structure. Subtract those and the palette holds **exactly three
game identities: coral, turquoise, grape.** Game four does not get a tint, a lighter coral or a
"teal-ish" turquoise — it gets a **new measured primitive** authored in `sunburst-tokens` with:

- ink or cream label contrast ≥ 4.5:1 recorded in the token table,
- a `*Deep` partner ≥ 20% darker for the ray/stripe layer, itself ≥ 3:1 against the base,
- ΔE76 ≥ 25 from every existing accent under deuteranope and protanope simulation, so two game cards
  on Home are never the same block,
- and no collision with the gameplay palette — a new accent within ΔE76 of `playRed`/`playOrange`
  puts a near-answer hue on the Stroop band.

## What the accent may tint

| Surface | How | Source |
|---|---|---|
| Play band background | flat fill, `flex:none`, 3px ink bottom border | `app.html .playband--*` |
| Play band rays | `*Deep` repeating conic, 5° on / 7° off, **opacity .45**, 720×720 centred, top −330 | `app.html .playband .rays` |
| Progress track fill | 45° stripe, base 0–9px / `*Deep` 9–18px, 3px ink right border | `app.html .track i` |
| Timer ring arc | base for the running arc, `warning` for the last 5s (shell-owned) | `system.html` §10 Timer ring |
| Home game card | flat fill behind the card's 3px ink border | `app.html` screen 01 |
| Game detail hero | flat fill + rays, same recipe as the play band | `app.html` screen 02 |
| Stats "best" card for that game | flat fill; lifetime totals stay neutral | `app.html` screen 07 |
| The board field — **`decorative` games only** | flat fill, e.g. `.playfill--schulte` is turquoise | `app.html` screen 05 |

## What the accent may never tint

- **Any text, anywhere.** Accents are fills; labels on them are `textPrimary` or `textInvert`.
  `textSecondary` (`ink-2`) drops to 2.8:1 on coral and 3.7:1 on turquoise — on a saturated fill the
  label goes to full ink.
- **A primary button.** Primary is always `accent` (sunshine); a coral "Play" makes Stroop's own
  action look like a Stroop answer.
- **A HUD pill fill.** Pills are `surfaceRaised`; only the third may be `accent`.
- **The progress track's well.** Always `surfaceSunk` (`#FFEEDA`), in every game.
- **The focus ring.** Always `focusRing` (`grape-pop`), 4px outside a 3px cream gap, on every fill.
- **The board field of a `mechanic` game.** Stroop's board field is `surfaceSunk` — see below.
- **Success, warning or danger.** An accent never stands in for a semantic slot, and a semantic slot
  never stands in for an accent.

## `GameColourRole` — the flag that splits the two boards

```dart
/// Declared by the game, read by the board and by the review checklist.
/// `mechanic` = hue is part of the answer the player is being timed on.
enum GameColourRole { decorative, mechanic }
```

| | Stroop (`mechanic`) | Schulte (`decorative`) |
|---|---|---|
| Play band | coral + coral-deep rays | turquoise + turquoise-deep rays |
| **Board field** | **`surfaceSunk` `#FFEEDA`** — deliberately not coral | `gameSchulte` `#22C7B8` |
| Board objects | `surfaceRaised` stimulus card, `play*` answer keys | `surface` idle tiles, `gameSchulteDeep` found tiles |
| Wrong feedback | depth + ink strike + shake, **no `danger`** | `danger` fill + `surfaceRaised` glyph + shake |
| Correct feedback | key lifts to e3 and holds, **no `success`** | tile sinks to `gameSchulteDeep`, `next` cue advances |

That one row — `surfaceSunk` versus `gameSchulte` — is the whole rule made structural. Schulte can
stand on its own colour because a turquoise field never competes with "which number is 7". Stroop
cannot, because a coral field is one hue step from `playRed #D81E2C` and `playOrange #C24409`, and a
player who is being timed will take the hint.

## How the shell consumes it

The game never holds a `Color`. It declares a case; the theme layer resolves it.

```dart
// lib/theme/game_accent.dart — owned by this skill, read by the shell and by
// every board. It is a theme-layer file so `lib/games/**` may import it; the
// primitives in `sunburst_primitives.dart` stay unreachable from a game.
enum GameAccent { stroopCoral, schulteTurquoise, nBackGrape }

/// Declared by the game, read by the board and by the review checklist.
/// `mechanic` = hue is part of the answer the player is being timed on.
enum GameColourRole { decorative, mechanic }

extension GameAccentTokens on GameAccent {
  Color base(SunburstColors c) => switch (this) {
        GameAccent.stroopCoral => c.gameStroop,
        GameAccent.schulteTurquoise => c.gameSchulte,
        GameAccent.nBackGrape => c.gameNBack,
      };
  Color deep(SunburstColors c) => switch (this) {
        GameAccent.stroopCoral => c.gameStroopDeep,
        GameAccent.schulteTurquoise => c.gameSchulteDeep,
        GameAccent.nBackGrape => c.gameNBackDeep,
      };
  /// Label colour ON this accent. Grape is the only one that inverts.
  Color onAccent(SunburstColors c) =>
      this == GameAccent.nBackGrape ? c.textInvert : c.textPrimary;
}
```

`GameDefinition` (owned by `sunburst-shell-screens`) carries `accent`, `boardBackground` and
`buildBoard`; `PlayScaffoldScreen` reads `accent` to paint the band, the rays and the track, and
nothing else in the shell branches on which game is running.

`GameColourRole` and `GameDefinition.boardBackground` are the same decision seen from two sides, and
the game must keep them in step: `mechanic` ⇒ `BoardBackground.surfaceSunk`, `decorative` ⇒
`BoardBackground.gameAccent`. The role is the *reason* and lives here, next to the board it governs;
`boardBackground` is the shell-facing projection of it, because the shell must paint the field
without knowing why. A `mechanic` game that ships `BoardBackground.gameAccent` is the single change
that quietly turns Stroop into a hinted test — check it in review, since no `switch` can catch it.

Adding a game is a new enum case, a new `GameDefinition`, and a board widget — the exhaustive
`switch` above turns "you forgot the deep tone" into a compile error rather than a grey band in the
field.
