import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/core/app_settings.dart';
import 'package:mindforge/data/data_providers.dart';
import 'package:mindforge/shared/feedback/feedback_gates.dart';

void main() {
  ProviderContainer containerFor(
    AppSettings seed, {
    Stream<AppSettings>? stream,
  }) {
    final container = ProviderContainer(
      overrides: [
        initialAppSettingsProvider.overrideWithValue(seed),
        settingsProvider.overrideWith(
          (ref) => stream ?? Stream<AppSettings>.value(seed),
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('the seed', () {
    test('answers on the first frame, before the stream has emitted', () {
      // A player who turned haptics off does not want one buzz on launch while
      // the stream catches up. Same shape as localeProvider, same reason.
      final container = containerFor(
        const AppSettings.defaults().copyWith(isHapticsEnabled: false),
        stream: const Stream<AppSettings>.empty(),
      );

      expect(container.read(hapticsEnabledProvider), isFalse);
    });

    test('and the defaults have all three on', () {
      final container = containerFor(const AppSettings.defaults());

      expect(container.read(hapticsEnabledProvider), isTrue);
      expect(container.read(soundEnabledProvider), isTrue);
      expect(container.read(reduceMotionEnabledProvider), isFalse);
    });
  });

  group('the stream wins once it emits', () {
    test('flipping a toggle changes the gate', () async {
      final controller = StreamController<AppSettings>();
      addTearDown(controller.close);

      final container = containerFor(
        const AppSettings.defaults(),
        stream: controller.stream,
      );
      // Keep the stream provider alive: an unlistened one is never subscribed,
      // so it would sit on its seed forever.
      final subscription = container.listen(
        settingsProvider,
        (_, _) {},
        fireImmediately: true,
      );
      addTearDown(subscription.close);

      expect(container.read(soundEnabledProvider), isTrue);

      controller.add(
        const AppSettings.defaults().copyWith(isSoundEnabled: false),
      );
      await Future<void>.delayed(Duration.zero);

      expect(container.read(soundEnabledProvider), isFalse);
    });
  });

  group('the gates are independent', () {
    test('flipping sound does not rebuild the haptics watcher', () async {
      // THE POINT OF select. Three booleans on one object; a listener on one of
      // them must not wake when another moves. Without select every settings
      // write would rebuild every consumer of every gate.
      final controller = StreamController<AppSettings>();
      addTearDown(controller.close);

      final container = containerFor(
        const AppSettings.defaults(),
        stream: controller.stream,
      );
      final keepAlive = container.listen(
        settingsProvider,
        (_, _) {},
        fireImmediately: true,
      );
      addTearDown(keepAlive.close);

      var hapticRebuilds = 0;
      final subscription = container.listen(
        hapticsEnabledProvider,
        (_, _) => hapticRebuilds++,
      );
      addTearDown(subscription.close);

      controller.add(
        const AppSettings.defaults().copyWith(isSoundEnabled: false),
      );
      await Future<void>.delayed(Duration.zero);

      expect(container.read(soundEnabledProvider), isFalse);
      expect(hapticRebuilds, 0);
    });

    test('and turning haptics off leaves sound alone', () {
      final container = containerFor(
        const AppSettings.defaults().copyWith(isHapticsEnabled: false),
      );

      expect(container.read(hapticsEnabledProvider), isFalse);
      expect(container.read(soundEnabledProvider), isTrue);
    });
  });
}
