import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/core/difficulty.dart';
import 'package:mindforge/core/game_id.dart';
import 'package:mindforge/features/play/domain/run_config.dart';

import '../../../support/design_source.dart';

void main() {
  RunConfig configWith({int seed = 42, Difficulty? difficulty}) => RunConfig(
    gameId: GameId('stroop_rush'),
    difficulty: difficulty ?? Difficulty.classic,
    seed: seed,
  );

  group('RunConfig', () {
    test('is value-equal, so it is a safe family key', () {
      // Two widgets asking for the same run must get the same notifier, not
      // two runs of the same game.
      expect(configWith(), configWith());
      expect(configWith().hashCode, configWith().hashCode);

      final byConfig = <RunConfig, int>{configWith(): 1};
      expect(byConfig[configWith()], 1);
    });

    test('and a different seed is a different config', () {
      // Which is exactly what "Play again" is: a new seed, therefore a new
      // notifier, therefore a fresh run rather than a resumed one.
      expect(configWith(seed: 1), isNot(configWith(seed: 2)));
    });

    test('and a different difficulty is too', () {
      expect(
        configWith(difficulty: Difficulty.chill),
        isNot(configWith(difficulty: Difficulty.blitz)),
      );
    });
  });

  group('what it deliberately does not carry', () {
    test('no locale, because a language switch is not a new run', () {
      // A locale on the family key would make switching language mid-run start
      // a different run, which is precisely backwards: it is the same run,
      // rendered in another language.
      expect(
        DesignSource.dartFieldNames(
          'lib/features/play/domain/run_config.dart',
          'RunConfig',
        ),
        <String>['gameId', 'difficulty', 'seed'],
      );

      expect(
        File('lib/features/play/domain/run_config.dart').readAsStringSync(),
        isNot(contains('Locale')),
      );
    });
  });
}
