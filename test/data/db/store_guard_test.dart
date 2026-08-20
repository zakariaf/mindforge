import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/core/calendar_day.dart';
import 'package:mindforge/core/result.dart';
import 'package:mindforge/core/run_commit.dart';
import 'package:mindforge/core/run_draft.dart';
import 'package:mindforge/core/score_format.dart';
import 'package:mindforge/data/data_failure.dart';
import 'package:mindforge/data/db/app_database.dart';
import 'package:mindforge/data/db/connection.dart';

import '../../support/test_repositories.dart';

/// The regression test for a bug that passed every other test in this suite.
///
/// Production opens the store through `NativeDatabase.createInBackground`,
/// which runs it in a drift isolate; the rest of the suite opens
/// `NativeDatabase.memory()` directly, which has no isolate hop. A repository
/// catching only `SqliteException` therefore converted nothing in the shipped
/// app while every in-memory test went green.
///
/// So this file opens the database **the way the app does** and asserts the
/// typed failures actually arrive.
void main() {
  late Directory directory;
  late AppDatabase db;

  setUp(() {
    directory = Directory.systemTemp.createTempSync('mindforge-guard');
    db = AppDatabase(
      NativeDatabase.createInBackground(
        File('${directory.path}/mindforge.sqlite'),
        setup: applyConnectionPragmas,
      ),
    );
    addTearDown(() => directory.deleteSync(recursive: true));
    addTearDown(db.close);
  });

  RunDraft draft({String key = 'key-1', int longestCombo = 11}) => RunDraft(
    gameId: 'stroop_rush',
    difficultyId: 'classic',
    clientRunKey: key,
    startedAtUtcMs: 1755600000000,
    playedOnDay: const CalendarDay.fromSerial(20685),
    durationMs: 90000,
    format: ScoreFormat.points,
    metricValue: 1480,
    correctCount: 46,
    wrongCount: 4,
    longestCombo: longestCombo,
    totalReactionMs: 32000,
  );

  test(
    'drift wraps a constraint violation, and the cause survives typed',
    () async {
      // The measurement the guard rests on. If remoteCause ever stopped being a
      // real SqliteException, unwrapping it would buy nothing and this test is
      // where that shows up.
      Object? caught;
      try {
        await db.customStatement(
          'INSERT INTO runs (id, created_at_utc_ms, updated_at_utc_ms, '
          'row_revision, is_deleted, game_id, difficulty_id, client_run_key, '
          'started_at_utc_ms, played_on_day, duration_ms, metric_kind, '
          'metric_value, correct_count, wrong_count, longest_combo, '
          "total_reaction_ms) VALUES ('a', 1, 1, 1, 0, 'stroop_rush', "
          "'classic', 'k', 1, 1, 1, 'points', 1, 5, 0, 6, 0)",
        );
      } on Object catch (error) {
        caught = error;
      }

      expect(caught, isNotNull, reason: 'the CHECK must reject this row');
      expect(
        caught.toString(),
        contains('CHECK constraint failed: longest_combo <= correct_count'),
      );
    },
  );

  test('a constraint violation still becomes ConstraintViolated', () async {
    final result = await testRunRepository(
      db,
    ).saveRun(draft(longestCombo: 99));

    expect(
      result,
      isA<Err<RunCommit, DataFailure>>(),
      reason:
          'this is the assertion that was green for the wrong reason: the '
          'in-memory suite never crossed an isolate, so a catch on '
          'SqliteException alone appeared to work',
    );
    expect(
      (result as Err<RunCommit, DataFailure>).failure,
      isA<ConstraintViolated>(),
    );
  });

  test('a duplicate client key still becomes RunAlreadyRecorded', () async {
    final repository = testRunRepository(db);

    expect(
      await repository.saveRun(draft()),
      isA<Ok<RunCommit, DataFailure>>(),
    );

    expect(
      await repository.saveRun(draft()),
      const Err<RunCommit, DataFailure>(RunAlreadyRecorded('key-1')),
      reason:
          'the engine replays a save it could not confirm; without the '
          'unwrap this crashed into the global error net instead of telling '
          'the caller the first attempt landed',
    );
  });

  test(
    'a missing settings row degrades rather than taking down bootstrap',
    () async {
      // Seeding runs only under wasCreated, so a restored file or a partially
      // applied migration can leave the row absent. drift's getSingle() throws a
      // StateError for that, which is neither a SqliteException nor something
      // bootstrap() can survive.
      await db.customStatement("DELETE FROM settings WHERE id = 'app'");

      final result = await testSettingsRepository(db).read();

      expect(result, isA<Err<Object?, DataFailure>>());
      expect(
        (result as Err<Object?, DataFailure>).failure,
        isA<StoreUnavailable>(),
      );
    },
  );
}
