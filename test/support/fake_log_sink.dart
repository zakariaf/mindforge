import 'package:mindforge/core/failure.dart';
import 'package:mindforge/data/log_sink.dart';

/// A `LogSink` that remembers what it was told, so a test can assert a
/// degradation was **visible** rather than silent.
///
/// A bare `implements` fake, not a mock: there is no stubbing to configure and
/// no call-order protocol to verify, so a mock would add a framework for
/// nothing (`testing-strategy`).
final class FakeLogSink implements LogSink {
  /// Every failure recorded, in order.
  final List<Failure> recorded = <Failure>[];

  /// The codes recorded, in order — the usual thing to assert on.
  List<String> get codes => recorded.map((f) => f.code).toList();

  /// The stack traces recorded alongside them, in the same order.
  ///
  /// Kept so a test can assert the stack SURVIVED. A reporting path that
  /// captures a stack and then drops it looks identical, from the outside, to
  /// one that records the failure properly.
  final List<StackTrace?> stackTraces = <StackTrace?>[];

  @override
  void recordFailure(
    Failure failure, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    recorded.add(failure);
    stackTraces.add(stackTrace);
  }
}
