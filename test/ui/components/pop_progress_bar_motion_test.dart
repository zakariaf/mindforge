import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/theme/sunburst_motion.dart';
import 'package:mindforge/ui/components/pop_progress_bar.dart';

import '../../support/component_harness.dart';
import '../../support/locale_cases.dart';

/// The motion half of the progress bar.
///
/// E05 already asserts the bar's RESTING geometry mirrors. These are the
/// assertions about it moving, and they deliberately do not restate that.
void main() {
  const motion = SunburstMotion.sunburstPop;

  Widget bar(double value) => SizedBox(
    width: 200,
    child: PopProgressBar(value: value, semanticLabel: 'progress'),
  );

  /// The rect of the filled portion, which is the fractionally sized box.
  Rect fillRect(WidgetTester tester) =>
      tester.getRect(find.byType(FractionallySizedBox));

  Rect trackRect(WidgetTester tester) =>
      tester.getRect(find.byType(PopProgressBar));

  group('the fill grows from the start edge', () {
    testWidgets('flush left in English, flush right in Persian', (
      tester,
    ) async {
      final widths = <String, double>{};

      for (final localeCase in LocaleCase.bothDirections) {
        await tester.pumpPopComponent(bar(0.24), localeCase: localeCase);
        await tester.pump(motion.durState);

        final fill = fillRect(tester);
        final track = trackRect(tester);
        widths[localeCase.tag] = fill.width;

        if (localeCase.direction == TextDirection.ltr) {
          expect(fill.left, closeTo(track.left, 3), reason: localeCase.tag);
        } else {
          expect(fill.right, closeTo(track.right, 3), reason: localeCase.tag);
        }
      }

      expect(
        widths['fa'],
        widths['en'],
        reason: 'the same 24% is the same number of pixels in both directions',
      );
    });

    testWidgets('and it mirrors with no conditional and no slide', (
      tester,
    ) async {
      // The anchor is AlignmentDirectional.centerStart and mirrors by
      // construction. The fill CHANGES SIZE; it does not travel, so it is not a
      // DirectionalSlide and reads no direction of its own.
      final code = File('lib/ui/components/pop_progress_bar.dart')
          .readAsStringSync()
          .split('\n')
          .where((line) => !line.trimLeft().startsWith('//'))
          .join('\n');

      expect(code, isNot(contains('Directionality')));
      expect(code, isNot(contains('DirectionalSlide')));
      expect(code, contains('AlignmentDirectional.centerStart'));
    });
  });

  group('an advancing fill', () {
    testWidgets('tweens rather than jumping', (tester) async {
      await tester.pumpPopComponent(bar(0.24));
      await tester.pump(motion.durState);
      final from = fillRect(tester).width;

      await tester.pumpPopComponent(bar(0.32));
      await tester.pump(motion.durState ~/ 2);
      final midway = fillRect(tester).width;

      await tester.pump(motion.durState);
      final to = fillRect(tester).width;

      expect(to, greaterThan(from));
      expect(
        midway,
        greaterThan(from),
        reason: 'it has started moving half a durState in',
      );
      expect(
        midway,
        lessThan(to),
        reason: 'and it has not arrived yet, which is what tweening means',
      );
    });

    testWidgets('but a bar that has just appeared does not grow from zero', (
      tester,
    ) async {
      // The tween begins AT the value on first build. A results screen whose
      // bar swept up from empty every time it opened would be announcing
      // progress that did not just happen.
      await tester.pumpPopComponent(bar(0.62));
      final onFirstFrame = fillRect(tester).width;

      await tester.pump(motion.durState);

      expect(fillRect(tester).width, onFirstFrame);
      expect(onFirstFrame, greaterThan(0));
    });

    testWidgets('and lands on the same value under reduce motion', (
      tester,
    ) async {
      // Reduce motion collapses the duration to zero. The END VALUE is
      // identical either way: a player with motion off sees the same bar, on
      // the frame it changed.
      await tester.pumpPopComponent(bar(0.24), disableAnimations: true);
      await tester.pumpPopComponent(bar(0.32), disableAnimations: true);
      await tester.pump();

      final still = fillRect(tester).width;

      await tester.pumpPopComponent(bar(0.24));
      await tester.pumpPopComponent(bar(0.32));
      await tester.pump(motion.durState * 2);

      expect(fillRect(tester).width, closeTo(still, 0.01));
    });
  });
}
