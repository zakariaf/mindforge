import 'package:mindforge/core/calendar_day.dart';
import 'package:mindforge/core/run_draft.dart';
import 'package:mindforge/core/score_format.dart';

/// Builds a deterministic run set from an integer seed.
///
/// No ambient `Random()` and no locale-dependent value anywhere: the same seed
/// produces the identical `List<RunDraft>` on every device and under every
/// locale, which is the golden-vector rule applied at the only place this epic
/// generates anything.
List<RunDraft> seededDrafts({
  required int seed,
  required int count,
  String gameId = 'stroop_rush',
  String difficultyId = 'classic',
  ScoreFormat format = ScoreFormat.points,
  int firstDaySerial = 20680,
}) {
  var state = (seed * 2654435761) % 2147483647;
  int next(int bound) {
    state = (state * 1103515245 + 12345) % 2147483647;
    return state % bound;
  }

  return List<RunDraft>.generate(count, (i) {
    final correct = next(50);
    final wrong = next(10);
    return RunDraft(
      gameId: gameId,
      difficultyId: difficultyId,
      clientRunKey: 'seed$seed-run$i',
      startedAtUtcMs: 1755600000000 + i * 3600000,
      playedOnDay: CalendarDay.fromSerial(firstDaySerial + i),
      durationMs: 30000 + next(120000),
      format: format,
      metricValue: next(2000),
      correctCount: correct,
      wrongCount: wrong,
      // Never more than correctCount — the schema CHECK enforces it, and a
      // fixture that violated it would fail as a constraint error rather than
      // as the thing under test.
      longestCombo: correct == 0 ? 0 : next(correct + 1),
      totalReactionMs: (correct + wrong) * (300 + next(800)),
    );
  });
}
