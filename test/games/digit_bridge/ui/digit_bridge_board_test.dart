import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/core/difficulty.dart';
import 'package:mindforge/core/game_id.dart';
import 'package:mindforge/core/run_config.dart';
import 'package:mindforge/games/digit_bridge/domain/bridge_difficulty_profile.dart';
import 'package:mindforge/games/digit_bridge/ui/board/bridge_chip.dart';
import 'package:mindforge/games/digit_bridge/ui/board/bridge_target.dart';
import 'package:mindforge/games/digit_bridge/ui/bridge_metrics.dart';
import 'package:mindforge/games/digit_bridge/ui/digit_bridge_board.dart';
import 'package:mindforge/l10n/locale_numbers.dart';
import 'package:mindforge/ui/components/hud_pill.dart';
import 'package:mindforge/ui/components/pop_surface.dart';

import '../../../support/component_harness.dart';
import '../../../support/harness.dart';
import '../../../support/load_app_fonts.dart';
import '../../../support/locale_cases.dart';

/// The board rectangle, at every size and in every language.
///
/// One `testWidgets` per tuple, never a loop inside one: Flutter reports an
/// overflow once per `RenderObject`, so a matrix written as one test reports
/// the first combination that broke and stays silent for the rest.
///
/// **Real fonts, every lane.** Ahem renders no Persian digit — it would draw an
/// em-square and bless a fit that does not exist — and this board's whole
/// content is digits in two scripts.
void main() {
  setUpAll(loadAppFonts);

  final run = RunConfig(
    gameId: GameId('digit_bridge'),
    difficulty: Difficulty.classic,
    seed: 42,
  );

  Future<void> pumpBoard(
    WidgetTester tester, {
    Device device = Device.reference390,
    LocaleCase? localeCase,
    TextScaler textScaler = TextScaler.noScaling,
  }) async {
    await tester.pumpPopComponent(
      SizedBox(
        // The board's own rectangle: the shell's 20pt gutter on each side, and
        // the play field's height at the reference.
        width: device.logicalSize.width - 40,
        height: 420,
        child: DigitBridgeBoard(run: run),
      ),
      localeCase: localeCase,
      device: device,
      textScaler: textScaler,
      resetFirst: true,
    );

    // The board opens on the first post-frame callback.
    await tester.pump();
  }

  group('the board draws no chrome', () {
    testWidgets('no HUD pill, no Scaffold, no SafeArea, no background', (
      tester,
    ) async {
      // The gutter and the lilac behind it are the shell's, asked for by the
      // definition's `BoardBackground.gameAccent`. A board that painted its own
      // would be the second owner of a colour.
      await pumpBoard(tester);

      expect(
        find.descendant(
          of: find.byType(DigitBridgeBoard),
          matching: find.byType(HudPill),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byType(DigitBridgeBoard),
          matching: find.byType(SafeArea),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byType(DigitBridgeBoard),
          matching: find.byType(ColoredBox),
        ),
        findsNothing,
      );
    });

    testWidgets('and the grid does not clip its own shadows', (tester) async {
      // Clip.none, or the e2 hard shadow is sheared off at the grid's edge --
      // the one defect that looks like a rendering glitch rather than a layout
      // mistake.
      await pumpBoard(tester);

      expect(
        tester.widget<GridView>(find.byType(GridView)).clipBehavior,
        Clip.none,
      );
    });
  });

  for (final device in <Device>[
    Device.compact320,
    Device.small360,
    Device.reference390,
  ]) {
    for (final localeCase in LocaleCase.all) {
      testWidgets(
        '${device.name} ${localeCase.tag} lays six chips out above the floor',
        (tester) async {
          await pumpBoard(tester, device: device, localeCase: localeCase);

          final chips = find.byType(BridgeChip);

          expect(chips, findsNWidgets(kBridgeCandidateCount));

          for (var i = 0; i < kBridgeCandidateCount; i++) {
            final size = tester.getSize(chips.at(i));

            expect(
              size.width,
              greaterThanOrEqualTo(kPopMinTarget),
              reason: 'chip $i is under the 48pt tap floor on ${device.name}',
            );
            expect(
              size.height,
              greaterThanOrEqualTo(kPopMinTarget),
              reason: 'chip $i is under the 48pt tap floor on ${device.name}',
            );
          }
        },
      );
    }
  }

  for (final localeCase in LocaleCase.all) {
    testWidgets('${localeCase.tag} fits at text scale 1.3', (tester) async {
      // Nothing shrinks to fit. If this overflows, the layout is wrong -- the
      // fix is never a clamped scaler or a FittedBox.
      await pumpBoard(
        tester,
        localeCase: localeCase,
        textScaler: const TextScaler.linear(1.3),
      );

      expect(tester.takeException(), isNull);
    });
  }

  group('the two scripts', () {
    testWidgets('the target and the chips never share a numbering system', (
      tester,
    ) async {
      // The board's whole question. If both sides rendered in the reader's own
      // script they would be identical runs and there would be nothing to ask.
      for (final localeCase in LocaleCase.all) {
        await pumpBoard(tester, localeCase: localeCase);

        final target = tester.widget<BridgeTarget>(find.byType(BridgeTarget));
        final chip = tester.widget<BridgeChip>(find.byType(BridgeChip).first);

        expect(
          AsciiNumerals.hasNonAsciiDigits(target.label),
          isNot(AsciiNumerals.hasNonAsciiDigits(chip.label)),
          reason:
              'under ${localeCase.tag} both sides drew the same script, so the '
              'board asks nothing',
        );
      }
    });

    testWidgets('and both numerals read back to the same ASCII digits', (
      tester,
    ) async {
      // The match is on INTEGERS. This is the render-side half of that: a chip
      // showing the target must normalise to the same digits, whichever script
      // each of them happens to be drawn in.
      await pumpBoard(tester);

      final target = tester.widget<BridgeTarget>(find.byType(BridgeTarget));
      final normalised = AsciiNumerals.normalize(target.label);

      expect(int.tryParse(normalised), isNotNull);

      final chips = tester
          .widgetList<BridgeChip>(find.byType(BridgeChip))
          .map((chip) => AsciiNumerals.normalize(chip.label))
          .toList();

      expect(chips, contains(normalised));
      expect(chips.toSet(), hasLength(kBridgeCandidateCount));
    });
  });

  group('the chip grid mirrors while the numerals do not', () {
    testWidgets('chip zero leads in both directions', (tester) async {
      await pumpBoard(tester, localeCase: LocaleCase.english);
      final ltrFirst = tester.getTopLeft(find.byType(BridgeChip).first).dx;
      final ltrLast = tester.getTopLeft(find.byType(BridgeChip).at(2)).dx;

      await pumpBoard(tester, localeCase: LocaleCase.persian);
      final rtlFirst = tester.getTopLeft(find.byType(BridgeChip).first).dx;
      final rtlLast = tester.getTopLeft(find.byType(BridgeChip).at(2)).dx;

      expect(
        ltrFirst,
        lessThan(ltrLast),
        reason: 'chip 0 is on the left in English',
      );
      expect(
        rtlFirst,
        greaterThan(rtlLast),
        reason: 'chip 0 is on the right in Persian -- the grid mirrors',
      );
    });

    testWidgets('and the numeral run itself keeps its own direction', (
      tester,
    ) async {
      // A numeral's most significant digit is on the left in BOTH scripts. The
      // pin lives in one widget, BridgeNumeral, and this is what it buys.
      await pumpBoard(tester, localeCase: LocaleCase.persian);

      final numeral = find.descendant(
        of: find.byType(BridgeTarget),
        matching: find.byType(Directionality),
      );

      expect(numeral, findsWidgets);
      expect(
        tester.widget<Directionality>(numeral.last).textDirection,
        TextDirection.ltr,
      );
    });
  });

  group('metrics', () {
    test('the gap steps down rather than sliding, to defend the tap floor', () {
      // A gap that slid continuously would put a different number on every
      // device and make a screenshot comparison meaningless.
      //
      // The narrow case is BELOW ANY SHIPPED DEVICE, deliberately: the
      // narrowest is 320pt, which leaves the board 280pt after the shell's
      // gutter, and three columns at the roomy gap is 85.3pt there. The step
      // binds under 168pt. Testing it at a width no phone has is what keeps a
      // dormant floor honest rather than dead.
      const shippedNarrowest = Size(280, 420);
      const belowAnyDevice = Size(160, 420);

      expect(
        BridgeMetrics.forField(shippedNarrowest).gap,
        BridgeMetrics.roomyGap,
      );
      expect(
        BridgeMetrics.forField(belowAnyDevice).gap,
        BridgeMetrics.tightGap,
      );
    });

    test('and a chip never draws under the tap floor', () {
      for (final width in <double>[320, 360, 375, 390, 430]) {
        final metrics = BridgeMetrics.forField(Size(width - 40, 420));

        expect(metrics.chipHeight, greaterThanOrEqualTo(kPopMinTarget));
      }
    });
  });
}
