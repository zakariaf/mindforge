import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:mindforge/core/calendar_day.dart';
import 'package:mindforge/core/game_id.dart';
import 'package:mindforge/data/data_providers.dart';
import 'package:mindforge/features/home/application/home_notifier.dart';
import 'package:mindforge/games/game_definition.dart';
import 'package:mindforge/games/game_registry.dart';
import 'package:mindforge/games/placeholder/placeholder_definitions.dart';

import '../../support/locale_matrix.dart';

void main() {
  ProviderContainer containerAt(
    DateTime instant, {
    List<GameDefinition>? games,
  }) {
    final container = ProviderContainer(
      overrides: [
        clockProvider.overrideWithValue(Clock.fixed(instant)),
        if (games != null) gameRegistryProvider.overrideWithValue(games),
      ],
    );
    addTearDown(container.dispose);

    return container;
  }

  group('the greeting', () {
    test('resolves from the injected clock, as a KEY', () {
      // A key, not a sentence. The ARB decides what each part of the day
      // sounds like, which is what lets a locale greet differently at
      // different hours in its own file rather than in a Dart switch.
      const expected = <int, Daypart>{
        0: Daypart.morning,
        8: Daypart.morning,
        11: Daypart.morning,
        12: Daypart.afternoon,
        14: Daypart.afternoon,
        17: Daypart.afternoon,
        18: Daypart.evening,
        20: Daypart.evening,
        23: Daypart.evening,
      };

      for (final entry in expected.entries) {
        expect(daypartAt(entry.key), entry.value, reason: '${entry.key}:00');
      }
    });

    test('and the state carries it, not a string', () {
      expect(
        containerAt(
          DateTime.utc(2026, 1, 1, 20),
        ).read(homeStateProvider).daypart,
        Daypart.evening,
      );
    });
  });

  group('the registry', () {
    test('is rendered in order, unfiltered', () {
      // A locked game still appears: the hub draws it as a "coming soon" card
      // rather than hiding it.
      final state = containerAt(DateTime.utc(2026)).read(homeStateProvider);

      expect(
        state.games.map((game) => game.id.value),
        <String>[
          'placeholder_coral',
          'placeholder_turquoise',
          'placeholder_locked',
        ],
      );
    });

    test('and unlockedCount counts only what is playable', () {
      expect(
        containerAt(DateTime.utc(2026)).read(homeStateProvider).unlockedCount,
        2,
      );
    });
  });

  group('the daily pick', () {
    test('is identical in every locale', () {
      // The generator consumes a CIVIL DATE and emits a semantic token. A pick
      // that moved because the language changed would mean localisation had
      // leaked into generation — the one thing the seeded-generator gate
      // exists to prevent.
      final previous = Intl.defaultLocale;
      addTearDown(() => Intl.defaultLocale = previous);

      final picks = <String, GameId>{};

      for (final tag in localeMatrix) {
        Intl.defaultLocale = tag;
        picks[tag] = containerAt(
          DateTime.utc(2026, 3, 21),
        ).read(homeStateProvider).dailyPick;
      }

      for (final entry in picks.entries) {
        expect(entry.value, picks['en'], reason: entry.key);
      }
    });

    test('and it never lands on a locked game', () {
      // A hub whose one call to action opened a "coming soon" card would be a
      // dead chevron. Swept across a year rather than spot-checked.
      final games = placeholderDefinitions();

      for (var serial = 20000; serial < 20365; serial++) {
        final picked = dailyPickFrom(games, CalendarDay.fromSerial(serial));
        final game = games.firstWhere((g) => g.id == picked);

        expect(game.isLocked, isFalse, reason: 'day $serial');
      }
    });

    test('and it is stable for one day and moves across days', () {
      // Stable, or the card would change under the player mid-session.
      final games = placeholderDefinitions();
      const day = CalendarDay.fromSerial(20680);

      expect(dailyPickFrom(games, day), dailyPickFrom(games, day));

      final week = <GameId>{
        for (var i = 0; i < 14; i++)
          dailyPickFrom(games, CalendarDay.fromSerial(20680 + i)),
      };

      expect(
        week.length,
        greaterThan(1),
        reason: 'a pick that never moves is not a daily pick',
      );
    });
  });
}
