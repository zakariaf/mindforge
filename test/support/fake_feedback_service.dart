import 'package:mindforge/shared/feedback/feedback_service.dart';
import 'package:mindforge/shared/feedback/moment.dart';
import 'package:mindforge/shared/feedback/sound_cue.dart';

/// A [FeedbackService] that records what it was handed.
///
/// A bare `implements` rather than a mock: there is nothing to stub and no
/// call-order protocol to verify beyond "which moments fired, in what order",
/// which is a list this fake keeps rather than a rule a framework enforces.
///
/// E09 T09.6 names this as one of E05's files. It was not one — E05 shipped
/// `SilentFeedbackService` in `lib/` and `FakeHapticGateway` in test support,
/// and neither can answer "did the milestone fire twice?". A haptic gateway
/// sees only moments that HAVE a haptic, and six of the eighteen do not.
final class FakeFeedbackService implements FeedbackService {
  /// Every moment fired, in order.
  final List<Moment> fired = <Moment>[];

  /// Whether sound is on, for [soundCueFor].
  bool soundEnabled = true;

  /// How many times [moment] fired.
  int countOf(Moment moment) =>
      fired.where((candidate) => candidate == moment).length;

  @override
  void fire(Moment moment) => fired.add(moment);

  @override
  SoundCue? soundCueFor(Moment moment) => soundEnabled ? SoundCue.pop : null;
}
