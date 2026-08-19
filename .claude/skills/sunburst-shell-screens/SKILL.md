---
name: sunburst-shell-screens
description: Enforces the MindForge shell contract for Sunburst Pop — the eight shared screens (home, game detail, countdown, play scaffold, pause sheet, results, stats, settings) are authored once under lib/features/**; a game supplies only GameDefinition.buildBoard and a BoardSnapshot. RunNotifier owns the RunPhase machine (idle→countdown→playing→paused→over), the injected Clock, the three-slot GameHud and every route change; lib/games/** may not import go_router or build a Scaffold, AppBar or HudPill; gutter 20, cardGap 16, PopBottomNav on three screens. Use when building a shell screen, adding a game, or wiring PlayScaffoldScreen, the countdown or results.
---

# Sunburst Pop — shell screens

MindForge is an engine: one shell, many small games. The eight screens in
`design/sunburst-pop/app.html` are the whole product except the board rectangle, and they are written
**once** — a new game ships rules, a board widget and an accent colour, and inherits home, difficulty
select, countdown, HUD, pause, results, stats and settings without adding a line to any of them. This
skill owns those eight screens, their layout numbers, and the seam between shell and game; it does not
own the tokens they read (`sunburst-tokens`), the widgets they compose (`sunburst-components`), the
board's visual language (`sunburst-game-surfaces`) or the feel of each transition
(`sunburst-motion-and-haptics`).

**Every hex, spacing, elevation and radius here is transcribed from `app.html` and `system.html`**;
anything derived is marked `DERIVED` at the point of use. Token classes are the ones `sunburst-tokens`
declares — `SunburstColors` / `SunburstShape` / `SunburstType` / `SunburstMotion`, each with an
asserting `of(context)`. (system.html §12 sketches them as `MindforgeTokens`/`MindforgeText`; the token
skill renamed them and, as owner of the layer, its names win.)

Read the reference for the task at hand:
- `references/screen-anatomy.md` — the eight screens as ASCII wireframes: anatomy top to bottom, the components each composes, its spacing rhythm, and a fixed-vs-variable table per screen.
- `references/shell-game-boundary.md` — `GameDefinition`, `BoardSnapshot`, `GameHud`, what the shell passes down, what a game hands back, and the list of things a game is forbidden to do.
- `references/run-lifecycle.md` — the `RunPhase` machine, every transition and its trigger, which screen renders each phase, and the background/resume, back-button and announcement rules.

The visual sign-off target for every screen is its rendered PNG in `design/sunburst-pop/screens/`
(procedure: `screens/README.md`, rule 13 below). Read the wireframes here to build; compare against
the screenshots to finish.
- `templates/screen_template.dart` — copy to start a new shell screen: layout scaffold, spacing tokens and a11y hooks pre-wired.
- `examples/play_scaffold.dart` / `examples/home_screen.dart` — the two screens worth reading end to end: the board seam, and a hub with zero per-game code.

Run `scripts/check_shell_boundaries.sh` before a PR, alongside `sunburst-tokens`'
`check_raw_values.sh`.

## Non-negotiable rules

1. **The shell owns every pixel outside the board rectangle.** Top bar, difficulty chip, play band,
   HUD, progress track, pause affordance, countdown, results hand-off and bottom nav are built by
   `lib/features/**` and are not parameterised by game id. A game contributes exactly two things:
   `GameDefinition.buildBoard(context, config)` and a `BoardSnapshot` listenable.
   WHY: the second game is where an engine either proves itself or forks — one re-implemented HUD and
   every future game inherits a copy instead of the shell.

2. **A game never navigates.** No `package:go_router` import, no `context.go`/`context.push`, no
   `Navigator`, no `Scaffold`, no `AppBar`, no `PopScope` anywhere under `lib/games/**`. The board
   reports an outcome into its snapshot; `RunNotifier` reads it, transitions to `RunPhase.over`, and
   the shell replaces the route. `scripts/check_shell_boundaries.sh` fails the build on any of these.
   WHY: a game that pushes its own results screen owns back-stack behaviour it cannot test, and the
   pause sheet's "Leave run" then pops into a screen nobody expected.

3. **The shell owns the clock; the game owns the board.** `RunNotifier` holds the only ticker, driven
   by the injected `Clock` (`clockProvider`, owned by `service-boundary-and-native`), and publishes
   `elapsed`/`remaining`. A game may not start a `Timer.periodic`, `Ticker` or `Stopwatch` for run timing.
   WHY: two clocks drift, and pause has to stop exactly one of them — a board-local stopwatch keeps
   counting behind the pause sheet and the player is robbed of the seconds they paused for.

4. **The HUD is exactly three slots and the game only fills them.** `GameHud(slotA, slotB, slotC)`,
   each an `HudSlot(label, value, tone)`: `neutral` (`surfaceRaised`, e1, `textSecondary` label),
   `highlight` (`accent` sunshine, both lines `textPrimary`), or `alarm` (`colors.danger`, both lines
   `colors.surfaceRaised`). The alarm is **`danger`, not the gallery's coral** `.hstat.bad`: coral is
   `colors.gameStroop`, which is also the fill of the Stroop play band the HUD sits on, so a coral
   pill vanishes on the screen that needs it most. `sunburst-motion-and-haptics` owns that DERIVED
   call as `Moment.timerAlarm` and `sunburst-components` renders it; this skill only decides when the
   tone is set. Stroop fills Time / Score / Streak; Schulte fills Time / Found / Next. A game never
   constructs `HudPill`, never adds a fourth pill, and never sets `HudTone.alarm`.
   WHY: three equal-flex pills at gutter 20 with gap 8 is the only arrangement that survives 360pt and
   a large text scale; a game-authored fourth pill overflows on the cheapest phone we target.

5. **Spend `SunburstShape`'s scale and nothing else: gutter 20, `cardGap` 16, card padding 15–17.**
   `SunburstShape.gutter` (`space5`) is the horizontal gutter on all eight screens without exception;
   `cardGap` (`space4`) is the gap between stacked cards. system.html §05 reserves `space6` 28 for
   "between a header and the content it owns" and `space7` 40 for "the hero moment" — app.html spends
   26 in both places, so reach for either only where a hero moment genuinely asks for it.
   WHY: hard 3px borders and unblurred offset shadows already read as space — an improvised 24 or 32
   makes one card look broken rather than roomy.

6. **Only the countdown goes edge-to-edge.** `Scaffold.backgroundColor` is `colors.surface` and
   content sits inside `SafeArea`: app.html paints its status-bar strip on `--surface` for seven of
   the eight screens, so the coloured header and the play band begin **below** the inset, not under the
   notch. `CountdownScreen` is the exception — `.count` is `inset: 0` grape with cream-tinted status
   glyphs, so it takes `SystemUiOverlayStyle.light`, skips the top `SafeArea` and insets its own content.
   WHY: both mistakes are visible — a header bled under a dark status bar loses its glyphs, and a
   countdown that stops at the inset shows a cream bar over a grape burst.

7. **`RunPhase` is a machine and only `RunNotifier` transitions it.** `idle → countdown → playing →
   paused → over`, plus `paused → countdown` and `paused → over`. No widget sets a phase and no board
   emits one; `over` is terminal — a rerun is a new `RunConfig`, family key, notifier and countdown.
   WHY: the transition is also where the run is persisted; a phase set from two places persists twice
   or not at all, and the personal-best badge fires on a run that was never written.

8. **Backgrounding pauses; resuming never un-pauses.** On `AppLifecycleState.inactive`, `.paused` or
   `.hidden`, `RunNotifier` moves `playing → paused` and shows the pause sheet. Returning to the
   foreground leaves the phase at `paused`; the player taps "Keep playing" and the shell replays the
   3-2-1 before the clock restarts (`DERIVED` — app.html shows the countdown only at run start).
   WHY: an auto-resume hands the player a stopwatch that started while they read a notification.

9. **One `Semantics(header: true)` per screen, and the run-over announcement fires exactly once.** The
   h1 is: Home "Ready to train?", detail = the hero title, countdown "Get ready", pause sheet "Leave the
   run?", results "Nice run!", stats "Stats", settings "Settings"; the play scaffold has **no** header —
   the board is the content. On `→ over` the shell calls `SemanticsService.announce` once with the whole
   outcome sentence and moves focus to the results h1.
   WHY: announcing score, accuracy and badge as three live regions speaks over itself; and a HUD
   marked `liveRegion: true` re-reads the timer every tick, which is unusable.

10. **The bottom nav exists on exactly three screens.** `Play`, `Stats`, `Settings` are branches of one
    `StatefulShellRoute.indexedStack` (owned by `navigation-and-routing`); the 90pt `PopBottomNav` with
    its 3px ink top border never appears on game detail, countdown, play or results. Its 90pt
    **includes** the bottom inset — `.tabs` top-aligns its items and the home indicator floats below.
    WHY: a nav bar under a live board is a mistap that ends the run, and it steals 90pt from the board
    on the screen with the least room.

11. **Nothing shrinks to fit, and no shell widget writes a `fontSize`.** No `FittedBox`, no
    `TextOverflow.ellipsis` on a value, no clamped `textScaler`. A step `SunburstType` lacks is a **new
    field on `SunburstType`**, never `type.title.copyWith(fontSize: 17)` — that literal fails
    `check_raw_values.sh`. Results and stats bodies scroll so `scoreHero` (76) can grow; the HUD row
    reflows from 3-across to 2+1 above `textScaler` 1.3 (`DERIVED` — the mock has one text scale).
    WHY: `accessibility-as-code` bans fit-to-shrink outright, and the one number the player came for is
    the first thing a `FittedBox` makes unreadable.

12. **A game's presence on Home, Stats and Results is data, not code.** Card, BEST pill, locked slot,
    difficulty list and score formatting (`ScoreFormat.points` → "1,480", `ScoreFormat.duration` →
    "18.6s") are `GameDefinition` fields read out of `gameRegistryProvider`. A file under
    `lib/features/**` that imports `lib/games/<a specific game>/` is a gate failure;
    `lib/games/game_registry.dart` is the one file allowed to name them all.
    WHY: the locked "N-Back / Coming soon" slot in app.html exists to prove the engine grows — it stops
    being proof the moment adding a game means editing `home_screen.dart`.

13. **Sign a screen off against its reference screenshot, never against this document.**
    `design/sunburst-pop/screens/NN-<name>.png` is the rendered truth for each of the eight screens —
    390×844 at 2×, regenerated by `design/sunburst-pop/capture-screens.sh`. Run the built screen at
    390×844 and compare in this order: **structure** (same regions, same order, same relative heights)
    → **spacing rhythm** → **surface construction** (3px ink border, the right hard-shadow step, zero
    blur) → **type role** → **sampled hex**. A difference is a defect in the code. If the reference is
    genuinely wrong, change `app.html`, re-run `capture-screens.sh`, and commit that as a deliberate
    design change — never let code and reference drift apart silently.
    WHY: prose and ASCII wireframes under-specify optical detail. Two engineers reading rule 5 still
    produce two different screens, and only the pixel comparison catches it. Note the limit: these are
    **end states only** — press physics, transitions and haptics cannot be verified from a screenshot
    and belong to `sunburst-motion-and-haptics`.

## The one seam: where a game enters the tree

```dart
// lib/features/play/presentation/play_scaffold_screen.dart
// The ONLY place a game-authored widget is inserted into the shell tree.
Expanded(
  child: _BoardPane(               // applies the 0/20/26 gutter and the board background
    background: definition.boardBackground,
    accent: definition.accent,
    child: RepaintBoundary(        // the board repaints per frame; the HUD above it must not
      child: definition.buildBoard(context, config),
    ),
  ),
)

// WRONG — lib/games/stroop_rush/ui/stroop_board.dart: a game rebuilding the shell.
Scaffold(                                           // rule 2: no Scaffold in a game
  appBar: AppBar(title: const Text('Stroop Rush')),  // rule 1: the shell owns the top bar
  body: SafeArea(                                    // rule 1: _BoardPane already inset it
    child: Column(children: [
      const HudPill(label: 'Time', value: '0:23'),   // rule 4: the shell owns the HUD
      StroopAnswerGrid(onAnswer: (a) => context.go('/results')), // rule 2: never navigates
    ]),
  ),
);

// RIGHT — the board fills the constraints it is handed, and nothing else.
Column(children: [
  Expanded(child: StroopStimulusCard(prompt: board.prompt)),
  const SizedBox(height: SunburstShape.cardGap),     // 16 between stacked surfaces
  StroopAnswerGrid(
    answers: board.answers,
    onAnswer: (a) => ref.read(stroopBoardNotifierProvider(config).notifier).answer(a),
  ),
]);
```

The board adds no `SafeArea` and no gutter `Padding` — `PlayScaffoldScreen` applied both — and reports
being finished by setting `BoardSnapshot.outcome`, never by routing. Full contract in
`references/shell-game-boundary.md`.

## The run lifecycle, and who renders what

| Phase | Rendered by | Entered on | Left on |
|---|---|---|---|
| `idle` | `GameDetailScreen` | route entry | Play tapped |
| `countdown` | `CountdownScreen` (full-bleed grape, e4 ring) | `start()` | 3 ticks elapsed |
| `playing` | `PlayScaffoldScreen` + board | countdown ends | pause, lifecycle, or outcome |
| `paused` | `PlayScaffoldScreen` + `PauseSheet` over it | pause tap / app backgrounded | keep playing, or leave |
| `over` | `ResultsScreen` | `BoardSnapshot.outcome != null` | Play again / Home |

A finished board writes `outcome: RunOutcome.completed(score: found)` into its snapshot and stops.
`RunNotifier` persists the run through the repository (the single write path, owned by
`state-management-riverpod`) and only *then* sets `RunPhase.over`, so the personal-best badge can never
celebrate a run that failed to save. `PlayScaffoldScreen` holds the one `ref.listen` that replaces the
route. Every transition and trigger: `references/run-lifecycle.md`.

## Vertical rhythm, verbatim from app.html

| Slot | Value | Where |
|---|---|---|
| Screen gutter | **20** (`SunburstShape.gutter`) | all eight screens, horizontally |
| Stacked-card gap | **16** (`SunburstShape.cardGap`) | `.body-pad`, results body, settings groups |
| Card inner padding | **15–17** | game card 15/16, daily mix 17/16, hero 20 |
| Header inner padding | `6/20/22` home · `10/20/18` stats + settings · `10/20/26` results | `.hdr > .in` |
| Body pane top padding | **16** home/stats/settings · **20** results/play | `.body-pad`, `.playfill` |
| Top bar | padding `2/20/16` detail · `2/20/10` play | `.topbar` |
| HUD row | padding `2/20/12`, gap **8**; track padding `0/20/14`, height **16** | `.hud`, `.trackwrap` |
| Bottom nav | height **90** incl. bottom inset, 3px ink top border, pad `9/14/0` | `.tabs` |
| Board pane | padding `0/20/26`, top **20** | `.playfill` |
| Answer grid / tile grid | gap **12** | `.answers`, `.grid5` |

Odd values there (2, 6, 10, 14, 22, 26) are real: app.html pairs a scale step with a 2–6pt optical
nudge where a ray layer or a hard shadow eats the gap. Transcribe them; do not round to the nearest
step. The constants themselves (`SunburstShape.space1…space7` = 4/8/12/16/20/28/40, `gutter`,
`cardGap`, `cardPadding`) are declared by `sunburst-tokens`; this skill decides only where each is spent.

Six type steps the screens need are **not** on `SunburstType`, and rule 11 forbids
`copyWith(fontSize:)`, so they are token requests. Names `DERIVED`, values measured from app.html:
`titleBar` Fredoka 600 · 17 · −0.17 (`.topbar .tt`), `greeting` Nunito 800 · 14 · +0.28 (`.greet`),
`sectionLabel` Fredoka 600 · 15 · +0.15 (`.seclab b`), `heroTitle` Fredoka 700 · 38/0.98 · −1.14
(`.hero .ht`), `countdownNumeral` Fredoka 700 · 132 · −5.28 (`.bigring b`), `statValue` Fredoka 700 ·
26 · −0.52 (`.statbox b`).

## Small screens and large text

app.html scales the whole 390×844 mock by `--k` rather than reflowing, so it specifies **nothing** below
390pt. These four are `DERIVED` and are the shell's contract:

- **The 20pt gutter never shrinks.** At 360pt a Schulte tile is `(360 − 40 − 4×12) / 5 = 54.4pt` — above
  the 48pt target floor, so the grid keeps five columns and the tile floats. Never floor a tile size
  (`widget-composition`), and never drop the 12pt gap to make a tile *bigger*. The one sanctioned
  reason to step the gap 12 → 8 is the opposite case: at 320pt the 12pt gap puts the cell at 46.4pt,
  under the 48pt floor, and 8 puts it at 49.6. That step lives inside the board and is derived from
  the floor, never from a width breakpoint — `sunburst-game-surfaces` rule 8 owns it. The gutter is
  not part of the trade.
- **Above `textScaler` 1.3 the HUD reflows:** the three pills leave the `Row` for a `Wrap`, 2 + 1,
  rather than each losing its label.
- **Results and Stats bodies scroll.** `scoreHero` at 76 × 200% overflows the pane, so the mock's
  `justify-content: center` becomes `Center` in a `SingleChildScrollView` with
  `ConstrainedBox(minHeight: viewport)` — centred at 1×, scrollable at 2×.
- **The play scaffold never scrolls.** If the HUD grows the board shrinks; a scrolling board moves the
  tile out from under the thumb already aiming at it.

## Anti-patterns

- **A `PlayScaffold` variant per game** (`StroopPlayScaffold`) — there is one, and it takes a `GameDefinition`.
- **`switch (gameId)` in a shell file** — the branch belongs on `GameDefinition` as a field.
- **A board that reads `runNotifierProvider`** — the shell's phase is not board state.
- **A pause sheet with a third action** — system.html §10 specifies exactly "Keep playing" and "Leave run".
- **A HUD marked `liveRegion: true`**, or a per-stat announcement on results — see rule 9.
- **A header bled under the status bar** on anything but the countdown — see rule 6.
- **The bottom nav rebuilt per screen** instead of living in the `StatefulShellRoute` branch shell.
- **A game reading `MediaQuery` to decide its own gutter** — the shell already applied it.

## Boundaries

- `sunburst-tokens` owns every value and token type these screens read — `SunburstColors`,
  `SunburstShape` (`gutter`/`cardGap`/`space1…space7`), `SunburstType`, `SunburstMotion`, their
  asserting `of(context)`, and `check_raw_values.sh`. This skill declares no tokens.
- `sunburst-components` owns `PopSurface`, the press formula, and the catalog these screens compose
  (`PopButton`, `PopIconButton`, `PopChip`, `PopCard`, `GameCard`, `DifficultySegmented`, `HudPill`,
  `TimerRing`, `PopProgressBar`, `GridTile`, `PopToggle`, `PopBadge`, `PopSheet`, `PopBottomNav`). The
  screen-shaped composites (`RayHeader`, `HalftoneDots`, `PlayBand`, `GameHeroPanel`, `DailyMixCard`,
  `StatBox`, `ScoreSlab`, `BestCard`, `Wordmark`) are shell-owned, live in
  `lib/features/shell/widgets/`, compose `PopSurface`, and add no new visual vocabulary. The drawn
  glyph set (`SunburstGlyph`, `lib/ui/glyphs/`) is also shell-owned — no sibling claims it — and follows
  the README's two stroke weights: 2.6 at 22pt, 3 at 18–20pt. No emoji, ever.
- `sunburst-game-surfaces` owns `GameAccent`, `GameColourRole`, `PlayFill`, the gameplay and
  colour-blind palettes, and what a board paints inside its rectangle.
- `sunburst-motion-and-haptics` owns every duration, curve, haptic and reduce-motion collapse named here
  — countdown tick, press, correct/wrong, found, timer alarm, personal-best celebration.
- `navigation-and-routing` owns `GoRouter`, `StatefulShellRoute.indexedStack` and `PopScope` mechanics;
  `state-management-riverpod` owns `RunNotifier`'s provider shape, the single write path and
  `clockProvider`; `widget-composition` owns const-class/`SafeArea`/grid mechanics;
  `accessibility-as-code` owns target sizes, never-clamp-`textScaler` and `Semantics` roles.

## Definition of done

- [ ] `check_shell_boundaries.sh` clean: no game navigates, builds a `Scaffold`/`AppBar`/`SafeArea` or
      draws shell chrome; no shell file imports a specific game.
- [ ] Gutter 20, stack gap 16, and no spacing outside 4/8/12/16/20/28/40 plus the table's optical nudges.
- [ ] Exactly one `Semantics(header: true)`; focus on entry lands on it.
- [ ] Content inside `SafeArea` over a `colors.surface` background; only `CountdownScreen` bleeds.
- [ ] No `FittedBox`, clamped `textScaler`, ellipsised value or `copyWith(fontSize:)`; checked at 200%
      text scale and 360pt.
- [ ] The game touched here added zero lines to `lib/features/**`, and `RunPhase` still transitions only
      inside `RunNotifier`.
- [ ] `PopBottomNav` present on exactly Home, Stats and Settings.
- [ ] Compared side by side with `design/sunburst-pop/screens/NN-<name>.png` at 390×844 — structure,
      spacing rhythm, surface construction, type roles and sampled hexes all match, or the delta is
      recorded as a deliberate, committed design change.
