import 'package:clock/clock.dart';
import 'package:intl/intl.dart';
import 'package:mindforge/core/calendar_day.dart';
import 'package:mindforge/core/result.dart';
import 'package:mindforge/core/run_commit.dart';
import 'package:mindforge/core/run_scope.dart';
import 'package:mindforge/core/streak_status.dart';
import 'package:mindforge/data/daos/runs_dao.dart';
import 'package:mindforge/data/data_failure.dart';
import 'package:mindforge/data/db/app_database.dart';
import 'package:mindforge/data/repositories/run_repository.dart';
import 'package:test/test.dart';

import '../../support/fake_id_generator.dart';
import '../../support/fake_log_sink.dart';
import '../../support/run_fixtures.dart';
import '../../support/test_database.dart';

/// Four consecutive days ending on the 19th of August 2026, which is what the
/// fixed clock below reports as "today".
const _kFirstDaySerial = 20684;

void main() {
  /// Opens a store holding four consecutive played days, with [now] as the
  /// injected clock's answer.
  Future<(AppDatabase, RunRepository)> openWithFourDays(DateTime now) async {
    final db = openTestDatabase(now: now);
    final repository = RunRepository(
      database: db,
      dao: RunsDao(db),
      clock: Clock.fixed(now),
      idGenerator: FakeIdGenerator(),
      logSink: FakeLogSink(),
      isRegisteredGameId: (id) => id == 'stroop_rush',
    );

    for (final draft in seededDrafts(
      seed: 11,
      count: 4,
      firstDaySerial: _kFirstDaySerial,
    )) {
      final result = await repository.saveRun(draft);
      expect(result, isA<Ok<RunCommit, DataFailure>>(), reason: r'$result');
    }

    return (db, repository);
  }

  /// The local instant whose civil day is [serial].
  DateTime localMidnightOf(int serial) =>
      DateTime.fromMillisecondsSinceEpoch(serial * 86400000, isUtc: true);

  test('the streak is four on the last played day', () async {
    final lastPlayed = localMidnightOf(_kFirstDaySerial + 3);
    final (db, repository) = await openWithFourDays(lastPlayed);
    addTearDown(db.close);

    final status = await repository.watchStreak().first;

    expect(status.currentDays, 4);
    expect(status.longestDays, 4);
  });

  test(
    'two containers over the same fixture disagree only by their clock',
    () async {
      // Since the ONLY difference is the injected clock, a DateTime.now()
      // anywhere on this path makes the second expectation fail.
      final lastPlayed = localMidnightOf(_kFirstDaySerial + 3);

      final (dbNow, repositoryNow) = await openWithFourDays(lastPlayed);
      addTearDown(dbNow.close);

      final (dbLater, repositoryLater) = await openWithFourDays(
        lastPlayed.add(const Duration(days: 2)),
      );
      addTearDown(dbLater.close);

      expect((await repositoryNow.watchStreak().first).currentDays, 4);
      expect(
        (await repositoryLater.watchStreak().first).currentDays,
        0,
        reason:
            'two days after the last run the streak is broken, and the only '
            'thing that changed is the Clock',
      );
    },
  );

  test('the streak is identical under every shipped locale', () async {
    final lastPlayed = localMidnightOf(_kFirstDaySerial + 3);
    StreakStatus? baseline;

    for (final tag in <String>['en', 'de', 'fa', 'ckb']) {
      final previous = Intl.defaultLocale;
      Intl.defaultLocale = tag;
      addTearDown(() => Intl.defaultLocale = previous);

      final (db, repository) = await openWithFourDays(lastPlayed);
      final status = await repository.watchStreak().first;
      await db.close();

      baseline ??= status;
      expect(
        status,
        baseline,
        reason:
            'the streak counts GREGORIAN civil days, because that is what '
            'CalendarDay is. A Persian user streak breaks at the same local '
            'midnight and only the rendered label differs. This test is what '
            'stops someone "fixing" the streak with Jalali arithmetic in E04. '
            'Diverged under $tag',
      );
    }
  });

  test('an empty store is a zero streak, never null', () async {
    final db = openTestDatabase();
    final repository = RunRepository(
      database: db,
      dao: RunsDao(db),
      clock: Clock.fixed(kTestNow),
      idGenerator: FakeIdGenerator(),
      logSink: FakeLogSink(),
      isRegisteredGameId: (id) => id == 'stroop_rush',
    );
    addTearDown(db.close);

    expect(await repository.watchStreak().first, const StreakStatus.empty());
  });

  test('a scoped read is unaffected by the streak read', () async {
    final lastPlayed = localMidnightOf(_kFirstDaySerial + 3);
    final (db, repository) = await openWithFourDays(lastPlayed);
    addTearDown(db.close);

    final runs = await repository
        .watchChartSeries(const RunScope('stroop_rush', 'classic'))
        .first;

    expect(runs, hasLength(4));
    expect(
      runs.map((r) => r.playedOnDay).toSet(),
      List.generate(
        4,
        (i) => CalendarDay.fromSerial(_kFirstDaySerial + i),
      ).toSet(),
    );
  });
}
