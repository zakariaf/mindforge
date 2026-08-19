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
    ProviderContainer open({
      required List<Locale> systemLocales,
      AppSettings initial = const AppSettings.defaults(),
    }) {
      final db = openTestDatabase();
      final made = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          initialAppSettingsProvider.overrideWithValue(initial),
          systemLocalesProvider.overrideWith(
            () => _FixedSystemLocales(systemLocales),
          ),
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
      final container = open(systemLocales: const <Locale>[Locale('fa')]);

      expect(container.read(localeProvider), SupportedLocale.fa);
    });

    test('honours the persisted override on the FIRST read', () async {
      // The whole reason bootstrap() awaits a settings read: the seeded value
      // is already correct, so the first frame is in the right language and
      // the right direction rather than flipping.
      final container = open(
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
      final container = open(systemLocales: const <Locale>[Locale('en')]);
      expect(container.read(localeProvider), SupportedLocale.en);

      final result = await container
          .read(localeControllerProvider)
          .setLocale(SupportedLocale.fa);
      expect(result, isA<Ok<AppSettings, DataFailure>>());

      await pumpEventQueue();

      expect(container.read(localeProvider), SupportedLocale.fa);
    });

    test('clearing the override returns to the system locale', () async {
      final container = open(
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
      await pumpEventQueue();

      expect(container.read(localeProvider), SupportedLocale.de);
    });

    test('a broken store keeps the last known-good language', () async {
      // The seed and the system DISAGREE on purpose. With both saying the same
      // thing this assertion was green whether or not the store was consulted
      // at all — measured: it stayed green with localeProvider ignoring the
      // persisted settings entirely.
      final container = open(
        systemLocales: const <Locale>[Locale('fa')],
        initial: const AppSettings.defaults().withLocaleOverride(
          SupportedLocale.de,
        ),
      );

      expect(container.read(localeProvider), SupportedLocale.de);

      await container
          .read(appDatabaseProvider)
          .customStatement('DROP TABLE settings');
      await pumpEventQueue();

      expect(
        container.read(localeProvider),
        SupportedLocale.de,
        reason:
            'Riverpod retains the last data value across a stream error, so '
            'the language the user chose survives a store that has stopped '
            'answering. Falling back to the system here would change the '
            'language under them at the moment things go wrong',
      );
    });

    testWidgets('re-reads the system list when the device language changes', (
      tester,
    ) async {
      // A snapshot taken at first read left a user with no override in the OLD
      // language until a cold start: MindForgeApp passes an explicit locale:,
      // so Flutter's own re-resolution never runs.
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final before = container.read(systemLocalesProvider);
      expect(before, isNotEmpty);

      tester.platformDispatcher.localesTestValue = const <Locale>[
        Locale('de'),
        Locale('en'),
      ];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);

      // What the engine calls on a system language change.
      WidgetsBinding.instance.handleLocaleChanged();

      expect(
        container.read(systemLocalesProvider).first.languageCode,
        'de',
        reason:
            'the observer must republish, or the app stays in the previous '
            'language until it is killed and relaunched',
      );
    });

    test('and with no override it follows the system, not en', () async {
      final container = open(systemLocales: const <Locale>[Locale('fa')]);

      await container
          .read(appDatabaseProvider)
          .customStatement('DROP TABLE settings');
      await pumpEventQueue();

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

/// A [SystemLocales] pinned to a fixed list.
///
/// The real one reads `PlatformDispatcher` and registers a
/// `WidgetsBindingObserver`; a pure-Dart test has neither and needs neither.
final class _FixedSystemLocales extends SystemLocales {
  _FixedSystemLocales(this.locales);

  final List<Locale> locales;

  @override
  List<Locale> build() => locales;
}
