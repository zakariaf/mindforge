import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/core/app_settings.dart';
import 'package:mindforge/core/difficulty.dart';
import 'package:mindforge/core/game_id.dart';
import 'package:mindforge/core/run_config.dart';
import 'package:mindforge/core/supported_locale.dart';
import 'package:mindforge/data/data_providers.dart';
import 'package:mindforge/games/schulte_grid/application/schulte_board_notifier.dart';
import 'package:mindforge/games/schulte_grid/domain/schulte_board_state.dart';
import 'package:mindforge/games/schulte_grid/domain/schulte_rules.dart';
import 'package:mindforge/games/schulte_grid/domain/schulte_tile_state.dart';
import 'package:mindforge/shared/feedback/feedback_service.dart';
import 'package:mindforge/shared/feedback/moment.dart';

import '../../../support/fake_feedback_service.dart';

/// The board's one owner: the tile machine, the wrong latch and the tap gate.
///
/// Driven headlessly with a `ProviderContainer`. There is no widget here — the
/// board's behaviour is not a rendering question.
void main() {
  late FakeFeedbackService feedback;

  RunConfig configFor(Difficulty difficulty, {int seed = 42}) => RunConfig(
    gameId: GameId('schulte_grid'),
    difficulty: difficulty,
    seed: seed,
  );

  ProviderContainer containerWith({SupportedLocale? locale}) {
    feedback = FakeFeedbackService();

    final settings = locale == null
        ? const AppSettings.defaults()
        : const AppSettings.defaults().withLocaleOverride(locale);
    final container = ProviderContainer(
      overrides: [
        feedbackServiceProvider.overrideWithValue(feedback),
        initialAppSettingsProvider.overrideWithValue(settings),
        settingsProvider.overrideWith(
          (ref) => Stream<AppSettings>.value(settings),
        ),
      ],
    );

    addTearDown(container.dispose);

    return container;
  }

  SchulteBoardState stateOf(ProviderContainer c, RunConfig config) =>
      c.read(schulteBoardNotifierProvider(config));

  SchulteBoardNotifier notifierOf(ProviderContainer c, RunConfig config) =>
      c.read(schulteBoardNotifierProvider(config).notifier);

  /// Taps the tile currently holding [value].
  void tapValue(ProviderContainer c, RunConfig config, int value) {
    final board = stateOf(c, config);

    notifierOf(c, config).tapCell(board.cells.indexOf(value));
  }

  group('before start', () {
    test('every tile is disabled and a tap changes nothing', () {
      // The board is on screen behind the countdown. A tap that counted there
      // would be a free head start on a timed run.
      final config = configFor(Difficulty.classic);
      final container = containerWith();
      final before = stateOf(container, config);

      expect(before.started, isFalse);

      for (var i = 0; i < before.cellCount; i++) {
        expect(before.stateOf(i), SchulteTileState.disabled);
      }

      notifierOf(container, config).tapCell(0);

      expect(stateOf(container, config), before);
      expect(feedback.fired, isEmpty);
    });
  });

  group('a tap in order', () {
    test('marks the tile found and advances the cue', () {
      final config = configFor(Difficulty.classic);
      final container = containerWith();

      notifierOf(container, config).start();
      tapValue(container, config, 1);

      final after = stateOf(container, config);

      expect(after.nextValue, 2);
      expect(after.foundCount, 1);
      expect(after.stateOf(after.cells.indexOf(1)), SchulteTileState.found);
      expect(after.stateOf(after.cells.indexOf(2)), SchulteTileState.next);
    });

    test('and fires exactly one moment', () {
      // `tileNextCue` is a DECLARED SILENCE: the cue moving is not an event the
      // player did, and buzzing on it would make every correct tap buzz twice.
      final config = configFor(Difficulty.classic);
      final container = containerWith();

      notifierOf(container, config).start();
      tapValue(container, config, 1);

      expect(feedback.fired, <Moment>[Moment.tileFound]);
    });
  });

  group('a tap out of order', () {
    test('registers as wrong WITHOUT ending the run', () {
      // THE NAMED TEST. Schulte does not punish a wrong tap by ending the run
      // or by rewinding progress — the clock is the punishment. Anything else
      // makes the game about caution rather than about search.
      final config = configFor(Difficulty.classic);
      final container = containerWith();

      notifierOf(container, config).start();

      final board = stateOf(container, config);
      final wrongIndex = board.cells.indexOf(5);

      notifierOf(container, config).tapCell(wrongIndex);

      final after = stateOf(container, config);

      expect(after.stateOf(wrongIndex), SchulteTileState.wrong);
      expect(after.nextValue, 1, reason: 'the hunt did not move');
      expect(after.foundCount, 0);
      expect(after.isComplete, isFalse);
      expect(feedback.fired, <Moment>[Moment.answerWrong]);
    });

    test('and a second wrong tap on the SAME tile shakes again', () {
      final config = configFor(Difficulty.classic);
      final container = containerWith();

      notifierOf(container, config).start();

      final wrongIndex = stateOf(container, config).cells.indexOf(5);

      notifierOf(container, config).tapCell(wrongIndex);

      final first = stateOf(container, config).wrongCount;

      notifierOf(container, config).tapCell(wrongIndex);

      expect(stateOf(container, config).wrongCount, greaterThan(first));
    });

    test('and the latch clears on the next tap, right or wrong', () {
      // The game owns no timer, so the latch resolves on the next interaction.
      final config = configFor(Difficulty.classic);
      final container = containerWith();

      notifierOf(container, config).start();
      notifierOf(container, config).tapCell(
        stateOf(container, config).cells.indexOf(5),
      );

      expect(stateOf(container, config).wrongIndex, isNotNull);

      tapValue(container, config, 1);

      expect(stateOf(container, config).wrongIndex, isNull);
    });
  });

  group('a tap on a tile already found', () {
    test('does nothing and fires no moment', () {
      final config = configFor(Difficulty.classic);
      final container = containerWith();

      notifierOf(container, config).start();
      tapValue(container, config, 1);

      final settled = stateOf(container, config);

      feedback.fired.clear();
      notifierOf(container, config).tapCell(settled.cells.indexOf(1));

      expect(stateOf(container, config), settled);
      expect(feedback.fired, isEmpty);
    });
  });

  group('a whole board', () {
    test('completes in exactly cellCount taps, at every seed and size', () {
      for (final difficulty in schulteDifficulties) {
        final size = SchulteRules.forDifficulty(difficulty).cellCount;

        for (var seed = 0; seed < 200; seed++) {
          final config = configFor(difficulty, seed: seed);
          final container = containerWith();

          notifierOf(container, config).start();

          for (var value = 1; value <= size; value++) {
            tapValue(container, config, value);
          }

          final done = stateOf(container, config);

          expect(done.isComplete, isTrue, reason: 'seed $seed, $size cells');
          expect(done.nextValue, size + 1);
        }
      }
    });
  });

  group('the locale', () {
    test('does not reach the board — four locales, one state', () {
      final config = configFor(Difficulty.classic);
      final states = <SupportedLocale, SchulteBoardState>{
        for (final locale in SupportedLocale.values)
          locale: stateOf(containerWith(locale: locale), config),
      };

      final english = states[SupportedLocale.en];

      for (final entry in states.entries) {
        expect(entry.value, english, reason: '${entry.key.tag} differed');
      }
    });
  });
}
