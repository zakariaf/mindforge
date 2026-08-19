import 'package:clock/clock.dart';
import 'package:mindforge/core/game_stats.dart';
import 'package:mindforge/core/result.dart';
import 'package:mindforge/core/run_commit.dart';
import 'package:mindforge/core/run_draft.dart';
import 'package:mindforge/core/run_metric.dart';
import 'package:mindforge/core/run_scope.dart';
import 'package:mindforge/core/score_format.dart';
import 'package:mindforge/data/daos/runs_dao.dart';
import 'package:mindforge/data/data_failure.dart';
import 'package:mindforge/data/db/app_database.dart';
import 'package:mindforge/data/repositories/run_repository.dart';
import 'package:test/test.dart';

import '../../support/fake_id_generator.dart';
import '../../support/fake_log_sink.dart';
import '../../support/run_fixtures.dart';
import '../../support/test_database.dart';

const _kRegisteredGames = <String>{'stroop_rush', 'schulte_grid', 'quiet_game'};

void main() {
  late AppDatabase db;
  late RunRepository repository;

  setUp(() {
    db = openTestDatabase();
    repository = RunRepository(
      database: db,
      dao: RunsDao(db),
      clock: Clock.fixed(kTestNow),
      idGenerator: FakeIdGenerator(),
      logSink: FakeLogSink(),
      isRegisteredGameId: _kRegisteredGames.contains,
    );
    addTearDown(db.close);
  });

  Future<void> saveAll(List<RunDraft> drafts) async {
    for (final draft in drafts) {
      final result = await repository.saveRun(draft);
      expect(result, isA<Ok<RunCommit, DataFailure>>(), reason: '$result');
    }
  }

  Future<RunMetric?> bestOf(RunScope scope) async {
    final result = await repository.watchPersonalBest(scope).first;
    expect(result, isA<Ok<RunMetric?, DataFailure>>(), reason: '$result');
    return (result as Ok<RunMetric?, DataFailure>).value;
  }

  group('personal best', () {
    test('for points it is the MAX', () async {
      await saveAll(
        seededDrafts(seed: 1, count: 12)..addAll(
          seededDrafts(seed: 99, count: 1).map(
            (d) => RunDraft(
              gameId: d.gameId,
              difficultyId: d.difficultyId,
              clientRunKey: 'peak',
              startedAtUtcMs: d.startedAtUtcMs,
              playedOnDay: d.playedOnDay,
              durationMs: d.durationMs,
              format: ScoreFormat.points,
              metricValue: 9999,
              correctCount: d.correctCount,
              wrongCount: d.wrongCount,
              longestCombo: d.longestCombo,
              totalReactionMs: d.totalReactionMs,
            ),
          ),
        ),
      );

      expect(
        (await bestOf(const RunScope('stroop_rush', 'classic')))?.value,
        9999,
      );
    });

    test('for duration it is the MIN', () async {
      await saveAll(
        seededDrafts(
          seed: 2,
          count: 8,
          gameId: 'schulte_grid',
          format: ScoreFormat.duration,
        ),
      );

      final best = await bestOf(const RunScope('schulte_grid', 'classic'));
      final all = await repository
          .watchChartSeries(
            const RunScope('schulte_grid', 'classic'),
            count: 50,
          )
          .first;

      expect(
        best?.value,
        all.map((r) => r.metricValue).reduce((a, b) => a < b ? a : b),
        reason: 'lower wins for a duration score',
      );
    });

    test('an empty scope is null, not zero', () async {
      expect(
        await bestOf(const RunScope('stroop_rush', 'classic')),
        isNull,
        reason:
            'a zero would render as a real BEST pill for someone who has '
            'never played',
      );
    });

    test('a scope holding two formats surfaces CorruptRow', () async {
      await saveAll(seededDrafts(seed: 3, count: 2, gameId: 'quiet_game'));
      await saveAll(
        seededDrafts(
              seed: 4,
              count: 2,
              gameId: 'quiet_game',
              format: ScoreFormat.duration,
            )
            .map(
              (d) => RunDraft(
                gameId: d.gameId,
                difficultyId: d.difficultyId,
                clientRunKey: 'mixed-${d.clientRunKey}',
                startedAtUtcMs: d.startedAtUtcMs,
                playedOnDay: d.playedOnDay,
                durationMs: d.durationMs,
                format: d.format,
                metricValue: d.metricValue,
                correctCount: d.correctCount,
                wrongCount: d.wrongCount,
                longestCombo: d.longestCombo,
                totalReactionMs: d.totalReactionMs,
              ),
            )
            .toList(),
      );

      final result = await repository
          .watchPersonalBest(const RunScope('quiet_game'))
          .first;

      expect(
        result,
        isA<Err<RunMetric?, DataFailure>>(),
        reason:
            'comparing points against milliseconds must be reported, not '
            'silently ranked',
      );
    });
  });

  group('watchBestsByGame', () {
    test('returns one entry per game that has any run', () async {
      await saveAll(seededDrafts(seed: 5, count: 3));
      await saveAll(
        seededDrafts(
          seed: 6,
          count: 2,
          gameId: 'schulte_grid',
          format: ScoreFormat.duration,
        ),
      );

      final bests = await repository.watchBestsByGame().first;

      expect(bests.keys.toSet(), {'stroop_rush', 'schulte_grid'});
      expect(
        bests.containsKey('quiet_game'),
        isFalse,
        reason:
            'a game with no runs has no entry; the caller renders no BEST '
            'pill rather than a zero',
      );
    });
  });

  group('aggregates', () {
    test('gamesPlayed and timeTrainedMs match an independent oracle', () async {
      final drafts = seededDrafts(seed: 7, count: 25);
      await saveAll(drafts);

      final stats = await repository
          .watchStats(const RunScope('stroop_rush', 'classic'))
          .first;

      expect(stats.gamesPlayed, drafts.length);
      expect(
        stats.timeTrainedMs,
        drafts.fold<int>(0, (sum, d) => sum + d.durationMs),
        reason: 'summed in Dart, never by the SQL under test',
      );
    });

    test('an empty scope is the empty aggregate', () async {
      expect(
        await repository.watchStats(const RunScope('quiet_game')).first,
        const GameStats.empty(),
      );
    });

    test('accuracy stays in [0,1] and is null exactly when nothing was '
        'answered', () async {
      for (var seed = 0; seed < 40; seed++) {
        final db = openTestDatabase();
        final repo = RunRepository(
          database: db,
          dao: RunsDao(db),
          clock: Clock.fixed(kTestNow),
          idGenerator: FakeIdGenerator(),
          logSink: FakeLogSink(),
          isRegisteredGameId: _kRegisteredGames.contains,
        );

        final drafts = seededDrafts(seed: seed, count: 5);
        for (final draft in drafts) {
          expect(await repo.saveRun(draft), isA<Ok<RunCommit, DataFailure>>());
        }

        final stats = await repo
            .watchStats(const RunScope('stroop_rush', 'classic'))
            .first;
        final accuracy = stats.accuracy;

        if (stats.answeredCount == 0) {
          expect(accuracy, isNull, reason: 'seed $seed');
          expect(stats.averageReactionMs, isNull, reason: 'seed $seed');
        } else {
          expect(
            accuracy! >= 0.0 && accuracy <= 1.0,
            isTrue,
            reason: 'seed $seed gave accuracy $accuracy',
          );
        }

        await db.close();
      }
    });
  });
}
