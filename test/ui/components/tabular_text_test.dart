import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/l10n/bidi_text.dart';
import 'package:mindforge/l10n/locale_numbers.dart';
import 'package:mindforge/ui/components/tabular_text.dart';

import '../../support/component_harness.dart';
import '../../support/locale_cases.dart';

/// A number reads left to right in every language.
///
/// This file exists because the device said otherwise. `1,480` rendered as
/// `۰۸۴٬۱` on the canonical simulator under Sorani — the digits reversed —
/// while the same string in a plain `Text` was correct in E04's RTL golden.
/// The golden lane could not see it: it renders `Text`, and this widget is a
/// `Row` of one box per character.
void main() {
  /// The characters, in the physical order they are painted.
  List<String> paintedOrder(WidgetTester tester) {
    final row = tester.widget<Row>(
      find.descendant(of: find.byType(TabularText), matching: find.byType(Row)),
    );

    // Children in list order are painted start-to-end for LTR and end-to-start
    // for RTL, so the direction is the whole question.
    final characters = tester
        .widgetList<Text>(
          find.descendant(
            of: find.byType(TabularText),
            matching: find.byType(Text),
          ),
        )
        .map((t) => t.data ?? '')
        .toList();

    return row.textDirection == TextDirection.rtl
        ? characters.reversed.toList()
        : characters;
  }

  group('the digit run is laid out left to right', () {
    for (final localeCase in LocaleCase.all) {
      testWidgets('in ${localeCase.tag}', (tester) async {
        // THE BUG: a Row inheriting the ambient RTL direction puts the leading
        // digit on the RIGHT, so 1,480 paints as 0,841 reversed. Splitting a
        // number into one widget per character destroys the bidi rule that a
        // numeric run is displayed LTR inside an RTL paragraph, because each
        // character is now its own paragraph and the Row does the ordering.
        final value = LocaleNumbers(localeCase.locale).count(1480);

        await tester.pumpPopComponent(
          TabularText(value, style: const TextStyle(fontSize: 20)),
          localeCase: localeCase,
        );

        expect(
          paintedOrder(tester).join(),
          value,
          reason:
              '${localeCase.tag}: painted order must equal logical order. A '
              'number is not re-ordered by reading direction',
        );
      });
    }

    testWidgets('and the leading digit is physically leftmost under fa', (
      tester,
    ) async {
      // The same claim measured in pixels rather than in child order, because
      // the child-order version would pass if someone reversed the list AND
      // the direction.
      final value = LocaleNumbers(LocaleCase.persian.locale).count(1480);

      await tester.pumpPopComponent(
        TabularText(value, style: const TextStyle(fontSize: 20)),
        localeCase: LocaleCase.persian,
      );

      final glyphs = find.descendant(
        of: find.byType(TabularText),
        matching: find.byType(Text),
      );

      final first = tester.getTopLeft(glyphs.first).dx;
      final last = tester.getTopLeft(glyphs.last).dx;

      expect(
        first,
        lessThan(last),
        reason: 'the leading digit paints to the left of the trailing one',
      );
    });
  });

  group('what it still owes the reader', () {
    testWidgets('the whole value is one semantic node', (tester) async {
      // A fixed layout is worth nothing if it costs the announcement: without
      // this a screen reader walks the per-character boxes and reads
      // "one, comma, four, eight, zero".
      await tester.pumpPopComponent(
        const TabularText('1,480', style: TextStyle(fontSize: 20)),
      );

      expect(
        tester.getSemantics(find.byType(TabularText)).label,
        '1,480',
      );
    });
  });

  group('a value that arrives bidi-isolated', () {
    testWidgets('lays out, rather than throwing a negative width', (
      tester,
    ) async {
      // AN ISOLATE MARK IS NOT A CHARACTER TO BOX. This widget splits a value
      // into one box per character and pins the row LTR — which is exactly
      // what an isolate is for, so the marks are redundant here and the split
      // makes them harmful: each box is its own paragraph, and a lone FSI in
      // one of them fed a negative width into IntrinsicHeight.
      //
      // On screen that was a results page with a green header and NOTHING
      // under it: no score, no stats, no buttons. Reached by finishing a
      // Schulte run, whose TILES stat is a fraction and therefore isolated.
      await tester.pumpPopComponent(
        SizedBox(
          width: 200,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Expanded(
                  child: TabularText(
                    BidiText.isolate('25 / 25'),
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('and still announces the whole value', (tester) async {
      // The marks are stripped from what is DRAWN, not from what is said.
      // Written as escapes: an invisible bidi control in source changes how
      // the surrounding code READS to a human while meaning something else to
      // the compiler, which is a review hazard the analyzer is right to flag.
      const isolated =
          '\u2068'
          '18.6s'
          '\u2069';

      await tester.pumpPopComponent(
        const TabularText(isolated, style: TextStyle(fontSize: 22)),
      );

      expect(
        tester.getSemantics(find.byType(TabularText)).label,
        isolated,
      );
    });

    testWidgets('and draws no box for a control character', (tester) async {
      await tester.pumpPopComponent(
        TabularText(
          BidiText.isolate('7'),
          style: const TextStyle(fontSize: 22),
        ),
      );

      final drawn = tester
          .widgetList<Text>(
            find.descendant(
              of: find.byType(TabularText),
              matching: find.byType(Text),
            ),
          )
          .map((text) => text.data)
          .join();

      expect(drawn, '7', reason: 'the isolate marks were boxed as characters');
    });
  });

  group('a value that is not only a number', () {
    testWidgets('is drawn as ONE text, because Arabic letters join', (
      tester,
    ) async {
      // THE DEFECT THIS EXISTS FOR. Stats' "time trained" is a whole sentence
      // in Persian — `۰ ساعت و ۰ دقیقه` — and this widget splits a value into
      // one box per character. Each box is its own paragraph, so every letter
      // is shaped in ISOLATED form and the joins that make Arabic script
      // readable are gone; the row is then laid out LTR, which reverses the
      // words on top of it. On screen it was an unreadable smear that also
      // overflowed its box.
      //
      // Latin never showed it: `0h 0m` split into boxes still reads, because
      // Latin letters do not join. So this is a defect only the RTL sweep
      // could find.
      await tester.pumpPopComponent(
        const TabularText(
          '۰ ساعت و ۰ دقیقه',
          style: TextStyle(fontSize: 20),
        ),
      );

      final drawn = tester.widgetList<Text>(
        find.descendant(
          of: find.byType(TabularText),
          matching: find.byType(Text),
        ),
      );

      expect(
        drawn,
        hasLength(1),
        reason: 'a joined script must be shaped as one run, not per character',
      );
    });

    testWidgets('and German is not shredded either', (tester) async {
      // THE HALF THE FIRST FIX MISSED. `0 Std. 0 Min.` is prose too, and the
      // per-character row cannot wrap: at 2.0x it measured 275pt of content in
      // a 141pt viewport, so a German player saw it cut off mid-word with no
      // ellipsis and no scroll affordance. The first guard tested for a
      // JOINING script and rescued only Persian.
      await tester.pumpPopComponent(
        const TabularText('0 Std. 0 Min.', style: TextStyle(fontSize: 20)),
      );

      expect(
        tester.widgetList<Text>(
          find.descendant(
            of: find.byType(TabularText),
            matching: find.byType(Text),
          ),
        ),
        hasLength(1),
      );
    });

    testWidgets('but a value whose digits MOVE keeps its fixed pitch', (
      tester,
    ) async {
      // The line the guard draws. Every value that changes under the player's
      // eye — the clock, a score, a streak, a percentage — carries no letter
      // at all, which is why a letter is the right question to ask.
      for (final value in <String>['1,480', '0:00', '100%', '×7']) {
        await tester.pumpPopComponent(
          TabularText(value, style: const TextStyle(fontSize: 20)),
          resetFirst: true,
        );

        expect(
          tester.widgetList<Text>(
            find.descendant(
              of: find.byType(TabularText),
              matching: find.byType(Text),
            ),
          ),
          hasLength(greaterThan(1)),
          reason: '$value lost its tabular pitch',
        );
      }
    });
  });
}
