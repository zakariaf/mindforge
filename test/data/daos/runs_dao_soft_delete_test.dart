import 'dart:io';

import 'package:drift/drift.dart' show Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/core/result.dart';
import 'package:mindforge/core/run_commit.dart';
import 'package:mindforge/core/run_scope.dart';
import 'package:mindforge/data/daos/runs_dao.dart';
import 'package:mindforge/data/data_failure.dart';
import 'package:mindforge/data/db/app_database.dart';

import '../../support/run_fixtures.dart';
import '../../support/test_database.dart';
import '../../support/test_repositories.dart';

/// Replaces `check-softdelete-parity.sh`, which is skipped for this codebase.
///
/// That script selects candidate files by grepping for `stat`, which is a
/// substring of `static`, and then matches a guarded table name at a word
/// boundary — and MindForge's one soft-deleted table is named `runs`, an
/// extremely common English verb. Between them it fired on doc comments in the
/// theme layer and never looked at a query.
///
/// The contract it was meant to enforce is asserted here directly, and more
/// strictly: **no read of `runs` may forget `is_deleted = 0`**, because there
/// is exactly one base query and every read composes it.
void main() {
  group('the shared active-only base query', () {
    test('every select in RunsDao composes _liveRuns()', () {
      final source = File('lib/data/daos/runs_dao.dart').readAsStringSync();

      // A `select(runs)` that is not the one inside _liveRuns() is a read that
      // can forget the filter.
      final directSelects = RegExp(
        r'select\(runs\)',
      ).allMatches(source).length;

      expect(
        directSelects,
        1,
        reason:
            'there must be exactly one select(runs) in this file — the one '
            'inside _liveRuns(). Found $directSelects',
      );

      // selectOnly() is the aggregate path and cannot compose _liveRuns(), so
      // each occurrence must carry the filter inline.
      final aggregateSelects = RegExp(
        r'selectOnly\(runs[,)]',
      ).allMatches(source).length;
      final inlineFilters = RegExp(
        r'runs\.isDeleted\.equals\(0\)',
      ).allMatches(source).length;

      expect(
        inlineFilters,
        aggregateSelects,
        reason:
            'every selectOnly(runs) must carry runs.isDeleted.equals(0). '
            '$aggregateSelects aggregates, $inlineFilters filters',
      );
    });
  });

  group('a soft-deleted run disappears from every read', () {
    late AppDatabase db;
    late RunsDao dao;
    late String deletedId;
    late int deletedValue;

    setUp(() async {
      db = openTestDatabase();
      dao = RunsDao(db);
      addTearDown(db.close);

      final repository = testRunRepository(db);
      for (final draft in seededDrafts(seed: 31, count: 4)) {
        expect(
          await repository.saveRun(draft),
          isA<Ok<RunCommit, DataFailure>>(),
        );
      }
      // The run holding the MAXIMUM score, not an arbitrary one. Deleting a
      // middling run leaves MAX(metric_value) unchanged whether or not the
      // filter is present, so the best-score assertion below would pass over a
      // DAO that had forgotten it entirely — and that test is the stated
      // justification for skipping check-softdelete-parity.sh.
      final best = await db
          .customSelect(
            'SELECT id AS i FROM runs ORDER BY metric_value DESC LIMIT 1',
          )
          .getSingle();
      deletedId = best.data['i']! as String;

      final row = await db
          .customSelect(
            'SELECT metric_value AS v FROM runs WHERE id = ?',
            variables: [Variable<String>(deletedId)],
          )
          .getSingle();
      deletedValue = row.data['v']! as int;

      await db.customStatement(
        'UPDATE runs SET is_deleted = 1, deleted_at_utc_ms = 1 WHERE id = ?',
        [deletedId],
      );
    });

    const scope = RunScope('stroop_rush', 'classic');

    test('the recent list', () async {
      expect(await dao.watchRecent(scope, limit: 10).first, hasLength(3));
    });

    test('the aggregate', () async {
      expect((await dao.readAggregate(scope)).gamesPlayed, 3);
    });

    test('the personal best', () async {
      final live = await dao.watchRecent(scope, limit: 10).first;
      final best = await dao.readBest(scope);

      expect(
        best.value,
        lessThan(deletedValue),
        reason:
            'the deleted run held the maximum ($deletedValue). If the '
            'filter were missing, readBest would still return it',
      );
      expect(
        best.value,
        live.map((r) => r.metricValue).reduce((a, b) => a > b ? a : b),
        reason: 'and the best is the maximum of what remains',
      );
      expect(live.map((r) => r.id), isNot(contains(deletedId)));
    });

    test('the played days', () async {
      expect(await dao.watchPlayedDays().first, hasLength(3));
    });
  });
}
