import 'package:meta/meta.dart';

/// A civil date, identified by the number of days since 1970-01-01.
///
/// A day is **not** an instant. `CalendarDay` exists because three separate
/// things — the daily streak, the "played today" check and the stats chart —
/// all need to agree on where one day ends and the next begins, and an instant
/// divided by 86_400_000 disagrees with local midnight for half the year in any
/// zone with daylight saving.
///
/// The serial is computed by lifting the **local** year, month and day into UTC
/// midnight, which is what makes it DST-proof: every instant within one local
/// day yields the same serial, whatever the offset was that day.
///
/// The calendar is Gregorian, deliberately and permanently. A Persian or Kurdish
/// user's day begins at the same local midnight as everyone else's; only the
/// *label* differs, and a Jalali or Hijri label is a render projection E04 owns.
/// Storing a Jalali day number would make the streak arithmetic locale-dependent
/// and every stored row unreadable under a different locale.
@immutable
final class CalendarDay implements Comparable<CalendarDay> {
  /// Creates a day from its [serial].
  const CalendarDay.fromSerial(this.serial);

  /// The civil date [local] falls on, in [local]'s own zone.
  factory CalendarDay.fromLocal(DateTime local) => CalendarDay.fromSerial(
    DateTime.utc(local.year, local.month, local.day).millisecondsSinceEpoch ~/
        _millisecondsPerDay,
  );

  static const int _millisecondsPerDay = 86400000;

  /// Days since 1970-01-01, which is serial `0`. Negative before that.
  ///
  /// This is what the `runs.played_on_day` column stores.
  final int serial;

  /// The number of days from this day to [other]: positive when [other] is
  /// later, negative when it is earlier, zero when they are the same day.
  int daysBetween(CalendarDay other) => other.serial - serial;

  /// The day [days] after this one. Negative [days] moves backwards.
  CalendarDay addDays(int days) => CalendarDay.fromSerial(serial + days);

  @override
  int compareTo(CalendarDay other) => serial.compareTo(other.serial);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is CalendarDay && other.serial == serial;

  @override
  int get hashCode => serial.hashCode;

  @override
  String toString() => 'CalendarDay($serial)';
}
