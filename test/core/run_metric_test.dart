import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/core/run_metric.dart';
import 'package:mindforge/core/score_format.dart';

void main() {
  group('RunMetric', () {
    test('for points, higher is better', () {
      expect(
        const RunMetric.points(1480).isBetterThan(const RunMetric.points(1310)),
        const BetterThan(isBetter: true),
      );
      expect(
        const RunMetric.points(1310).isBetterThan(const RunMetric.points(1480)),
        const BetterThan(isBetter: false),
      );
    });

    test('for duration, lower is better', () {
      expect(
        const RunMetric.duration(
          18600,
        ).isBetterThan(const RunMetric.duration(21400)),
        const BetterThan(isBetter: true),
      );
      expect(
        const RunMetric.duration(
          21400,
        ).isBetterThan(const RunMetric.duration(18600)),
        const BetterThan(isBetter: false),
      );
    });

    test('comparing two different formats returns a value, never a throw', () {
      final outcome = const RunMetric.points(
        1480,
      ).isBetterThan(const RunMetric.duration(18600));

      expect(outcome, isA<ScoreFormatMismatch>());
      expect(
        (outcome as ScoreFormatMismatch).left,
        ScoreFormat.points,
      );
      expect(outcome.right, ScoreFormat.duration);
    });

    test('the comparison outcome switches exhaustively with no default', () {
      final outcome = const RunMetric.points(
        1,
      ).isBetterThan(const RunMetric.points(0));

      final described = switch (outcome) {
        BetterThan(isBetter: final b) => 'better=$b',
        ScoreFormatMismatch() => 'mismatch',
      };

      expect(described, 'better=true');
    });

    test('RunMetric declares no formatter and no display string', () {
      // Asserted over the source rather than by reflection: dart:mirrors is
      // unavailable in Flutter, and the property being protected is a source
      // property anyway — nobody may ADD a formatter here.
      final source = File('lib/core/run_metric.dart').readAsStringSync();

      for (final banned in <String>[
        'NumberFormat',
        'toStringAsFixed',
        'package:intl',
        'String format',
      ]) {
        expect(
          source.contains(banned),
          isFalse,
          reason:
              'formatting a metric is E04 LocaleNumbers job. A formatter '
              'here would render 1480 as 1,480 in en and 1.480 in de, inside '
              r'a layer that must stay locale-independent. Found: $banned',
        );
      }
    });
  });
}
