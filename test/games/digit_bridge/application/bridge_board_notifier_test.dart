import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/core/board_snapshot.dart';
import 'package:mindforge/core/difficulty.dart';
import 'package:mindforge/core/game_id.dart';
import 'package:mindforge/core/hud_tone.dart';
import 'package:mindforge/core/run_config.dart';
import 'package:mindforge/data/data_providers.dart';
import 'package:mindforge/games/digit_bridge/application/bridge_board_notifier.dart';
import 'package:mindforge/games/digit_bridge/domain/bridge_board_state.dart';
import 'package:mindforge/games/digit_bridge/domain/bridge_difficulty_profile.dart';
import 'package:mindforge/games/digit_bridge/domain/bridge_scoring.dart';
import 'package:mindforge/shared/feedback/feedback_service.dart';
import 'package:mindforge/shared/feedback/moment.dart';

import '../../../support/fake_feedback_service.dart';

/// The board's one owner: the run, the score, the chip states and the latches.
///
/// Driven headlessly with a `ProviderContainer`. There is no widget here — the
/// board's behaviour is not a rendering question, and a test that pumped one
/// would be slower and would prove less.
void main() {
  final config = RunConfig(
    gameId: GameId('digit_bridge'),
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

  BridgeBoardState stateOf(ProviderContainer container) =>
      container.read(bridgeBoardNotifierProvider(config));

  BridgeBoardNotifier notifierOf(ProviderContainer container) =>
      container.read(bridgeBoardNotifierProvider(config).notifier);

  BoardSnapshot snapshotOf(ProviderContainer container) =>
      container.read(bridgeBoardSnapshotProvider(config));

  /// Answers the current round correctly, or deliberately wrongly.
  void answer(ProviderContainer container, {required bool correctly}) {
    final state = stateOf(container);
    final round = state.rounds[state.index];

    notifierOf(container).submit(
      correctly
          ? round.correctIndex
          : (round.correctIndex + 1) % round.candidates.length,
    );
  }

  group('build', () {
    test('seeds the run from the RunConfig and starts on round zero', () {
      final state = stateOf(containerWith());

      expect(state.index, 0);
      expect(
        state.rounds,
        hasLength(profileFor(Difficulty.classic).roundCount),
      );
      expect(state.score.points, 0);
      expect(state.chipStates, everyElement(BridgeChipState.idle));
      expect(state.chipStates, hasLength(kBridgeCandidateCount));
    });

    test('and a different seed deals a different run', () {
      final other = RunConfig(
        gameId: config.gameId,
        difficulty: config.difficulty,
        seed: 43,
      );
      final container = containerWith();

      expect(
        container.read(bridgeBoardNotifierProvider(other)).rounds.first,
        isNot(stateOf(container).rounds.first),
      );
    });
  });

  group('a correct answer', () {
    test('advances the round, adds points and fires answerCorrect', () {
      final container = containerWith();

      answer(container, correctly: true);

      expect(stateOf(container).index, 1);
      expect(stateOf(container).score.points, kBridgeBasePoints);
      expect(stateOf(container).score.correct, 1);
      expect(feedback.fired, contains(Moment.answerCorrect));
    });

    test('and the chips reset to idle for the next round', () {
      final container = containerWith();

      answer(container, correctly: true);

      expect(stateOf(container).chipStates, everyElement(BridgeChipState.idle));
    });
  });

  group('a wrong answer', () {
    test('holds the round, marks the chip rejected and fires answerWrong', () {
      final container = containerWith();
      final round = stateOf(container).rounds.first;
      final wrongIndex = (round.correctIndex + 1) % round.candidates.length;

      answer(container, correctly: false);

      expect(stateOf(container).index, 0, reason: 'the round is still asked');
      expect(
        stateOf(container).chipStates[wrongIndex],
        BridgeChipState.rejected,
      );
      expect(stateOf(container).score.points, 0);
      expect(stateOf(container).score.wrong, 1);
      expect(feedback.fired, contains(Moment.answerWrong));
    });

    test('never subtracts, because a negative total cannot be saved', () {
      // runs carries CHECK (metric_value >= 0). A negative score is a row the
      // database refuses, a repository that returns ConstraintViolated, and --
      // because nothing reads saveFailure -- an ordinary results screen for a
      // run that left no trace.
      final container = containerWith();

      for (var i = 0; i < 5; i++) {
        answer(container, correctly: false);
      }

      expect(stateOf(container).score.points, 0);
      expect(snapshotOf(container).score, isNonNegative);
    });

    test('gives every wrong tap a new identity, so two taps shake twice', () {
      final container = containerWith();

      answer(container, correctly: false);
      final first = stateOf(container).wrongTapId;
      answer(container, correctly: false);

      expect(stateOf(container).wrongTapId, greaterThan(first));
    });

    test('and resets the streak, which is the whole punishment', () {
      final container = containerWith();

      answer(container, correctly: true);
      answer(container, correctly: true);
      expect(stateOf(container).score.streak, 2);

      answer(container, correctly: false);

      expect(stateOf(container).score.streak, 0);
      expect(
        stateOf(container).score.bestStreak,
        2,
        reason: 'the best survives the streak that produced it being broken',
      );
    });
  });

  group('the run ends when the rounds do', () {
    test('the last answer locks the chips and publishes an outcome', () {
      final container = containerWith();
      final total = profileFor(Difficulty.classic).roundCount;

      expect(snapshotOf(container).outcome, isNull);

      for (var i = 0; i < total; i++) {
        answer(container, correctly: true);
      }

      expect(stateOf(container).isFinished, isTrue);
      expect(
        stateOf(container).chipStates,
        everyElement(BridgeChipState.locked),
      );
      expect(snapshotOf(container).outcome, isNotNull);
    });

    test('and a tap after the last round changes nothing', () {
      final container = containerWith();
      final total = profileFor(Difficulty.classic).roundCount;

      for (var i = 0; i < total; i++) {
        answer(container, correctly: true);
      }

      final before = stateOf(container);
      notifierOf(container).submit(0);

      expect(stateOf(container), before);
    });
  });

  group('the snapshot the shell reads', () {
    test('declares TIME as the run clock and never fills it', () {
      // The board does not know how long the run has been going and must not.
      final hud = snapshotOf(containerWith()).hud;

      expect(hud.leading.source, HudSource.runClock);
      expect(hud.leading.canonicalValue, 0);
      expect(hud.leading.labelKey, 'hudTime');
    });

    test('lights the streak pill only once the multiplier is paying', () {
      final container = containerWith();

      expect(snapshotOf(container).hud.trailing?.tone, HudTone.neutral);

      for (var i = 0; i < kBridgeStreakStep; i++) {
        answer(container, correctly: true);
      }

      expect(snapshotOf(container).hud.trailing?.tone, HudTone.highlight);
      expect(snapshotOf(container).hud.trailing?.canonicalValue, 2);
    });

    test('publishes canonical integers, never a rendered numeral', () {
      final container = containerWith();

      answer(container, correctly: true);

      final hud = snapshotOf(container).hud;

      expect(hud.middle.canonicalValue, isA<int>());
      expect(hud.middle.canonicalValue, kBridgeBasePoints);
    });

    test(
      'keeps longestCombo at or below correctCount, which runs requires',
      () {
        // CHECK (longest_combo <= correct_count). A state that broke it would
        // produce a run the repository silently refuses to save.
        final container = containerWith();

        for (var i = 0; i < 6; i++) {
          answer(container, correctly: true);
          answer(container, correctly: false);
        }

        final snapshot = snapshotOf(container);

        expect(snapshot.longestCombo, lessThanOrEqualTo(snapshot.correctCount));
      },
    );
  });

  group('the reaction clock', () {
    test('reads the injected Clock and banks only correct answers', () {
      var now = DateTime.utc(2026);
      final container = containerWith(clock: Clock(() => now));

      notifierOf(container).markShown();

      now = now.add(const Duration(milliseconds: 900));
      answer(container, correctly: false);
      expect(
        snapshotOf(container).totalReactionMs,
        0,
        reason: 'a false start is not a measurement of anything',
      );

      answer(container, correctly: true);
      expect(snapshotOf(container).totalReactionMs, 900);
    });

    test('and floors a clock that ran backwards at zero', () {
      var now = DateTime.utc(2026);
      final container = containerWith(clock: Clock(() => now));

      notifierOf(container).markShown();
      now = now.subtract(const Duration(seconds: 5));
      answer(container, correctly: true);

      expect(snapshotOf(container).totalReactionMs, 0);
    });
  });
}
