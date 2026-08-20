import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:mindforge/data/data_providers.dart';
import 'package:mindforge/features/play/application/seeded_random_provider.dart';

void main() {
  ProviderContainer containerAt(DateTime instant) {
    final container = ProviderContainer(
      overrides: [clockProvider.overrideWithValue(Clock.fixed(instant))],
    );
    addTearDown(container.dispose);

    return container;
  }

  final instant = DateTime.utc(2026);

  group('the run seed', () {
    test('is a pure function of the injected clock', () {
      final container = containerAt(instant);
      final draw = container.read(seededRandomProvider);

      expect(draw(), draw());
    });

    test('and two instants one millisecond apart differ', () {
      // A player who starts two runs in the same second must not get the same
      // round twice.
      expect(
        containerAt(instant).read(seededRandomProvider)(),
        isNot(
          containerAt(
            instant.add(const Duration(milliseconds: 1)),
          ).read(seededRandomProvider)(),
        ),
      );
    });
  });

  group('the seed key is locale-independent', () {
    test('it is an ASCII ISO-8601 instant even under fa', () {
      // THE FAILURE THIS PREVENTS is silent: a Jalali date or Eastern Arabic
      // digits in the key would deal a Persian player a different round from
      // an English one on the same instant. It cannot happen quietly, because
      // seedFrom asserts ASCII — but the key is built here, so the property is
      // asserted here too.
      final previous = Intl.defaultLocale;
      addTearDown(() => Intl.defaultLocale = previous);

      final english = containerAt(instant).read(seededRandomProvider)();

      Intl.defaultLocale = 'fa';
      final persian = containerAt(instant).read(seededRandomProvider)();

      Intl.defaultLocale = 'ckb';
      final sorani = containerAt(instant).read(seededRandomProvider)();

      expect(persian, english);
      expect(sorani, english);
    });

    test('and the instant itself is the Gregorian ASCII form', () {
      // Pinned directly, because the assertion above would also pass if every
      // locale produced the same WRONG key.
      expect(instant.toUtc().toIso8601String(), '2026-01-01T00:00:00.000Z');

      for (final rune in instant.toUtc().toIso8601String().runes) {
        expect(rune, lessThan(0x80));
      }
    });
  });
}
