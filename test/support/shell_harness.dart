import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/core/app_settings.dart';
import 'package:mindforge/core/game_stats.dart';
import 'package:mindforge/core/result.dart';
import 'package:mindforge/core/run_metric.dart';
import 'package:mindforge/core/run_record.dart';
import 'package:mindforge/core/run_scope.dart';
import 'package:mindforge/core/streak_status.dart';
import 'package:mindforge/data/data_failure.dart';
import 'package:mindforge/data/data_providers.dart';
import 'package:mindforge/games/game_definition.dart';
import 'package:mindforge/games/game_registry.dart';
import 'package:mindforge/routing/app_router.dart';
import 'package:mindforge/shared/feedback/haptic_gateway.dart';
import 'package:mindforge/shared/feedback/testing/fake_haptic_gateway.dart';

import 'fake_save_run.dart';

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
    Map<RunScope, GameStats> stats = const <RunScope, GameStats>{},
    StreakStatus streak = const StreakStatus.empty(),
    List<AppSettings>? settingsWrites,
    FakeSaveRun? saveRun,
    Map<RunScope, List<RunRecord>> chartSeries =
        const <RunScope, List<RunRecord>>{},
  }) async {
    final resolved = localeCase ?? LocaleCase.english;
    final seeded = settings.withLocaleOverride(resolved.locale);
    // The live value a write mutates, so a second write sees the first one.
    var current = seeded;

    useDevice(this, device);

    // TEAR THE PREVIOUS TREE DOWN FIRST. A second pumpShellApp in the same
    // test UPDATES the existing element tree rather than replacing it —
    // the widget types match all the way down — so the outgoing route's
    // Directionality can still be the first one in the tree when the
    // assertion below runs, and a Persian pump reports LTR. Three tests hit
    // this before the harness did something about it.
    await pumpWidget(const SizedBox.shrink());

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
          // The other derived read a screen makes. Unseeded it would reach the
          // repository, which opens a database — see the note above on why
          // that deadlocks inside testWidgets.
          runStatsProvider.overrideWith(
            (ref, scope) => Stream<GameStats>.value(
              stats[scope] ?? const GameStats.empty(),
            ),
          ),
          chartSeriesProvider.overrideWith(
            (ref, scope) => Stream<List<RunRecord>>.value(
              chartSeries[scope] ?? const <RunRecord>[],
            ),
          ),
          streakProvider.overrideWith(
            (ref) => Stream<StreakStatus>.value(streak),
          ),
          clockProvider.overrideWithValue(
            Clock.fixed(now ?? DateTime.utc(2026)),
          ),
          initialAppSettingsProvider.overrideWithValue(seeded),
          settingsProvider.overrideWith(
            (ref) => Stream<AppSettings>.value(seeded),
          ),
          // The settings WRITE seam, recorded rather than persisted. Without
          // it a toggle or the language row reaches the repository, which
          // opens a database — see the note above on why that deadlocks. It is
          // a list rather than a flag so a test can assert the ORDER of two
          // writes, which is what persist-before-publish means.
          writeSettingsProvider.overrideWithValue((change) async {
            current = change(current);
            settingsWrites?.add(current);

            return Ok<AppSettings, DataFailure>(current);
          }),
          if (games != null) gameRegistryProvider.overrideWithValue(games),
          // The same wiring bootstrap() does: the registry decides which ids
          // the repository will accept. Without it every save fails, silently.
          registeredGameIdsProvider.overrideWith(
            (ref) => ref
                .watch(gameRegistryProvider)
                .map((definition) => definition.id.value)
                .toSet(),
          ),
          // The run WRITE seam. Unseeded, finishing a run reaches the
          // repository and opens a database — the deadlock again — and a test
          // could not tell a run that saved from one that did not.
          saveRunProvider.overrideWithValue((saveRun ?? FakeSaveRun()).call),
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
