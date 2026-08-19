# Template — adding a moment to the Sunburst Pop catalog

A moment gets a catalog row **before** it gets a line of code. Copy this file, answer the six
questions, paste the row into `SKILL.md`'s table and the values row into
`references/moment-catalog.md`, then add the enum value.

## Answer these first — an unanswerable question means the moment is not designed

1. **Is this actually a new moment, or an existing one on a new surface?**
   Eighteen rows already exist. A new game's tile tap is `tileFound`, not `nBackCellHit`. Adding a
   row that duplicates a row is how the app ends up with three slightly different "correct" feelings.

2. **What committed state change is the trigger?**
   Name the notifier write. "When the widget appears" and "when the animation ends" are not triggers
   — those produce haptics that fire on rebuild and on frame callbacks. If the trigger is a threshold
   (a countdown boundary, a score crossing, a first-time event), name the `bool`/`int` latch field on
   the notifier state and where it resets.

3. **Which of the four durations and three curves does it spend?**
   `durTap` 120 (press) · `durState` 160 (a value or fill changing in place) · `durMove` 180 (a
   surface travelling) · `durCelebrate` 240 (a bounded payoff). `easePop` overshoots once and is
   legal on **transform and scale only**; `easeOut` arrives (every colour and opacity change);
   `easeInOut` travels. Read them off `SunburstMotion.of(context)` and pass them through
   `resolve(context, …)`. Nothing runs longer than 240ms. If none of the four fits, the moment is
   wrong, not the scale.

4. **Which haptic verb, and is `—` the honest answer?**
   Consult `references/haptics-map.md` for the ceiling per class of event. `heavyImpact` is already
   spent on `personalBest` and is not available. A declared silence is a correct answer and must be
   written as `—`, never left blank.

5. **What is left when Sound is off, Haptics are off, and Reduce motion is on?**
   Write the residue as a concrete fill, shape, ring, border or word. "Nothing" and "a shorter
   animation" are both failures. If the residue is only a colour change, the moment also needs a
   shape or a word — see `accessibility-as-code`. Reduce motion never gates the haptic: put the
   `fire()` call **above** any reduce-motion early return.

6. **What is the stop condition?**
   For anything that is not a single tween to a fixed end state: what stops it when the route is
   popped, the app is backgrounded, the widget disposes, or the player taps mid-flight? A moment with
   no stop condition does not ship.

## The row for SKILL.md

```
| `momentName` | <committed state change> | <what moves, with pixel values> | `durX` | `easeX` | `verb` or `—` | `slot` or `—` | <residue with all three switches off> |
```

## The row for references/moment-catalog.md

```
| `momentName` | <exact offsets, amplitudes, fills; mark anything not in system.html as **DERIVED**> | <latch field name or `—`> |
```

Add a short prose section under it if any answer above was non-obvious — especially if you derived a
value. A **DERIVED** value with no stated reason is indistinguishable from a value someone made up.
If the value you need *is* in `system.html` but disagrees with itself (the rendered gallery vs the
sketched Dart block), the rendered gallery wins and you say so in the prose.

## The code

```dart
// lib/shared/feedback/moment.dart
enum Moment {
  // ...existing eighteen, in catalog order...
  momentName,
}

// lib/shared/feedback/feedback_service.dart — the map gains one line.
// A null verb is the declared silence from question 4.
Moment.momentName => null,
```

## Before the PR

- [ ] Row added to both tables; every column filled, `—` used for declared silences.
- [ ] `Moment` enum value added in catalog order; the `FeedbackService` switch is still exhaustive
      with no `default:`.
- [ ] Any **DERIVED** value carries a stated reason.
- [ ] `scripts/check_motion_tokens.sh` clean.
- [ ] Verified on a physical device with Sound off, Haptics off and Reduce motion on, then again
      with all three on — the haptic fires exactly **once** in both passes.
