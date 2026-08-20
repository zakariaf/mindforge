import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mindforge/app.dart';
import 'package:mindforge/core/difficulty.dart';
import 'package:mindforge/core/run_config.dart';
import 'package:mindforge/features/countdown/ui/countdown_screen.dart';
import 'package:mindforge/features/play/ui/play_scaffold.dart';
import 'package:mindforge/features/shell/widgets/ray_header.dart';
import 'package:mindforge/l10n/app_localizations.dart';
import 'package:mindforge/routing/routes.dart';
import 'package:mindforge/theme/sunburst_colors.dart';
import 'package:mindforge/theme/sunburst_shape.dart';
import 'package:mindforge/ui/components/pop_bottom_nav.dart';
import 'package:mindforge/ui/components/pop_surface.dart';

import '../../support/fixture_registry.dart';
import '../../support/locale_cases.dart';
import '../../support/shell_harness.dart';

/// The hand-off from menu to game.
void main() {
  const colours = SunburstColors.sunburstPop;
  const shape = SunburstShape.sunburstPop;

  final config = RunConfig(
    gameId: fixtureAlpha.id,
    difficulty: Difficulty.classic,
    seed: 3,
  );

  Future<void> pumpCountdown(
    WidgetTester tester, {
    LocaleCase? localeCase,
  }) => tester.pumpShellApp(
    const MindForgeApp(),
    localeCase: localeCase,
    initialLocation: Routes.countdown(config),
  );

  group('the full-bleed frame', () {
    testWidgets('is the only screen whose fill reaches the top', (
      tester,
    ) async {
      // Everything else in MindForge sits under a header. This is the hand-off
      // and it is loud on purpose.
      await pumpCountdown(tester);

      expect(find.byType(RayHeader), findsNothing);
      expect(find.byType(PopBottomNav), findsNothing);
      expect(
        tester.getRect(find.byType(CountdownScreen)).top,
        0,
        reason: 'the grape must reach y=0',
      );
    });

    testWidgets('and the content still respects the top inset', (tester) async {
      await pumpCountdown(tester);

      final safeArea = tester
          .widgetList<SafeArea>(
            find.descendant(
              of: find.byType(CountdownScreen),
              matching: find.byType(SafeArea),
            ),
          )
          .first;

      expect(safeArea.top, isFalse, reason: 'the fill must not be inset');
    });
  });

  group('the ring', () {
    testWidgets('is the one e4 on the screen, at its declared diameter', (
      tester,
    ) async {
      await pumpCountdown(tester);

      final lifted = tester
          .widgetList<PopSurface>(find.byType(PopSurface))
          .where((surface) => surface.elevation == PopElevation.e4)
          .toList();

      expect(lifted, hasLength(1));
      expect(lifted.single.fill, colours.accent);
      expect(
        tester.getSize(find.byType(CountdownScreen)).width,
        greaterThan(shape.countdownRing),
      );
    });
  });

  group('the numerals are the locale own', () {
    for (final localeCase in LocaleCase.all) {
      testWidgets('${localeCase.tag} counts in its own digits', (tester) async {
        await pumpCountdown(tester, localeCase: localeCase);

        final expected = localeCase.locale.isRightToLeft ? '۳' : '3';

        expect(
          find.text(expected),
          findsOneWidget,
          reason: '${localeCase.tag} did not print $expected',
        );
      });
    }

    testWidgets('and it counts down 3, 2, 1 before starting the run', (
      tester,
    ) async {
      await pumpCountdown(tester);

      expect(find.text('3'), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
      expect(find.text('2'), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
      expect(find.text('1'), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(PlayScaffold), findsOneWidget);
    });
  });

  group('the ready line', () {
    testWidgets('casts a hard ink shadow that does NOT mirror', (tester) async {
      // The same light-source rule as every box shadow in the app.
      for (final localeCase in LocaleCase.rightToLeft) {
        await pumpCountdown(tester, localeCase: localeCase);

        final l10n = AppLocalizations.of(
          tester.element(find.byType(CountdownScreen)),
        );
        final shadow = tester
            .widget<Text>(find.text(l10n.getReady))
            .style!
            .shadows!
            .single;

        expect(
          shadow.offset,
          shape.countdownReadyShadow,
          reason: localeCase.tag,
        );
        expect(shadow.blurRadius, 0);
      }
    });

    testWidgets('and it is the screen one heading', (tester) async {
      await pumpCountdown(tester);

      expect(
        tester
            .widgetList<Semantics>(find.byType(Semantics))
            .where((node) => node.properties.header ?? false),
        hasLength(1),
      );
    });
  });

  group('leaving', () {
    testWidgets('the close button abandons and writes nothing', (tester) async {
      await pumpCountdown(tester);

      final l10n = AppLocalizations.of(
        tester.element(find.byType(CountdownScreen)),
      );

      await tester.tap(find.bySemanticsLabel(l10n.pauseQuit));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // The LOCATION, not the absence of a widget: go() unwinds and the
      // outgoing route is still in the tree while it does.
      expect(
        GoRouter.of(
          tester.element(find.byType(CountdownScreen)),
        ).state.uri.path,
        Routes.gameDetail(config.gameId),
      );
      expect(tester.takeException(), isNull);
    });
  });
}
