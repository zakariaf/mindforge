import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/core/calendar_day.dart';
import 'package:mindforge/core/result.dart';
import 'package:mindforge/core/run_commit.dart';
import 'package:mindforge/core/run_draft.dart';
import 'package:mindforge/core/run_scope.dart';
import 'package:mindforge/core/score_format.dart';
import 'package:mindforge/data/data_failure.dart';
import 'package:mindforge/data/db/app_database.dart';
import 'package:mindforge/data/repositories/run_repository.dart';

import '../../support/fake_id_generator.dart';
import '../../support/fake_log_sink.dart';
import '../../support/test_database.dart';
import '../../support/test_repositories.dart';

RunDraft _draft({
  String clientRunKey = 'key-1',
  String gameId = 'stroop_rush',
  String difficultyId = 'classic',
  ScoreFormat format = ScoreFormat.points,
  int metricValue = 1480,
  int correctCount = 46,
  int longestCombo = 11,
  int daySerial = 20685,
}) => RunDraft(
  gameId: gameId,
  difficultyId: difficultyId,
  clientRunKey: clientRunKey,
  startedAtUtcMs: 1755600000000,
  playedOnDay: CalendarDay.fromSerial(daySerial),
  durationMs: 90000,
  format: format,
  metricValue: metricValue,
  correctCount: correctCount,
  wrongCount: 4,
  longestCombo: longestCombo,
  totalReactionMs: 32000,
);

void main() {
  late AppDatabase db;
  late RunRepository repository;
  late FakeIdGenerator ids;
  late FakeLogSink logSink;

  setUp(() {
    db = openTestDatabase();
    ids = FakeIdGenerator();
    logSink = FakeLogSink();
    repository = testRunRepository(
      db,
      now: kTestNow,
      idGenerator: ids,
      logSink: logSink,
    );
    addTearDown(db.close);
  });

  Future<RunCommit> save(RunDraft draft) async {
    final result = await repository.saveRun(draft);
    expect(
      result,
      isA<Ok<RunCommit, DataFailure>>(),
      reason: 'expected a successful save, got $result',
    );
    return (result as Ok<RunCommit, DataFailure>).value;
  }

  group('saveRun', () {
    test('stamps id from the IdGenerator and time from the Clock', () async {
      final commit = await save(_draft());

      expect(commit.record.id, 'run-1');
      expect(commit.record.createdAtUtcMs, kTestNow.millisecondsSinceEpoch);
    });

    test('resolves only after the row is durable', () async {
      await save(_draft());

      final row = await db
          .customSelect('SELECT COUNT(*) AS c FROM runs')
          .getSingle();
      expect(row.data['c'], 1);
    });

    test('watchRecent emits the new run with no manual republish', () async {
      const scope = RunScope('stroop_rush', 'classic');
      final emissions = <int>[];
      final subscription = repository
          .watchChartSeries(scope)
          .listen((runs) => emissions.add(runs.length));
      addTearDown(subscription.cancel);

      await pumpEventQueue();
      await save(_draft());
      await pumpEventQueue();

      expect(emissions, [0, 1]);
    });
  });

  group('isPersonalBest', () {
    test('is true for the first run in a scope', () async {
      final commit = await save(_draft());

      expect(
        commit.isPersonalBest,
        isTrue,
        reason:
            'the case a naive `value > currentBest` against a null best '
            'gets wrong',
      );
    });

    test('for points, a higher score wins and a lower one does not', () async {
      await save(_draft());

      expect(
        (await save(
          _draft(clientRunKey: 'key-2', metricValue: 1600),
        )).isPersonalBest,
        isTrue,
      );
      expect(
        (await save(
          _draft(clientRunKey: 'key-3', metricValue: 1200),
        )).isPersonalBest,
        isFalse,
      );
    });

    test('for duration, a lower time wins and a higher one does not', () async {
      RunDraft timed(String key, int ms) => _draft(
        clientRunKey: key,
        gameId: 'schulte_grid',
        format: ScoreFormat.duration,
        metricValue: ms,
      );

      await save(timed('t-1', 21400));

      expect((await save(timed('t-2', 18600))).isPersonalBest, isTrue);
      expect((await save(timed('t-3', 25000))).isPersonalBest, isFalse);
    });

    test(
      'agrees with a post-commit read for every row in a 200-run fixture',
      () async {
        // A guard that read the best OUTSIDE the transaction would disagree on at
        // least one row here, because each save changes what the next one is
        // compared against.
        var best = 0;
        for (var i = 0; i < 200; i++) {
          final value = (i * 37) % 500;
          final commit = await save(
            _draft(clientRunKey: 'fixture-$i', metricValue: value),
          );

          expect(
            commit.isPersonalBest,
            i == 0 || value > best,
            reason: 'run $i scored $value against a running best of $best',
          );
          if (value > best) best = value;
        }
      },
    );
  });

  group('idempotency', () {
    test('the same clientRunKey twice returns RunAlreadyRecorded', () async {
      await save(_draft());

      final second = await repository.saveRun(_draft());

      expect(
        second,
        const Err<RunCommit, DataFailure>(RunAlreadyRecorded('key-1')),
      );
    });

    test('the first row is left completely untouched', () async {
      await save(_draft());
      final before =
          (await db.customSelect('SELECT * FROM runs').getSingle()).data;

      expect(
        await repository.saveRun(_draft()),
        const Err<RunCommit, DataFailure>(RunAlreadyRecorded('key-1')),
      );

      final after = await db.customSelect('SELECT * FROM runs').get();
      expect(after, hasLength(1));
      expect(
        after.single.data,
        before,
        reason:
            'a retried write must not bump row_revision or updated_at — '
            'that is the other half of the idempotency guarantee',
      );
    });
  });

  group('rejection', () {
    test('a constraint violation returns Err and changes nothing', () async {
      await save(_draft());
      final before = (await db.customSelect('SELECT * FROM runs').get())
          .map((r) => r.data)
          .toList();

      final result = await repository.saveRun(
        _draft(clientRunKey: 'key-2', correctCount: 5, longestCombo: 6),
      );

      expect(result, isA<Err<RunCommit, DataFailure>>());
      expect(
        (await db.customSelect('SELECT * FROM runs').get())
            .map((r) => r.data)
            .toList(),
        before,
        reason: 'the table is byte-identical afterwards',
      );
    });

    test('an unregistered gameId is rejected before any SQL runs', () async {
      final result = await repository.saveRun(_draft(gameId: 'not_a_game'));

      expect(result, const Err<RunCommit, DataFailure>(NotFound('not_a_game')));
      expect(ids.mintedCount, 0, reason: 'no id was minted, so nothing ran');
    });

    test(
      'a display string where a token belongs hits the same guard',
      () async {
        for (final name in <String>['Stroop Rush', 'ستروپ']) {
          final result = await repository.saveRun(_draft(gameId: name));

          expect(
            result,
            Err<RunCommit, DataFailure>(NotFound(name)),
            reason:
                'the ASCII CHECK in the schema is the BACKSTOP, not the '
                'first line of defence',
          );
        }
      },
    );

    test('the result switches exhaustively with no default', () async {
      final result = await repository.saveRun(_draft());

      final described = switch (result) {
        Ok<RunCommit, DataFailure>(:final value) => 'ok ${value.record.id}',
        Err<RunCommit, DataFailure>(:final failure) => 'err ${failure.code}',
      };

      expect(described, 'ok run-1');
    });
  });
}
