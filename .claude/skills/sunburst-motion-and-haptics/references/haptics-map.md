# The haptic map

MindForge spends **four** `HapticFeedback` verbs across eighteen moments. Every one of them goes
through `FeedbackService`, which resolves the moment to a verb and asks `HapticGateway` to play it.
`lib/shared/feedback/haptic_gateway.dart` is the only file in the repo allowed to name
`HapticFeedback`; `scripts/check_motion_tokens.sh` enforces that.

## Moment → verb

| Moment | Verb | Note |
|---|---|---|
| `buttonPress` | — | the visual press is the acknowledgment; a tick on every pointer-down is noise |
| `buttonCommit` | `lightImpact` | primary and secondary buttons only; ghost buttons are silent |
| `homeCardEnter` | — | not an interaction |
| `difficultySelect` | `selectionClick` | selection is the meaning of the control |
| `countdownBeat` | `selectionClick` | three, one per beat |
| `runStart` | `mediumImpact` | the hand-off; the loudest routine slot |
| `answerCorrect` | `lightImpact` | fires up to ~40× a run — must stay at the bottom of the scale |
| `answerWrong` | `lightImpact` | **never** `heavyImpact` |
| `tileFound` | `selectionClick` | |
| `tileNextCue` | — | same commit frame as `tileFound`; one event, one haptic |
| `streakMilestone` | `mediumImpact` | latched to multiples of 5 |
| `timerAlarm` | `selectionClick` | latched; exactly one per run |
| `runEnd` | `mediumImpact` | |
| `resultsReveal` | — | |
| `personalBest` | `heavyImpact` | **the only `heavyImpact` in the app** |
| `toggleFlip` | `selectionClick` | |
| `sheetTransition` | — | |
| `routeTransition` | — | navigation does not need confirming |

A `—` is a **declared silence**: the design decided there is no haptic here. Model it as a `null`
verb in the map so the row exists and reviewers can see the decision, rather than as a missing case.
`HapticFeedback.vibrate` is the fifth verb Flutter offers and MindForge never uses it — it is a
~500ms buzz on Android and a heavy fallback on iOS, and it is not in this table.

## The commit-frame rule

Fire on the frame the state actually changed, from the code path that changed it:

```dart
// WRONG — inside an animation listener. Fires ~7 times over durTap, and drifts
// away from its own visual by however long the controller took to schedule.
_controller.addListener(() { if (_controller.value > .5) HapticFeedback.lightImpact(); });

// WRONG — a bare boundary condition in a 10Hz tick. Fires 50 times in the last 5s.
if (state.secondsLeft <= 5) feedback.fire(Moment.timerAlarm);

// RIGHT — once, on the commit, latched where the trigger is a boundary crossing.
void onTick() {
  final next = state.copyWith(secondsLeft: state.secondsLeft - 1);
  if (!state.hasAlarmed && next.secondsLeft <= 5) {
    state = next.copyWith(hasAlarmed: true);
    _feedback.fire(Moment.timerAlarm);
    return;
  }
  state = next;
}
```

Three places a single event becomes a burst, all of which exist in this app:

1. **An `AnimationController` listener or `onEnd`.** The press controller runs at display refresh.
2. **An un-latched boundary in a repeating tick.** The run timer ticks at 10Hz; the streak recomputes
   on every answer. `hasAlarmed`, `lastMilestone` and `hasPlayed` live on the immutable notifier state
   and reset only in `startRun()`.
3. **A `for` loop over affected widgets.** A Schulte tap changes two tiles — one haptic, not two.

## The gates

Settings (app.html screen 08) has four rows; three of them gate feedback, and all three off at once
is a supported configuration:

| Row | Gate | Effect |
|---|---|---|
| Haptics | `hapticsEnabledProvider` | `FeedbackService.fire` returns before touching the gateway |
| Sound | `soundEnabledProvider` | the sound slot is skipped; the haptic still fires |
| Reduce motion | folded into `MediaQuery.disableAnimations` at the root | durations → `Duration.zero`; **haptics are unaffected** |

Reduce motion must never suppress a haptic. It is the opposite: haptics and sound are what remains
when motion is gone, and a moment whose only channel was motion has already failed rule 8. The most
common form of this bug is an early `return` for reduce-motion placed *above* the `fire()` call —
`examples/feedback_moments.dart` shows the correct order for `personalBest`.

The gate lives in `FeedbackService`, once. A call site that checks `if (settings.hapticsEnabled)`
before calling `fire()` is a bug even when it is correct today — it is the second gate, and the second
gate is the one that gets forgotten.

## Platform caveats

- **Simulators and emulators reproduce none of this.** Verifying "exactly once" is a physical-device
  task, on the checklist `design-review-workflow` owns. A burst is inaudible in code review and
  unmistakable in the hand.
- **Android maps `selectionClick` to `HapticFeedbackConstants.CLICK`** and honours the system "Touch
  feedback" setting — a device with it off feels nothing regardless of the app toggle. That is correct
  behaviour; do not route around it with a `vibration` package.
- **iOS suppresses haptics while the Taptic Engine is asleep**, including the first moments after the
  app foregrounds. `runStart` sits comfortably past that; do not move a haptic onto the first frame of
  a route and expect it to land.
- **`HapticFeedback.*` returns a `Future`.** Ignoring it trips `discarded_futures`. `HapticGateway`
  is declared `Future<void>` and `FeedbackService` uses `unawaited(... .catchError(...))` — a haptic
  that fails on an unsupported device must never surface as an error to the player. The discipline
  around that is `async-safety`'s.
