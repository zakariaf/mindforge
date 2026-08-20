import 'package:flutter/foundation.dart';
import 'package:mindforge/core/failure.dart';
import 'package:mindforge/shared/feedback/haptic_verb.dart';

/// A failure in the sensory layer.
///
/// Its own family rather than a `DataFailure`, because nothing here touches the
/// store — and a `Failure` rather than a bespoke error callback, because the
/// app already has one reporting seam and a second, shallower one is invisible
/// to every test that swaps in `FakeLogSink`.
@immutable
sealed class FeedbackFailure extends Failure {
  /// Creates a feedback failure.
  const FeedbackFailure();
}

/// The device would not play [verb].
///
/// Recorded and swallowed: a device with no taptic engine has nothing to show,
/// retry or decide, and an unhandled rejection would take a screen down over a
/// buzz that did not happen.
@immutable
final class HapticUnavailable extends FeedbackFailure {
  /// Creates the failure for [verb].
  const HapticUnavailable(this.verb);

  /// The verb that did not play.
  final HapticVerb verb;

  @override
  String get code => 'feedback.haptic_unavailable';

  @override
  bool operator ==(Object other) =>
      other is HapticUnavailable && other.verb == verb;

  @override
  int get hashCode => Object.hash(code, verb);
}
