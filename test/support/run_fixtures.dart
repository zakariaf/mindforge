import 'package:mindforge/core/calendar_day.dart';
import 'package:mindforge/core/run_draft.dart';
import 'package:mindforge/core/score_format.dart';
import 'package:mindforge/core/seeded_generator.dart';

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
  // SeededGenerator, not a second PRNG. lib/core/seeded_generator.dart states
  // that there is no other generator in this repository, and a hand-rolled LCG
  // here made that claim false — in a file whose whole job is producing
  // reproducible fixtures.
  final random = SeededGenerator(seed);
  int next(int bound) => random.nextInt(bound);

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
