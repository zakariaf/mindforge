import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindforge/app.dart';
import 'package:mindforge/core/app_settings.dart';
import 'package:mindforge/core/result.dart';
import 'package:mindforge/data/daos/settings_dao.dart';
import 'package:mindforge/data/data_providers.dart';
import 'package:mindforge/data/db/app_database.dart';
import 'package:mindforge/data/db/connection.dart';
import 'package:mindforge/data/log_sink.dart';
import 'package:mindforge/data/repositories/settings_repository.dart';
import 'package:mindforge/theme/font_licences.dart';

/// Starts MindForge.
///
/// The one composition root. The order below is the contract, not a
/// preference: the crash net is installed before anything that can throw, and
/// nothing above it may be reordered without moving code out from under it.
///
/// One bounded read runs before `runApp`, and it is the only thing E02 adds to
/// the sequence. `MaterialApp` must be built with the persisted locale on the
/// **first** frame: if the locale arrived through an `AsyncValue`, a Persian
/// user's cold start would paint an English LTR frame and then flip to Persian
/// RTL — a visible, unmistakable defect. The same argument applies to E06's
/// reduce-motion toggle, which must be honoured by the first transition rather
/// than by the second. `async-safety` rule 9 forbids *unbounded* work here; a
/// single-row read from a local file is bounded, and that is the whole
/// justification.
///
/// Two things `app-startup-and-bootstrap` describes are still deliberately
/// absent:
/// * a durable on-device crash sink — `DebugLogSink` reports to the console,
///   and replacing it is a one-line provider override once a crash log exists;
/// * the root `WidgetsBindingObserver` that flushes on background — every write
///   is already durable by the time it returns, so there is nothing to flush.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  // The restore callback is discarded on purpose: the app never uninstalls its
  // own crash net.
  installErrorHandlers();
  registerSunburstFontLicences();

  final database = AppDatabase(openDatabaseConnection());
  final initialSettings = await _readInitialSettings(database);

  runApp(
    ProviderScope(
      // MindForge is fully offline: every provider failure is a local bug or a
      // local I/O failure, and neither gets better by being retried on a
      // schedule. Returning null disables the retry entirely so a failure
      // surfaces once, immediately, instead of flickering.
      retry: (count, error) => null,
      overrides: [
        appDatabaseProvider.overrideWithValue(database),
        initialAppSettingsProvider.overrideWithValue(initialSettings),
      ],
      child: const MindForgeApp(),
    ),
  );
}

/// Reads the persisted settings once, falling back to the defaults.
///
/// The `Err` arm falls back to `AppSettings.defaults()` rather than propagating,
/// so a broken store still boots into a usable app. A player with a corrupt
/// database should get English and sound on, not a black screen.
Future<AppSettings> _readInitialSettings(AppDatabase database) async {
  final repository = SettingsRepository(
    database: database,
    dao: SettingsDao(database),
    clock: const Clock(),
    logSink: const DebugLogSink(),
  );

  return (await repository.read()).fold(
    onOk: (settings) => settings,
    onErr: (_) => const AppSettings.defaults(),
  );
}

/// Installs the two error handlers that catch everything the app can throw,
/// and returns a callback that puts the previous handlers back.
///
/// Exactly two handlers, and no `runZonedGuarded`: a third capture point
/// swallows what the other two were installed to report. Called from
/// [bootstrap] before any other statement that can fail; `bootstrap` discards
/// the restore callback because the app never uninstalls its own crash net.
///
/// The callback exists because this function mutates process-global state, and
/// a function that does that should hand back the undo rather than making every
/// caller reconstruct it. `test/bootstrap_test.dart` uses it so the handlers
/// cannot leak into a suite running under
/// `--test-randomize-ordering-seed random`.
void Function() installErrorHandlers() {
  final previousFlutterOnError = FlutterError.onError;
  final previousPlatformOnError = PlatformDispatcher.instance.onError;

  FlutterError.onError = (details) {
    // A crash handler that can itself crash turns one failure into two, and
    // the second one has no net under it.
    try {
      FlutterError.presentError(details);
      if (kDebugMode) {
        debugPrint('FlutterError: ${details.exceptionAsString()}');
      }
      // This IS the top of the reporting chain, so a failure here has nothing
      // above it to be reported to. Rethrowing would turn one crash into two.
      // ignore: swallowed_catch
    } on Object catch (_) {
      // Nothing to do, for the reason immediately above.
    }
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    try {
      if (kDebugMode) {
        debugPrint('PlatformDispatcher error: $error\n$stack');
      }
      // Same reason as above: the top of the reporting chain has nothing
      // above it to report to.
      // ignore: swallowed_catch
    } on Object catch (_) {
      // Nothing to do, for the reason immediately above.
    }
    // Unconditionally true. Returning false re-throws into the engine and
    // terminates the isolate, which is the opposite of a crash net.
    return true;
  };

  return () {
    FlutterError.onError = previousFlutterOnError;
    PlatformDispatcher.instance.onError = previousPlatformOnError;
  };
}
