import 'package:mindforge/core/calendar_day.dart';
import 'package:mindforge/core/streak_status.dart';

/// Computes the daily streak from the days a player actually played.
///
/// Pure and **total**: it holds no clock at all — `today` is a parameter — and
/// it never throws or returns null. Taking `today` rather than reading it is
/// what makes the two-container clock test in the data suite possible.
final class StreakCalculator {
  /// Creates the calculator.
  const StreakCalculator();

  /// The streak implied by [playedDays], as of [today].
  ///
  /// [playedDays] may contain duplicates and may be in any order; only the set
  /// of distinct days matters.
  ///
  /// A streak **survives the day after its last run** and breaks on the day
  /// after that: playing on Monday leaves Tuesday still showing the streak and
  /// Wednesday showing zero. That is deliberate — a player who has not opened
  /// the app yet today has not lost anything yet.
  StreakStatus compute({
    required List<CalendarDay> playedDays,
    required CalendarDay today,
  }) {
    if (playedDays.isEmpty) return const StreakStatus.empty();

    final serials = playedDays.map((d) => d.serial).toSet().toList()..sort();

    var longest = 1;
    var runLength = 1;
    for (var i = 1; i < serials.length; i++) {
      runLength = serials[i] == serials[i - 1] + 1 ? runLength + 1 : 1;
      if (runLength > longest) longest = runLength;
    }

    final lastPlayed = serials.last;
    final daysSinceLastPlayed = today.serial - lastPlayed;

    // Negative means the history runs past today, which a fixed test clock can
    // produce; treat it as "played today" rather than inventing a rule for it.
    final isActiveToday = daysSinceLastPlayed <= 0;
    final isStillRunning = daysSinceLastPlayed <= 1;

    var current = 0;
    if (isStillRunning) {
      current = 1;
      for (var i = serials.length - 1; i > 0; i--) {
        if (serials[i - 1] != serials[i] - 1) break;
        current++;
      }
    }

    return StreakStatus(
      currentDays: current,
      longestDays: longest,
      isActiveToday: isActiveToday,
    );
  }
}
