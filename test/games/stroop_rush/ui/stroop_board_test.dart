import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/core/app_settings.dart';
import 'package:mindforge/core/difficulty.dart';
import 'package:mindforge/core/game_id.dart';
import 'package:mindforge/core/run_config.dart';
import 'package:mindforge/data/data_providers.dart';
import 'package:mindforge/games/stroop_rush/application/stroop_board_notifier.dart';
import 'package:mindforge/games/stroop_rush/domain/stroop_board_state.dart';
import 'package:mindforge/games/stroop_rush/ui/board/answer_key.dart';
import 'package:mindforge/games/stroop_rush/ui/stroop_board.dart';
import 'package:mindforge/ui/components/hud_pill.dart';
import 'package:mindforge/ui/components/pop_progress_bar.dart';
import 'package:mindforge/ui/components/pop_surface.dart';

import '../../../support/component_harness.dart';
import '../../../support/harness.dart';
import '../../../support/load_app_fonts.dart';
import '../../../support/locale_cases.dart';

/// The board rectangle, and nothing outside it.
void main() {
  setUpAll(loadAppFonts);

  final run = RunConfig(
    gameId: GameId('stroop_rush'),
    difficulty: Difficulty.classic,
    seed: 42,
  );

  Future<void> pumpBoard(
    WidgetTester tester, {
    LocaleCase? localeCase,
    Device device = Device.reference390,
    TextScaler textScaler = TextScaler.noScaling,
  }) => tester.pumpPopComponent(
    ProviderScope(
      overrides: [
        initialAppSettingsProvider.overrideWithValue(
          const AppSettings.defaults(),
        ),
        settingsProvider.overrideWith(
          (ref) => Stream<AppSettings>.value(const AppSettings.defaults()),
        ),
      ],
      child: SizedBox(
        width: device.logicalSize.width - 40,
        height: 560,
        child: StroopBoard(run: run),
      ),
    ),
    localeCase: localeCase,
    device: device,
    textScaler: textScaler,
  );

  group('the board draws no chrome', () {
    testWidgets('no HUD pill, no Scaffold, no SafeArea, no progress track', (
      tester,
    ) async {
      // The band above it and the gutter around it are the shell's. A board
      // that drew any of these would be the second owner of the screen.
      await pumpBoard(tester);

      expect(find.byType(HudPill), findsNothing);
      expect(find.byType(PopProgressBar), findsNothing);
      expect(
        find.descendant(
          of: find.byType(StroopBoard),
          matching: find.byType(Scaffold),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byType(StroopBoard),
          matching: find.byType(SafeArea),
        ),
        findsNothing,
      );
    });

    testWidgets('and no Directionality of its own', (tester) async {
      // Direction is a consequence of the locale. A hardcoded one is exactly
      // what hides a physical-side bug.
      await pumpBoard(tester, localeCase: LocaleCase.persian);

      expect(
        find.descendant(
          of: find.byType(StroopBoard),
          matching: find.byType(Directionality),
        ),
        findsNothing,
      );
    });
  });

  group('the answer grid', () {
    testWidgets('draws four keys', (tester) async {
      await pumpBoard(tester);

      expect(find.byType(StroopAnswerKey), findsNWidgets(4));
    });

    testWidgets('keys in a row share a top, keys in a column share a start', (
      tester,
    ) async {
      await pumpBoard(tester);

      final rects = tester
          .widgetList<StroopAnswerKey>(find.byType(StroopAnswerKey))
          .map((key) => tester.getRect(find.byWidget(key)))
          .toList();

      expect(rects[0].top, moreOrLessEquals(rects[1].top, epsilon: 0.5));
      expect(rects[2].top, moreOrLessEquals(rects[3].top, epsilon: 0.5));
      expect(rects[0].left, moreOrLessEquals(rects[2].left, epsilon: 0.5));
      expect(rects[1].left, moreOrLessEquals(rects[3].left, epsilon: 0.5));
    });

    testWidgets('and it mirrors under an RTL locale', (tester) async {
      // GridView under Directionality.rtl does this for free. The test exists
      // to catch the day someone "fixes" the order with an index flip and
      // double-mirrors it.
      await pumpBoard(tester);
      final ltrFirst = tester.getRect(find.byType(StroopAnswerKey).first);
      final ltrBoard = tester.getRect(find.byType(StroopBoard));

      await pumpBoard(tester, localeCase: LocaleCase.persian);
      final rtlFirst = tester.getRect(find.byType(StroopAnswerKey).first);
      final rtlBoard = tester.getRect(find.byType(StroopBoard));

      expect(
        ltrFirst.left - ltrBoard.left,
        lessThan(ltrBoard.right - ltrFirst.right),
        reason: 'option 0 should lead under en',
      );
      expect(
        rtlBoard.right - rtlFirst.right,
        lessThan(rtlFirst.left - rtlBoard.left),
        reason: 'option 0 should lead under fa, which is the right edge',
      );
    });
  });

  group('tapping a key submits its MODEL index', () {
    for (final localeCase in LocaleCase.bothDirections) {
      testWidgets('under ${localeCase.tag}', (tester) async {
        // The index is the model's, not a visual position: under fa the key
        // that is visually top-right is still option 0, and a board that
        // submitted a position would answer a different question in half the
        // shipped locales.
        await pumpBoard(tester, localeCase: localeCase);

        final container = ProviderScope.containerOf(
          tester.element(find.byType(StroopBoard)),
        );
        final state = container.read(stroopBoardNotifierProvider(run));
        final round = state.rounds.first;
        final correct = round.options.indexOf(round.ink);

        await tester.tap(find.byType(StroopAnswerKey).at(correct));
        await tester.pump();

        expect(
          container.read(stroopBoardNotifierProvider(run)).index,
          1,
          reason: 'the correct key advanced the round under ${localeCase.tag}',
        );
      });
    }

    testWidgets('and a wrong key marks itself without advancing', (
      tester,
    ) async {
      await pumpBoard(tester);

      final container = ProviderScope.containerOf(
        tester.element(find.byType(StroopBoard)),
      );
      final round = container
          .read(stroopBoardNotifierProvider(run))
          .rounds
          .first;
      final wrong = (round.options.indexOf(round.ink) + 1) % 4;

      await tester.tap(find.byType(StroopAnswerKey).at(wrong));
      await tester.pump();

      final state = container.read(stroopBoardNotifierProvider(run));

      expect(state.index, 0);
      expect(state.keyStates[wrong], AnswerKeyState.rejected);
    });
  });

  group('every key is a real target', () {
    for (final device in Device.all) {
      for (final localeCase in LocaleCase.all) {
        testWidgets('at ${device.name} under ${localeCase.tag}', (
          tester,
        ) async {
          await pumpBoard(tester, device: device, localeCase: localeCase);

          for (final key in tester.widgetList<StroopAnswerKey>(
            find.byType(StroopAnswerKey),
          )) {
            final size = tester.getSize(find.byWidget(key));

            expect(
              size.height,
              greaterThanOrEqualTo(kPopMinTarget),
              reason: '${device.name} ${localeCase.tag}',
            );
            expect(size.width, greaterThanOrEqualTo(kPopMinTarget));
          }

          expect(tester.takeException(), isNull);
        });
      }
    }
  });
}
