import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/theme/sunburst_colors.dart';
import 'package:mindforge/theme/sunburst_shape.dart';
import 'package:mindforge/ui/components/pop_surface.dart';

import '../../../support/component_harness.dart';
import '../../../support/locale_cases.dart';

/// THE ONE DELIBERATE NON-MIRRORING RULE IN THE WHOLE APP.
///
/// Every inset, alignment and slide in MindForge follows the reading
/// direction. The hard offset shadow does not: it is a light-source constant,
/// one imaginary light for the entire app, and a build whose buttons cast their
/// shadow up and to the start edge would be lit from the other side for no
/// reason a reader could name.
///
/// It lives in its own file because it is the assertion a reviewer goes
/// looking for, and because an RTL build that flipped it would keep every other
/// RTL checklist green.
void main() {
  const colours = SunburstColors.sunburstPop;
  const shape = SunburstShape.sunburstPop;

  testWidgets('a raised surface casts (5, 5) in all four locales', (
    tester,
  ) async {
    final offsets = <String, Offset>{};

    for (final localeCase in LocaleCase.all) {
      await tester.pumpPopComponent(
        PopSurface(
          fill: colours.accent,
          child: const SizedBox(width: 80, height: 40),
        ),
        localeCase: localeCase,
      );

      offsets[localeCase.tag] = tester
          .widgetList<DecoratedBox>(find.byType(DecoratedBox))
          .map((box) => box.decoration)
          .whereType<BoxDecoration>()
          .expand((d) => d.boxShadow ?? const <BoxShadow>[])
          .first
          .offset;
    }

    for (final tag in <String>['en', 'de', 'fa', 'ckb']) {
      expect(
        offsets[tag],
        shape.e2,
        reason:
            'the hard offset shadow mirrored under $tag — it is a light '
            'source, not a reading direction',
      );
    }
  });

  testWidgets('and it is hard: zero blur, zero spread, in every locale', (
    tester,
  ) async {
    for (final localeCase in LocaleCase.all) {
      await tester.pumpPopComponent(
        PopSurface(
          fill: colours.accent,
          elevation: PopElevation.e3,
          child: const SizedBox(width: 80, height: 40),
        ),
        localeCase: localeCase,
      );

      final shadow = tester
          .widgetList<DecoratedBox>(find.byType(DecoratedBox))
          .map((box) => box.decoration)
          .whereType<BoxDecoration>()
          .expand((d) => d.boxShadow ?? const <BoxShadow>[])
          .first;

      expect(shadow.blurRadius, 0, reason: localeCase.tag);
      expect(shadow.spreadRadius, 0, reason: localeCase.tag);
    }
  });
}
