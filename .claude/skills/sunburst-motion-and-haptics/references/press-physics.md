# Press physics

Sunburst Pop's whole claim is that every surface is a physical object sitting on the page. The press
is where that claim is proved or lost, and it is the most-executed animation in the app — a Schulte
run alone fires it 25 times in twenty seconds.

## The geometry is derived, not designed per component

Every raised surface carries a hard offset shadow at one of two elevations:

`PopElevation` (`flat`, `e1`…`e4`) is the elevation vocabulary and is declared **once**, by
`sunburst-components` in `pop_surface.dart`. This skill declares no elevation enum of its own:
`PressPhysics` takes the geometry already resolved (`restShadow`, `pressedShadow`, `travel`, `scale`),
which is what keeps one name for one concept and keeps `lib/shared/motion/` from importing
`lib/ui/components/`.

| `PopElevation` | Resting shadow | Press travel | Pressed shadow | Press scale | Surfaces |
|---|---|---|---|---|---|
| `e2` | `(5, 5)` | `(4, 4)` | `(1, 1)` | `shape.pressScale` 0.98 | primary/secondary buttons, game cards, answer keys, daily card |
| `e1` | `(3, 3)` | `(2, 2)` | `(1, 1)` | `shape.pressScaleSmall` 0.97 | grid tiles, toggles, nav tabs, segmented items, chips |
| `e3` / `e4` | `(8, 8)` / `(10, 10)` | `(7, 7)` / `(9, 9)` | `(1, 1)` | `shape.pressScale` 0.98 | hero panels, the stimulus card, `PopSheet`; the countdown ring at e4 |
| `e1` + `borderStyle: none` | none drawn | `(2, 2)` | none | `shape.pressScale` 0.98 | the ghost button only |

The rule underneath the table is one line: **travel = restingShadowOffset − 1, and the shadow becomes
(1, 1).** The surface travels down its own shadow and leaves a 1px sliver, so the total ink footprint
is unchanged while the object is down. `system.html`'s Dart block states it as
`Offset pressTranslate(Offset o) => Offset(o.dx - 1, o.dy - 1)`, and `sunburst-tokens` ships exactly
that on `SunburstShape` with `pressedShadow = Offset(1, 1)`. Derive it; never write a literal 4 or 2.

The ghost button looks like an exception and is not one. `system.html` states its 2px travel outright
(`.btn--ghost:active`) because it draws no shadow — but it still *sits* at e1, and `pressTranslate(e1)`
is exactly 2. `PopSurface` therefore builds it as `PopElevation.e1` with `borderStyle: none`: the
shadow is suppressed, the travel derives, and the stated number and the derived number agree. Nobody
types a 2.

**A source disagreement, resolved.** The rendered CSS uses `scale(.98)` on e2 surfaces and
`scale(.97)` on e1 (`.ans:active` vs `.tile:active`), and `README.md` confirms both — "e2 surfaces
translate 4px, e1 surfaces 2px, both shrink to `scale(.97–.98)`". The sketched Dart block at the
bottom of `system.html` collapses that to one `pressScale = 0.98`. **The rendered gallery wins** — the
same precedent `sunburst-tokens` applies when §04 and §12 disagree on a weight. Both scales are
therefore transcribed tokens, not press decisions: `sunburst-tokens` ships `shape.pressScale` 0.98 and
`shape.pressScaleSmall` 0.97, and `PopElevation.pressScale(shape)` is the one place that picks between
them. `PressPhysics` is handed the result and never chooses.

## State versus animation — the distinction that gets reversed

A press has four components. Two are **state** and two are **animation**:

| Component | Kind | Animations on | Reduce motion |
|---|---|---|---|
| fill → deep variant | state | crosses over `durTap` | applies at 0ms |
| shadow (5,5) → (1,1) | state | crosses over `durTap` | applies at 0ms |
| translate (4,4) | animation | tweens over `durTap` | **dropped** |
| scale 0.98 | animation | tweens over `durTap` | **dropped** |

`system.html` §09 is explicit: "every duration collapses to 0ms and the press transform is dropped —
the pressed *colour and shadow* state still applies instantly, so feedback survives."

Both halves of that sentence are load-bearing and each breaks on its own. Dropping the whole press
because it is "an animation" leaves a reduce-motion player tapping a button that never acknowledges
anything — the exact double-tap failure the press exists to prevent. Keeping the translate but zeroing
its duration produces a 4px instantaneous jump, which reads as a rendering glitch rather than a press
and flickers hard on a low-refresh panel. Keep the state, drop the transform.

Note the shape of that rule: it is about the *press*, which is transient. A resting state that happens
to include a transform — a found Schulte tile permanently at translate(2,2), the personal-best badge's
−2.5° tilt — is not motion and is never dropped. It is where the widget lives.

## Interruption

Drive the press from one `AnimationController` at `durTap` and move it with `animateTo` /
`animateBack`, never `forward()` / `reverse()` on a freshly reset controller. A player tapping a
Schulte tile every 400ms will regularly release before the press-down finishes, and `animateTo` picks
up from the controller's current value instead of snapping to 0 first.

Three pointer outcomes, all mandatory:

- `onTapDown` → `animateTo(1)`. **No haptic** — the commit has not happened.
- `onTap` → the commit: run the callback, fire the moment's haptic **once**, then `animateBack(0)`.
- `onTapCancel` → `animateBack(0)`, no haptic, no state change. A scroll that steals the gesture must
  leave the surface visually and behaviourally untouched.

A disabled surface takes none of these: `system.html` renders disabled as `transform: none` with a
soft-ink border and a soft-ink shadow, so the controller is never driven when `onPressed == null`.

## Golden tests

A press golden is only meaningful at a pinned animation phase. `pumpAndSettle` on a pressed surface
either times out or lands on the resting frame, so neither gives you the pressed pixels.

```dart
final gesture = await tester.startGesture(tester.getCenter(find.byType(PopButton)));
await tester.pump();                                   // dispatch the pointer-down
await tester.pump(SunburstMotion.sunburstPop.durTap);  // controller now at 1.0
await expectLater(find.byType(PopButton), matchesGoldenFile('button_pressed.png'));
await gesture.up();
```

Take the reduce-motion golden through a `MediaQuery(data: ...copyWith(disableAnimations: true))`
wrapper and assert it differs from the resting golden — that assertion is what catches someone
"simplifying" the reduce-motion branch into a no-op. Harness details belong to
`widget-golden-and-a11y-testing`.

## What this file does not own

The border width, radius, fill, shadow colour, focus ring and the ≥48px target of a pressable surface
belong to `sunburst-components` (`PopSurface`, `PopElevation`, `kPopMinTarget`); the `e1`–`e4` offsets,
`pressTranslate`, `pressedShadow`, `pressScale` and `pressScaleSmall` belong to `sunburst-tokens`. This
file owns only what those values do between pointer-down and pointer-up, and which haptic the commit
spends.

`PopSurface` **composes** `PressPhysics` — it does not reimplement it. There is one `GestureDetector`,
one `AnimationController` and one `FeedbackService.fire` on the press path in the whole app. If you
find a second widget driving a press, that is the bug.
