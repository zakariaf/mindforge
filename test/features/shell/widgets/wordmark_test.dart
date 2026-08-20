import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/features/shell/widgets/wordmark.dart';
import 'package:mindforge/theme/sunburst_colors.dart';
import 'package:mindforge/theme/sunburst_shape.dart';

import '../../../support/component_harness.dart';
import '../../../support/locale_cases.dart';

/// The product lockup.
///
/// A Latin brand string inside an RTL page: the one place in MindForge where a
/// direction is pinned rather than inherited, and the reason is bidi, not
/// taste.
void main() {
  const colours = SunburstColors.sunburstPop;
  const shape = SunburstShape.sunburstPop;

  group('semantics', () {
    testWidgets('is labelled MindForge and is NOT a header', (tester) async {
      // A screen has one h1 and this is not it, so the heading list stays
      // useful.
      await tester.pumpPopComponent(const Wordmark());

      final node = tester.getSemantics(find.byType(Wordmark));

      expect(node.label, 'MindForge');
      expect(node.flagsCollection.isHeader, isFalse);
    });

    testWidgets('and announces the name exactly once', (tester) async {
      // The tile and the text are excluded beneath the label; without that the
      // reader says "MindForge, MindForge".
      await tester.pumpPopComponent(const Wordmark());

      expect(tester.getSemantics(find.byType(Wordmark)).label, 'MindForge');
      expect(
        find.descendant(
          of: find.byType(Wordmark),
          matching: find.byType(ExcludeSemantics),
        ),
        findsOneWidget,
      );
    });
  });

  group('the direction pin', () {
    testWidgets('the name is LTR in every locale, including the RTL two', (
      tester,
    ) async {
      // A Latin run in an RTL paragraph is reordered by the bidi algorithm
      // unless it is isolated — which is how a wordmark renders as "orgeMindF"
      // beside a Persian sentence.
      for (final localeCase in LocaleCase.all) {
        await tester.pumpPopComponent(
          const Wordmark(),
          localeCase: localeCase,
        );

        final text = tester.widget<Text>(
          find.descendant(
            of: find.byType(Wordmark),
            matching: find.byType(Text),
          ),
        );

        expect(text.textDirection, TextDirection.ltr, reason: localeCase.tag);
        expect(
          text.data,
          'MindForge',
          reason: 'the brand is never translated and never cased in Dart',
        );
      }
    });

    testWidgets('and the tile still LEADS in every locale', (tester) async {
      // The pin is on the NAME, not on the lockup. The tile-then-name order is
      // reading order and mirrors like everything else, which is the
      // distinction the pin is easy to get wrong in.
      final leads = <String, bool>{};

      for (final localeCase in LocaleCase.bothDirections) {
        await tester.pumpPopComponent(
          const Wordmark(),
          localeCase: localeCase,
        );

        final tile = tester.getRect(
          find
              .descendant(
                of: find.byType(Wordmark),
                matching: find.byType(Container),
              )
              .first,
        );
        final name = tester.getRect(
          find.descendant(
            of: find.byType(Wordmark),
            matching: find.byType(Text),
          ),
        );

        leads[localeCase.tag] = localeCase.direction == TextDirection.ltr
            ? tile.left < name.left
            : tile.right > name.right;
      }

      expect(leads['en'], isTrue);
      expect(leads['fa'], isTrue, reason: 'the lockup did not mirror');
    });
  });

  group('the construction', () {
    testWidgets('is a coral tile with a 3px ink border and a cream centre', (
      tester,
    ) async {
      await tester.pumpPopComponent(const Wordmark());

      final tile = tester
          .widgetList<Container>(
            find.descendant(
              of: find.byType(Wordmark),
              matching: find.byType(Container),
            ),
          )
          .first;
      final decoration = tile.decoration! as BoxDecoration;

      expect(decoration.color, colours.accentWarm);
      expect((decoration.border! as Border).top.width, shape.borderWidth);
      expect(
        tester.getSize(find.byType(Container).first),
        Size(shape.wordmarkTile, shape.wordmarkTile),
      );
    });
  });
}
