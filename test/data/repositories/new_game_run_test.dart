import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/core/calendar_day.dart';
import 'package:mindforge/core/game_id.dart';
import 'package:mindforge/core/result.dart';
import 'package:mindforge/core/run_commit.dart';
import 'package:mindforge/core/run_draft.dart';
import 'package:mindforge/core/run_metric.dart';
import 'package:mindforge/core/run_scope.dart';
import 'package:mindforge/core/score_format.dart';
import 'package:mindforge/data/data_failure.dart';
import 'package:mindforge/data/db/app_database.dart';
import 'package:mindforge/data/repositories/run_repository.dart';

import '../../support/fake_id_generator.dart';
import '../../support/fake_log_sink.dart';
import '../../support/test_database.dart';
import '../../support/test_repositories.dart';

/// A run of each new game survives the repository and comes back.
///
/// **This is the test that would have failed on the negative score**, which is
/// why it exists rather than being covered by the notifier tests. The `runs`
/// table carries `CHECK (metric_value >= 0)` and
/// `CHECK (longest_combo <= correct_count)`; a draft breaking either is refused
/// by SQLite, classified as `ConstraintViolated`, and — because nothing in the
/// UI reads `saveFailure` — leaves the player looking at an ordinary results
/// screen for a run that left no row, never reached Stats and never became a
/// BEST.
///
/// E12 asked whether False Light could score negatively. The seam answered:
/// render and rank can, persistence cannot. This asserts the decision that
/// followed rather than assuming it.
void main() {
  late AppDatabase db;
  late RunRepository repository;

  setUp(() {
    db = openTestDatabase();
    repository = testRunRepository(
      db,
      now: kTestNow,
      idGenerator: FakeIdGenerator(),
      logSink: FakeLogSink(),
    );
    addTearDown(db.close);
  });

  RunDraft draftFor(String gameId, {required int metricValue}) => RunDraft(
    gameId: gameId,
    difficultyId: 'classic',
    clientRunKey: '$gameId-key',
    startedAtUtcMs: 1755600000000,
    playedOnDay: const CalendarDay.fromSerial(20685),
    durationMs: 60000,
    format: ScoreFormat.points,
    metricValue: metricValue,
    correctCount: 14,
    wrongCount: 3,
    // At or below correctCount, which the sibling CHECK requires.
    longestCombo: 6,
    totalReactionMs: 21000,
  );

  for (final (gameId, score) in <(String, int)>[
    ('digit_bridge', 2050),
    ('false_light', 1725),
  ]) {
    test('$gameId saves, and reads back as a BEST', () async {
      final result = await repository.saveRun(
        draftFor(gameId, metricValue: score),
      );

      expect(
        result,
        isA<Ok<RunCommit, DataFailure>>(),
        reason: 'a $gameId run was refused by the repository: $result',
      );

      // READ BACK THROUGH THE WATCHED STREAM, which is the only read path --
      // the repository publishes rather than returning, so a save that landed
      // but never republished would look identical to one that failed.
      final best = await repository
          .watchPersonalBest(RunScope.of(GameId(gameId), null))
          .first;

      expect(best, isA<Ok<RunMetric?, DataFailure>>());
      expect(
        (best as Ok<RunMetric?, DataFailure>).value?.value,
        score,
        reason: 'the run saved but did not become a BEST',
      );
    });
  }

  test(
    'and a negative points total is refused, which is why none is dealt',
    () {
      // The constraint, asserted rather than described. If this ever starts
      // passing, the persistence epic happened and False Light may reconsider
      // charging points for a wrong sweep.
      expect(
        () async {
          final result = await repository.saveRun(
            draftFor('false_light', metricValue: -7),
          );

          expect(result, isA<Err<RunCommit, DataFailure>>());
        },
        returnsNormally,
      );
    },
  );
}
