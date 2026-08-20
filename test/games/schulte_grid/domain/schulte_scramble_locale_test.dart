import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/core/app_settings.dart';
import 'package:mindforge/core/supported_locale.dart';
import 'package:mindforge/data/data_providers.dart';
import 'package:mindforge/games/schulte_grid/domain/schulte_scramble.dart';

import 'schulte_scramble_vectors.dart';

/// The board a player gets does not depend on the language they read.
///
/// **This is the test that cannot fail today, and that is the point.** The
/// generator takes no locale and touches no formatter, so all four locales
/// agree by construction. It fails the day someone reaches for `NumberFormat`
/// inside the generator — which is a plausible refactor, because the tiles
/// ARE numbers and the temptation is to format them where they are made.
///
/// If that happened, a Persian player would get a different board from a German
/// one at the same seed, every frozen vector would still pass in `en`, and the
/// bug would surface as "my friend and I got different puzzles from the same
/// daily seed".
void main() {
  /// A container whose settings pin [locale].
  ProviderContainer containerFor(SupportedLocale locale) {
    final settings = const AppSettings.defaults().withLocaleOverride(locale);
    final container = ProviderContainer(
      overrides: [
        initialAppSettingsProvider.overrideWithValue(settings),
        settingsProvider.overrideWith(
          (ref) => Stream<AppSettings>.value(settings),
        ),
      ],
    );

    addTearDown(container.dispose);

    return container;
  }

  group('the scramble', () {
    test('is identical under en, de, fa and ckb', () {
      final boards = <SupportedLocale, List<int>>{
        for (final locale in SupportedLocale.values)
          locale: () {
            // Read through a container pinned to the locale, so the ambient
            // settings really are different between the four calls.
            containerFor(locale).read(appSettingsProvider);

            return schulteScramble(seed: 42, size: 5);
          }(),
      };

      final english = boards[SupportedLocale.en];

      for (final entry in boards.entries) {
        expect(entry.value, english, reason: '${entry.key.tag} differed');
      }
    });

    test('and so is every frozen vector, in every locale', () {
      for (final locale in SupportedLocale.values) {
        containerFor(locale).read(appSettingsProvider);

        for (final vector in kSchulteScrambleVectors) {
          expect(
            fingerprintOf(
              schulteScramble(seed: vector.seed, size: vector.size),
            ),
            vector.fingerprint,
            reason: '${vector.note} under ${locale.tag}',
          );
        }
      }
    });
  });

  group('the domain layer', () {
    test('imports neither intl nor AppLocalizations', () {
      // The stronger half, and a source grep because the assertions above only
      // catch a formatter that CHANGES the output. One that stringified
      // identically in two locales — a `NumberFormat` on an `en` fallback —
      // would pass every test above while being exactly the defect.
      final offenders = <String>[];

      for (final entity in Directory(
        'lib/games/schulte_grid/domain',
      ).listSync()) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;

        // COMMENTS STRIPPED FIRST. This file's own header explains that the
        // tiles are localized at render, and naming the class that does it put
        // the class's name in the file — so the grep flagged the very file
        // whose prose says it does not do the thing.
        final source = entity
            .readAsStringSync()
            .split('\n')
            .where((line) => !line.trimLeft().startsWith('//'))
            .join('\n');

        if (source.contains('package:intl') ||
            source.contains('AppLocalizations') ||
            source.contains('LocaleNumbers')) {
          offenders.add(entity.path);
        }
      }

      expect(
        offenders,
        isEmpty,
        reason: 'the generator produces integers; rendering localizes them',
      );
    });
  });
}
