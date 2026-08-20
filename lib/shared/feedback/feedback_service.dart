import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindforge/shared/feedback/moment.dart';

/// The one place a [Moment] turns into something the player can feel or hear.
///
/// A seam, deliberately empty at this point in the build. E05 needs to *fire*
/// moments — a pressed button commits — and E06 owns what firing one does. The
/// interface exists now so that fourteen components call one name, and so that
/// E06 replaces an implementation rather than rewriting call sites.
///
/// **Components never call `HapticFeedback` directly.** That is the whole
/// reason this type exists: haptics that are scattered cannot be turned off
/// from Settings, and a moment that is fired twice from two layers is felt
/// twice.
abstract interface class FeedbackService {
  /// Acknowledges that [moment] happened.
  ///
  /// Never throws and never awaits: a caller is telling the app what occurred,
  /// not asking it to do something it might fail at.
  void fire(Moment moment);
}

/// A [FeedbackService] that does nothing.
///
/// The default until E06 lands, and the correct implementation in a test that
/// is not asserting feedback. Silence is a valid rendering of every moment —
/// each one carries a non-motion, non-haptic residue in the UI itself.
final class SilentFeedbackService implements FeedbackService {
  /// Creates the no-op service.
  const SilentFeedbackService();

  @override
  void fire(Moment moment) {}
}

/// The app's feedback service.
///
/// E06 overrides this with the real implementation. A test overrides it with a
/// recording fake; there is exactly one such fake in the repository, at
/// `test/support/fake_feedback_service.dart`.
final Provider<FeedbackService> feedbackServiceProvider =
    Provider<FeedbackService>((ref) => const SilentFeedbackService());
