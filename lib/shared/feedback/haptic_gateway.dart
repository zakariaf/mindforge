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
/// **Defaults to the live one**, which is what every entry point wants. It used
/// to throw until overridden, on the theory that a silent default would hide a
/// missing override — and the theory was wrong twice.
///
/// It was wrong about tests: `HapticFeedback` goes through a platform channel
/// with no handler registered under `flutter_test`, so [LiveHapticGateway]
/// neither buzzes nor throws there. Nothing was being protected.
///
/// And it was wrong about the cost. `PopSurface` reads the feedback service
/// inside its tap handler, so a scope missing the override did not get a silent
/// app — it got an app whose every button, tile and toggle was INERT, because
/// the exception came out of the gesture callback. That is a far worse failure
/// than the one the throw was guarding against, and it shipped in the developer
/// gallery.
///
/// A test that wants to observe haptics overrides this with `FakeHapticGateway`
/// — which every pumped tree does through the harness — and one that does not
/// care is now correct by default instead of broken by default.
final Provider<HapticGateway> hapticGatewayProvider = Provider<HapticGateway>(
  (ref) => const LiveHapticGateway(),
);
