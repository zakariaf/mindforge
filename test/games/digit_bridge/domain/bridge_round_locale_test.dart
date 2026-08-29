import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:mindforge/core/difficulty.dart';
import 'package:mindforge/core/supported_locale.dart';
import 'package:mindforge/games/digit_bridge/domain/bridge_round_generator.dart';
import 'package:mindforge/l10n/locale_numbers.dart';

import 'bridge_round_vectors.dart';

/// A golden vector must not move because the locale moved.
///
/// This is the assertion Digit Bridge exists to be most careful about. Its
/// content IS numerals, it renders two numbering systems at once, and it is the
/// one game in the app allowed to pick a script rather than inherit one — so
/// "generation is locale-free" is a claim that has to be tested rather than
/// assumed from the import list.
void main() {
  group('generation does not read the ambient locale', () {
    test('the frozen fingerprints hold under every default locale', () {
      final original = Intl.defaultLocale;

      addTearDown(() => Intl.defaultLocale = original);

      for (final locale in SupportedLocale.values) {
        // The symbol locale, not the tag: `ckb` is not a locale `intl` knows,
        // and setting it would throw rather than test anything.
        Intl.defaultLocale = LocaleNumbers.symbolLocaleFor(locale);

        for (final vector in kBridgeRoundVectors) {
          expect(
            fingerprintOf(
              generateBridgeRounds(
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

    test('and a round carries integers, never a rendered numeral', () {
      // canonical() is what the fingerprint is built from. If a formatted
      // numeral ever reached it, the assertion above would start failing in a
      // way that looks like a generator bug -- so the shape is pinned here too.
      final round = generateBridgeRounds(
        seed: 42,
        difficulty: Difficulty.classic,
      ).first;

      expect(
        round.canonical(),
        matches(RegExp(r'^[0-9:,\-]+$')),
        reason: 'a canonical row is ASCII digits and separators, nothing else',
      );
    });
  });
}
