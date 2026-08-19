import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/core/app_settings.dart';
import 'package:mindforge/core/result.dart';
import 'package:mindforge/core/run_commit.dart';
import 'package:mindforge/core/run_scope.dart';
import 'package:mindforge/data/data_failure.dart';
import 'package:mindforge/data/data_providers.dart';
import 'package:mindforge/data/db/app_database.dart';

import '../support/fake_id_generator.dart';
import '../support/run_fixtures.dart';
import '../support/test_database.dart';

void main() {
  group('the seams throw until overridden', () {
    test('appDatabaseProvider names the file to fix', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Riverpod 3 wraps a provider's error in a ProviderException, so this
      // asserts what a caller ACTUALLY sees rather than what was thrown. The
      // message has to survive the wrapping, or the whole point of a named
      // placeholder is lost.
      expect(
        () => container.read(appDatabaseProvider),
        throwsA(
          isA<Object>().having(
            (e) => e.toString(),
            'toString',
            allOf(
              contains('UnimplementedError'),
              contains('lib/bootstrap.dart'),
            ),
          ),
        ),
        reason:
            'a forgotten wiring must fail loudly, not quietly construct a '
            'second real database inside a test',
      );
    });

    test('initialAppSettingsProvider throws too', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        () => container.read(initialAppSettingsProvider),
        throwsA(
          isA<Object>().having(
            (e) => e.toString(),
            'toString',
            contains('UnimplementedError'),
          ),
        ),
      );
    });

    test(
      'registeredGameIdsProvider refuses everything until E07 overrides it',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        expect(
          container.read(registeredGameIdsProvider),
          isEmpty,
          reason:
              'it refuses rather than accepts, so a run written against an '
              'unregistered game fails in a test rather than in a history',
        );
      },
    );
  });

  group('with the seams overridden', () {
    late AppDatabase db;
    late ProviderContainer container;

    setUp(() {
      db = openTestDatabase();
      container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          clockProvider.overrideWithValue(Clock.fixed(kTestNow)),
          idGeneratorProvider.overrideWithValue(FakeIdGenerator()),
          registeredGameIdsProvider.overrideWithValue(const {'stroop_rush'}),
        ],
      );
      // Order matters: tear-downs run in REVERSE, so the container must be
      // added LAST to be disposed FIRST. Closing the database while a
      // StreamProvider still holds a subscription over it hangs the test
      // rather than failing it.
      addTearDown(db.close);
      addTearDown(container.dispose);
    });

    /// Lets pending microtasks and the drift stream settle.
    Future<void> settle() async {
      for (var i = 0; i < 5; i++) {
        await Future<void>.delayed(Duration.zero);
      }
    }

    /// Holds an `autoDispose` provider alive for the duration of a test.
    ///
    /// Without a listener the provider is torn down the moment
    /// `container.read(p.future)` starts, and the future completes with
    /// "disposed during loading state". A real widget always holds one; the
    /// closure is passed rather than the provider itself because Riverpod 3
    /// does not export `ProviderListenable` from `flutter_riverpod`.
    void keepAlive(ProviderSubscription<Object?> Function() listen) {
      addTearDown(listen().close);
    }

    test(
      'settingsProvider emits the seeded value and re-emits after a write',
      () async {
        final emissions = <AppSettings>[];
        final subscription = container.listen(settingsProvider, (_, next) {
          final value = next.value;
          if (value != null) emissions.add(value);
        }, fireImmediately: true);
        addTearDown(subscription.close);

        // A bounded settle rather than pumpEventQueue(): Riverpod's scheduler
        // keeps re-arming microtasks while a StreamProvider has a live
        // listener, so pumpEventQueue() never observes an empty queue and the
        // test times out instead of failing.
        await settle();
        expect(emissions.last, const AppSettings.defaults());

        expect(
          await container
              .read(settingsRepositoryProvider)
              .update(
                const AppSettings.defaults().copyWith(isSoundEnabled: false),
              ),
          isA<Ok<AppSettings, DataFailure>>(),
        );

        await settle();
        expect(
          emissions.last.isSoundEnabled,
          isFalse,
          reason:
              'no manual republish — the stream re-emits because the row '
              'changed',
        );
      },
    );

    test('runStatsProvider emits the fixture numbers', () async {
      const scope = RunScope('stroop_rush', 'classic');
      final repository = container.read(runRepositoryProvider);

      final drafts = seededDrafts(seed: 21, count: 6);
      for (final draft in drafts) {
        expect(
          await repository.saveRun(draft),
          isA<Ok<RunCommit, DataFailure>>(),
        );
      }

      keepAlive(() => container.listen(runStatsProvider(scope), (_, _) {}));
      final stats = await container.read(runStatsProvider(scope).future);

      expect(stats.gamesPlayed, drafts.length);
      expect(
        stats.timeTrainedMs,
        drafts.fold<int>(0, (sum, d) => sum + d.durationMs),
      );
    });

    test('the same RunScope is one provider; a different one is not', () {
      const a = RunScope('stroop_rush', 'classic');
      const b = RunScope('stroop_rush', 'classic');
      const c = RunScope('stroop_rush', 'blitz');

      expect(
        runStatsProvider(a),
        runStatsProvider(b),
        reason:
            'value equality on the family key is what stops two widgets '
            'opening two database subscriptions over the same query',
      );
      expect(runStatsProvider(a), isNot(runStatsProvider(c)));
    });

    test('every derived read resolves through the repository layer', () async {
      const scope = RunScope('stroop_rush', 'classic');

      keepAlive(() => container.listen(allBestsProvider, (_, _) {}));
      keepAlive(
        () => container.listen(personalBestProvider(scope), (_, _) {}),
      );
      keepAlive(
        () => container.listen(chartSeriesProvider(scope), (_, _) {}),
      );
      keepAlive(() => container.listen(streakProvider, (_, _) {}));

      expect(await container.read(allBestsProvider.future), isEmpty);
      expect(
        await container.read(personalBestProvider(scope).future),
        isA<Ok<Object?, DataFailure>>(),
      );
      expect(await container.read(chartSeriesProvider(scope).future), isEmpty);
      expect(
        (await container.read(streakProvider.future)).currentDays,
        0,
      );
    });

    test('the DAO providers exist for repositories to compose', () {
      expect(container.read(settingsDaoProvider), isNotNull);
      expect(container.read(runsDaoProvider), isNotNull);
    });
  });
}
