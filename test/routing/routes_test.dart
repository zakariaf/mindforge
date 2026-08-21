import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:mindforge/core/difficulty.dart';
import 'package:mindforge/core/game_id.dart';
import 'package:mindforge/core/run_config.dart';
import 'package:mindforge/routing/routes.dart';

import '../support/locale_matrix.dart';

void main() {
  final config = RunConfig(
    gameId: GameId('fixture_alpha'),
    difficulty: Difficulty.classic,
    seed: 42,
  );

  group('a location round-trips', () {
    test('a game detail path carries the id', () {
      expect(
        Routes.gameDetail(GameId('fixture_alpha')),
        '/game/fixture_alpha',
      );
    });

    test('and a run path names its whole config', () {
      expect(
        Routes.play(config),
        '/game/fixture_alpha/play?difficulty=classic&seed=42',
      );
    });

    test('and configFrom rebuilds it', () {
      expect(
        Routes.configFrom(
          gameId: 'fixture_alpha',
          difficulty: 'classic',
          seed: '42',
        ),
        config,
      );
    });

    test('and a link that cannot be read returns null', () {
      // Not a throw: a stale or hand-edited deep link is a thing users
      // produce, and the caller decides what to do about it. This only reports
      // that it could not be read.
      for (final broken in <List<String?>>[
        <String?>[null, 'classic', '1'],
        <String?>['g', null, '1'],
        <String?>['g', 'classic', null],
        <String?>['g', 'nope', '1'],
        <String?>['g', 'classic', 'x'],
        // The one that matters most: Eastern Arabic digits in the seed. A URL
        // built under fa must never carry them, and one that somehow does is
        // unreadable rather than silently a different run.
        <String?>['g', 'classic', '۴۲'],
      ]) {
        expect(
          Routes.configFrom(
            gameId: broken[0],
            difficulty: broken[1],
            seed: broken[2],
          ),
          isNull,
          reason: '$broken',
        );
      }
    });
  });

  group('locations are ASCII in every locale', () {
    test('the same run builds the same string under all four', () {
      // A URL is canonical data. Localisation happens at render — a location
      // that moved with the language could not be pasted into a bug report,
      // deep-linked, or compared.
      final previous = Intl.defaultLocale;
      addTearDown(() => Intl.defaultLocale = previous);

      final built = <String, String>{};

      for (final tag in localeMatrix) {
        Intl.defaultLocale = tag;
        built[tag] = Routes.play(config);
      }

      for (final entry in built.entries) {
        expect(entry.value, built['en'], reason: entry.key);

        for (final rune in entry.value.runes) {
          expect(rune, lessThan(0x80), reason: '${entry.key}: ${entry.value}');
        }
      }
    });

    test('and the difficulty is the enum name, never a label', () {
      for (final difficulty in Difficulty.values) {
        final location = Routes.play(
          RunConfig(
            gameId: GameId('fixture_alpha'),
            difficulty: difficulty,
            seed: 1,
          ),
        );

        expect(location, contains('difficulty=${difficulty.name}'));
        expect(location, isNot(contains(difficulty.labelKey)));
      }
    });
  });
}
