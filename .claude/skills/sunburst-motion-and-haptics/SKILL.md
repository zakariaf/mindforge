---
name: sunburst-motion-and-haptics
description: >-
  Enforces the Sunburst Pop moment catalog for MindForge — eighteen named moments deciding WHICH
  moment spends durTap 120 / durState 160 / durMove 180 / durCelebrate 240 and easePop
  Cubic(.2,1.5,.4,1) / easeOut / easeInOut (the values are sunburst-tokens'), nothing over 240ms and
  nothing repeating; PressPhysics is the app's one press CONTROLLER, timing geometry PopElevation
  resolved; every HapticFeedback call is confined to FeedbackService with heavyImpact spent once on
  personalBest; each moment declares a non-motion residue. Use when adding or tuning an animation,
  the countdown, a correct/wrong/found response, the last-5-seconds alarm, a celebration, a sheet or
  route transition, or a haptic.
---

# Sunburst Pop — motion and haptics

Sunburst Pop moves like an arcade cabinet: everything is snappy, everything overshoots once, and
nothing lingers. This skill owns the **concrete moment catalog** for MindForge — which animations and
haptics exist at all, what each one spends, and what is left when the player turns motion off. The
generic discipline (why moments are named, the commit-frame rule, interruptibility, celebration
budgets) is owned by `motion-and-haptics`; this skill fixes the eighteen moments and their numbers so
no agent has to invent a duration.

Read the reference for the task at hand:
- `references/moment-catalog.md` — the eighteen moments with their exact offsets, amplitudes, latch names and per-moment reasoning; the source of truth for "what does this moment actually do".
- `references/press-physics.md` — the press geometry derived from the resting shadow, the state-vs-animation split under reduce-motion, interruption handling, and the golden-test note.
- `references/haptics-map.md` — moment → `HapticFeedback` verb, the commit-frame and latch rules, platform caveats, and the three Settings gates.
- `templates/moment_entry.md` — the six questions a new moment must answer before it gets a catalog row or a line of code.

Working code: `examples/press_physics.dart` (the `PressPhysics` / `PressGeometry` / `PressBuilder`
seam every pressable surface drives, and which `PopSurface` composes) and
`examples/feedback_moments.dart` (`StroopRunNotifier`, `ShakeOnWrong`, `SchulteTile`,
`PersonalBestBadge`).

Run `scripts/check_motion_tokens.sh` before a PR, alongside `sunburst-tokens`' `check_raw_values.sh`.

## Non-negotiable rules

1. **There are four durations and three curves. There is no fifth.** Read them off
   `SunburstMotion.of(context)`: `durTap` 120ms, `durState` 160ms, `durMove` 180ms, `durCelebrate`
   240ms; `easePop` `Cubic(0.2, 1.5, 0.4, 1.0)`, `easeOut` `Cubic(0.2, 0.8, 0.2, 1.0)`, `easeInOut`
   `Cubic(0.6, 0.0, 0.3, 1.0)`. Nothing in the app runs longer than 240ms. A raw `Duration(...)`,
   `Curves.*` or `Cubic(` outside `lib/theme/**` fails `scripts/check_motion_tokens.sh`.
   **WHY:** system.html §09 states the ceiling directly — above 240ms this direction stops reading as
   arcade and starts reading as sluggish and cheap. A 200ms "just this once" is a value nobody chose.
   `easePop` overshoots past 1.0, so it is legal on scale and translate and illegal on colour or
   opacity — a fill tween driven past its endpoint shows a frame of a colour nobody picked.

2. **Press geometry is derived from the resting shadow, never picked, and there is ONE press
   implementation.** `travel = shadowOffset − 1` on both axes, the shadow collapses to `(1, 1)`, and
   the surface shrinks by `shape.pressScale` 0.98 above e1 or `shape.pressScaleSmall` 0.97 at e1 — so
   e2 surfaces (buttons, game cards, answer keys) travel 4px at 0.98 and e1 surfaces (grid tiles,
   toggles, nav tabs, segmented items, chips) travel 2px at 0.97. The ghost button draws no shadow but
   still sits at e1, so its travel derives to the 2px `system.html` states. `PopElevation`
   (`sunburst-components`) is the only elevation enum in the app and the only thing that resolves a
   step to those numbers; `PressPhysics` here is handed the result and `PopSurface` composes it —
   neither declares a rival enum, and no second widget drives a press controller.
   **WHY:** the object travels down its own shadow and leaves the 1px sliver behind, so the total ink
   footprint never changes. Any other pairing reads as the surface detaching from its shadow — and two
   press implementations diverge on the day one of them learns about reduce-motion.

3. **A press is a STATE; only its transform is animation.** Under reduce-motion the 120ms tween
   collapses to `Duration.zero` **and the translate + scale are dropped entirely** — but the shadow
   collapse to `(1, 1)` and the deepened fill still apply, on the pointer-down frame.
   **WHY:** system.html §09 is explicit — "the press transform is dropped, the pressed colour and
   shadow state still applies instantly, so feedback survives". A 4px translate at zero duration is a
   teleport that reads as a rendering glitch; fill and shadow read correctly at 0ms. Dropping the
   *whole* press because it "looks like motion" leaves a dead button and a double tap. This is the
   subtle rule, and it gets broken in both directions about equally often.

4. **Reduce motion collapses to zero, and the in-app toggle is folded into `MediaQuery` at the root.**
   Settings has its own "Reduce motion" row (app.html screen 08). Wrap the app once in a `MediaQuery`
   that ORs the stored preference into `disableAnimations`; every widget then goes through
   `SunburstMotion.resolve`, and **no widget reads `settings.reduceMotion`**.
   **WHY:** two sources of truth for "should I animate" means half the app honours the OS flag and
   half honours the app switch, and the split is invisible until one device has both set.

5. **The Stroop stimulus and the Schulte board never animate in.** The stimulus word cross-fades in
   place at `durState`/`easeOut` — no slide, no scale, no stagger. Tiles are painted at full opacity
   from the first frame of the run.
   **WHY:** this is a reaction-time measurement — every millisecond the stimulus is illegible is a
   millisecond added to the player's score, so an entrance corrupts the data the game exists to collect.

6. **One haptic per committed event, fired on the commit frame, latched where the trigger is a
   boundary.** The run timer ticks at 10Hz and the streak recomputes on every answer — a bare
   `if (secondsLeft <= 5)` fires fifty times. Every boundary moment (`timerAlarm`, `streakMilestone`,
   `personalBest`) carries a latch field on the immutable notifier state, reset only at run start.
   **WHY:** an unlatched boundary is not a haptic, it is a continuous vibration — invisible on a
   simulator and unmistakable in the hand.

7. **`HapticFeedback.*` appears in exactly one file, and `heavyImpact` appears exactly once in the
   app.** All calls live in `lib/shared/feedback/haptic_gateway.dart`; features call
   `ref.read(feedbackServiceProvider).fire(Moment.answerCorrect)`. `heavyImpact` is spent on
   `Moment.personalBest` and nowhere else — never on `answerWrong`, never on `runEnd`.
   **WHY:** ad-hoc haptics only ever escalate, and escalating intensity for a wrong answer punishes
   the player for a mistake the game deliberately induced.

8. **Every moment must still land with Sound off, Haptics off and Reduce motion on.** Those three
   Settings rows are independent switches and all three off at once is a supported configuration.
   Each catalog row's residue must be a fill, a shape, a ring, a border or a word — never "nothing"
   and never "a shorter animation".
   **WHY:** the design bans feedback that exists only as motion; this is where that ban is tested.

9. **Nothing repeats.** The wrong-answer shake is the only multi-cycle motion in the app, written as
   two explicit `forward(from: 0)` calls so the stop condition is the absence of a third line.
   `AnimationController.repeat()` should not appear in `lib/` at all; the gate fails it whenever the
   file has no `dispose()` **and** no `.stop()`, and review catches the rest. The header rays, the
   countdown ray burst and the play-band dots are static by design.
   **WHY:** system.html §09 — "nothing is allowed to repeat without an end". An ambient loop in an
   offline game is a battery bug no test catches and no screenshot shows.

10. **The last-5-seconds alarm is one state swap, not a pulse, and never the only channel.** At the
    boundary the HUD Time pill crosses once to `danger` with a `surfaceRaised` label over
    `durState`/`easeOut` — no pulsing, no shaking, no per-second tick. The fill and label inversion
    survive with motion off, and the tabular numerals keep counting. Both values are **DERIVED**.
    **WHY:** a repeating urgency animation is pressure rather than feedback, and it would be the one
    channel a reduce-motion player loses entirely.

11. **Celebrations are latched, bounded, non-blocking and disposed.** `personalBest` runs
    `durCelebrate`/`easePop`, scale `0.86 → 1.06 → 1.00` over a −2.5° resting tilt, plays once behind
    a `_hasPlayed` latch, mounts no barrier and no `AbsorbPointer`, rests at `value: 1` so any
    interruption lands on the end state, and is disposed on pop.
    **WHY:** the second time a player sees the badge they want to be past it, and a celebration that
    blocks input is a load screen nobody asked for.

12. **A new moment gets a catalog row before it gets code.** Fill `templates/moment_entry.md` — all
    eight columns, residue included, with an explicit `—` for a declared silence — then add the
    `Moment` enum value. A moment that cannot fill a column has not been designed.
    **WHY:** the framework default fills every empty column, and it has never seen this design system.

## The moment catalog

Eighteen moments. The duration and curve columns name `SunburstMotion` fields; the haptic column
names the verb `FeedbackService` maps the moment to; `—` is a **declared silence**, not an omission.
Sound cues are **DERIVED** slot names — system.html has a Sound settings row but no audio assets.

| Moment | Trigger | What moves | Duration | Curve | Haptic | Sound | Reduce-motion residue |
|---|---|---|---|---|---|---|---|
| `buttonPress` | pointer down | travel (off−1), shrink, shadow→(1,1), fill→deep | `durTap` | `easePop` | — | — | shadow (1,1) + deep fill at 0ms; no travel |
| `buttonCommit` | `onTap` resolves | release back to rest | `durTap` | `easePop` | `lightImpact` | `pop` | rest state at 0ms |
| `homeCardEnter` | Home first build | card dy 12→0 + fade, 40ms stagger, first 4 only | `durMove` | `easePop` | — | — | cards already in place |
| `difficultySelect` | segmented item tap | selected lifts to (−1,−1) with a (2,2) shadow, fill→`accent` | `durState` | `easeOut` | `selectionClick` | `tick` | lift + sunshine fill as state, 0ms |
| `countdownBeat` | each of 3, 2, 1 | numeral `0.86→1.06→1.00` (**DERIVED** reuse); next dot fills sunshine | `durCelebrate` | `easePop` | `selectionClick` | `tick` | numeral swaps, dot fills |
| `runStart` | beat 0 → board | grape countdown pane cross-fades to the play scaffold | `durMove` | `easeInOut` | `mediumImpact` | `go` | board appears |
| `answerCorrect` | correct key committed | key lifts e2→e3 and holds — **keeps its own hue**; stimulus cross-fades in place; Score pill value swaps | `durState` | `easeOut` | `lightImpact` | `pop` | key at e3 + new stimulus + new score |
| `answerWrong` | wrong key committed | key drops to `flat` at translate(2,2) with an ink strike bar and shakes ±4px × 2 — **keeps its own hue**; a Schulte tile takes `danger` + paper glyph instead | `durCelebrate` ×2 | `easeOut` | `lightImpact` | `thud` | depth + strike bar (tile: `danger` fill + paper glyph), no shake |
| `tileFound` | correct Schulte tile | fill→`gameSchulteDeep`, shadow→none, held at (2,2) | `durState` | `easeOut` | `selectionClick` | `click` | deep fill, flat, sunk — at 0ms |
| `tileNextCue` | same frame as `tileFound` | next tile fill→`accent`, e2 shadow + 2px cream gap + 3px ink ring | `durState` | `easeOut` | — | — | ring + fill as state, 0ms |
| `streakMilestone` | streak crosses a multiple of 5 (latched) | Streak pill bumps `0.86→1.06→1.00` | `durCelebrate` | `easePop` | `mediumImpact` | `chime` | the pill's new value |
| `timerAlarm` | secondsLeft crosses 5 (latched) | Time pill fill→`danger`, label→`surfaceRaised` | `durState` | `easeOut` | `selectionClick` | `alert` | inverted pill + counting numerals |
| `runEnd` | last answer / timer 0 | nothing — the board freezes | — | — | `mediumImpact` | `end` | frozen board |
| `resultsReveal` | Results route settles | 3 result cards dy 12→0 + fade, 40ms stagger | `durMove` | `easePop` | — | — | cards already in place |
| `personalBest` | new best, after reveal (latched) | badge `0.86→1.06→1.00` over its −2.5° tilt | `durCelebrate` | `easePop` | `heavyImpact` | `fanfare` | badge present, tilted, static |
| `toggleFlip` | Settings row tap | knob travels 32px; track fill→`success`; ON/OFF word swaps side | `durMove` (knob) / `durState` (track) | `easePop` / `easeOut` | `selectionClick` | `tick` | knob, track and word in final position, 0ms |
| `sheetTransition` | pause sheet open/close | sheet translates from/to the bottom edge | `durMove` | `easeInOut` | — | — | sheet present/absent |
| `routeTransition` | any push/pop | directional slide following `Directionality` | `durMove` | `easeInOut` | — | — | cross-fade |

`references/moment-catalog.md` carries the exact offsets, amplitudes and latch names per row.

## Derived values — not in system.html, chosen here

system.html fixes the tokens and the component states; it does not specify every moment. Six values
are **DERIVED**, each argued in `references/moment-catalog.md`: the **40ms stagger, first four cards
only**; the **1000ms countdown beat interval** (app.html screen 03 fixes three dots, not a cadence);
the **countdown numeral amplitude** (system.html states `0.86→1.06→1.00` for the celebrate class, and
the beat borrows it — but not the −2.5° tilt, which is `.badge.new` alone); the **last-5-seconds
pill** (the gallery offers `.hstat.bad` in coral, but coral is `gameStroop` and the HUD sits *on*
Stroop's coral play band, where a coral pill vanishes — so the alarm takes `danger` with a
`surfaceRaised` label, following the `.tile.wrong` precedent: paper on `danger` is 5.07:1, the pill's
default inks 3.03:1 and 1.53:1); the **wrong Stroop answer key** (`.tile.wrong` is specified for the
Schulte tile only, and the key may **not** borrow its `danger` fill — on a `GameColourRole.mechanic`
board the fill *is* the question and `danger` **is** `playRed`, a legal answer, so the key keeps its
hue and spends depth, an ink strike bar and the shake instead; `sunburst-game-surfaces` rule 3 owns
that boundary and this catalog follows it); and the **nine sound slot names**.
Anything else you need and cannot find: derive it, mark it `**DERIVED**` in the catalog with the
reason, and never quietly invent a token.

## Building the overshoot curve

```dart
// WRONG — a real spring in a widget: wrong shape, wrong file, 240ms hardcoded.
AnimatedScale(scale: s, duration: const Duration(milliseconds: 240), curve: Curves.elasticOut);

// RIGHT — the token. easePop is one cubic whose first control point sits at
// y = 1.5, so it crosses its target once, peaks 8% past it at ~45% of the
// duration, and settles. Measured from Cubic(.2, 1.5, .4, 1), not guessed.
final motion = SunburstMotion.of(context);
AnimatedScale(
  scale: s,
  duration: motion.resolve(context, motion.durCelebrate),
  curve: motion.easePop, // Cubic(0.2, 1.5, 0.4, 1.0)
);
```

`Curves.elasticOut` and a `SpringSimulation` oscillate — they cross the target three or four times
before settling, and that reads as a bouncy toy. `easePop` overshoots **once**: the mechanical snap
of a plastic arcade button returning past its detent, which is what makes a 3px ink border feel like
an object rather than a sticker.

## Reduce motion is a root override, not a per-widget check

```dart
// WRONG — feature code re-reading app state. Half the app will forget, and the
// framework's own transitions never see the app switch at all.
if (ref.watch(settingsProvider).reduceMotion) { /* ... */ }

// RIGHT — fold the Settings row into MediaQuery once, at the composition root.
// After this, SunburstMotion.resolve is the only place a widget asks.
Widget build(BuildContext context, WidgetRef ref) {
  final reduce = ref.watch(settingsProvider.select((s) => s.reduceMotion));
  final media = MediaQuery.of(context);
  return MediaQuery(
    data: media.copyWith(disableAnimations: media.disableAnimations || reduce),
    child: const MindforgeApp(),
  );
}
```

`resolve` is Sunburst Pop's binding of the generic `resolveMotion` mechanism `design-system-structure`
owns; it returns `Duration.zero`, never a shorter duration.

## Boundaries

- `motion-and-haptics` owns the generic discipline — why moments are named, the commit-frame rule,
  interruptibility, celebration budgets, multi-channel feedback. This skill supplies the rows.
- `sunburst-tokens` owns `SunburstMotion`/`SunburstShape`/`SunburstColors` themselves — the fields,
  `copyWith`/`lerp`, the asserting `of(context)`, `resolve`, and the raw-value gate this script
  narrows to motion. It fixes the four durations; this skill decides who spends them.
- `sunburst-components` owns the pressable surface's *chrome* (3px border, `e1`–`e4` shadow, radius,
  focus ring, `PopSurface`); this skill owns what happens to that chrome over 120ms.
- `sunburst-game-surfaces` owns tile and answer-key *state* semantics (`SchulteTileState`, the accent
  contract, `PlayFill`); this skill owns the transition between those states.
- `sunburst-shell-screens` owns the countdown, pause-sheet and results *anatomy* and the `RunPhase`
  machine that triggers these moments; this skill owns their beats.
- `state-management-riverpod` owns `FeedbackService`'s provider wiring and the latches on immutable
  notifier state; `accessibility-as-code` owns the never-colour-alone floor rule 8's residue column
  depends on; `widget-golden-and-a11y-testing` owns pumping a golden at a pinned animation phase;
  `async-safety` owns `unawaited` and post-await `mounted` guards.

## Definition of done

- [ ] `scripts/check_motion_tokens.sh` is clean over `lib/`; every animation reads `durX`/`easeX` off
      `SunburstMotion.of(context)`, none exceeds 240ms, and `easePop` appears only on transform/scale.
- [ ] Press geometry is derived from the resting shadow offset, not written per component.
- [ ] Reduce motion collapses to `Duration.zero` at the root; the press keeps its shadow and fill and
      drops its transform; no widget reads `settings.reduceMotion`.
- [ ] Every boundary-triggered haptic is latched and resets at run start; `HapticFeedback.*` appears
      only in `lib/shared/feedback/`; `heavyImpact` only for `personalBest`.
- [ ] Every new or changed moment has a filled catalog row, a `Moment` value, and any derived number marked.
- [ ] Verified on a physical device with Sound off + Haptics off + Reduce motion on, then all three on.

## References

- Design source of truth — `design/sunburst-pop/system.html` §09 Motion, §10 Components; `design/sunburst-pop/app.html` screens 03 Countdown, 04/05 Gameplay, 06 Results, 08 Settings.
- Flutter API — [`HapticFeedback`](https://api.flutter.dev/flutter/services/HapticFeedback-class.html), [`Cubic`](https://api.flutter.dev/flutter/animation/Cubic-class.html), [`MediaQueryData.disableAnimations`](https://api.flutter.dev/flutter/widgets/MediaQueryData/disableAnimations.html)
- WCAG 2.2 — [Animation from Interactions (2.3.3)](https://www.w3.org/WAI/WCAG22/Understanding/animation-from-interactions.html)
