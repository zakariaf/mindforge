import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindforge/shared/feedback/haptic_verb.dart';

/// The one boundary between the app and the device's taptic engine.
///
/// **iOS is the only implemented and verified platform.** The interface names
/// none, so that stays a one-file question if Android is ever undeferred — but
/// nothing here has been run on Android and this doc does not imply parity.
///
/// **It returns `Future<void>`, not a typed result, and that is deliberate.**
/// `service-boundary-and-native` rule 4 asks every boundary for one. A haptic
/// that fails on an unsupported device has no recoverable branch and must never
/// reach the player: there is nothing to show, nothing to retry and nothing to
/// decide. The single `catchError` in `FeedbackService` is the whole error
/// contract, and it is there so a missing engine cannot take a screen down.
abstract interface class HapticGateway {
  /// Asks the device for [verb].
  Future<void> play(HapticVerb verb);
}

/// The real gateway.
///
/// **The only file in the app that names `HapticFeedback`.**
/// `test/policy/haptic_confinement_test.dart` asserts that, because haptics
/// that are scattered cannot be switched off from Settings and a moment fired
/// from two layers is felt twice.
final class LiveHapticGateway implements HapticGateway {
  /// Creates the live gateway.
  const LiveHapticGateway();

  @override
  Future<void> play(HapticVerb verb) => switch (verb) {
    // Exhaustive, with no default: a fifth verb does not compile until someone
    // decides what the device should do.
    HapticVerb.selectionClick => HapticFeedback.selectionClick(),
    HapticVerb.lightImpact => HapticFeedback.lightImpact(),
    HapticVerb.mediumImpact => HapticFeedback.mediumImpact(),
    HapticVerb.heavyImpact => HapticFeedback.heavyImpact(),
  };
}

/// The app's haptic gateway.
///
/// Throws until overridden, rather than defaulting to the live one: a provider
/// that silently works in a test is a provider that buzzes a developer's phone
/// during a suite run, and one that silently does nothing hides a missing
/// override in `bootstrap()`.
final Provider<HapticGateway> hapticGatewayProvider = Provider<HapticGateway>(
  (ref) => throw UnimplementedError(
    'override hapticGatewayProvider in bootstrap() or in a test',
  ),
);
