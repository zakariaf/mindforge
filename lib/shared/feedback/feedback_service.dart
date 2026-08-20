import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindforge/shared/feedback/feedback_gates.dart';
import 'package:mindforge/shared/feedback/haptic_gateway.dart';
import 'package:mindforge/shared/feedback/moment.dart';
import 'package:mindforge/shared/feedback/moment_catalog.dart';
import 'package:mindforge/shared/feedback/sound_cue.dart';

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

  /// The sound [moment] would play, or `null` when sound is off or unassigned.
  SoundCue? soundCueFor(Moment moment);
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

  @override
  SoundCue? soundCueFor(Moment moment) => null;
}

/// The real service: the catalog, gated by the player's settings.
///
/// Plain `bool`s rather than a `Ref`, so every test of its behaviour is a unit
/// test with no container.
///
/// **It takes no motion input at all.** Reduce motion changes what a moment
/// *looks* like; it does not change whether the device acknowledges a tap. An
/// early return above `fire()` for reduced motion is the bug this shape exists
/// to make unwritable — a player who turned animation off still wants to feel
/// their answer land.
final class LiveFeedbackService implements FeedbackService {
  /// Creates a service gated by [hapticsEnabled] and [soundEnabled].
  const LiveFeedbackService({
    required this.gateway,
    required this.hapticsEnabled,
    required this.soundEnabled,
    required this.onError,
  });

  /// Where a verb goes.
  final HapticGateway gateway;

  /// Whether the player wants to feel anything.
  final bool hapticsEnabled;

  /// Whether the player wants to hear anything.
  final bool soundEnabled;

  /// Where a failed haptic is recorded.
  final void Function(Object error, StackTrace stack) onError;

  @override
  void fire(Moment moment) {
    if (!hapticsEnabled) return;

    final verb = kMomentCatalog[moment]?.haptic;
    if (verb == null) return;

    // The WHOLE error contract, and the reason the gateway returns no typed
    // result: a device with no taptic engine has nothing to show, retry or
    // decide, and an unhandled rejection here would take a screen down over a
    // buzz that did not happen.
    unawaited(gateway.play(verb).catchError(onError));
  }

  @override
  SoundCue? soundCueFor(Moment moment) =>
      soundEnabled ? kMomentCatalog[moment]?.sound : null;
}

/// The app's feedback service.
///
/// **The provider and the interface are E05's and did not change.** Every
/// component in the catalog already calls through them; E06 replaced what is
/// behind the name, which is the whole point of having shipped a seam.
///
/// It rebuilds when a gate flips, so switching haptics off in Settings takes
/// effect on the next tap rather than on the next launch.
final Provider<FeedbackService> feedbackServiceProvider =
    Provider<FeedbackService>(
      (ref) => LiveFeedbackService(
        gateway: ref.watch(hapticGatewayProvider),
        hapticsEnabled: ref.watch(hapticsEnabledProvider),
        soundEnabled: ref.watch(soundEnabledProvider),
        onError: (error, stack) => debugPrint(
          'feedback: a haptic failed and was swallowed: '
          '${error.runtimeType}',
        ),
      ),
    );
