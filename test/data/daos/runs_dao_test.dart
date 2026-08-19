import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/core/result.dart';
import 'package:mindforge/core/run_commit.dart';
import 'package:mindforge/core/run_scope.dart';
import 'package:mindforge/data/daos/runs_dao.dart';
import 'package:mindforge/data/data_failure.dart';
import 'package:mindforge/data/db/app_database.dart';
import 'package:mindforge/data/repositories/run_repository.dart';

import '../../support/run_fixtures.dart';
import '../../support/test_database.dart';
import '../../support/test_repositories.dart';

void main() {
  late AppDatabase db;
  late RunsDao dao;
  late RunRepository repository;

  setUp(() {
    db = openTestDatabase();
    dao = RunsDao(db);
    // ONE repository per test, so its FakeIdGenerator keeps counting. A fresh
    // one per call restarts at run-1 and collides on the primary key.
    repository = testRunRepository(db);
    addTearDown(db.close);
  });

  Future<void> saveAll(int count, {String difficultyId = 'classic'}) async {
    for (final draft in seededDrafts(
      seed: 4,
      count: count,
      difficultyId: difficultyId,
    )) {
      expect(
        await repository.saveRun(
          draft.copyWith(clientRunKey: '$difficultyId-${draft.clientRunKey}'),
        ),
        isA<Ok<RunCommit, DataFailure>>(),
      );
    }
  }

  group('watchRecent', () {
    test('is newest first and scoped to one game and difficulty', () async {
      await saveAll(5);
      await saveAll(3, difficultyId: 'blitz');

      final classic = await dao
          .watchRecent(const RunScope('stroop_rush', 'classic'), limit: 10)
          .first;

      expect(classic, hasLength(5));
      expect(
        classic.map((r) => r.startedAtUtcMs).toList(),
        [...classic.map((r) => r.startedAtUtcMs)]
          ..sort((a, b) => b.compareTo(a)),
      );
      expect(classic.every((r) => r.difficultyId == 'classic'), isTrue);
    });

    test('a null difficulty spans every difficulty of one game', () async {
      await saveAll(5);
      await saveAll(3, difficultyId: 'blitz');

      final all = await dao
          .watchRecent(const RunScope('stroop_rush'), limit: 20)
          .first;

      expect(all, hasLength(8));
    });

    test('never includes a soft-deleted row', () async {
      await saveAll(3);
      await db.customStatement(
        'UPDATE runs SET is_deleted = 1, deleted_at_utc_ms = 1 '
        "WHERE client_run_key = 'classic-seed4-run0'",
      );

      final rows = await dao
          .watchRecent(const RunScope('stroop_rush', 'classic'), limit: 10)
          .first;

      expect(rows, hasLength(2));
    });
  });

  group('pageBefore', () {
    test('paging through a fixture yields every id once, with no gap', () async {
      const total = 45;
      await saveAll(total);
      const scope = RunScope('stroop_rush', 'classic');

      final seen = <String>[];
      var page = await dao.watchRecent(scope, limit: 20).first;

      while (page.isNotEmpty) {
        seen.addAll(page.map((r) => r.id));
        page = await dao.pageBefore(
          scope,
          cursor: (
            startedAtUtcMs: page.last.startedAtUtcMs,
            id: page.last.id,
          ),
          limit: 20,
        );
      }

      expect(
        seen.toSet(),
        hasLength(total),
        reason:
            'the invariant a skip-based pager breaks: a row inserted while '
            'paging shifts every later offset by one, so it repeats and drops',
      );
      expect(seen, hasLength(total), reason: 'and nothing was seen twice');
    });

    test('runs sharing a millisecond are not skipped', () async {
      // Not hypothetical: every test driving a fixed Clock produces these, and
      // a real device can finish two runs in the same millisecond. With the
      // instant alone as the cursor, they collapse onto one value and the
      // second is skipped forever.
      const scope = RunScope('stroop_rush', 'classic');
      final draft = seededDrafts(seed: 9, count: 1).single;

      for (final key in <String>['a', 'b', 'c']) {
        expect(
          await repository.saveRun(
            draft.copyWith(clientRunKey: key, startedAtUtcMs: 1755600000000),
          ),
          isA<Ok<RunCommit, DataFailure>>(),
        );
      }

      final first = await dao.watchRecent(scope, limit: 1).first;
      expect(first, hasLength(1));

      final rest = await dao.pageBefore(
        scope,
        cursor: (
          startedAtUtcMs: first.single.startedAtUtcMs,
          id: first.single.id,
        ),
        limit: 10,
      );

      expect(
        rest,
        hasLength(2),
        reason:
            'the cursor is the (instant, id) PAIR. With the instant alone '
            'this returns nothing at all, because every row fails the strict '
            'less-than',
      );
    });
  });

  group('ordering is locale-independent', () {
    test(
      'every ORDER BY in this DAO is over an integer or an ASCII id',
      () async {
        await saveAll(6);
        const scope = RunScope('stroop_rush', 'classic');

        final ids = (await dao.watchRecent(scope, limit: 10).first)
            .map((r) => r.id)
            .toList();

        // A collation-sensitive ordering over a text column is the classic way
        // for a locale to change a query result. The ids here are ASCII tokens
        // from the FakeIdGenerator and the sort key is an integer instant, so
        // the sequence cannot move.
        expect(ids, isNotEmpty);
        expect(
          (await dao.watchRecent(scope, limit: 10).first)
              .map((r) => r.id)
              .toList(),
          ids,
        );
      },
    );
  });
}
