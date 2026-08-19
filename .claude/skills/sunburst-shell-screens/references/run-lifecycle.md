# The run lifecycle

One machine, one owner. `RunNotifier` is the only thing in the app that assigns a `RunPhase`, and the
phase is the only thing that decides which screen is on screen. A game reports facts; it never
transitions.

```text
                 ┌──────────── abandon()  (✕ on countdown) ───────────┐
                 │                                                    │
                 ▼            start()              3 ticks            │
            ┌────────┐  ────────────────▶  ┌───────────┐  ────────▶  ┌─────────┐
            │  idle  │                     │ countdown │             │ playing │
            └────────┘                     └───────────┘             └─────────┘
            GameDetail                      Countdown         PlayScaffold + board
                                                 ▲                  │      │
                                    keepPlaying() │          pause() │      │ snapshot.outcome
                                                  │       lifecycle  ▼      │  != null, or
                                            ┌──────────┐             │      │  remaining == 0
                                            │  paused  │◀────────────┘      │
                                            └──────────┘                    │
                                     PlayScaffold + PauseSheet              │
                                                  │  leaveRun()             │
                                                  ▼                         ▼
                                                    ┌──────────────────────────┐
                                                    │           over           │
                                                    └──────────────────────────┘
                                                                Results
```

`over` is terminal. "Play again" builds a **new** `RunConfig` (new seed), which is a new family key,
which is a fresh `RunNotifier` — there is no `over → countdown` edge and no reset method.

## Transitions

| From → To | Trigger | Side effects, in order |
|---|---|---|
| `idle → countdown` | Play tapped on `GameDetailScreen` | seed drawn; board notifier constructed (family key = config); route replaced with `/play/:gameId` |
| `countdown → playing` | third tick elapses | clock started from the injected `Clock`; board told to begin via its notifier's `start()` |
| `countdown → idle` | ✕ tapped | notifiers disposed; route popped; nothing written |
| `playing → paused` | pause tapped, **or** `AppLifecycleState.inactive`/`.paused`/`.hidden` | clock stopped at the current `elapsed`; `PauseSheet` shown |
| `paused → countdown` | "Keep playing", or the sheet's barrier/back | sheet dismissed; the 3-2-1 replays; the clock stays stopped until it ends |
| `paused → over` | "Leave run" | `RunOutcome.abandoned()`; **nothing persisted**; streak untouched |
| `playing → over` | `snapshot.outcome != null`, **or** `remaining` hits zero | run persisted through the repository, personal-best computed, THEN phase set; route replaced with `/results` |

The persist-then-transition order in the last row is the reason the shell owns this edge: the results
screen reads `isPersonalBest` off the committed row, so it can never celebrate a run that failed to save.

```dart
// lib/features/play/application/run_notifier.dart (abridged)
// runNotifierProvider = NotifierProvider.family<RunNotifier, RunState, RunConfig>(…)
final class RunNotifier extends FamilyNotifier<RunState, RunConfig> {
  final _ticker = RunTicker();                           // wraps the injected Clock

  @override
  RunState build(RunConfig config) {
    final definition = ref.watch(gameDefinitionProvider(config.gameId));
    ref.listen(definition.snapshotOf(config), _onSnapshot);
    ref.onDispose(_ticker.dispose);
    return RunState.idle(config);
  }

  void _onSnapshot(BoardSnapshot? previous, BoardSnapshot next) {
    final outcome = next.outcome;
    // WRONG: `state = state.toOver(outcome)` here, then saving in the background —
    // the personal-best badge is on screen before the row exists, and a failed
    // write leaves a celebrated run that Stats has never heard of.
    if (outcome != null && state.phase == RunPhase.playing) unawaited(_finish(outcome));
  }

  // RIGHT — commit, then transition. One await, one guard, one typed failure.
  Future<void> _finish(RunOutcome outcome) async {
    _ticker.stop();
    final result = await ref.read(runRepositoryProvider).saveRun(
          config: state.config, outcome: outcome, elapsed: _ticker.elapsed,
        );
    if (!ref.mounted) return;                            // async-safety
    state = switch (result) {
      Ok(:final value) => state.toOver(outcome, isPersonalBest: value.isPersonalBest),
      Err(:final failure) => state.toOver(outcome, saveFailure: failure),
    };
  }
}
```

`unawaited(_finish(...))` is the one fire-and-forget in the shell and it is honest: `_finish` catches
nothing, because `saveRun` returns a `Result` rather than throwing (`error-handling-typed-results`).

An abandoned run skips `saveRun` entirely — there is no "partial run" row, so Stats cannot be polluted
by a pause-and-quit.

## Background and resume

`RunNotifier` registers a `WidgetsBindingObserver` (`app-startup-and-bootstrap` owns the app-level one;
this is a run-scoped observer disposed with the notifier).

- `inactive` / `paused` / `hidden` while `playing` → `paused`, clock stopped at that instant. Never
  "keep running in the background": a notification shade pulled down during a Blitz run must not cost
  the player their score.
- `resumed` → **stay** `paused`. The sheet is still up. The player taps "Keep playing" and gets the
  countdown back. `DERIVED` — app.html shows the countdown only at run start; replaying it on resume is
  this skill's decision, because a cold thumb on an already-running reaction clock is a lost run.
- `detached` → nothing. The run dies with the process and was never written, which is the honest
  outcome for an offline app with no in-flight save.
- A phone call, a screenshot, a system dialog, and a swipe to the app switcher all arrive as `inactive`
  and are therefore all the same event. This is deliberate: there is no allow-list of "harmless"
  interruptions.

## Back-button and gesture interception

`PopScope` on the play route (`navigation-and-routing` owns the mechanics):

| Phase | `canPop` | `onPopInvokedWithResult` |
|---|---|---|
| `countdown` | `false` | `abandon()` — same as ✕ |
| `playing` | `false` | `pause()` — back never leaves a live run silently |
| `paused` | `false` | `keepPlaying()` — back dismisses the sheet, it does not leave the run |
| `over` | `true` | route replaced already; back goes Home |

A game may not add its own `PopScope`; on Android a nested one wins and the run leaks.

## Which phase renders what, and what it announces

| Phase | Screen | Focus on entry | Announced |
|---|---|---|---|
| `idle` | `GameDetailScreen` | the hero h1 | screen title |
| `countdown` | `CountdownScreen` | "Get ready" h1 | each numeral, once ("3", "2", "1") |
| `playing` | `PlayScaffoldScreen` | the board's first target | nothing per tick — the HUD is **not** a live region |
| `paused` | `PauseSheet` | "Leave the run?" h1 | the sheet title and body |
| `over` | `ResultsScreen` | "Nice run!" h1 | one sentence: `"Run over. Final score 1,240. New personal best."` |

The HUD announces only at threshold crossings — 10s and 5s remaining, and each personal-best
overtake — via `SemanticsService.announce`, not a live region. `DERIVED`: system.html specifies the
alarm *tone* at under five seconds; which values are spoken is this skill's decision.
`sunburst-motion-and-haptics` owns the paired haptic and the visual alarm state.

## Testing the machine

- The whole machine is testable without a widget: `ProviderContainer.test`, a `Clock.fixed`, and a fake
  `BoardSnapshot` stream. Every row of the transition table is one test.
- `over` is terminal: assert that no method on `RunNotifier` produces an edge out of it.
- The lifecycle rows are tested by pushing `AppLifecycleState` values through the observer, not by
  backgrounding a real app.
- Assert the persist-before-transition order by failing `saveRun` and checking that the results state
  carries `saveFailure` and no personal-best badge.
