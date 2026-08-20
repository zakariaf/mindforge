import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/core/supported_locale.dart';
import 'package:mindforge/l10n/l10n_providers.dart';

import '../policy/support/source_text.dart';

/// The two context-free accessors, and the reason they exist.
///
/// E07's run projection and E10's Schulte painter run outside the widget tree
/// and cannot call `AppLocalizations.of(context)`. **There is no `pumpWidget`
/// anywhere in this file** — that absence is the assertion.
///
/// `localeProvider` is overridden rather than driven through the settings
/// store: what is under test here is that both accessors are *derivations of
/// the locale authority*, not that the store round-trips — which
/// `locale_resolution_test.dart` already proves against a real database.
void main() {
  ProviderContainer containerAt(SupportedLocale locale) {
    final container = ProviderContainer(
      overrides: [localeProvider.overrideWithValue(locale)],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('appLocalizationsProvider', () {
    test('resolves the strings for the active locale, with no context', () {
      for (final locale in SupportedLocale.values) {
        expect(
          containerAt(locale).read(appLocalizationsProvider).localeName,
          locale.tag,
        );
      }
    });

    test('and they are really four different translations', () {
      final rendered = <String>{
        for (final locale in SupportedLocale.values)
          containerAt(locale).read(appLocalizationsProvider).playButton,
      };

      expect(
        rendered,
        hasLength(SupportedLocale.values.length),
        reason:
            'a shared value here means an ARB fell back to the template, '
            'which gen-l10n does silently',
      );
    });
  });

  group('localeNumbersProvider', () {
    test('formats in the active locale, with no context', () {
      expect(
        containerAt(SupportedLocale.fa).read(localeNumbersProvider).count(1480),
        '۱٬۴۸۰',
      );
      expect(
        containerAt(SupportedLocale.de).read(localeNumbersProvider).count(1480),
        '1.480',
      );
      expect(
        containerAt(SupportedLocale.en).read(localeNumbersProvider).count(1480),
        '1,480',
      );
    });

    test('is a value, so a rebuild at the same locale does not churn', () {
      expect(
        containerAt(SupportedLocale.fa).read(localeNumbersProvider),
        const LocaleNumbers(SupportedLocale.fa),
        reason:
            'LocaleNumbers is a value type: a provider rebuilding to a new '
            'identity would invalidate every widget watching it, on a locale '
            'change that did not happen',
      );
    });
  });

  group('they are the only context-free lookup path', () {
    test('lookupAppLocalizations is called from l10n_providers.dart alone', () {
      // The generated file DEFINES lookupAppLocalizations; dartFilesUnderLib
      // excludes it, along with the comments — this scan used to read prose,
      // so a file explaining the rule would have violated it.
      final offenders =
          dartFilesUnderLib(
                skip: const <String>{'lib/l10n/l10n_providers.dart'},
              )
              .where(
                (f) => withoutDartComments(
                  f.readAsStringSync(),
                ).contains('lookupAppLocalizations('),
              )
              .map((f) => f.path)
              .toList();

      expect(
        offenders,
        isEmpty,
        reason:
            'a second lookup site is a second locale authority, and the two '
            'would disagree the moment one of them forgot the override',
      );
    });
  });
}
