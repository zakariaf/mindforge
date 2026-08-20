import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindforge/core/board_snapshot.dart';
import 'package:mindforge/core/calendar_day.dart';
import 'package:mindforge/core/result.dart';
import 'package:mindforge/core/result_stat.dart';
import 'package:mindforge/core/run_config.dart';
import 'package:mindforge/core/run_draft.dart';
import 'package:mindforge/core/run_outcome.dart';
import 'package:mindforge/core/run_scope.dart';
import 'package:mindforge/data/data_providers.dart';
import 'package:mindforge/features/play/application/run_ticker.dart';

import 'package:mindforge/features/play/domain/run_phase.dart';
import 'package:mindforge/features/play/domain/run_state.dart';
import 'package:mindforge/games/game_definition.dart';
import 'package:mindforge/games/game_registry.dart';
import 'package:mindforge/theme/sunburst_motion.dart';

/// Owns the run: every phase change, the one clock, and the one write.
///
/// **Nothing else may move a phase.** Boards report outcomes into a snapshot
/// and the shell reads state; both go through here, and every assignment goes
/// through `RunState.transitionTo`, which is guarded by the machine.
///
/// **It formats nothing.** `scoreFormatterProvider` is not read in this file
/// and neither is `AppLocalizations`. The score is an integer all the way
/// through and E08 renders it, which is why switching language mid-run leaves
/// the `RunState` byte-identical.
class RunNotifier extends Notifier<RunState> {
  /// Creates the notifier for [config].
  ///
  /// Riverpod 3 hands a family's argument to the CONSTRUCTOR — `build()` takes
  /// none — so the config is a field rather than a parameter.
  RunNotifier(this.config);

  /// What is being played.
  final RunConfig config;

  /// Whether a save is in flight.
  ///
  /// **The phase does not leave `playing` until AFTER the write returns**, by
  /// design — that ordering is the point of `_finish`. Which means the phase
  /// cannot be the guard against a second finish: any board emission carrying
  /// an outcome during the await runs `_finish` again. Measured: two rows
  /// committed with different clientRunKeys, both counting toward stats and
  /// both able to claim a personal best, and then
  /// `over -> over is not a legal run transition` from the second `toOver`.
  ///
  /// A board keeps its terminal snapshot in its own provider state, so any
  /// later emission — an end-of-round animation frame, a late tap — re-fires
  /// it. This is what stops that.
  bool _finishing = false;

  /// Non-nullable, and reassigned on every build.
  ///
  /// It was nullable, which bought six `?.` call sites where a missing clock
  /// SILENTLY no-ops: `pause()` would move the phase without stopping
  /// anything, and `durationMs: _ticker?.elapsed ?? 0` read as though a
  /// zero-duration run were a legitimate thing to persist. It is not a
  /// fallback anyone chose. `build()` always assigns before returning and no
  /// public method can run before `build()`, so `late` is the honest type: a
  /// genuine misuse throws instead of writing a zero.
  late RunTicker _ticker;

  @override
  RunState build() {
    final definition = ref.watch(gameDefinitionProvider(config.gameId));
    const motion = SunburstMotion.sunburstPop;

    final ticker = RunTicker(
      clock: ref.watch(clockProvider),
      onTick: _onTick,
      pulse: motion.timerPulse,
    );
    _ticker = ticker;

    // A plain WidgetsBindingObserver, NOT AppLifecycleListener. That class was
    // tried and reverted: it models TRANSITIONS and synthesizes intermediate
    // states, so it only pauses when the binding walks a sequence it
    // recognises. The rule here is stateless — if the run is live and the app
    // is not foreground, stop the clock — and expressing it through a
    // transition machine makes the tests assert Flutter's synthesis rather
    // than the rule. Measured: reaching `hidden` did not pause.
    final observer = _PauseOnBackground(onBackground: pause)..attach();

    ref.onDispose(() {
      ticker.dispose();
      observer.detach();
    });

    return RunState.idle(
      config: config,
      // bindBoard SUBSCRIBES and returns the current value. Watching it here
      // instead would re-run this build on every board update and hand back a
      // fresh idle state, ending the run on the player's first tap.
      snapshot: definition.bindBoard(ref, config, onSnapshot),
      runLimitMs: definition.runLimitMsFor(config.difficulty),
    );
  }

  /// Moves to [next] if the machine allows it, and reports whether it did.
  ///
  /// One guard, not six copies of it. Every intent below asked the same
  /// question and then called `transitionTo`, which asserts the same
  /// predicate — so the assert could never fire from production and the
  /// condition was written twice per method.
  bool _moveTo(RunPhase next) {
    if (!state.phase.canTransitionTo(next)) return false;

    state = state.transitionTo(next);

    return true;
  }

  /// Begins the countdown.
  void start() => _moveTo(RunPhase.countdown);

  /// The countdown finished; the board goes live.
  void beginPlaying() {
    if (_moveTo(RunPhase.playing)) _ticker.start();
  }

  /// The player backed out. Writes nothing, and RESETS.
  ///
  /// Not just a phase change. `playing -> paused -> countdown -> idle` is a
  /// legal path, so a run can reach `idle` after thirty seconds of play — and
  /// relabelling it left `elapsed`, the alarm latch, the board's snapshot and
  /// the ticker's banked time all intact. Measured: abandoning a 30-second run
  /// and starting again reported `elapsed 0:00:31` one second in, with 29
  /// seconds left on a 60-second limit.
  ///
  /// A run that never started is not a run, and neither is one that was
  /// abandoned — so both leave nothing behind.
  void abandon() {
    if (!state.phase.canTransitionTo(RunPhase.idle)) return;

    _ticker.reset();

    // A fresh idle state rather than a phase change: RunState.idle IS the
    // starting state, so rebuilding it clears elapsed, the alarm latch and the
    // best/failure flags in one move. Legality is checked above, which is the
    // same guard transitionTo asserts.
    state = RunState.idle(
      config: state.config,
      snapshot: state.snapshot,
      runLimitMs: state.runLimitMs,
    );
  }

  /// The player paused. The clock stops rather than slowing.
  void pause() {
    if (_moveTo(RunPhase.paused)) _ticker.stop();
  }

  /// The player resumed — through a fresh countdown, never straight back in.
  ///
  /// The same edge as [start], deliberately: resuming re-enters the 3-2-1
  /// rather than dropping the player into a live board. Two names because they
  /// are two intents, one body because they are one transition.
  void keepPlaying() => start();

  /// The player left a paused run. Writes nothing.
  void leaveRun() {
    if (!state.phase.canTransitionTo(RunPhase.over)) return;

    _ticker.stop();
    state = state.toOver();
  }

  /// The board reported. Ends the run if the report carries an outcome.
  void onSnapshot(BoardSnapshot snapshot) {
    // A late snapshot must not mutate the results screen's figures after the
    // row is written, so the phase is checked BEFORE the state is updated
    // rather than only before finishing.
    if (state.phase != RunPhase.playing || _finishing) return;

    state = state.copyWith(snapshot: snapshot);

    final outcome = snapshot.outcome;
    if (outcome == null) return;

    unawaited(_finish(outcome));
  }

  void _onTick() {
    if (state.phase != RunPhase.playing) return;

    var next = state.copyWith(elapsed: _ticker.elapsed);

    // A latch, because the boundary is true on every frame after it happens:
    // the clock is still under five seconds a second later, and firing the
    // alarm at 10 Hz for the last fifty ticks is a rattle rather than a signal.
    if (!next.hasFiredTimerAlarm &&
        next.isTimerAlarmAt(SunburstMotion.sunburstPop.alarmThreshold)) {
      next = next.copyWith(hasFiredTimerAlarm: true);
    }

    state = next;

    // THE CLOCK RUNNING OUT IS A COMPLETED RUN, not an abandoned one. For
    // Stroop Rush Blitz the timer IS the normal ending — the board never gets
    // to declare an outcome — and this branch used to persist every one of
    // those as abandoned with a score of zero.
    if (next.remainingMs == 0) {
      unawaited(_finish(next.snapshot.outcome ?? _expiredOutcome()));
    }
  }

  /// What a run that ran out its clock counts as.
  ///
  /// A completed run whose figures come from the board's last snapshot. The
  /// three display stats are the game's own — a definition that wants
  /// meaningful ones supplies an outcome before the clock expires — so these
  /// are the neutral placeholders the results grid needs to have three cells.
  RunOutcome _expiredOutcome() => const RunOutcome.completed(
    first: ResultStat(
      labelKey: 'accuracyLabel',
      canonicalValue: 0,
      format: StatFormat.percent,
    ),
    second: ResultStat(
      labelKey: 'longestStreakLabel',
      canonicalValue: 0,
      format: StatFormat.count,
    ),
    third: ResultStat(
      labelKey: 'avgReactionLabel',
      canonicalValue: 0,
      format: StatFormat.duration,
    ),
  );

  /// Writes the run, THEN moves to over.
  ///
  /// The ordering is the whole point. A phase change first would let the
  /// results screen celebrate a personal best whose row never landed, and the
  /// player would find it gone on the next launch.
  Future<void> _finish(RunOutcome outcome) async {
    if (_finishing) return;
    _finishing = true;

    _ticker.stop();

    final now = ref.read(clockProvider).now();
    final definition = ref.read(gameDefinitionProvider(state.config.gameId));
    final elapsedMs = _ticker.elapsed.inMilliseconds;

    // CANONICAL, NOT RENDERED. playedOnDay is a Gregorian civil date over the
    // injected clock — never a Jalali or Hijri projection — durationMs is whole
    // milliseconds, metricValue is an integer, and clientRunKey is ASCII.
    // Nothing here reads a locale, which is what makes a run's stored bytes
    // identical in all four. This is the line a "show Persian dates in the
    // export" request would break.
    // One RunScope.of for BOTH halves of the pair it exists to produce. It was
    // used for the game id while the difficulty came from `.name` directly —
    // half a helper, which is how the two eventually spell the same key
    // differently.
    final scope = RunScope.of(state.config.gameId, state.config.difficulty);

    final draft = RunDraft(
      gameId: scope.gameId,
      difficultyId: scope.difficultyId!,
      clientRunKey: ref.read(idGeneratorProvider).newId(),
      startedAtUtcMs: now.toUtc().millisecondsSinceEpoch,
      playedOnDay: CalendarDay.fromLocal(now),
      durationMs: elapsedMs,
      format: definition.scoreFormat,
      // From the DECLARED source. Schulte Grid is scored by elapsed time and
      // cannot compute that itself — the clock belongs to the shell and the
      // fence keeps a board away from it — so the definition says where its
      // score comes from and this reads it rather than switching on the game.
      metricValue: switch (outcome) {
        RunCompleted() => switch (definition.scoreSource) {
          ScoreSource.board => state.snapshot.score,
          ScoreSource.runClock => elapsedMs,
        },
        // An abandoned run does not go on the leaderboard.
        RunAbandoned() => 0,
      },
      // From the SNAPSHOT, not the outcome. A timed run can end with the board
      // having declared nothing at all, and these still have to reach the row.
      correctCount: state.snapshot.correctCount,
      wrongCount: state.snapshot.wrongCount,
      longestCombo: state.snapshot.longestCombo,
      totalReactionMs: state.snapshot.totalReactionMs,
    );

    final result = await ref.read(saveRunProvider)(draft);

    // The run can be disposed while the write is in flight — a player who
    // leaves the screen the moment the board ends.
    if (!ref.mounted) return;

    state = switch (result) {
      // The flag comes from the COMMITTED row: E02 computes it inside the same
      // transaction as the insert. A post-commit read of watchPersonalBest
      // would race this notifier's own write.
      Ok(:final value) => state.toOver(isPersonalBest: value.isPersonalBest),
      // A failed save still reaches over, carrying the failure. The player
      // finished the run; hiding that because a row did not land is worse than
      // telling them it did not.
      Err(:final failure) => state.toOver(saveFailure: failure),
    };
  }
}

/// The run family.
// The lint wants the family's own type spelled out, and Riverpod 3 does not
// export a name for it.
// ignore: specify_nonobvious_property_types
final runNotifierProvider =
    NotifierProvider.family<RunNotifier, RunState, RunConfig>(RunNotifier.new);

/// Pauses a live run when the app leaves the foreground.
///
/// **It never un-pauses.** `resumed` is deliberately not handled: coming back
/// to the app is not the same as choosing to keep playing, and dropping a
/// player straight into a live Blitz board is how a run is lost to the OS
/// rather than to the game. `detached` is not handled either — there is nothing
/// left to pause, and writing a row on the way out is how a half-run is saved.
class _PauseOnBackground with WidgetsBindingObserver {
  _PauseOnBackground({required this.onBackground});

  /// Called for every state that is not the foreground.
  final VoidCallback onBackground;

  /// Starts listening.
  void attach() => WidgetsBinding.instance.addObserver(this);

  /// Stops listening.
  void detach() => WidgetsBinding.instance.removeObserver(this);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        onBackground();
      case AppLifecycleState.resumed:
      case AppLifecycleState.detached:
        break;
    }
  }
}
