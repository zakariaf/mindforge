import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/theme/sunburst_colors.dart';
import 'package:mindforge/theme/sunburst_type.dart';
import 'package:mindforge/ui/components/pop_button.dart';
import 'package:mindforge/ui/components/pop_card.dart';
import 'package:mindforge/ui/components/pop_chip.dart';
import 'package:mindforge/ui/components/pop_icon_button.dart';
import 'package:mindforge/ui/components/pop_surface.dart';
import 'package:mindforge/ui/glyphs/sunburst_glyph.dart';

import '../../support/component_harness.dart';
import '../../support/harness.dart';
import '../../support/load_app_fonts.dart';
import '../../support/locale_cases.dart';
import '../../support/sample_strings.dart';

void main() {
  const colours = SunburstColors.sunburstPop;
  final en = LocaleCase.all.first;
  final de = LocaleCase.all[1];
  final fa = LocaleCase.rightToLeft.first;

  setUpAll(loadAppFonts);

  BoxDecoration decorationOf(WidgetTester tester) =>
      tester.widget<DecoratedBox>(find.byType(DecoratedBox).first).decoration
          as BoxDecoration;

  group('PopButton variants', () {
    testWidgets('each paints its own fill slot', (tester) async {
      final expected = <PopButtonVariant, Color>{
        PopButtonVariant.primary: colours.accent,
        PopButtonVariant.success: colours.success,
        PopButtonVariant.secondary: colours.surfaceRaised,
        PopButtonVariant.ghost: Colors.transparent,
      };

      expect(
        expected.keys.toSet(),
        PopButtonVariant.values.toSet(),
        reason: 'a variant with no declared fill is a variant nobody designed',
      );

      for (final entry in expected.entries) {
        await tester.pumpPopComponent(
          PopButton(label: 'Play', variant: entry.key, onPressed: () {}),
        );

        expect(decorationOf(tester).color, entry.value, reason: '${entry.key}');
      }
    });

    testWidgets('the ghost draws no edge and no shadow', (tester) async {
      await tester.pumpPopComponent(
        PopButton(
          label: 'Play',
          variant: PopButtonVariant.ghost,
          onPressed: () {},
        ),
      );

      final decoration = decorationOf(tester);

      expect(decoration.border, isNull);
      expect(decoration.boxShadow, anyOf(isNull, isEmpty));
    });

    testWidgets('the label is textPrimary on every enabled fill', (
      tester,
    ) async {
      for (final variant in PopButtonVariant.values) {
        await tester.pumpPopComponent(
          PopButton(label: 'Play', variant: variant, onPressed: () {}),
        );

        expect(
          tester.widget<Text>(find.text('Play')).style!.color,
          colours.textPrimary,
          reason: '$variant',
        );
      }
    });
  });

  group('PopButton sizes', () {
    testWidgets('large takes the buttonLarge step', (tester) async {
      late SunburstType type;

      await tester.pumpPopComponent(
        Builder(
          builder: (context) {
            type = SunburstType.of(context);
            return PopButton(
              label: 'Play',
              size: PopButtonSize.large,
              onPressed: () {},
            );
          },
        ),
      );

      expect(
        tester.widget<Text>(find.text('Play')).style!.fontSize,
        type.buttonLarge.fontSize,
      );
    });
  });

  group('PopButton state', () {
    testWidgets('a null onPressed disables it, and there is no second flag', (
      tester,
    ) async {
      // One answer to "is this live". Two flags is how a button ends up
      // looking enabled and doing nothing.
      await tester.pumpPopComponent(
        const PopButton(label: 'Play', onPressed: null),
      );

      expect(decorationOf(tester).color, colours.surfaceSunk);
      expect(
        tester.widget<Text>(find.text('Play')).style!.color,
        colours.textDisabled,
      );
    });
  });

  group('the leading glyph', () {
    testWidgets('sits at the start edge in both directions', (tester) async {
      // The grep for a physical inset cannot see a Row whose child ORDER was
      // hardcoded for LTR, which is why this is measured rather than scanned.
      Future<(Rect glyph, Rect label)> rectsIn(LocaleCase localeCase) async {
        await tester.pumpPopComponent(
          PopButton(
            label: 'Play',
            leading: SunburstGlyph.go,
            onPressed: () {},
          ),
          localeCase: localeCase,
        );

        return (
          tester.getRect(find.byType(SunburstGlyphIcon)),
          tester.getRect(find.text('Play')),
        );
      }

      final (ltrGlyph, ltrLabel) = await rectsIn(en);
      expect(ltrGlyph.left, lessThan(ltrLabel.left));

      final (rtlGlyph, rtlLabel) = await rectsIn(fa);
      expect(rtlGlyph.left, greaterThan(rtlLabel.left));
    });
  });

  group('German', () {
    testWidgets('wraps rather than shrinking, on the narrowest phone', (
      tester,
    ) async {
      // accessibility-as-code rules 4 and 5: nothing shrinks to fit. A label
      // that stops fitting takes a smaller BASE step or a different layout —
      // never a FittedBox, never an ellipsis, never a clamped scaler.
      late SunburstType type;

      await tester.pumpPopComponent(
        Builder(
          builder: (context) {
            type = SunburstType.of(context);
            return SizedBox(
              width: 200,
              child: PopButton(
                label: sampleStrings['de']!.navSettings,
                onPressed: () {},
              ),
            );
          },
        ),
        device: Device.compact320,
        localeCase: de,
      );

      final text = tester.widget<Text>(
        find.text(sampleStrings['de']!.navSettings),
      );

      expect(tester.takeException(), isNull);
      expect(
        text.style!.fontSize,
        type.button.fontSize,
        reason: 'nothing shrank',
      );
      expect(text.overflow, isNull, reason: 'no ellipsis on a label');
      expect(find.byType(FittedBox), findsNothing);
    });
  });

  group('PopIconButton', () {
    testWidgets('is at least 48 square and speaks its label', (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpPopComponent(
        PopIconButton(
          glyph: SunburstGlyph.close,
          semanticLabel: 'Close',
          onPressed: () {},
        ),
      );

      final size = tester.getSize(find.byType(PopIconButton));

      expect(size.width, greaterThanOrEqualTo(kPopMinTarget));
      expect(size.height, greaterThanOrEqualTo(kPopMinTarget));
      expect(
        tester.getSemantics(find.bySemanticsLabel('Close')),
        matchesSemantics(
          label: 'Close',
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );

      handle.dispose();
    });

    testWidgets('and its directional glyph still mirrors inside a surface', (
      tester,
    ) async {
      // The composed check: the flip has to survive being wrapped.
      for (final localeCase in <LocaleCase>[en, fa]) {
        await tester.pumpPopComponent(
          PopIconButton(
            glyph: SunburstGlyph.back,
            semanticLabel: 'Back',
            onPressed: () {},
          ),
          localeCase: localeCase,
        );

        final flipped = find
            .descendant(
              of: find.byType(SunburstGlyphIcon),
              matching: find.byType(Transform),
            )
            .evaluate()
            .isNotEmpty;

        expect(flipped, localeCase == fa, reason: localeCase.tag);
      }
    });
  });

  group('PopChip', () {
    testWidgets('renders Persian digits with no notdef box', (tester) async {
      await tester.pumpPopComponent(
        PopChip(label: sampleStrings['fa']!.score),
        localeCase: fa,
      );

      expect(tester.takeException(), isNull);
      expect(find.text('۱٬۴۸۰'), findsOneWidget);
    });

    testWidgets('and does not claim the 48pt floor', (tester) async {
      // A chip is a label, not a target: claiming the floor would push every
      // row it sits in taller than the design.
      await tester.pumpPopComponent(const PopChip(label: 'Reaction'));

      expect(
        tester.getSize(find.byType(PopChip)).height,
        lessThan(kPopMinTarget),
      );
    });
  });

  group('PopCard', () {
    testWidgets('is not a control without an onTap', (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpPopComponent(
        const PopCard(
          semanticLabel: 'Stats',
          child: SizedBox(width: 100, height: 60),
        ),
      );

      expect(
        tester.getSemantics(find.bySemanticsLabel('Stats')),
        matchesSemantics(label: 'Stats'),
      );

      handle.dispose();
    });

    testWidgets('density maps to elevation', (tester) async {
      const expected = <PopCardDensity, PopElevation>{
        PopCardDensity.dense: PopElevation.e1,
        PopCardDensity.standard: PopElevation.e2,
        PopCardDensity.hero: PopElevation.e3,
      };

      expect(expected.keys.toSet(), PopCardDensity.values.toSet());

      for (final entry in expected.entries) {
        expect(entry.key.elevation, entry.value, reason: '${entry.key}');
      }
    });

    testWidgets('its divider is a 3px ink rule, not the divider slot', (
      tester,
    ) async {
      // Inside a card the separation is part of the same drawing as the card's
      // own edge; a lighter hairline reads as a different construction.
      await tester.pumpPopComponent(const PopCardDivider());

      final box = tester.widget<Container>(find.byType(Container));

      expect(tester.getSize(find.byType(PopCardDivider)).height, 3);
      expect(box.color, colours.border);
    });
  });
}
