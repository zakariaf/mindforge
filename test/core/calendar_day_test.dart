import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:mindforge/core/calendar_day.dart';

void main() {
  group('CalendarDay', () {
    test('the epoch day is serial 0', () {
      expect(CalendarDay.fromLocal(DateTime(1970)).serial, 0);
    });

    test('the first and last instant of a local day map to one serial', () {
      // 2026-03-29 is the European DST spring-forward date. A serial computed
      // from the raw instant divided by 86_400_000 would put these two on
      // different days in a shifting zone; lifting the local Y/M/D into UTC
      // midnight cannot.
      final firstInstant = DateTime(2026, 3, 29, 0, 30);
      final lastInstant = DateTime(2026, 3, 29, 23, 30);

      expect(
        CalendarDay.fromLocal(firstInstant),
        CalendarDay.fromLocal(lastInstant),
        reason: 'a day boundary is local midnight, not an offset from UTC',
      );
    });

    test('serial round-trips through fromSerial', () {
      final day = CalendarDay.fromLocal(DateTime(2026, 8, 19, 14, 3));

      expect(CalendarDay.fromSerial(day.serial), day);
    });

    test('daysBetween is symmetric in magnitude and signed by order', () {
      final earlier = CalendarDay.fromLocal(DateTime(2026, 8, 15));
      final later = CalendarDay.fromLocal(DateTime(2026, 8, 19));

      expect(earlier.daysBetween(later), 4);
      expect(later.daysBetween(earlier), -4);
    });

    test(
      'the serial is the Gregorian civil date under every shipped locale',
      () {
        // CalendarDay imports no intl. The ambient locale is set here purely to
        // prove the absence of a dependency: a Jalali or Hijri label is a
        // projection E04 renders, never a stored value, so a Persian user's day
        // boundary is the same local midnight as everyone else's.
        final instant = DateTime(2026, 8, 19, 23, 59);
        final baseline = CalendarDay.fromLocal(instant).serial;

        for (final tag in <String>['en', 'de', 'fa', 'ckb']) {
          final previous = Intl.defaultLocale;
          Intl.defaultLocale = tag;
          addTearDown(() => Intl.defaultLocale = previous);

          expect(
            CalendarDay.fromLocal(instant).serial,
            baseline,
            reason:
                'the day serial moved under $tag, which means a calendar '
                'leaked into lib/core/',
          );
        }
      },
    );
  });
}
