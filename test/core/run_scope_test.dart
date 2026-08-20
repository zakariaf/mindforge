import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/core/difficulty.dart';
import 'package:mindforge/core/game_id.dart';
import 'package:mindforge/core/run_scope.dart';

import '../policy/support/source_text.dart';

void main() {
  group('RunScope.of', () {
    test('maps a typed id and difficulty to the persisted strings', () {
      expect(
        RunScope.of(GameId('stroop_rush'), Difficulty.classic),
        const RunScope('stroop_rush', 'classic'),
      );
    });

    test('and a null difficulty is the all-difficulties scope', () {
      expect(
        RunScope.of(GameId('stroop_rush'), null),
        const RunScope('stroop_rush'),
      );
      expect(RunScope.of(GameId('stroop_rush'), null).difficultyId, isNull);
    });

    test('the persisted difficulty id is the enum name, never the key', () {
      // The column is a join key. It has to survive an ARB rename and a
      // translation edit alike.
      for (final difficulty in Difficulty.values) {
        final scope = RunScope.of(GameId('stroop_rush'), difficulty);

        expect(scope.difficultyId, difficulty.name);
        expect(scope.difficultyId, isNot(difficulty.labelKey));
      }
    });

    test('and both components are pure ASCII', () {
      for (final difficulty in Difficulty.values) {
        final scope = RunScope.of(GameId('stroop_rush'), difficulty);

        for (final rune in '${scope.gameId}${scope.difficultyId}'.runes) {
          expect(rune, lessThan(0x80));
        }
      }
    });
  });

  group('it is the only conversion', () {
    test('nothing else in lib builds a scope from a value or a name', () {
      // Written before there are screens to break it. A second conversion is
      // not a duplicate function, it is a second spelling of a database key.
      final offenders = <String>[];

      for (final file in dartFilesUnderLib(skip: {'run_scope.dart'})) {
        final code = withoutDartComments(file.readAsStringSync());

        if (RegExp(r'RunScope\(\s*\w+\.(value|name)').hasMatch(code)) {
          offenders.add(file.path);
        }
      }

      expect(offenders, isEmpty);
    });

    test('and run_scope.dart itself holds exactly one factory', () {
      final code = withoutDartComments(
        File('lib/core/run_scope.dart').readAsStringSync(),
      );

      expect('factory RunScope'.allMatches(code), hasLength(1));
    });
  });
}
