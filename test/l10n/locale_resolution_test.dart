import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/core/app_settings.dart';
import 'package:mindforge/core/result.dart';
import 'package:mindforge/core/supported_locale.dart';
import 'package:mindforge/data/data_failure.dart';
import 'package:mindforge/data/data_providers.dart';
import 'package:mindforge/l10n/locale_resolution.dart';

import '../support/test_database.dart';

void main() {
  group('resolveLocale', () {
    test('an explicit override wins over every system locale', () {
      expect(
        resolveLocale(
          override: SupportedLocale.ckb,
          systemLocales: const <Locale>[Locale('en'), Locale('de')],
        ),
        SupportedLocale.ckb,
      );
    });

    test('otherwise the first system locale this build ships', () {
      expect(
        resolveLocale(
          override: null,
          systemLocales: const <Locale>[Locale('ja'), Locale('fa')],
        ),
        SupportedLocale.fa,
        reason: 'the platform ranks them; the first one we ship wins',
      );
    });

    test('a region subtag does not disqualify a language', () {
      // A device set to fa-IR wants Persian. Dropping it to English because
      // the region differs is a wrong-language bug the user cannot act on.
      for (final locale in const <Locale>[
        Locale('fa', 'IR'),
        Locale('de', 'AT'),
        Locale('en', 'GB'),
      ]) {
        expect(
          resolveLocale(override: null, systemLocales: <Locale>[locale]),
          SupportedLocale.tryParse(locale.languageCode),
          reason: '$locale',
        );
      }
    });

    test('and en is the fallback when nothing matches', () {
      expect(
        resolveLocale(
          override: null,
          systemLocales: const <Locale>[Locale('ja'), Locale('ko')],
        ),
        SupportedLocale.en,
      );
      expect(
        resolveLocale(override: null, systemLocales: const <Locale>[]),
        SupportedLocale.en,
      );
    });
  });

  group('localeProvider', () {
    late ProviderContainer container;

    ProviderContainer open({
      required List<Locale> systemLocales,
      AppSettings initial = const AppSettings.defaults(),
    }) {
      final db = openTestDatabase();
      final made = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          initialAppSettingsProvider.overrideWithValue(initial),
          systemLocalesProvider.overrideWithValue(systemLocales),
        ],
      );
      // A live listener, so settingsProvider actually subscribes. Without one
      // the stream never runs and localeProvider answers from the seed
      // forever — which would make the re-emit assertions below pass for the
      // wrong reason.
      final subscription = made.listen(settingsProvider, (_, _) {});
      addTearDown(subscription.close);
      addTearDown(db.close);
      addTearDown(made.dispose);
      return made;
    }

    test('follows the system when there is no override', () {
      container = open(systemLocales: const <Locale>[Locale('fa')]);

      expect(container.read(localeProvider), SupportedLocale.fa);
    });

    test('honours the persisted override on the FIRST read', () async {
      // The whole reason bootstrap() awaits a settings read: the seeded value
      // is already correct, so the first frame is in the right language and
      // the right direction rather than flipping.
      container = open(
        systemLocales: const <Locale>[Locale('en')],
        initial: const AppSettings.defaults().withLocaleOverride(
          SupportedLocale.ckb,
        ),
      );

      expect(
        container.read(localeProvider),
        SupportedLocale.ckb,
        reason: 'no pump, no settle — the very first read is already ckb',
      );
    });

    test('re-emits after the override is written', () async {
      container = open(systemLocales: const <Locale>[Locale('en')]);
      expect(container.read(localeProvider), SupportedLocale.en);

      final result = await container
          .read(localeControllerProvider)
          .setLocale(SupportedLocale.fa);
      expect(result, isA<Ok<AppSettings, DataFailure>>());

      for (var i = 0; i < 5; i++) {
        await Future<void>.delayed(Duration.zero);
      }

      expect(container.read(localeProvider), SupportedLocale.fa);
    });

    test('clearing the override returns to the system locale', () async {
      container = open(
        systemLocales: const <Locale>[Locale('de')],
        initial: const AppSettings.defaults().withLocaleOverride(
          SupportedLocale.fa,
        ),
      );
      expect(container.read(localeProvider), SupportedLocale.fa);

      expect(
        await container.read(localeControllerProvider).setLocale(null),
        isA<Ok<AppSettings, DataFailure>>(),
      );
      for (var i = 0; i < 5; i++) {
        await Future<void>.delayed(Duration.zero);
      }

      expect(container.read(localeProvider), SupportedLocale.de);
    });

    test('a broken store falls back to the system, not to en', () async {
      container = open(systemLocales: const <Locale>[Locale('fa')]);
      await container
          .read(appDatabaseProvider)
          .customStatement(
            'DROP TABLE settings',
          );

      expect(
        container.read(localeProvider),
        SupportedLocale.fa,
        reason:
            '"the store is broken" is not a reason to also get the '
            'language wrong',
      );
    });
  });
}
