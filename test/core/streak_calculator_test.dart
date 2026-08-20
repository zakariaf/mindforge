import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/core/calendar_day.dart';
import 'package:mindforge/core/streak_calculator.dart';
import 'package:mindforge/core/streak_status.dart';

const _calculator = StreakCalculator();

List<CalendarDay> _days(List<int> serials) =>
    serials.map(CalendarDay.fromSerial).toList();

void main() {
  const today = CalendarDay.fromSerial(100);

  group('StreakCalculator', () {
    test('four consecutive days ending today give a streak of four', () {
      final status = _calculator.compute(
        playedDays: _days([100, 99, 98, 97]),
        today: today,
      );

      expect(
        status.currentDays,
        4,
        reason: 'the quantity behind the "4 day streak" chip on 01-home.png',
      );
      expect(status.isActiveToday, isTrue);
      expect(status.longestDays, 4);
    });

    test('a streak survives the day after its last run', () {
      final status = _calculator.compute(
        playedDays: _days([100, 99, 98, 97]),
        today: const CalendarDay.fromSerial(101),
      );

      expect(status.currentDays, 4);
      expect(
        status.isActiveToday,
        isFalse,
        reason:
            'nothing has been lost yet — the player simply has not opened '
            'the app today',
      );
    });

    test('it breaks the day after that, but the record stands', () {
      final status = _calculator.compute(
        playedDays: _days([100, 99, 98, 97]),
        today: const CalendarDay.fromSerial(102),
      );

      expect(status.currentDays, 0);
      expect(status.longestDays, 4);
      expect(status.isActiveToday, isFalse);
    });

    test('two runs on the same day count once', () {
      final status = _calculator.compute(
        playedDays: _days([100, 100, 99]),
        today: today,
      );

      expect(status.currentDays, 2);
    });

    test('an empty history is zero, never null and never a throw', () {
      final status = _calculator.compute(playedDays: const [], today: today);

      expect(status, const StreakStatus.empty());
    });

    test('the longest streak is found even when it is not the current one', () {
      final status = _calculator.compute(
        // A five-day run long ago, a two-day run ending today.
        playedDays: _days([50, 51, 52, 53, 54, 99, 100]),
        today: today,
      );

      expect(status.currentDays, 2);
      expect(status.longestDays, 5);
    });

    test('current <= longest <= distinct day count, over 500 seeds', () {
      for (var seed = 0; seed < 500; seed++) {
        // A deterministic pseudo-random day set. No ambient Random(): a failure
        // must be reproducible from the seed printed in the reason.
        var state = seed * 2654435761 % 2147483647;
        int next(int bound) {
          state = (state * 1103515245 + 12345) % 2147483647;
          return state % bound;
        }

        final serials = List<int>.generate(next(20) + 1, (_) => 80 + next(25));
        final status = _calculator.compute(
          playedDays: _days(serials),
          today: today,
        );

        final distinct = serials.toSet().length;
        expect(
          status.currentDays <= status.longestDays &&
              status.longestDays <= distinct,
          isTrue,
          reason: 'seed $seed, days $serials -> $status (distinct $distinct)',
        );
      }
    });
  });
}
