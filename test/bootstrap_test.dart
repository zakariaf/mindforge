import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/bootstrap.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Installs the handlers and registers their own restore callback as the
  /// tear-down, so they cannot leak into a suite running under
  /// `--test-randomize-ordering-seed random`.
  ///
  /// The restore comes from `installErrorHandlers` itself rather than from a
  /// capture-and-reassign in this file. A test that assigns the framework's
  /// global error hook directly is indistinguishable, to a grep, from a widget
  /// test disarming the overflow net — and that grep is a gate this repository
  /// runs.
  void installAndRestoreAfter() => addTearDown(installErrorHandlers());

  group('installErrorHandlers', () {
    test('replaces the default FlutterError.onError', () {
      installAndRestoreAfter();

      expect(FlutterError.onError, isNotNull);
      expect(
        FlutterError.onError,
        isNot(same(FlutterError.presentError)),
        reason:
            'the default handler was left in place, so nothing new is '
            'reported',
      );
    });

    test('installs a PlatformDispatcher.onError that returns true', () {
      installAndRestoreAfter();

      final handler = PlatformDispatcher.instance.onError;
      expect(handler, isNotNull);

      expect(
        handler!(Exception('boom'), StackTrace.empty),
        isTrue,
        reason:
            'returning false re-throws into the engine and terminates the '
            'isolate. The handler must claim every error unconditionally '
            '(app-startup-and-bootstrap)',
      );
    });

    test('FlutterError.onError does not throw on a real error', () {
      installAndRestoreAfter();

      expect(
        () => FlutterError.onError!(
          FlutterErrorDetails(
            exception: Exception('boom'),
            stack: StackTrace.empty,
            library: 'mindforge test',
          ),
        ),
        returnsNormally,
        reason:
            'a crash handler that can itself crash turns one failure into '
            'two, and the second one has no net under it',
      );
    });
  });
}
