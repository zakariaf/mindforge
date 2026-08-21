import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/features/shell/widgets/top_bar.dart';
import 'package:mindforge/ui/components/pop_chip.dart';
import 'package:mindforge/ui/components/pop_icon_button.dart';
import 'package:mindforge/ui/glyphs/sunburst_glyph.dart';

import '../../../support/component_harness.dart';
import '../../../support/harness.dart';
import '../../../support/locale_cases.dart';

void main() {
  group('the bar app.html draws above a screen', () {
    testWidgets('is leading, title, trailing on one row', (tester) async {
      await tester.pumpPopComponent(
        TopBar(
          leading: PopIconButton(
            glyph: SunburstGlyph.pause,
            semanticLabel: 'pause',
            onPressed: () {},
          ),
          title: 'Stroop Rush',
          trailing: const PopChip(label: 'Classic'),
        ),
      );

      expect(find.byType(PopIconButton), findsOneWidget);
      expect(find.text('Stroop Rush'), findsOneWidget);
      expect(find.byType(PopChip), findsOneWidget);
    });

    testWidgets('and the title is DRAWN, never announced', (tester) async {
      // Every screen that carries this bar names itself again below it — the
      // hero panel on game detail, the Semantics header on play. A bar that
      // also announced would make a screen reader say the game's name twice
      // before reaching anything new.
      await tester.pumpPopComponent(
        const TopBar(title: 'Stroop Rush'),
      );

      expect(find.text('Stroop Rush'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Stroop Rush'),
        findsNothing,
        reason: 'the title is decoration; the h1 lives on the screen',
      );
    });

    testWidgets('and it takes the padding app.html states', (tester) async {
      // `.topbar{padding:2px 20px 16px}` — DERIVED nothing, transcribed.
      await tester.pumpPopComponent(const TopBar(title: 'x'));

      final padding = tester.widget<Padding>(
        find
            .descendant(
              of: find.byType(TopBar),
              matching: find.byType(Padding),
            )
            .first,
      );

      expect(
        padding.padding,
        const EdgeInsetsDirectional.fromSTEB(20, 2, 20, 16),
      );
    });

    testWidgets('and a long title ELLIPSES rather than shoving the chip out', (
      tester,
    ) async {
      // The trailing chip is the difficulty. A title that pushed it off the
      // end would take the one piece of state the bar carries with it —
      // and `ckb` titles run longer than `en` ones.
      for (final localeCase in LocaleCase.all) {
        await tester.pumpPopComponent(
          const TopBar(
            title: 'A title long enough to need the whole bar and then some',
            trailing: PopChip(label: 'Classic'),
          ),
          localeCase: localeCase,
        );

        expect(tester.takeException(), isNull, reason: localeCase.tag);
        expect(
          tester.widget<Text>(find.textContaining('A title long')).overflow,
          TextOverflow.ellipsis,
        );
      }
    });

    testWidgets('and the TRAILING shrinks too, at 320 and x2.0', (
      tester,
    ) async {
      // Ellipsing the title is only half of it: the chip is intrinsic, and at
      // x2.0 on the narrowest phone "Klassisch" is wider than what an ellipsed
      // title leaves. The row overflowed to the RIGHT — physical side, because
      // that is what a RenderFlex reports — in de, en and both scales at 320.
      await tester.pumpPopComponent(
        const TopBar(
          title: 'Stroop Rush',
          leading: PopChip(label: 'x'),
          trailing: PopChip(label: 'Klassisch'),
        ),
        device: Device.compact320,
        textScaler: const TextScaler.linear(2),
      );

      expect(tester.takeException(), isNull);
    });
  });
}
