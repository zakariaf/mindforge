import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/core/board_snapshot.dart';
import 'package:mindforge/core/difficulty.dart';
import 'package:mindforge/core/game_id.dart';
import 'package:mindforge/core/hud_tone.dart';
import 'package:mindforge/core/run_config.dart';
import 'package:mindforge/data/data_providers.dart';
import 'package:mindforge/games/false_light/application/light_board_notifier.dart';
import 'package:mindforge/games/false_light/domain/light_board_state.dart';
import 'package:mindforge/games/false_light/domain/light_difficulty_profile.dart';
import 'package:mindforge/games/false_light/domain/light_scoring.dart';
import 'package:mindforge/games/false_light/domain/tile_depth.dart';
import 'package:mindforge/shared/feedback/feedback_service.dart';
import 'package:mindforge/shared/feedback/moment.dart';

import '../../../support/fake_feedback_service.dart';

/// The board's one owner: the ladder, the score, the tile states and the
/// latches. Driven headlessly with a `ProviderContainer`.
void main() {
  final config = RunConfig(
    gameId: GameId('false_light'),
    difficulty: Difficulty.classic,
    seed: 42,
  );

  late FakeFeedbackService feedback;

  ProviderContainer containerWith({Clock? clock}) {
    feedback = FakeFeedbackService();

    final container = ProviderContainer(
      overrides: [
        feedbackServiceProvider.overrideWithValue(feedback),
        if (clock != null) clockProvider.overrideWithValue(clock),
      ],
    );
    addTearDown(container.dispose);

    return container;
  }

  LightBoardState stateOf(ProviderContainer c) =>
      c.read(lightBoardNotifierProvider(config));

  LightBoardNotifier notifierOf(ProviderContainer c) =>
      c.read(lightBoardNotifierProvider(config).notifier);

  BoardSnapshot snapshotOf(ProviderContainer c) =>
      c.read(lightBoardSnapshotProvider(config));

  /// The index of the first tile of [depth] not yet swept.
  int firstOfDepth(ProviderContainer c, TileDepth depth) {
    final state = stateOf(c);
    final field = state.current!;

    for (var i = 0; i < field.tiles.length; i++) {
      if (field.tiles[i] == depth &&
          state.tileStates[i] != LightTileState.swept) {
        return i;
      }
    }

    throw StateError('no unswept $depth tile');
  }

  /// Sweeps every pressed tile of the current field.
  void clearField(ProviderContainer c) {
    final field = stateOf(c).current!;
    final notifier = notifierOf(c);

    for (var i = 0; i < field.tiles.length; i++) {
      if (field.tiles[i] != TileDepth.pressed) continue;

      notifier.submit(i);
    }
  }

  group('build', () {
    test('deals the whole ladder and opens on field zero', () {
      final state = stateOf(containerWith());

      expect(state.index, 0);
      expect(
        state.fields,
        hasLength(profileFor(Difficulty.classic).fieldCount),
      );
      expect(state.tileStates, everyElement(LightTileState.idle));
      expect(state.tileStates, hasLength(state.current!.tileCount));
    });
  });

  group('a sweep', () {
    test('marks the tile swept, scores, and fires tileFound', () {
      final c = containerWith();

      notifierOf(c).submit(firstOfDepth(c, TileDepth.pressed));

      expect(stateOf(c).score.points, kFalseLightBasePoints);
      expect(stateOf(c).score.correct, 1);
      expect(feedback.fired, contains(Moment.tileFound));
    });

    test('and a swept tile stays swept while the field is worked', () {
      // The field's end condition is every pressed tile swept. A tile state
      // reset on each tap would make that unreachable.
      final c = containerWith();
      final first = firstOfDepth(c, TileDepth.pressed);

      notifierOf(c).submit(first);
      final second = firstOfDepth(c, TileDepth.pressed);
      notifierOf(c).submit(second);

      expect(stateOf(c).tileStates[first], LightTileState.swept);
      expect(stateOf(c).tileStates[second], LightTileState.swept);
    });

    test('and sweeping the same tile twice is a no-op', () {
      // Without the guard a player could farm one tile, and correctCount would
      // climb past the number of tiles that were ever pressed.
      final c = containerWith();
      final index = firstOfDepth(c, TileDepth.pressed);

      notifierOf(c).submit(index);
      final before = stateOf(c);
      notifierOf(c).submit(index);

      expect(stateOf(c), before);
    });
  });

  group('a raised tap', () {
    test('marks it rejected, breaks the streak and fires answerWrong', () {
      final c = containerWith();

      notifierOf(c).submit(firstOfDepth(c, TileDepth.pressed));
      expect(stateOf(c).score.streak, 1);

      final raised = firstOfDepth(c, TileDepth.raised);
      notifierOf(c).submit(raised);

      expect(stateOf(c).tileStates[raised], LightTileState.rejected);
      expect(stateOf(c).score.streak, 0);
      expect(stateOf(c).score.wrong, 1);
      expect(feedback.fired, contains(Moment.answerWrong));
    });

    test('never subtracts, because a negative total cannot be saved', () {
      // runs carries CHECK (metric_value >= 0). A negative score is a row the
      // database refuses, a repository that returns ConstraintViolated, and --
      // because nothing reads saveFailure -- an ordinary results screen for a
      // run that left no trace.
      final c = containerWith();

      for (var i = 0; i < 5; i++) {
        notifierOf(c).submit(firstOfDepth(c, TileDepth.raised));
      }

      expect(stateOf(c).score.points, 0);
      expect(snapshotOf(c).score, isNonNegative);
    });

    test('gives every wrong tap a new identity, so two taps shake twice', () {
      final c = containerWith();
      final raised = firstOfDepth(c, TileDepth.raised);

      notifierOf(c).submit(raised);
      final first = stateOf(c).wrongTapId;
      notifierOf(c).submit(raised);

      expect(stateOf(c).wrongTapId, greaterThan(first));
    });

    test('and does not finish a field', () {
      final c = containerWith();

      notifierOf(c).submit(firstOfDepth(c, TileDepth.raised));

      expect(stateOf(c).index, 0);
    });
  });

  group('the field ladder', () {
    test('clearing every pressed tile advances to the next field', () {
      final c = containerWith();

      clearField(c);

      expect(stateOf(c).index, 1);
      expect(stateOf(c).tileStates, everyElement(LightTileState.idle));
    });

    test('and clearing the last field locks the board and ends the run', () {
      final c = containerWith();
      final fields = profileFor(Difficulty.classic).fieldCount;

      expect(snapshotOf(c).outcome, isNull);

      for (var i = 0; i < fields; i++) {
        clearField(c);
      }

      expect(stateOf(c).isFinished, isTrue);
      expect(stateOf(c).tileStates, everyElement(LightTileState.locked));
      expect(snapshotOf(c).outcome, isNotNull);
    });

    test('and a tap after the last field changes nothing', () {
      final c = containerWith();

      for (var i = 0; i < profileFor(Difficulty.classic).fieldCount; i++) {
        clearField(c);
      }

      final before = stateOf(c);
      notifierOf(c).submit(0);

      expect(stateOf(c), before);
    });
  });

  group('the snapshot the shell reads', () {
    test('declares TIME as the run clock and never fills it', () {
      final hud = snapshotOf(containerWith()).hud;

      expect(hud.leading.source, HudSource.runClock);
      expect(hud.leading.canonicalValue, 0);
    });

    test('lights the streak pill only once the multiplier is paying', () {
      final c = containerWith();

      expect(snapshotOf(c).hud.trailing?.tone, HudTone.neutral);

      for (var i = 0; i < kFalseLightStreakStep; i++) {
        notifierOf(c).submit(firstOfDepth(c, TileDepth.pressed));
      }

      expect(snapshotOf(c).hud.trailing?.tone, HudTone.highlight);
    });

    test(
      'keeps longestCombo at or below correctCount, which runs requires',
      () {
        // CHECK (longest_combo <= correct_count). A state that broke it would
        // produce a run the repository silently refuses to save.
        final c = containerWith();

        for (var i = 0; i < 4; i++) {
          notifierOf(c).submit(firstOfDepth(c, TileDepth.pressed));
          notifierOf(c).submit(firstOfDepth(c, TileDepth.raised));
        }

        final snapshot = snapshotOf(c);

        expect(snapshot.longestCombo, lessThanOrEqualTo(snapshot.correctCount));
      },
    );
  });

  group('the field clock', () {
    test('banks time per FIELD, not per tap', () {
      // A sweep is one sustained search. An average per tap would measure
      // nothing a player recognises.
      var now = DateTime.utc(2026);
      final c = containerWith(clock: Clock(() => now));

      notifierOf(c).markShown();
      now = now.add(const Duration(seconds: 4));
      clearField(c);

      expect(notifierOf(c).fieldsCleared, 1);
      expect(notifierOf(c).averageFieldMs, 4000);
    });

    test('and floors a clock that ran backwards at zero', () {
      var now = DateTime.utc(2026);
      final c = containerWith(clock: Clock(() => now));

      notifierOf(c).markShown();
      now = now.subtract(const Duration(seconds: 5));
      clearField(c);

      expect(notifierOf(c).averageFieldMs, 0);
    });
  });
}
