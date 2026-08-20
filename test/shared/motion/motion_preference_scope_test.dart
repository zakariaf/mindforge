import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/core/app_settings.dart';
import 'package:mindforge/shared/motion/motion_preference_scope.dart';

import '../../support/harness.dart';

void main() {
  /// Pumps the scope over a probe and returns the flag the probe sees.
  Future<bool> pumpScope(
    WidgetTester tester, {
    required bool platformSaysOff,
    required bool appSaysOff,
  }) async {
    late bool seen;
    final settings = const AppSettings.defaults().copyWith(
      isReduceMotionEnabled: appSaysOff,
    );

    await tester.pumpWidget(
      settingsScope(
        settings: settings,
        child: MediaQuery(
          data: MediaQueryData(disableAnimations: platformSaysOff),
          child: MotionPreferenceScope(
            child: Builder(
              builder: (context) {
                seen = MediaQuery.disableAnimationsOf(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      ),
    );

    return seen;
  }

  group('the fold', () {
    testWidgets('neither off leaves animation on', (tester) async {
      expect(
        await pumpScope(tester, platformSaysOff: false, appSaysOff: false),
        isFalse,
      );
    });

    testWidgets('the app toggle alone disables animation', (tester) async {
      expect(
        await pumpScope(tester, platformSaysOff: false, appSaysOff: true),
        isTrue,
      );
    });

    testWidgets('and the OS setting alone does too, which is the whole '
        'reason this is an OR and not an assignment', (tester) async {
      // THE BUG THIS TEST EXISTS FOR: writing the app's answer over the
      // platform's — `disableAnimations: ref.watch(...)` instead of
      // `existing.disableAnimations || ref.watch(...)`. A player who switched
      // motion off at the OS level, which is the accessibility setting and not
      // a preference, must get stillness whatever the app's own toggle says.
      // Turning the app toggle OFF cannot turn animation back ON.
      expect(
        await pumpScope(tester, platformSaysOff: true, appSaysOff: false),
        isTrue,
      );
    });
  });

  group('what it does not touch', () {
    testWidgets('it keeps every other MediaQuery field', (tester) async {
      // copyWith, never a bare MediaQueryData(): constructing one from scratch
      // silently drops the size, the text scaler, the padding and every other
      // accessibility flag the app reads.
      late MediaQueryData seen;
      const source = MediaQueryData(
        size: Size(390, 844),
        devicePixelRatio: 2,
        textScaler: TextScaler.linear(1.3),
        boldText: true,
        padding: EdgeInsets.only(top: 47, bottom: 34),
      );

      await tester.pumpWidget(
        settingsScope(
          child: MediaQuery(
            data: source,
            child: MotionPreferenceScope(
              child: Builder(
                builder: (context) {
                  seen = MediaQuery.of(context);
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        ),
      );

      expect(seen.size, source.size);
      expect(seen.devicePixelRatio, source.devicePixelRatio);
      expect(seen.textScaler, source.textScaler);
      expect(seen.boldText, isTrue);
      expect(seen.padding, source.padding);
    });

    testWidgets('and it introduces no direction of its own', (tester) async {
      // A scope that quietly pinned a Directionality would make every RTL
      // screen below it read left-to-right, and the mistake would be invisible
      // on a developer device set to English.

      await tester.pumpWidget(
        settingsScope(
          child: const MediaQuery(
            data: MediaQueryData(),
            child: MotionPreferenceScope(child: SizedBox.shrink()),
          ),
        ),
      );

      expect(
        find.byType(Directionality),
        findsNothing,
        reason: 'direction comes from the locale, never from a motion scope',
      );
    });
  });
}
