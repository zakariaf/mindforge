import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/core/app_settings.dart';
import 'package:mindforge/core/difficulty.dart';
import 'package:mindforge/core/game_id.dart';
import 'package:mindforge/core/run_config.dart';
import 'package:mindforge/core/supported_locale.dart';
import 'package:mindforge/data/data_providers.dart';
import 'package:mindforge/features/play/application/run_notifier.dart';
import 'package:mindforge/features/play/domain/run_phase.dart';
import 'package:mindforge/games/game_registry.dart';
import 'package:mindforge/games/stroop_rush/application/stroop_board_notifier.dart';
import 'package:mindforge/games/stroop_rush/stroop_rush_definition.dart';

import '../../../support/test_database.dart';
import '../../../support/test_repositories.dart';

/// A whole Stroop Rush run, through the shipped pieces, into real SQLite.
///
/// **This is the on-device playthrough the epic asks for, written down.** The
/// canonical simulator cannot be driven from here — `simctl` has no tap verb
/// and the Simulator exposes no scriptable window — so the manual version of
/// this check could not be performed. What it was there to establish is
/// established here instead, and rather more strictly: thirty rounds answered
/// through `StroopBoardNotifier.submit`, reported to `RunNotifier` through the
/// definition's own subscription, ended by the board, and written by the real
/// `RunRepository` over `NativeDatabase.memory()`. Nothing is faked but the
/// clock and the id generator.
///
/// **Run twice, in `en` and in `ckb`.** The claim is not that the game works —
/// other tests say that — but that what lands in the database is the same
/// integers either way. A score that moved with the locale would mean a
/// numeral had been parsed back out of a rendered string somewhere.
void main() {
  setUp(TestWidgetsFlutterBinding.ensureInitialized);

  final config = RunConfig(
    gameId: GameId('stroop_rush'),
    difficulty: Difficulty.classic,
    seed: 42,
  );

  for (final locale in <SupportedLocale>[
    SupportedLocale.en,
    SupportedLocale.ckb,
  ]) {
    test('a full run lands one row of integers in ${locale.tag}', () async {
      final db = openTestDatabase();
      addTearDown(db.close);

      final repository = testRunRepository(db);
      final settings = const AppSettings.defaults().withLocaleOverride(locale);
      final container = ProviderContainer(
        overrides: [
          gameRegistryProvider.overrideWithValue([stroopRushDefinition]),
          runRepositoryProvider.overrideWithValue(repository),
          initialAppSettingsProvider.overrideWithValue(settings),
          settingsProvider.overrideWith(
            (ref) => Stream<AppSettings>.value(settings),
          ),
          clockProvider.overrideWithValue(Clock.fixed(kTestNow)),
        ],
      );
      addTearDown(container.dispose);

      container.read(runNotifierProvider(config).notifier)
        ..start()
        ..beginPlaying();

      // A LIVE SUBSCRIPTION, or the board is autoDisposed between reads and
      // every `read` hands back a fresh round 0 — the run would never end and
      // the loop below would spin to its guard. In the app the board widget is
      // the listener; here it has to be said out loud.
      final subscription = container.listen(
        stroopBoardNotifierProvider(config),
        (_, _) {},
      );

      addTearDown(subscription.close);

      final board = container.read(
        stroopBoardNotifierProvider(config).notifier,
      );

      // ANSWERED CORRECTLY, round by round, by asking the state which option
      // carries the ink. A wrong answer holds the round, so a run driven by a
      // fixed index would never finish — which is the same thing that would
      // have happened tapping blindly on the simulator.
      var guard = 0;

      while (container.read(stroopBoardNotifierProvider(config)).current !=
              null &&
          guard++ < 200) {
        final state = container.read(stroopBoardNotifierProvider(config));
        final round = state.current!;

        board.submit(round.options.indexOf(round.ink));
      }

      // PERSIST-THEN-TRANSITION, so `over` arrives only once real SQLite has
      // taken the row. Polled rather than slept on: the point of the test is
      // that the write happens, and a fixed delay would either be flaky or be
      // hiding how long it takes.
      for (
        var tick = 0;
        tick < 100 &&
            container.read(runNotifierProvider(config)).phase != RunPhase.over;
        tick++
      ) {
        await Future<void>.delayed(Duration.zero);
      }

      expect(
        container.read(runNotifierProvider(config)).phase,
        RunPhase.over,
        reason: 'the board never reported an outcome in ${locale.tag}',
      );

      final rows = await db.select(db.runs).get();

      expect(rows, hasLength(1));
      expect(rows.single.gameId, 'stroop_rush');
      // THE STORED METRIC IS AN INTEGER and it is the score, not a rendering
      // of one. `metricValue` is what a personal best is compared on.
      expect(rows.single.metricValue, isA<int>());
      expect(rows.single.metricValue, greaterThan(0));
      expect(rows.single.correctCount, 30);
      expect(rows.single.difficultyId, Difficulty.classic.name);
    });
  }
}
