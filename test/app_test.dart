import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/app.dart';
import 'package:mindforge/core/app_settings.dart';
import 'package:mindforge/core/supported_locale.dart';
import 'package:mindforge/data/data_providers.dart';
import 'package:mindforge/shared/motion/motion_preference_scope.dart';

import 'support/test_database.dart';

void main() {
  /// Boots the app the way `bootstrap()` does: a real database and the
  /// settings row read **before** the first frame.
  ///
  /// The overrides are not test scaffolding for their own sake — the app
  /// genuinely requires them, and a smoke test that pumped without them would
  /// be exercising a configuration that never ships.
  Widget bootedApp({AppSettings initial = const AppSettings.defaults()}) {
    final db = openTestDatabase();
    addTearDown(db.close);

    return ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        initialAppSettingsProvider.overrideWithValue(initial),
      ],
      child: const MindForgeApp(),
    );
  }

  testWidgets('MindForgeApp mounts without throwing', (tester) async {
    await tester.pumpWidget(bootedApp());

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the FIRST frame is already in the persisted locale', (
    tester,
  ) async {
    // No pump beyond the first, and no settle: if the locale arrived through
    // the stream instead of the seed, this frame would be English LTR and the
    // next one Sorani RTL — the visible flip the whole seeding exists to stop.
    await tester.pumpWidget(
      bootedApp(
        initial: const AppSettings.defaults().withLocaleOverride(
          SupportedLocale.ckb,
        ),
      ),
    );

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.locale, const Locale('ckb'));

    expect(
      Directionality.of(tester.element(find.byType(Scaffold))),
      TextDirection.rtl,
      reason: 'and the direction is right on that same first frame',
    );
  });

  group('the reduce-motion fold', () {
    testWidgets('is mounted, so the setting reaches every screen', (
      tester,
    ) async {
      // MotionPreferenceScope was built, tested and NOT INSTALLED. Every unit
      // test of it passed and the setting did nothing in the running app,
      // because nothing above the screens folded it into MediaQuery. This
      // asserts the wiring rather than the widget.
      await tester.pumpWidget(
        bootedApp(
          initial: const AppSettings.defaults().copyWith(
            isReduceMotionEnabled: true,
          ),
        ),
      );

      expect(
        MediaQuery.disableAnimationsOf(tester.element(find.byType(Scaffold))),
        isTrue,
      );
    });

    testWidgets('and it leaves animation alone when nobody asked', (
      tester,
    ) async {
      await tester.pumpWidget(bootedApp());

      expect(
        MediaQuery.disableAnimationsOf(tester.element(find.byType(Scaffold))),
        isFalse,
      );
    });

    testWidgets('it sits INSIDE MaterialApp, so it sees the real MediaQuery', (
      tester,
    ) async {
      // Above MaterialApp there is no MediaQuery to copyWith from — the one the
      // app reads is inserted BY MaterialApp from the view. A fold placed above
      // it would either build a bare MediaQueryData, dropping the size, the
      // text scaler and every accessibility flag, or read a MediaQuery that is
      // not the one the screens below are reading.
      await tester.pumpWidget(bootedApp());

      expect(
        find.descendant(
          of: find.byType(MaterialApp),
          matching: find.byType(MotionPreferenceScope),
        ),
        findsOneWidget,
      );
    });
  });
}
