import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/core/app_settings.dart';
import 'package:mindforge/core/result.dart';
import 'package:mindforge/core/supported_locale.dart';
import 'package:mindforge/data/data_failure.dart';
import 'package:mindforge/data/data_providers.dart';
import 'package:mindforge/l10n/l10n_providers.dart';

import '../../support/test_database.dart';
import '../../support/test_repositories.dart';

/// The D1 promise: the override survives a relaunch.
///
/// **It crosses two epics, so it is asserted where both are present.** E04 owns
/// the resolver and E02 owns the row; either alone can look correct while the
/// pair loses the choice. The container is disposed and rebuilt over the SAME
/// database, which is what a relaunch is.
///
/// `ckb` is the case that matters most: no iOS system language selects Sorani,
/// so the override is the ONLY way a Sorani reader ever sees the app in their
/// own language. If it does not persist, they re-choose it on every launch.
void main() {
  setUp(TestWidgetsFlutterBinding.ensureInitialized);

  /// A container as a launch would build one, seeded from the stored row.
  ProviderContainer launch(AppSettings seeded) {
    final container = ProviderContainer(
      overrides: [
        initialAppSettingsProvider.overrideWithValue(seeded),
        settingsProvider.overrideWith(
          (ref) => Stream<AppSettings>.value(seeded),
        ),
      ],
    );

    addTearDown(container.dispose);

    return container;
  }

  for (final locale in SupportedLocale.values) {
    test('${locale.tag} chosen in Settings survives a relaunch', () async {
      final db = openTestDatabase();

      addTearDown(db.close);

      final repository = testSettingsRepository(db);

      // WRITTEN THE WAY SETTINGS WRITES IT: through the repository's one path,
      // not by inserting a row by hand.
      final written = await repository.mutate(
        (current) => current.withLocaleOverride(locale),
      );

      expect(written, isA<Ok<AppSettings, DataFailure>>());

      // A RELAUNCH. Bootstrap reads the row once, before the first frame, so
      // the app comes up already in the right language rather than flashing
      // English and correcting itself.
      final reread = switch (await repository.read()) {
        Ok<AppSettings, DataFailure>(:final value) => value,
        Err<AppSettings, DataFailure>(:final failure) => fail(
          'reading the row back failed: $failure',
        ),
      };

      expect(
        reread.localeOverride,
        locale,
        reason: '${locale.tag} did not survive the round trip',
      );

      final container = launch(reread);

      expect(container.read(localeProvider), locale);
      expect(container.read(appSettingsProvider).localeOverride, locale);
    });
  }

  test('and clearing it goes back to following the system', () {
    // The other half: `withSystemLocale` is the only way to clear an override,
    // because a nullable field in a copyWith cannot say "set this to null".
    const persian = AppSettings.defaults();

    expect(
      persian
          .withLocaleOverride(SupportedLocale.ckb)
          .withSystemLocale()
          .localeOverride,
      isNull,
    );
  });
}
