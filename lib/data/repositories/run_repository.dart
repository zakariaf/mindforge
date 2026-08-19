import 'package:clock/clock.dart';
import 'package:drift/drift.dart' show Value;
import 'package:meta/meta.dart';
import 'package:mindforge/core/calendar_day.dart';
import 'package:mindforge/core/game_stats.dart';
import 'package:mindforge/core/id_generator.dart';
import 'package:mindforge/core/result.dart';
import 'package:mindforge/core/run_commit.dart';
import 'package:mindforge/core/run_draft.dart';
import 'package:mindforge/core/run_metric.dart';
import 'package:mindforge/core/run_record.dart';
import 'package:mindforge/core/run_scope.dart';
import 'package:mindforge/core/score_format.dart';
import 'package:mindforge/core/streak_calculator.dart';
import 'package:mindforge/core/streak_status.dart';
import 'package:mindforge/data/daos/runs_dao.dart';
import 'package:mindforge/data/data_failure.dart';
import 'package:mindforge/data/db/app_database.dart';
import 'package:mindforge/data/log_sink.dart';
import 'package:sqlite3/common.dart' show SqliteException;

/// Decides whether a `gameId` is one this build actually ships.
///
/// Injected rather than imported, because the registry is E07's
/// `GameDefinition` and `lib/data/` must not depend upward on it.
typedef GameIdPredicate = bool Function(String gameId);

/// The **single write path** for runs, and the single source of truth for every
/// number derived from them.
///
/// There is no `StatsRepository`. Home, game detail, results and stats all read
/// folds over the one `runs` table, and a second repository over that table
/// would be a second authority — the thing `flutter-architecture` forbids.
///
/// Nothing here is stored that can be derived: personal best, accuracy, the
/// aggregates and the streak are all recomputed on read.
final class RunRepository {
  /// Creates the repository.
  RunRepository({
    required AppDatabase database,
    required RunsDao dao,
    required Clock clock,
    required IdGenerator idGenerator,
    required LogSink logSink,
    required GameIdPredicate isRegisteredGameId,
  }) : _database = database,
       _dao = dao,
       _clock = clock,
       _idGenerator = idGenerator,
       _logSink = logSink,
       _isRegisteredGameId = isRegisteredGameId;

  /// Owns the transaction every write runs in.
  final AppDatabase _database;

  /// The single-table queries this repository composes.
  final RunsDao _dao;

  /// Where "now" comes from. Never the wall clock.
  final Clock _clock;

  /// Where a new row's identity comes from. Never a bare `Uuid().v7()`.
  final IdGenerator _idGenerator;

  /// Where a handled failure is reported.
  final LogSink _logSink;

  /// Whether a `gameId` names a game this build ships.
  final GameIdPredicate _isRegisteredGameId;

  static const StreakCalculator _streaks = StreakCalculator();

  /// Persists [draft] and reports whether it is a personal best.
  ///
  /// Exactly one `db.transaction`. The pre-write best is read **inside** it, so
  /// two runs finishing close together cannot both claim the badge — a caller
  /// that instead read `watchPersonalBest` after the commit would be racing its
  /// own write.
  ///
  /// Idempotent: recording the same `clientRunKey` twice returns
  /// [RunAlreadyRecorded] and leaves the first row untouched, revision and all.
  @useResult
  Future<Result<RunCommit, DataFailure>> saveRun(RunDraft draft) async {
    // Guarded before any SQL runs, so an unregistered id — or a display string
    // where a token belongs — fails the same way whether or not the ASCII CHECK
    // would also have caught it. The CHECK is the backstop, not the first line.
    if (!_isRegisteredGameId(draft.gameId)) {
      return Err(NotFound(draft.gameId));
    }

    try {
      return await _database.transaction(() async {
        final previousBest = await _dao.readBest(
          RunScope(draft.gameId, draft.difficultyId),
        );

        final nowMs = _clock.now().toUtc().millisecondsSinceEpoch;
        final id = _idGenerator.newId();

        await _dao.insertRun(
          RunsCompanion.insert(
            id: id,
            createdAtUtcMs: nowMs,
            updatedAtUtcMs: nowMs,
            gameId: draft.gameId,
            difficultyId: draft.difficultyId,
            clientRunKey: draft.clientRunKey,
            startedAtUtcMs: draft.startedAtUtcMs,
            playedOnDay: draft.playedOnDay.serial,
            durationMs: draft.durationMs,
            metricKind: draft.format.name,
            metricValue: draft.metricValue,
            correctCount: draft.correctCount,
            wrongCount: draft.wrongCount,
            longestCombo: draft.longestCombo,
            totalReactionMs: draft.totalReactionMs,
            rowRevision: const Value(1),
            isDeleted: const Value(0),
          ),
        );

        final record = RunRecord(
          id: id,
          gameId: draft.gameId,
          difficultyId: draft.difficultyId,
          clientRunKey: draft.clientRunKey,
          startedAtUtcMs: draft.startedAtUtcMs,
          playedOnDay: draft.playedOnDay,
          durationMs: draft.durationMs,
          format: draft.format,
          metricValue: draft.metricValue,
          correctCount: draft.correctCount,
          wrongCount: draft.wrongCount,
          longestCombo: draft.longestCombo,
          totalReactionMs: draft.totalReactionMs,
          createdAtUtcMs: nowMs,
        );

        return Ok<RunCommit, DataFailure>(
          RunCommit(
            record: record,
            isPersonalBest: _beatsPreviousBest(record.metric, previousBest),
          ),
        );
      });
    } on SqliteException catch (e, st) {
      final failure = _classify(e, draft);
      _logSink.recordFailure(failure, error: e, stackTrace: st);
      return Err(failure);
    }
  }

  /// Whether [metric] beats [previous].
  ///
  /// **True when there is no previous best** — the first run in a scope is a
  /// personal best, which is the case a naive `value > currentBest` against a
  /// null gets wrong.
  bool _beatsPreviousBest(RunMetric metric, BestRead previous) {
    final value = previous.value;
    if (value == null) return true;

    return switch (metric.isBetterThan(
      RunMetric(format: metric.format, value: value),
    )) {
      BetterThan(:final isBetter) => isBetter,
      // A scope already holding two formats has no ordering, so nothing in it
      // can be called a best. watchPersonalBest surfaces the CorruptRow.
      ScoreFormatMismatch() => false,
    };
  }

  DataFailure _classify(SqliteException e, RunDraft draft) {
    final message = e.message.toLowerCase();
    if (message.contains('unique')) {
      return RunAlreadyRecorded(draft.clientRunKey);
    }
    // SQLite names the failing CHECK when the constraint is named; when it is
    // not, the message still carries the table. Either way the caller gets a
    // typed failure with the detail, never a sentence.
    return ConstraintViolated(e.message);
  }

  /// The best score in [scope], or `null` when nothing has been played there.
  ///
  /// Emits `Err(CorruptRow)` for a scope holding more than one `ScoreFormat`,
  /// rather than silently ranking a point total against a millisecond count.
  Stream<Result<RunMetric?, DataFailure>> watchPersonalBest(RunScope scope) =>
      _dao.watchBest(scope).map((best) => _toMetric(best, scope.gameId));

  /// The best score for **every** game that has any run.
  ///
  /// The read Home's BEST pills need: one `GROUP BY` rather than an N+1 of
  /// per-game stream subscriptions.
  Stream<Map<String, Result<RunMetric?, DataFailure>>> watchBestsByGame() =>
      _dao.watchBestsByGame().map(
        (byGame) => byGame.map(
          (gameId, best) => MapEntry(gameId, _toMetric(best, gameId)),
        ),
      );

  Result<RunMetric?, DataFailure> _toMetric(BestRead best, String gameId) {
    if (best.metricKinds.length > 1) {
      return Err(
        CorruptRow(
          'runs',
          'game $gameId holds more than one metric_kind: '
              '${(best.metricKinds.toList()..sort()).join(", ")}',
        ),
      );
    }

    final value = best.value;
    if (value == null) return const Ok(null);

    return Ok(
      RunMetric(
        format: ScoreFormat.values.byName(best.metricKinds.single),
        value: value,
      ),
    );
  }

  /// The aggregate numbers for [scope].
  Stream<GameStats> watchStats(RunScope scope) => _dao.watchAggregate(scope);

  /// The [count] most recent runs in [scope], newest first — the chart series.
  Stream<List<RunRecord>> watchChartSeries(RunScope scope, {int count = 7}) =>
      _dao.watchRecent(scope, limit: count);

  /// The daily streak, with "today" read from the injected [Clock].
  Stream<StreakStatus> watchStreak() => _dao.watchPlayedDays().map(
    (days) => _streaks.compute(
      playedDays: days,
      today: CalendarDay.fromLocal(_clock.now()),
    ),
  );
}
