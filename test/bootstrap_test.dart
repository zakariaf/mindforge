import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/bootstrap.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FlutterExceptionHandler? originalFlutterOnError;
  late ErrorCallback? originalPlatformOnError;

  setUp(() {
    // Captured and restored so the handlers cannot leak into a suite running
    // under --test-randomize-ordering-seed random.
    originalFlutterOnError = FlutterError.onError;
    originalPlatformOnError = PlatformDispatcher.instance.onError;
    addTearDown(() {
      FlutterError.onError = originalFlutterOnError;
      PlatformDispatcher.instance.onError = originalPlatformOnError;
    });
  });

  group('installErrorHandlers', () {
    test('replaces the default FlutterError.onError', () {
      installErrorHandlers();

      expect(FlutterError.onError, isNotNull);
      expect(
        FlutterError.onError,
        isNot(same(FlutterError.presentError)),
        reason: 'the default handler was left in place, so nothing new is '
            'reported',
      );
    });

    test('installs a PlatformDispatcher.onError that returns true', () {
      installErrorHandlers();

      final handler = PlatformDispatcher.instance.onError;
      expect(handler, isNotNull);

      expect(
        handler!(Exception('boom'), StackTrace.empty),
        isTrue,
        reason: 'returning false re-throws into the engine and terminates the '
            'isolate. The handler must claim every error unconditionally '
            '(app-startup-and-bootstrap)',
      );
    });

    test('FlutterError.onError does not throw on a real error', () {
      installErrorHandlers();

      expect(
        () => FlutterError.onError!(
          FlutterErrorDetails(
            exception: Exception('boom'),
            stack: StackTrace.empty,
            library: 'mindforge test',
          ),
        ),
        returnsNormally,
        reason: 'a crash handler that can itself crash turns one failure into '
            'two, and the second one has no net under it',
      );
    });
  });
}
