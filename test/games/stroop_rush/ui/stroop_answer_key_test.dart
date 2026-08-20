import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/games/stroop_rush/domain/stroop_board_state.dart';
import 'package:mindforge/games/stroop_rush/ui/board/answer_key.dart';
import 'package:mindforge/games/stroop_rush/ui/board/play_fill_painter.dart';
import 'package:mindforge/shared/motion/shake_on_wrong.dart';
import 'package:mindforge/theme/sunburst_colors.dart';
import 'package:mindforge/theme/sunburst_shape.dart';
import 'package:mindforge/ui/components/pop_surface.dart';

import '../../../support/component_harness.dart';
import '../../../support/locale_cases.dart';

/// One answer key, in four states and two directions.
void main() {
  const colours = SunburstColors.sunburstPop;
  const shape = SunburstShape.sunburstPop;

  Widget keyFor(
    AnswerKeyState state, {
    PlayAnswer answer = PlayAnswer.red,
    bool colourBlind = false,
    int wrongTapId = 0,
  }) => SizedBox(
    width: 170,
    child: StroopAnswerKey(
      answer: answer,
      label: 'Red',
      state: state,
      isColourBlindPalette: colourBlind,
      wrongTapId: wrongTapId,
      onTap: state == AnswerKeyState.locked ? null : () {},
    ),
  );

  PopSurface surfaceOf(WidgetTester tester) => tester.widget<PopSurface>(
    find
        .descendant(
          of: find.byType(StroopAnswerKey),
          matching: find.byType(PopSurface),
        )
        .first,
  );

  /// The state's own translate — the Transform NEAREST the surface.
  ///
  /// Not `.first`: the shake wraps the key in a Transform of its own that sits
  /// at the identity between plays, and reading that one reports every state as
  /// untranslated.
  Offset translationOf(WidgetTester tester) {
    final transform = tester
        .widgetList<Transform>(
          find.ancestor(
            of: find.byType(PopSurface).first,
            matching: find.byType(Transform),
          ),
        )
        .first;

    return Offset(
      transform.transform.storage[12],
      transform.transform.storage[13],
    );
  }

  /// The pattern panel, found by its painter rather than by position.
  Finder panelFinder() => find.byWidgetPredicate(
    (widget) => widget is CustomPaint && widget.painter is PlayFillPainter,
  );

  group('each state renders its documented channels', () {
    const expected = <AnswerKeyState, (PopElevation, Offset, bool)>{
      AnswerKeyState.idle: (PopElevation.e2, Offset.zero, false),
      AnswerKeyState.accepted: (PopElevation.e3, Offset.zero, false),
      AnswerKeyState.rejected: (
        PopElevation.flat,
        SunburstShape.pressedShadow,
        true,
      ),
      AnswerKeyState.locked: (PopElevation.flat, Offset.zero, false),
    };

    for (final entry in expected.entries) {
      testWidgets(entry.key.name, (tester) async {
        // Three separated channels per state, none of them hue: the fill never
        // changes, so a player who cannot tell the colours apart still reads
        // the state from the depth, the travel and the bar.
        await tester.pumpPopComponent(keyFor(entry.key));

        expect(surfaceOf(tester).elevation, entry.value.$1);
        expect(translationOf(tester), entry.value.$2);
        expect(
          find.descendant(
            of: find.byType(StroopAnswerKey),
            matching: find.byType(ColoredBox),
          ),
          entry.value.$3 ? findsWidgets : findsNothing,
          reason: 'the ink strike bar',
        );
      });
    }
  });

  group('the fill is the answer colour, always', () {
    for (final state in AnswerKeyState.values) {
      testWidgets('${state.name} keeps the hue', (tester) async {
        // THE TEST THAT FAILS THE MOMENT SOMEONE PAINTS A WRONG KEY `danger`.
        // The question is about the colour; recolouring the key erases it.
        await tester.pumpPopComponent(keyFor(state));

        expect(surfaceOf(tester).fill, colours.playRed);
      });
    }

    testWidgets('and follows the colour-blind palette when the run did', (
      tester,
    ) async {
      await tester.pumpPopComponent(
        keyFor(AnswerKeyState.idle, colourBlind: true),
      );

      expect(surfaceOf(tester).fill, colours.cbPink);
    });
  });

  group('a resolved key', () {
    testWidgets('drops its onTap and never passes enabled: false', (
      tester,
    ) async {
      // `enabled: false` swaps the fill to surfaceSunk, which would erase the
      // answer. sunburst-components rule 6.
      await tester.pumpPopComponent(keyFor(AnswerKeyState.locked));

      final surface = surfaceOf(tester);

      expect(surface.onTap, isNull);
      expect(surface.enabled, isTrue);
    });

    testWidgets('and nothing in the subtree fades', (tester) async {
      // Opacity is a hue channel wearing a different name: it makes every
      // colour paler at once, which is the one thing that cannot distinguish
      // two answers.
      await tester.pumpPopComponent(keyFor(AnswerKeyState.locked));

      expect(
        find.descendant(
          of: find.byType(StroopAnswerKey),
          matching: find.byType(Opacity),
        ),
        findsNothing,
      );
    });
  });

  group('the label colour comes from the palette', () {
    testWidgets('ink on yellow, paper on the rest', (tester) async {
      for (final answer in <PlayAnswer>[
        PlayAnswer.yellow,
        PlayAnswer.red,
        PlayAnswer.blue,
        PlayAnswer.green,
      ]) {
        await tester.pumpPopComponent(
          keyFor(AnswerKeyState.idle, answer: answer),
        );

        expect(
          tester.widget<Text>(find.text('Red')).style!.color,
          colours.answerLabel(answer),
          reason: answer.name,
        );
      }
    });
  });

  group('the geometry mirrors and the shadow does not', () {
    testWidgets('the pattern panel sits at the START edge in both directions', (
      tester,
    ) async {
      // One Row with directional insets, no conditional. The panel leads
      // because it is the thing you scan first.
      final leads = <String, bool>{};

      for (final localeCase in LocaleCase.bothDirections) {
        await tester.pumpPopComponent(
          keyFor(AnswerKeyState.idle),
          localeCase: localeCase,
        );

        final key = tester.getRect(find.byType(StroopAnswerKey));
        final panel = tester.getRect(panelFinder());

        leads[localeCase.tag] = localeCase.direction == TextDirection.ltr
            ? (panel.left - key.left).abs() < 6
            : (key.right - panel.right).abs() < 6;
      }

      expect(leads['en'], isTrue);
      expect(leads['fa'], isTrue, reason: 'the panel did not mirror');
    });

    testWidgets('and the hard offset shadow is unchanged in all four', (
      tester,
    ) async {
      // THE ASSERTION A REVIEWER ASKS FOR. A mirrored shadow lights the RTL
      // half of the app from the other side of the room.
      for (final localeCase in LocaleCase.all) {
        await tester.pumpPopComponent(
          keyFor(AnswerKeyState.idle),
          localeCase: localeCase,
        );

        final shadow = tester
            .widgetList<DecoratedBox>(find.byType(DecoratedBox))
            .map((box) => box.decoration)
            .whereType<BoxDecoration>()
            .expand((d) => d.boxShadow ?? const <BoxShadow>[])
            .first;

        expect(shadow.offset, shape.e2, reason: localeCase.tag);
        expect(shadow.blurRadius, 0);
      }
    });

    testWidgets('and the strike bar spans the key in both directions', (
      tester,
    ) async {
      // start: 0, end: 0 — never a width, which becomes a half-bar under RTL.
      for (final localeCase in LocaleCase.bothDirections) {
        await tester.pumpPopComponent(
          keyFor(AnswerKeyState.rejected),
          localeCase: localeCase,
        );

        final key = tester.getRect(find.byType(StroopAnswerKey));
        final bar = tester.getRect(
          find
              .descendant(
                of: find.byType(StroopAnswerKey),
                matching: find.byType(ColoredBox),
              )
              .first,
        );

        expect(bar.width, closeTo(key.width, 8), reason: localeCase.tag);
      }
    });
  });

  group('the shake is E06 widget, wired', () {
    testWidgets('a rejected key is wrapped and keyed on the wrong-tap id', (
      tester,
    ) async {
      // The widget's two-cycle behaviour, its disposal and its reduce-motion
      // collapse are asserted in its OWN test. What this epic owns is the key
      // that tells one wrong tap from the next.
      await tester.pumpPopComponent(
        keyFor(AnswerKeyState.rejected, wrongTapId: 3),
      );

      final shake = tester.widget<ShakeOnWrong>(find.byType(ShakeOnWrong));

      expect(shake.isWrong, isTrue);
      expect(shake.key, const ValueKey<int>(3));
    });

    testWidgets('and a second wrong tap on the same key gets a new key', (
      tester,
    ) async {
      await tester.pumpPopComponent(
        keyFor(AnswerKeyState.rejected, wrongTapId: 1),
      );
      final first = tester.widget<ShakeOnWrong>(find.byType(ShakeOnWrong)).key;

      await tester.pumpPopComponent(
        keyFor(AnswerKeyState.rejected, wrongTapId: 2),
      );

      expect(
        tester.widget<ShakeOnWrong>(find.byType(ShakeOnWrong)).key,
        isNot(first),
      );
    });

    testWidgets('and the ink bar survives reduce motion, when the shake does '
        'not', (tester) async {
      // THE NON-MOTION RESIDUE. A player with animation off still has to be
      // told which key was wrong.
      await tester.pumpPopComponent(
        keyFor(AnswerKeyState.rejected),
        disableAnimations: true,
      );

      expect(
        find.descendant(
          of: find.byType(StroopAnswerKey),
          matching: find.byType(ColoredBox),
        ),
        findsWidgets,
      );
      expect(translationOf(tester), SunburstShape.pressedShadow);
    });
  });
}
