import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/core/app_settings.dart';
import 'package:mindforge/core/result.dart';
import 'package:mindforge/core/run_metric.dart';
import 'package:mindforge/data/data_failure.dart';
import 'package:mindforge/data/data_providers.dart';
import 'package:mindforge/games/game_definition.dart';
import 'package:mindforge/games/game_registry.dart';
import 'package:mindforge/routing/app_router.dart';
import 'package:mindforge/shared/feedback/haptic_gateway.dart';
import 'package:mindforge/shared/feedback/testing/fake_haptic_gateway.dart';

import 'harness.dart';
import 'locale_cases.dart';

/// Pumps the whole shell in one locale, on the reference device.
///
/// **It delegates to E04's `pumpLocalized` rather than building its own
/// `ProviderScope` -> `MaterialApp` chain**, because `pumpLocalized` asserts
/// the resolved `Directionality` matches the case's declared direction — and a
/// hand-rolled chain skips that assertion silently. It takes a [LocaleCase],
/// not a bare `Locale`, for the same reason.
///
/// It never wraps the tree in a hand-written `Directionality`. Direction is a
/// consequence of the resolved locale, and a hardcoded root is exactly what
/// hides every physical-side bug this epic exists to find.
///
/// **Real repositories over an in-memory database, not fakes.** `RunRepository`
/// and `SettingsRepository` are `final class`es and cannot be implemented from
/// a test anyway — and `check_test_hygiene.sh` is right that a mocked DAO
/// proves nothing about SQL or constraints. `openTestDatabase()` is E02's.
extension PumpShell on WidgetTester {
  /// Pumps the REAL `MindForgeApp` — its router, its `MaterialApp`, its
  /// delegates — in [localeCase]'s locale.
  ///
  /// **It does not go through `pumpLocalized`.** That helper supplies its own
  /// `MaterialApp`, which is right for a component but wrong here: nesting the
  /// app inside it made `MindForgeApp`'s `MaterialApp.router` a child of
  /// another router's Navigator, and the error route silently never rendered.
  /// The direction assertion `pumpLocalized` contributes is made here instead,
  /// so nothing is lost.
  ///
  /// The locale is seeded through the SETTINGS OVERRIDE rather than a
  /// `Directionality` wrapper, because that is how the app itself resolves one
  /// — and a hardcoded direction is exactly what hides a physical-side bug.
  ///
  /// **It opens no database.** A screen reads providers, so the harness seeds
  /// those. Opening a real drift database inside `testWidgets` deadlocks: the
  /// widget binding runs in a fake-async zone, drift's close never completes
  /// there, and `addTearDown(database.close)` hangs the test until the
  /// ten-minute timeout. Measured. A test that genuinely needs SQL is a
  /// repository test and belongs in a plain `test()`.
  Future<void> pumpShellApp(
    Widget app, {
    LocaleCase? localeCase,
    Device device = Device.reference390,
    AppSettings settings = const AppSettings.defaults(),
    List<GameDefinition>? games,
    TextScaler textScaler = TextScaler.noScaling,
    bool boldText = false,
    bool disableAnimations = false,
    FakeHapticGateway? hapticGateway,
    DateTime? now,
    String? initialLocation,
    Map<String, Result<RunMetric?, DataFailure>> bests =
        const <String, Result<RunMetric?, DataFailure>>{},
  }) async {
    final resolved = localeCase ?? LocaleCase.english;
    final seeded = settings.withLocaleOverride(resolved.locale);

    useDevice(this, device);

    await pumpWidget(
      ProviderScope(
        overrides: [
          // The screens' own data seam, seeded directly. See the note above on
          // why no database is opened here.
          allBestsProvider.overrideWith(
            (ref) => Stream<Map<String, Result<RunMetric?, DataFailure>>>.value(
              bests,
            ),
          ),
          clockProvider.overrideWithValue(
            Clock.fixed(now ?? DateTime.utc(2026)),
          ),
          initialAppSettingsProvider.overrideWithValue(seeded),
          settingsProvider.overrideWith(
            (ref) => Stream<AppSettings>.value(seeded),
          ),
          if (games != null) gameRegistryProvider.overrideWithValue(games),
          // The same wiring bootstrap() does: the registry decides which ids
          // the repository will accept. Without it every save fails, silently.
          registeredGameIdsProvider.overrideWith(
            (ref) => ref
                .watch(gameRegistryProvider)
                .map((definition) => definition.id.value)
                .toSet(),
          ),
          hapticGatewayProvider.overrideWithValue(
            hapticGateway ?? FakeHapticGateway(),
          ),
          // A cold start at an arbitrary location. go() from a live shell keeps
          // the branch it is already in, so this is the only way a test can
          // exercise a deep link — or an unmatched one.
          if (initialLocation != null)
            initialLocationProvider.overrideWithValue(initialLocation),
        ],
        child: MediaQuery(
          data: MediaQueryData.fromView(view).copyWith(
            textScaler: textScaler,
            boldText: boldText,
            disableAnimations: disableAnimations,
          ),
          child: app,
        ),
      ),
    );

    await pump(const Duration(milliseconds: 400));

    // The assertion pumpLocalized would have made. Direction is a consequence
    // of the resolved locale, and a test that skips this check is a test that
    // cannot tell a mirrored screen from an unmirrored one.
    expect(
      Directionality.of(element(find.byType(Directionality).first)),
      resolved.direction,
      reason:
          'the ambient direction under ${resolved.tag} is not what the locale '
          'requires — a delegate regression, not a screen bug',
    );
  }
}
