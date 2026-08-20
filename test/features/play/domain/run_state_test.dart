import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/core/difficulty.dart';
import 'package:mindforge/core/game_id.dart';
import 'package:mindforge/data/data_failure.dart';
import 'package:mindforge/features/play/domain/board_snapshot.dart';
import 'package:mindforge/features/play/domain/result_stat.dart';
import 'package:mindforge/features/play/domain/run_config.dart';
import 'package:mindforge/features/play/domain/run_phase.dart';
import 'package:mindforge/features/play/domain/run_state.dart';

import '../../../policy/support/source_text.dart';

void main() {
  const slot = HudSlot(
    labelKey: 'hudScore',
    canonicalValue: 0,
    format: StatFormat.points,
  );
  const snapshot = BoardSnapshot(
    hud: GameHud(leading: slot, middle: slot),
  );

  RunState idleRun({Duration? runLimit}) => RunState.idle(
    config: RunConfig(
      gameId: GameId('fixture_game'),
      difficulty: Difficulty.classic,
      seed: 1,
    ),
    snapshot: snapshot,
    runLimit: runLimit,
  );

  group('transitions', () {
    test('a legal one returns a new state and leaves the old one alone', () {
      final before = idleRun();
      final after = before.transitionTo(RunPhase.countdown);

      expect(after.phase, RunPhase.countdown);
      expect(before.phase, RunPhase.idle);
      expect(identical(before, after), isFalse);
    });

    test('and an illegal one trips in debug, at the attempt', () {
      // Guarded by the machine rather than by the caller's memory.
      expect(
        () => idleRun().transitionTo(RunPhase.playing),
        throwsAssertionError,
      );
    });

    test('toOver carries the best flag and the save failure together', () {
      // Set on this edge and nowhere else, so the state that says "new best"
      // is the same state that says the row was written. Celebrating a best
      // that failed to save is what the ordering exists to prevent.
      final over = idleRun()
          .transitionTo(RunPhase.countdown)
          .transitionTo(RunPhase.playing)
          .toOver(snapshot: snapshot, isPersonalBest: true);

      expect(over.phase, RunPhase.over);
      expect(over.isPersonalBest, isTrue);
      expect(over.saveFailure, isNull);
    });
  });

  group('remaining', () {
    test('is null for an untimed run', () {
      // Which is what definition.runLimitFor returns for a game that declares
      // no limit.
      expect(idleRun().remaining, isNull);
      expect(idleRun().isTimerAlarm, isFalse);
    });

    test('counts down from the limit', () {
      final state = idleRun(runLimit: const Duration(seconds: 60)).copyWith(
        elapsed: const Duration(seconds: 20),
      );

      expect(state.remaining, const Duration(seconds: 40));
    });

    test('and never goes below zero', () {
      // A frame landing after the deadline but before the notifier ends the run
      // would otherwise report a negative duration — a timer that appears to
      // GAIN a minute at the moment the round ends.
      final state = idleRun(runLimit: const Duration(seconds: 60)).copyWith(
        elapsed: const Duration(seconds: 61),
      );

      expect(state.remaining, Duration.zero);
    });
  });

  group('the five-second alarm', () {
    test('fires at or below five seconds, and not above', () {
      const limit = Duration(seconds: 60);

      const rows = <int, bool>{
        54999: false, // 5001 ms left
        55000: true, // exactly 5000 ms left
        55001: true,
        60000: true, // nothing left
        61000: true, // clamped at zero
      };

      for (final row in rows.entries) {
        final state = idleRun(runLimit: limit).copyWith(
          elapsed: Duration(milliseconds: row.key),
        );

        expect(
          state.isTimerAlarm,
          row.value,
          reason: '${state.remaining} left',
        );
      }
    });

    test('and an untimed run never alarms', () {
      expect(
        idleRun().copyWith(elapsed: const Duration(hours: 1)).isTimerAlarm,
        isFalse,
      );
    });
  });

  group('copyWith', () {
    test('can clear a save failure as well as set one', () {
      // "No failure" and "leave the failure alone" are different requests, and
      // a plain nullable parameter cannot tell them apart — which is how a
      // stale error survives a retry.
      final failed = idleRun().copyWith(
        saveFailure: const StoreUnavailable(),
      );

      expect(failed.saveFailure, isNotNull);
      expect(failed.copyWith(scoreValue: 5).saveFailure, isNotNull);
      expect(failed.copyWith(saveFailure: null).saveFailure, isNull);
    });
  });

  group('value equality', () {
    test('two identical states are equal, because listeners diff by value', () {
      expect(idleRun(), idleRun());
      expect(idleRun().hashCode, idleRun().hashCode);
      expect(idleRun(), isNot(idleRun().copyWith(scoreValue: 1)));
    });
  });

  group('it carries no formatted string', () {
    test('and declares no String field at all', () {
      // A `String scoreLabel` would go stale the instant the player changed
      // language mid-run, and would drag a locale into a value type that is a
      // family key's payload. The score is an int; E08 formats at render.
      final code = withoutDartComments(
        File('lib/features/play/domain/run_state.dart').readAsStringSync(),
      );

      expect(code, isNot(contains('final String')));
      expect(code, isNot(contains('scoreLabel')));
    });
  });
}
