import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/shared/feedback/haptic_gateway.dart';
import 'package:mindforge/shared/feedback/haptic_verb.dart';
import 'package:mindforge/shared/feedback/testing/fake_haptic_gateway.dart';

void main() {
  group('the fake', () {
    test('records each verb exactly once, in order', () async {
      final gateway = FakeHapticGateway();

      await gateway.play(HapticVerb.lightImpact);
      await gateway.play(HapticVerb.selectionClick);
      await gateway.play(HapticVerb.lightImpact);

      expect(gateway.played, <HapticVerb>[
        HapticVerb.lightImpact,
        HapticVerb.selectionClick,
        HapticVerb.lightImpact,
      ]);
    });

    test('and can be told to fail, so the error branch is reachable', () async {
      // A fake that always succeeds is a happy-path lie. The catchError in
      // FeedbackService exists for a device with no taptic engine, and it
      // cannot be tested against a gateway that cannot fail.
      final gateway = FakeHapticGateway.failing();

      await expectLater(
        gateway.play(HapticVerb.heavyImpact),
        throwsA(isA<StateError>()),
      );
      expect(gateway.played, <HapticVerb>[HapticVerb.heavyImpact]);
    });
  });

  group('the provider', () {
    test('throws until it is overridden', () {
      // Not a silent default. A provider that quietly returns the live gateway
      // buzzes a developer's phone during a test run; one that quietly returns
      // a no-op hides a missing override in bootstrap().
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Riverpod 3 wraps a provider's own throw in a ProviderException, so
      // the assertion is on what it carries rather than on the wrapper.
      expect(
        () => container.read(hapticGatewayProvider),
        throwsA(
          isA<Object>().having(
            (error) => error.toString(),
            'message',
            contains('override hapticGatewayProvider'),
          ),
        ),
      );
    });

    test('and serves the override when there is one', () {
      final fake = FakeHapticGateway();
      final container = ProviderContainer(
        overrides: [hapticGatewayProvider.overrideWithValue(fake)],
      );
      addTearDown(container.dispose);

      expect(container.read(hapticGatewayProvider), same(fake));
    });
  });

  group('the verb set', () {
    test('has no vibrate, so it cannot be reached', () {
      // A long buzz has no place in a game whose feedback is meant to feel
      // like something small and physical.
      expect(
        HapticVerb.values.map((verb) => verb.name),
        isNot(contains('vibrate')),
      );
      expect(HapticVerb.values, hasLength(4));
    });
  });
}
