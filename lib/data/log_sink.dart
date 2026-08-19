import 'package:mindforge/core/failure.dart';

/// Where the data layer reports a failure it handled.
///
/// An injected interface rather than a `debugPrint`, for two reasons: a test
/// can assert that a degradation was *visible* rather than silent, and there is
/// exactly one place to point at a durable on-device sink when one exists.
///
/// It carries a [Failure] and the original error, never a formatted sentence —
/// the data layer has no idea which of four locales the reader is in.
///
/// One member, on purpose: this is a **seam**, not a utility. A top-level
/// function cannot be substituted in a `ProviderScope`, and the whole point is
/// that a test swaps in `FakeLogSink` and asserts a degradation was visible.
abstract interface class LogSink {
  /// Records that [failure] happened, with the [error] and [stackTrace] that
  /// caused it where there was one.
  void recordFailure(
    Failure failure, {
    Object? error,
    StackTrace? stackTrace,
  });
}

/// The default sink: reports to the console in debug builds and drops the
/// record otherwise.
///
/// There is nowhere durable to write yet. When a crash log lands, it replaces
/// this class and nothing else changes.
final class DebugLogSink implements LogSink {
  /// Creates the sink.
  const DebugLogSink();

  @override
  void recordFailure(
    Failure failure, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    assert(() {
      // There is no logger to route through yet and no durable sink to write
      // to; this class exists to be replaced by one. Until then the console is
      // the only place a handled failure can surface at all.
      // ignore: avoid_print
      print('[data] ${failure.code}${error == null ? '' : ' — $error'}');
      return true;
    }(), 'debug-only reporting');
  }
}
