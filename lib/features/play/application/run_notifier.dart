import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindforge/core/calendar_day.dart';
import 'package:mindforge/core/result.dart';
import 'package:mindforge/core/run_draft.dart';
import 'package:mindforge/core/run_scope.dart';
import 'package:mindforge/data/data_providers.dart';
import 'package:mindforge/features/play/application/run_ticker.dart';
import 'package:mindforge/features/play/application/save_run.dart';
import 'package:mindforge/features/play/domain/board_snapshot.dart';
import 'package:mindforge/features/play/domain/run_config.dart';
import 'package:mindforge/features/play/domain/run_outcome.dart';
import 'package:mindforge/features/play/domain/run_phase.dart';
import 'package:mindforge/features/play/domain/run_state.dart';
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

  RunTicker? _ticker;

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

    final observer = _RunLifecycleObserver(onBackground: _onBackground)
      ..attach();

    ref.onDispose(() {
      ticker.dispose();
      observer.detach();
    });

    return RunState.idle(
      config: config,
      snapshot: definition.snapshotOf(ref, config),
      runLimit: definition.runLimitFor(config.difficulty),
    );
  }

  /// Begins the countdown.
  void start() {
    if (!state.phase.canTransitionTo(RunPhase.countdown)) return;

    state = state.transitionTo(RunPhase.countdown);
  }

  /// The countdown finished; the board goes live.
  void beginPlaying() {
    if (!state.phase.canTransitionTo(RunPhase.playing)) return;

    state = state.transitionTo(RunPhase.playing);
    _ticker?.start();
  }

  /// The player backed out during the countdown.
  ///
  /// Writes nothing: a run that never started is not a run.
  void abandon() {
    if (!state.phase.canTransitionTo(RunPhase.idle)) return;

    state = state.transitionTo(RunPhase.idle);
  }

  /// The player paused. The clock stops rather than slowing.
  void pause() {
    if (!state.phase.canTransitionTo(RunPhase.paused)) return;

    _ticker?.stop();
    state = state.transitionTo(RunPhase.paused);
  }

  /// The player resumed — through a fresh countdown, never straight back in.
  void keepPlaying() {
    if (!state.phase.canTransitionTo(RunPhase.countdown)) return;

    state = state.transitionTo(RunPhase.countdown);
  }

  /// The player left a paused run. Writes nothing.
  void leaveRun() {
    if (!state.phase.canTransitionTo(RunPhase.over)) return;

    _ticker?.stop();
    state = state.toOver(snapshot: state.snapshot);
  }

  /// The board reported. Ends the run if the report carries an outcome.
  void onSnapshot(BoardSnapshot snapshot) {
    state = state.copyWith(snapshot: snapshot);

    final outcome = snapshot.outcome;
    if (outcome == null) return;
    if (state.phase != RunPhase.playing) return;

    unawaited(_finish(outcome));
  }

  void _onTick() {
    final ticker = _ticker;
    if (ticker == null) return;
    if (state.phase != RunPhase.playing) return;

    var next = state.copyWith(elapsed: ticker.elapsed);

    // A latch, because the boundary is true on every frame after it happens:
    // the clock is still under five seconds a second later, and firing the
    // alarm at 10 Hz for the last fifty ticks is a rattle rather than a signal.
    if (!next.hasFiredTimerAlarm &&
        next.isTimerAlarmAt(SunburstMotion.sunburstPop.alarmThreshold)) {
      next = next.copyWith(hasFiredTimerAlarm: true);
    }

    state = next;

    final remaining = next.remaining;
    if (remaining == Duration.zero) {
      unawaited(_finish(next.snapshot.outcome ?? const RunOutcome.abandoned()));
    }
  }

  void _onBackground() {
    if (state.phase != RunPhase.playing) return;

    pause();
  }

  /// Writes the run, THEN moves to over.
  ///
  /// The ordering is the whole point. A phase change first would let the
  /// results screen celebrate a personal best whose row never landed, and the
  /// player would find it gone on the next launch.
  Future<void> _finish(RunOutcome outcome) async {
    _ticker?.stop();

    final clock = ref.read(clockProvider);
    final now = clock.now();

    // CANONICAL, NOT RENDERED. playedOnDay is a Gregorian civil date over the
    // injected clock — never a Jalali or Hijri projection — durationMs is whole
    // milliseconds, metricValue is an integer, and clientRunKey is ASCII.
    // Nothing here reads a locale, which is what makes a run's stored bytes
    // identical in all four. This is the line a "show Persian dates in the
    // export" request would break.
    final draft = RunDraft(
      gameId: RunScope.of(state.config.gameId, state.config.difficulty).gameId,
      difficultyId: state.config.difficulty.name,
      clientRunKey: ref.read(idGeneratorProvider).newId(),
      startedAtUtcMs: now.toUtc().millisecondsSinceEpoch,
      playedOnDay: CalendarDay.fromLocal(now),
      durationMs: _ticker?.elapsed.inMilliseconds ?? 0,
      format: ref.read(gameDefinitionProvider(state.config.gameId)).scoreFormat,
      metricValue: switch (outcome) {
        RunCompleted(:final scoreValue) => scoreValue,
        RunAbandoned() => 0,
      },
      correctCount: 0,
      wrongCount: 0,
      longestCombo: 0,
      totalReactionMs: 0,
    );

    final result = await ref.read(saveRunProvider)(draft);

    // The run can be disposed while the write is in flight — a player who
    // leaves the screen the moment the board ends.
    if (!ref.mounted) return;

    state = switch (result) {
      // The flag comes from the COMMITTED row: E02 computes it inside the same
      // transaction as the insert. A post-commit read of watchPersonalBest
      // would race this notifier's own write.
      Ok(:final value) => state.toOver(
        snapshot: state.snapshot,
        isPersonalBest: value.isPersonalBest,
      ),
      // A failed save still reaches over, carrying the failure. The player
      // finished the run; hiding that because a row did not land is worse than
      // telling them it did not.
      Err(:final failure) => state.toOver(
        snapshot: state.snapshot,
        saveFailure: failure,
      ),
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
/// player straight into a live Blitz board is how a run is lost to the OS.
class _RunLifecycleObserver with WidgetsBindingObserver {
  _RunLifecycleObserver({required this.onBackground});

  final VoidCallback onBackground;

  void attach() => WidgetsBinding.instance.addObserver(this);

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
