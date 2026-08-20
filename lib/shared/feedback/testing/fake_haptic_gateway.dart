import 'package:mindforge/shared/feedback/haptic_gateway.dart';
import 'package:mindforge/shared/feedback/haptic_verb.dart';

/// Records what the app asked the device for.
///
/// It **implements** rather than extends [HapticGateway], so a method added to
/// the interface breaks this file's build instead of silently inheriting a
/// behaviour no test ever exercised.
///
/// It ships in `lib/` rather than `test/` because E09 and E10 both consume it,
/// and a fake that lives under one epic's test tree gets copied rather than
/// imported.
final class FakeHapticGateway implements HapticGateway {
  /// Creates a gateway that records and succeeds.
  FakeHapticGateway() : _fails = false;

  /// Creates a gateway that records and then **fails**.
  ///
  /// A fake that always succeeds is a happy-path lie: the error branch in
  /// `FeedbackService` exists precisely for a device with no taptic engine, and
  /// it cannot be tested against a gateway that cannot fail.
  FakeHapticGateway.failing() : _fails = true;

  final bool _fails;

  /// Every verb asked for, in order.
  final List<HapticVerb> played = <HapticVerb>[];

  @override
  Future<void> play(HapticVerb verb) {
    played.add(verb);

    return _fails
        ? Future<void>.error(StateError('no taptic engine'))
        : Future<void>.value();
  }
}
