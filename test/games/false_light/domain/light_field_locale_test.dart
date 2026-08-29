import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:mindforge/core/difficulty.dart';
import 'package:mindforge/core/supported_locale.dart';
import 'package:mindforge/games/false_light/domain/light_field_generator.dart';
import 'package:mindforge/l10n/locale_numbers.dart';

import 'light_field_vectors.dart';

/// A golden vector must not move because the locale moved.
///
/// **The easiest claim in the app to hold and the easiest to lose silently.**
/// A False Light board renders no text at all, so if generation ever did start
/// reading the ambient locale, nothing on screen would look wrong in any of the
/// four languages — the fields would simply be different fields, and only a
/// player comparing a shared seed across two phones would ever find out.
void main() {
  group('generation does not read the ambient locale', () {
    test('the frozen fingerprints hold under every default locale', () {
      final original = Intl.defaultLocale;

      addTearDown(() => Intl.defaultLocale = original);

      for (final locale in SupportedLocale.values) {
        // The symbol locale, not the tag: `ckb` is not a locale `intl` knows,
        // and setting it would throw rather than test anything.
        Intl.defaultLocale = LocaleNumbers.symbolLocaleFor(locale);

        for (final vector in kLightFieldVectors) {
          expect(
            fingerprintOf(
              generateLightFields(
                seed: vector.seed,
                difficulty: vector.difficulty,
              ),
            ),
            vector.fingerprint,
            reason: '${vector.note} moved under ${locale.tag}',
          );
        }
      }
    });

    test('and a field carries integers, never a rendered numeral', () {
      // canonical() is what the fingerprint is built from. If a formatted
      // numeral ever reached it, the assertion above would start failing in a
      // way that looks like a generator bug -- so the shape is pinned here too.
      final field = generateLightFields(
        seed: 42,
        difficulty: Difficulty.classic,
      ).first;

      expect(
        field.canonical(),
        matches(RegExp(r'^[0-9:,]+$')),
        reason: 'a canonical row is ASCII digits and separators, nothing else',
      );
    });
  });
}
