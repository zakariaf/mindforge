import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/core/app_settings.dart';
import 'package:mindforge/core/difficulty.dart';
import 'package:mindforge/core/game_id.dart';
import 'package:mindforge/core/run_config.dart';
import 'package:mindforge/core/supported_locale.dart';
import 'package:mindforge/data/data_providers.dart';
import 'package:mindforge/data/db/app_database.dart';
import 'package:mindforge/features/play/application/run_notifier.dart';
import 'package:mindforge/features/play/domain/run_phase.dart';
import 'package:mindforge/games/game_registry.dart';
import 'package:mindforge/games/schulte_grid/application/schulte_board_notifier.dart';
import 'package:mindforge/games/schulte_grid/schulte_grid_definition.dart';
import 'package:mindforge/l10n/l10n_providers.dart';

import '../../support/test_database.dart';
import '../../support/test_repositories.dart';

/// A whole Schulte run, through the shipped pieces, into real SQLite.
///
/// **The score is a DURATION here, which no game had exercised before.** Stroop
/// Rush scores points; `ScoreFormat.duration` had never rendered a real run.
/// What is asserted is that an integer number of milliseconds is what lands in
/// the database and what the formatter is handed — never a rendered string —
/// and that the four locales differ only at the point of rendering.
void main() {
  setUp(TestWidgetsFlutterBinding.ensureInitialized);

  final config = RunConfig(
    gameId: GameId('schulte_grid'),
    difficulty: Difficulty.classic,
    seed: 42,
  );

  /// Plays a full board in [locale], with the clock advanced by [elapsed].
  Future<({ProviderContainer container, AppDatabase db})> playFullBoard(
    SupportedLocale locale, {
    required Duration elapsed,
    bool finish = true,
  }) async {
    final db = openTestDatabase();

    addTearDown(db.close);

    var now = kTestNow;
    final settings = const AppSettings.defaults().withLocaleOverride(locale);
    final container = ProviderContainer(
      overrides: [
        gameRegistryProvider.overrideWithValue([schulteGridDefinition]),
        runRepositoryProvider.overrideWithValue(testRunRepository(db)),
        initialAppSettingsProvider.overrideWithValue(settings),
        settingsProvider.overrideWith(
          (ref) => Stream<AppSettings>.value(settings),
        ),
        clockProvider.overrideWithValue(Clock(() => now)),
      ],
    );

    addTearDown(container.dispose);

    final subscription = container.listen(
      schulteBoardNotifierProvider(config),
      (_, _) {},
    );

    addTearDown(subscription.close);

    container.read(runNotifierProvider(config).notifier)
      ..start()
      ..beginPlaying();

    final board = container.read(schulteBoardNotifierProvider(config).notifier)
      ..start();

    // The whole run takes `elapsed`; the tiles are found at the end of it, so
    // the ticker reads exactly that when the board reports its outcome.
    now = now.add(elapsed);

    if (finish) {
      final cells = container.read(schulteBoardNotifierProvider(config)).cells;

      for (var value = 1; value <= cells.length; value++) {
        board.tapCell(cells.indexOf(value));
      }

      for (
        var tick = 0;
        tick < 100 &&
            container.read(runNotifierProvider(config)).phase != RunPhase.over;
        tick++
      ) {
        await Future<void>.delayed(Duration.zero);
      }
    }

    return (container: container, db: db);
  }

  group('a completed run', () {
    test('persists one row whose duration is an ASCII integer', () async {
      final played = await playFullBoard(
        SupportedLocale.en,
        elapsed: const Duration(milliseconds: 18600),
      );
      final rows = await played.db.select(played.db.runs).get();

      expect(rows, hasLength(1));
      expect(rows.single.gameId, 'schulte_grid');
      expect(rows.single.correctCount, 25);
      // NOT A FORMATTED STRING. The column is an int and the value is
      // milliseconds; a "18.6s" in here would be an English sentence in a
      // database four languages read.
      expect(rows.single.durationMs, 18600);
      expect(rows.single.durationMs, isA<int>());
    });

    test(
      'and lands the same integer whatever language it was played in',
      () async {
        for (final locale in SupportedLocale.values) {
          final played = await playFullBoard(
            locale,
            elapsed: const Duration(milliseconds: 18600),
          );
          final rows = await played.db.select(played.db.runs).get();

          expect(rows.single.durationMs, 18600, reason: locale.tag);
        }
      },
    );

    test('and the duration renders per locale, from that one integer', () async {
      // THE POINT OF ScoreFormat.duration, exercised for the first time. The
      // decimal separator moves and the digits move; the stored value does not.
      const expected = <SupportedLocale, String>{
        SupportedLocale.en: '18.6',
        SupportedLocale.de: '18,6',
        SupportedLocale.fa: '۱۸٫۶',
        SupportedLocale.ckb: '۱۸٫۶',
      };

      for (final entry in expected.entries) {
        final played = await playFullBoard(
          entry.key,
          elapsed: const Duration(milliseconds: 18600),
        );
        final numbers = played.container.read(localeNumbersProvider);

        expect(
          numbers.seconds(18600),
          entry.value,
          reason: '${entry.key.tag} rendered the wrong numeric run',
        );
      }
    });
  });

  group('an abandoned run', () {
    test('persists nothing', () async {
      final played = await playFullBoard(
        SupportedLocale.en,
        elapsed: const Duration(seconds: 5),
        finish: false,
      );
      final rows = await played.db.select(played.db.runs).get();

      expect(rows, isEmpty);
    });
  });
}
