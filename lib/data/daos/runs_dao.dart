import 'package:drift/drift.dart';
import 'package:mindforge/core/calendar_day.dart';
import 'package:mindforge/core/game_stats.dart';
import 'package:mindforge/core/run_record.dart';
import 'package:mindforge/core/run_scope.dart';
import 'package:mindforge/core/score_format.dart';
import 'package:mindforge/data/db/app_database.dart';
import 'package:mindforge/data/db/tables/runs.dart';

part 'runs_dao.drift.dart';

/// A best value as the store reports it, before it becomes a `RunMetric`.
///
/// Carries the set of distinct `metric_kind`s seen, so the repository can tell
/// a clean scope from one holding two formats at once — which would otherwise
/// silently rank a point total against a millisecond count.
typedef BestRead = ({int? value, Set<String> metricKinds});

/// Where a page of runs continues from.
///
/// The pair, not the instant: see [RunsDao.pageBefore].
typedef RunCursor = ({int startedAtUtcMs, String id});

/// Single-table queries over `runs`.
///
/// Every `ORDER BY` and every comparison in this file is over an **integer**
/// column. No query sorts or compares text, so no `COLLATE` clause is needed
/// and none is written — a collation-sensitive ordering over a text column is
/// the classic way for a locale to change a query result.
@DriftAccessor(tables: [Runs])
class RunsDao extends DatabaseAccessor<AppDatabase> with _$RunsDaoMixin {
  /// Creates the accessor over [db].
  RunsDao(super.attachedDatabase);

  /// Every live-row query starts here, so none can forget `is_deleted = 0`.
  SimpleSelectStatement<Runs, RunRow> _liveRuns() =>
      select(runs)..where((t) => t.isDeleted.equals(0));

  Expression<bool> _inScope(Runs t, RunScope scope) {
    final byGame = t.gameId.equals(scope.gameId);
    final difficultyId = scope.difficultyId;
    return difficultyId == null
        ? byGame
        : byGame & t.difficultyId.equals(difficultyId);
  }

  /// Maps a stored row to the pure value object. No generated row type ever
  /// leaves this class.
  RunRecord _toRecord(RunRow row) => RunRecord(
    id: row.id,
    gameId: row.gameId,
    difficultyId: row.difficultyId,
    clientRunKey: row.clientRunKey,
    startedAtUtcMs: row.startedAtUtcMs,
    playedOnDay: CalendarDay.fromSerial(row.playedOnDay),
    durationMs: row.durationMs,
    format: ScoreFormat.values.byName(row.metricKind),
    metricValue: row.metricValue,
    correctCount: row.correctCount,
    wrongCount: row.wrongCount,
    longestCombo: row.longestCombo,
    totalReactionMs: row.totalReactionMs,
    createdAtUtcMs: row.createdAtUtcMs,
  );

  /// The [limit] most recent runs in [scope], newest first.
  ///
  /// Ordered by start instant **and then by id**. The tiebreaker is not
  /// cosmetic: two runs can share a millisecond — genuinely on a fast device,
  /// and always in a test driving a fixed `Clock` — and without it the order
  /// between them is whatever SQLite happens to return, which makes the page
  /// boundary below non-deterministic.
  Stream<List<RunRecord>> watchRecent(RunScope scope, {required int limit}) =>
      (_liveRuns()
            ..where((t) => _inScope(t, scope))
            ..orderBy([
              (t) => OrderingTerm.desc(t.startedAtUtcMs),
              (t) => OrderingTerm.desc(t.id),
            ])
            ..limit(limit))
          .watch()
          .map((rows) => rows.map(_toRecord).toList());

  /// The [limit] runs in [scope] strictly after [cursor] in the descending
  /// `(started_at_utc_ms, id)` order [watchRecent] uses.
  ///
  /// Keyset paging. A row inserted while the user is paging shifts every later
  /// skip-count by one, so a skip-based pager silently repeats and drops rows.
  /// A cursor over an indexed integer cannot.
  ///
  /// The cursor is the **pair**, not the instant alone. With the instant alone,
  /// two runs sharing a millisecond collapse onto one cursor value and the
  /// second is skipped forever — which a fixed test clock produces every time.
  Future<List<RunRecord>> pageBefore(
    RunScope scope, {
    required RunCursor cursor,
    required int limit,
  }) async {
    final rows =
        await (_liveRuns()
              ..where(
                (t) =>
                    _inScope(t, scope) &
                    (t.startedAtUtcMs.isSmallerThanValue(
                          cursor.startedAtUtcMs,
                        ) |
                        (t.startedAtUtcMs.equals(cursor.startedAtUtcMs) &
                            t.id.isSmallerThanValue(cursor.id))),
              )
              ..orderBy([
                (t) => OrderingTerm.desc(t.startedAtUtcMs),
                (t) => OrderingTerm.desc(t.id),
              ])
              ..limit(limit))
            .get();

    return rows.map(_toRecord).toList();
  }

  /// Inserts one run. Called only from inside the repository's transaction.
  Future<void> insertRun(RunsCompanion companion) async {
    await into(runs).insert(companion);
  }

  /// The best `metric_value` in [scope], and the formats present there.
  ///
  /// Returns a `null` value when the scope is empty — not `0`,
  /// which would render as a real BEST pill for someone who has never played.
  Future<BestRead> readBest(RunScope scope) async {
    final rows =
        await (selectOnly(runs)
              ..addColumns([
                runs.metricKind,
                runs.metricValue.max(),
                runs.metricValue.min(),
              ])
              ..where(runs.isDeleted.equals(0) & _inScope(runs, scope))
              ..groupBy([runs.metricKind]))
            .get();

    if (rows.isEmpty) return (value: null, metricKinds: <String>{});

    final kinds = rows.map((r) => r.read(runs.metricKind)!).toSet();
    if (kinds.length > 1) return (value: null, metricKinds: kinds);

    final kind = kinds.single;
    final row = rows.single;
    // The MAX/MIN direction is decided by RunMetric.isBetterThan at the
    // repository; this only supplies the extremum each format could want.
    final value = ScoreFormat.values.byName(kind) == ScoreFormat.points
        ? row.read(runs.metricValue.max())
        : row.read(runs.metricValue.min());

    return (value: value, metricKinds: kinds);
  }

  /// Watches [readBest] for [scope].
  Stream<BestRead> watchBest(RunScope scope) =>
      _liveRuns().watch().asyncMap((_) => readBest(scope));

  /// The best value for **every** game that has any run, keyed by `game_id`.
  ///
  /// One `GROUP BY` query rather than a fan-out of per-game streams: this is
  /// the read Home's BEST pills need, and building it from the scoped ones
  /// would be an N+1 of stream subscriptions.
  Stream<Map<String, BestRead>> watchBestsByGame() =>
      _liveRuns().watch().asyncMap((_) async {
        final rows =
            await (selectOnly(runs)
                  ..addColumns([
                    runs.gameId,
                    runs.metricKind,
                    runs.metricValue.max(),
                    runs.metricValue.min(),
                  ])
                  ..where(runs.isDeleted.equals(0))
                  ..groupBy([runs.gameId, runs.metricKind]))
                .get();

        final byGame = <String, List<TypedResult>>{};
        for (final row in rows) {
          byGame.putIfAbsent(row.read(runs.gameId)!, () => []).add(row);
        }

        return byGame.map((gameId, groups) {
          final kinds = groups.map((r) => r.read(runs.metricKind)!).toSet();
          if (kinds.length > 1) {
            return MapEntry(gameId, (value: null, metricKinds: kinds));
          }
          final kind = kinds.single;
          final group = groups.single;
          final value = ScoreFormat.values.byName(kind) == ScoreFormat.points
              ? group.read(runs.metricValue.max())
              : group.read(runs.metricValue.min());
          return MapEntry(gameId, (value: value, metricKinds: kinds));
        });
      });

  /// The aggregate fold over [scope].
  Future<GameStats> readAggregate(RunScope scope) async {
    final row =
        await (selectOnly(runs)
              ..addColumns([
                runs.id.count(),
                runs.durationMs.sum(),
                runs.correctCount.sum(),
                runs.wrongCount.sum(),
                runs.totalReactionMs.sum(),
                runs.longestCombo.max(),
              ])
              ..where(runs.isDeleted.equals(0) & _inScope(runs, scope)))
            .getSingle();

    return GameStats(
      gamesPlayed: row.read(runs.id.count()) ?? 0,
      timeTrainedMs: row.read(runs.durationMs.sum()) ?? 0,
      correctCount: row.read(runs.correctCount.sum()) ?? 0,
      wrongCount: row.read(runs.wrongCount.sum()) ?? 0,
      totalReactionMs: row.read(runs.totalReactionMs.sum()) ?? 0,
      longestCombo: row.read(runs.longestCombo.max()) ?? 0,
    );
  }

  /// Watches [readAggregate] for [scope].
  Stream<GameStats> watchAggregate(RunScope scope) =>
      _liveRuns().watch().asyncMap((_) => readAggregate(scope));

  /// Every distinct local day that has at least one live run, ascending.
  Stream<List<CalendarDay>> watchPlayedDays() =>
      _liveRuns().watch().asyncMap((_) async {
        final rows =
            await (selectOnly(runs, distinct: true)
                  ..addColumns([runs.playedOnDay])
                  ..where(runs.isDeleted.equals(0))
                  ..orderBy([OrderingTerm.asc(runs.playedOnDay)]))
                .get();

        return rows
            .map((r) => CalendarDay.fromSerial(r.read(runs.playedOnDay)!))
            .toList();
      });
}
