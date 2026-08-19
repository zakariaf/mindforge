import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindforge/app.dart';
import 'package:mindforge/theme/font_licences.dart';

/// Starts MindForge.
///
/// The one composition root. The order below is the contract, not a
/// preference: the crash net is installed before anything that can throw, and
/// nothing above it may be reordered without moving code out from under it.
///
/// Three things `app-startup-and-bootstrap` describes are deliberately absent
/// until the epic that owns them lands:
/// * a durable on-device crash sink — there is nowhere to write one until E02
///   opens the database, so the handlers report to the console;
/// * the root `WidgetsBindingObserver` that flushes on background — there is no
///   durable state to flush until E02;
/// * reading the persisted locale before the first frame — there is no
///   persisted locale until E02 and no locale controller until E04.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  // The restore callback is discarded on purpose: the app never uninstalls its
  // own crash net.
  installErrorHandlers();
  registerSunburstFontLicences();

  runApp(
    ProviderScope(
      // MindForge is fully offline: every provider failure is a local bug or a
      // local I/O failure, and neither gets better by being retried on a
      // schedule. Returning null disables the retry entirely so a failure
      // surfaces once, immediately, instead of flickering.
      retry: (count, error) => null,
      child: const MindForgeApp(),
    ),
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
    } on Object catch (_) {}
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    try {
      if (kDebugMode) {
        debugPrint('PlatformDispatcher error: $error\n$stack');
      }
      // Same reason as above: the top of the reporting chain has nothing
      // above it to report to.
      // ignore: swallowed_catch
    } on Object catch (_) {}
    // Unconditionally true. Returning false re-throws into the engine and
    // terminates the isolate, which is the opposite of a crash net.
    return true;
  };

  return () {
    FlutterError.onError = previousFlutterOnError;
    PlatformDispatcher.instance.onError = previousPlatformOnError;
  };
}
