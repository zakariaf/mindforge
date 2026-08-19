import 'package:mindforge/core/calendar_day.dart';
import 'package:mindforge/core/run_record.dart';
import 'package:mindforge/core/score_format.dart';
import 'package:test/test.dart';

RunRecord _record({
  String id = 'run-1',
  int correctCount = 46,
  int wrongCount = 4,
  int totalReactionMs = 32000,
  int metricValue = 1480,
}) => RunRecord(
  id: id,
  gameId: 'stroop_rush',
  difficultyId: 'classic',
  clientRunKey: 'key-$id',
  startedAtUtcMs: 1755600000000,
  playedOnDay: const CalendarDay.fromSerial(20685),
  durationMs: 90000,
  format: ScoreFormat.points,
  metricValue: metricValue,
  correctCount: correctCount,
  wrongCount: wrongCount,
  longestCombo: 11,
  totalReactionMs: totalReactionMs,
  createdAtUtcMs: 1755600090000,
);

void main() {
  group('RunRecord', () {
    test('accuracy of 46 correct and 4 wrong is 0.92', () {
      expect(_record().accuracy, 0.92);
    });

    test('accuracy with nothing answered is null, not NaN', () {
      final record = _record(correctCount: 0, wrongCount: 0);

      expect(
        record.accuracy,
        isNull,
        reason:
            '0/0 is NaN, which renders as "NaN%" and compares false to '
            'itself. Absence must be absence',
      );
    });

    test('averageReaction is the total over the answered count', () {
      expect(
        _record().averageReaction,
        const Duration(milliseconds: 640),
        reason:
            '32000ms over 50 answered. The sum is stored and the average '
            'is derived, so no rounded double ever reaches a column',
      );
    });

    test('averageReaction with nothing answered is null', () {
      expect(_record(correctCount: 0, wrongCount: 0).averageReaction, isNull);
    });

    test('equality is identity on id', () {
      // Explicit stable identity: the same run read twice, once before and once
      // after a derived field changed shape, is still the same run.
      expect(_record(), _record(metricValue: 10));
      expect(_record().hashCode, _record(metricValue: 10).hashCode);
      expect(_record(), isNot(_record(id: 'run-2')));
    });
  });
}
