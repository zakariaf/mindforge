import 'package:meta/meta.dart';
import 'package:mindforge/core/board_snapshot.dart';
import 'package:mindforge/core/run_config.dart';
import 'package:mindforge/core/run_outcome.dart';
import 'package:mindforge/data/data_failure.dart';
import 'package:mindforge/features/play/domain/run_phase.dart';

/// Everything the shell knows about the run in progress.
///
/// **It carries no formatted string, and there is a test that says so.** The
/// score is an `int`; E08 renders it through `scoreFormatterProvider` at the
/// moment it draws, which is also where the countdown's 3-2-1 and the HUD's
/// clock get their digits. A `String scoreLabel` here would go stale the
/// instant the player changed language mid-run, and it would drag a locale into
/// a value type that is a family key's payload.
///
/// Derived values are **getters, not fields**: `remaining`, `isTimerAlarm`,
/// `hud`, `progress` and `outcome` are all functions of what is stored, and
/// storing them is how two of them end up disagreeing.
@immutable
final class RunState {
  /// Creates a state.
  const RunState({
    required this.config,
    required this.phase,
    required this.elapsed,
    required this.snapshot,
    this.runLimitMs,
    this.isPersonalBest = false,
    this.saveFailure,
    this.hasFiredTimerAlarm = false,
  });

  /// The state a run starts in.
  const RunState.idle({
    required this.config,
    required this.snapshot,
    this.runLimitMs,
  }) : phase = RunPhase.idle,
       elapsed = Duration.zero,
       isPersonalBest = false,
       saveFailure = null,
       hasFiredTimerAlarm = false;

  /// What is being played.
  final RunConfig config;

  /// Where the run is.
  final RunPhase phase;

  /// How long the board has been live, excluding paused time.
  final Duration elapsed;

  /// The board's last report.
  final BoardSnapshot snapshot;

  /// How long the run may last in milliseconds, or `null` when it is untimed.
  ///
  /// Integer milliseconds, like every other span the engine stores or compares.
  final int? runLimitMs;

  /// Whether this run beat the stored personal best.
  ///
  /// Set only **after** the row is persisted. Celebrating a best that failed to
  /// save is the bug the persist-then-transition ordering exists to prevent.
  final bool isPersonalBest;

  /// Why the run failed to save, if it did.
  ///
  /// A `DataFailure` — E02's family — not a `RunFailure`. Mirroring it would
  /// give the results screen two ways to say the same thing.
  final DataFailure? saveFailure;

  /// Whether the five-second alarm has already fired.
  ///
  /// A latch, because the boundary condition is true on every frame after it
  /// happens: the clock is still under five seconds a second later.
  final bool hasFiredTimerAlarm;

  /// The three HUD values.
  GameHud get hud => snapshot.hud;

  /// How far through the board is, or `null` when it cannot say.
  double? get progress => snapshot.progress;

  /// The result, or `null` while the run is still going.
  RunOutcome? get outcome => snapshot.outcome;

  /// How many milliseconds are left, or `null` for an untimed run.
  ///
  /// **Clamped at zero.** A frame landing after the deadline but before the
  /// notifier ends the run would otherwise report a negative span, and a timer
  /// that appears to gain a minute at the moment the round ends is the bug
  /// `LocaleNumbers.clock` documents from the rendering side.
  int? get remainingMs {
    final limit = runLimitMs;
    if (limit == null) return null;

    final left = limit - elapsed.inMilliseconds;

    return left < 0 ? 0 : left;
  }

  /// Whether the run is inside its last [threshold].
  ///
  /// **The threshold is passed in, not held here.** It is a design value —
  /// `SunburstMotion.alarmThreshold` carries it — and this is a Flutter-free
  /// domain type that may not reach the theme. Taking it as an argument keeps
  /// the number in the one file that owns numbers, and keeps this type honest
  /// about what it knows: how long is left, and nothing about when that starts
  /// to matter.
  ///
  /// Untimed runs never alarm: there is nothing to run out of.
  bool isTimerAlarmAt(Duration threshold) {
    final left = remainingMs;

    return left != null && left <= threshold.inMilliseconds;
  }

  /// This state with [next] as its phase.
  ///
  /// Guarded by the machine rather than by the caller's memory: an illegal edge
  /// trips in debug at the moment it is attempted.
  RunState transitionTo(RunPhase next) {
    assert(
      phase.canTransitionTo(next),
      '${phase.name} -> ${next.name} is not a legal run transition',
    );

    return copyWith(phase: next);
  }

  /// This state with the given fields replaced.
  ///
  /// `saveFailure` takes a sentinel rather than a plain null, because "no
  /// failure" and "leave the failure alone" are different requests and a
  /// nullable parameter cannot tell them apart.
  RunState copyWith({
    RunPhase? phase,
    Duration? elapsed,
    BoardSnapshot? snapshot,
    bool? isPersonalBest,
    Object? saveFailure = _unset,
    bool? hasFiredTimerAlarm,
  }) => RunState(
    config: config,
    phase: phase ?? this.phase,
    elapsed: elapsed ?? this.elapsed,
    snapshot: snapshot ?? this.snapshot,
    runLimitMs: runLimitMs,
    isPersonalBest: isPersonalBest ?? this.isPersonalBest,
    saveFailure: identical(saveFailure, _unset)
        ? this.saveFailure
        : saveFailure as DataFailure?,
    hasFiredTimerAlarm: hasFiredTimerAlarm ?? this.hasFiredTimerAlarm,
  );

  /// The run ended.
  ///
  /// [isPersonalBest] and [saveFailure] are set on this edge and nowhere else,
  /// so the state that says "new best" is the same state that says the row was
  /// written.
  /// It takes no snapshot: every caller passed the one the receiver already
  /// held, which is a required parameter with exactly one legal argument.
  RunState toOver({bool isPersonalBest = false, DataFailure? saveFailure}) =>
      transitionTo(RunPhase.over).copyWith(
        isPersonalBest: isPersonalBest,
        saveFailure: saveFailure,
      );

  static const Object _unset = Object();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RunState &&
          other.config == config &&
          other.phase == phase &&
          other.elapsed == elapsed &&
          other.snapshot == snapshot &&
          other.runLimitMs == runLimitMs &&
          other.isPersonalBest == isPersonalBest &&
          other.saveFailure == saveFailure &&
          other.hasFiredTimerAlarm == hasFiredTimerAlarm;

  @override
  int get hashCode => Object.hash(
    config,
    phase,
    elapsed,
    snapshot,
    runLimitMs,
    isPersonalBest,
    saveFailure,
    hasFiredTimerAlarm,
  );
}
