import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/core/score_format.dart';
import 'package:mindforge/core/supported_locale.dart';
import 'package:mindforge/l10n/l10n_providers.dart';
import 'package:mindforge/l10n/score_formatter_provider.dart';

void main() {
  /// localeProvider overridden directly, as l10n_providers_test does.
  ///
  /// What is under test is that the formatter is a DERIVATION of the locale
  /// authority. Driving it through the settings store instead would also drag
  /// in the system-locale fallback, which reads WidgetsBinding and needs a
  /// binding this file has no other reason to initialise —
  /// locale_resolution_test already proves that path against a real database.
  ProviderContainer containerIn(SupportedLocale locale) {
    final container = ProviderContainer(
      overrides: [localeProvider.overrideWithValue(locale)],
    );
    addTearDown(container.dispose);

    return container;
  }

  group('the formatter follows the active locale', () {
    const expected = <String, String>{
      'en': '1,480',
      'de': '1.480',
      'fa': '۱٬۴۸۰',
      'ckb': '۱٬۴۸۰',
    };

    for (final locale in SupportedLocale.values) {
      test('under ${locale.tag}', () {
        final formatter = containerIn(locale).read(scoreFormatterProvider);

        expect(
          formatter.format(ScoreFormat.points, 1480),
          expected[locale.tag],
        );
      });
    }
  });

  group('the unit comes from the ARB', () {
    test('so a duration is not glued to an English letter', () {
      // The provider composes `18.6` and the translated unit as two runs. If
      // the unit were a literal, every locale would render an English `s`.
      final formatter = containerIn(SupportedLocale.fa).read(
        scoreFormatterProvider,
      );

      final rendered = formatter.format(ScoreFormat.duration, 18600);

      expect(rendered, startsWith('۱۸٫۶'));
      expect(
        rendered.length,
        greaterThan('۱۸٫۶'.length),
        reason: 'a unit was appended',
      );
    });
  });
}
