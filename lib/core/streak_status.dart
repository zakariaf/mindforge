import 'package:meta/meta.dart';

/// The daily streak, as three plain numbers and a flag.
///
/// Derived on read from the distinct local civil days in `runs`; there is no
/// streak column and no cached counter, so a streak cannot drift out of step
/// with the runs that produced it.
@immutable
final class StreakStatus {
  /// Creates a streak status.
  const StreakStatus({
    required this.currentDays,
    required this.longestDays,
    required this.isActiveToday,
  });

  /// No runs at all: everything zero, nothing active. Never `null`.
  const StreakStatus.empty()
    : currentDays = 0,
      longestDays = 0,
      isActiveToday = false;

  /// How many consecutive days the streak currently runs to.
  ///
  /// A streak survives the day after its last run and breaks on the day after
  /// that: playing on Monday leaves Tuesday still showing the streak, and
  /// Wednesday showing zero.
  final int currentDays;

  /// The longest streak ever reached. Never less than [currentDays], and it
  /// stands after the current streak breaks.
  final int longestDays;

  /// Whether a run was recorded today, so the streak is already safe.
  final bool isActiveToday;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StreakStatus &&
          other.currentDays == currentDays &&
          other.longestDays == longestDays &&
          other.isActiveToday == isActiveToday;

  @override
  int get hashCode => Object.hash(currentDays, longestDays, isActiveToday);

  @override
  String toString() =>
      'StreakStatus(current: $currentDays, '
      'longest: $longestDays, activeToday: $isActiveToday)';
}
