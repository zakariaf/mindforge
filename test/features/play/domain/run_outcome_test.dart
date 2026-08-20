import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/features/play/domain/result_stat.dart';
import 'package:mindforge/features/play/domain/run_outcome.dart';

void main() {
  const stat = ResultStat(
    labelKey: 'statAccuracy',
    canonicalValue: 923,
    format: StatFormat.percent,
  );
  const trio = RunCompleted(
    scoreValue: 1480,
    first: stat,
    second: stat,
    third: stat,
  );

  group('a completed outcome', () {
    test('carries a score and exactly three stats', () {
      expect(trio.scoreValue, 1480);
      expect(trio.stats, hasLength(3));
    });

    test('and a fourth or a missing one does not compile', () {
      // Asserted by the TYPE, not at runtime: three named fields rather than a
      // list. There is no test that a four-stat outcome throws, because there
      // is no way to write one — which is the stronger guarantee and the reason
      // for the shape. It is also what keeps the constructor const: List.length
      // is not a constant expression.
      expect(trio.stats, <ResultStat>[stat, stat, stat]);
    });

    test('and is value-equal down to its stats', () {
      expect(
        trio,
        const RunCompleted(
          scoreValue: 1480,
          first: stat,
          second: stat,
          third: stat,
        ),
      );
      expect(
        trio,
        isNot(
          const RunCompleted(
            scoreValue: 1481,
            first: stat,
            second: stat,
            third: stat,
          ),
        ),
      );
    });
  });

  group('an abandoned outcome', () {
    test('has no score field to read', () {
      // Not "a score of zero". An abandoned run does not go on the leaderboard
      // and does not beat a personal best, and making that unrepresentable is
      // cheaper than remembering it at every call site.
      const outcome = RunOutcome.abandoned();

      expect(outcome, isA<RunAbandoned>());
      expect(outcome, const RunOutcome.abandoned());
    });
  });

  group('the family is sealed', () {
    test('so a switch is exhaustive with no wildcard', () {
      for (final outcome in <RunOutcome>[
        trio,
        const RunOutcome.abandoned(),
      ]) {
        final saved = switch (outcome) {
          RunCompleted() => true,
          RunAbandoned() => false,
        };

        expect(saved, outcome is RunCompleted);
      }
    });
  });
}
