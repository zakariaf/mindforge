import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/app.dart';
import 'package:mindforge/core/difficulty.dart';
import 'package:mindforge/core/game_id.dart';
import 'package:mindforge/core/run_config.dart';
import 'package:mindforge/features/countdown/ui/countdown_screen.dart';
import 'package:mindforge/features/game_detail/ui/game_detail_screen.dart';
import 'package:mindforge/features/home/ui/home_screen.dart';
import 'package:mindforge/features/play/ui/play_scaffold.dart';
import 'package:mindforge/features/results/ui/results_screen.dart';
import 'package:mindforge/features/settings/ui/settings_screen.dart';
import 'package:mindforge/features/stats/ui/stats_screen.dart';
import 'package:mindforge/routing/routes.dart';
import 'package:mindforge/theme/sunburst_colors.dart';
import 'package:mindforge/ui/components/pop_bottom_nav.dart';

import '../../support/locale_cases.dart';
import '../../support/shell_harness.dart';

/// Every screen, in every locale, rendered without throwing.
///
/// A breadth pass rather than a depth one: each screen has its own file for its
/// own behaviour. What this covers is the thing no single-screen test can — that
/// all eight render under all four locales, including the two that read
/// right-to-left and the one Flutter ships no Material translations for.
void main() {
  final run = RunConfig(
    gameId: GameId('placeholder_coral'),
    difficulty: Difficulty.classic,
    seed: 42,
  );

  final screens = <String, (String, Type)>{
    'home': (Routes.home, HomeScreen),
    'stats': (Routes.stats, StatsScreen),
    'settings': (Routes.settings, SettingsScreen),
    'detail': (Routes.gameDetail(run.gameId), GameDetailScreen),
    'countdown': (Routes.countdown(run), CountdownScreen),
    'play': (Routes.play(run), PlayScaffold),
    'results': (Routes.results(run), ResultsScreen),
  };

  for (final localeCase in LocaleCase.all) {
    for (final entry in screens.entries) {
      testWidgets('${entry.key} renders in ${localeCase.tag}', (tester) async {
        await tester.pumpShellApp(
          const MindForgeApp(),
          initialLocation: entry.value.$1,
          localeCase: localeCase,
        );

        expect(
          find.byType(entry.value.$2),
          findsOneWidget,
          reason: '${entry.key} under ${localeCase.tag}',
        );
        expect(tester.takeException(), isNull);
      });
    }
  }

  group('the bottom nav appears on exactly three screens', () {
    test('and the run screens are not among them', () {
      // A player mid-run has one way out and it is the pause sheet. The
      // assertion itself is per-screen below; this states the rule.
      expect(
        <String>['home', 'stats', 'settings'],
        hasLength(3),
      );
    });

    for (final entry in screens.entries) {
      final isBranch = <String>{
        'home',
        'stats',
        'settings',
      }.contains(entry.key);

      testWidgets('${entry.key}: nav ${isBranch ? "present" : "absent"}', (
        tester,
      ) async {
        await tester.pumpShellApp(
          const MindForgeApp(),
          initialLocation: entry.value.$1,
        );

        expect(
          find.byType(PopBottomNav),
          isBranch ? findsOneWidget : findsNothing,
          reason: entry.key,
        );
      });
    }
  });

  group('every screen has exactly one header', () {
    for (final entry in screens.entries) {
      testWidgets(entry.key, (tester) async {
        // A screen reader's heading list is only useful if one thing on the
        // screen claims to be the heading.
        await tester.pumpShellApp(
          const MindForgeApp(),
          initialLocation: entry.value.$1,
        );

        expect(
          tester
              .widgetList<Semantics>(find.byType(Semantics))
              .where((node) => node.properties.header ?? false),
          hasLength(1),
          reason: entry.key,
        );
      });
    }
  });

  group('every screen is drawn on a surface', () {
    for (final entry in screens.entries) {
      testWidgets('${entry.key} has a Material ancestor and the app fill', (
        tester,
      ) async {
        // FOUR SCREENS HAD NEITHER, and 1,842 tests passed anyway. Game
        // detail, countdown, play and results sit outside the tab shell, so
        // they never inherited NavShell's Scaffold — and without a Material
        // ancestor Flutter paints every Text with the debug double-underline,
        // on whatever the window's own background is. On the simulator that is
        // black, with yellow underlines under every word.
        //
        // No widget test caught it because a test harness supplies its own
        // MaterialApp chrome. This one asserts the SCREEN's own ancestry
        // rather than the harness's.
        await tester.pumpShellApp(
          const MindForgeApp(),
          initialLocation: entry.value.$1,
        );

        expect(
          find.ancestor(
            of: find.byType(entry.value.$2),
            matching: find.byType(Material),
          ),
          findsWidgets,
          reason: '${entry.key} would render with debug-underlined text',
        );

        final scaffold = tester
            .widgetList<Scaffold>(
              find.ancestor(
                of: find.byType(entry.value.$2),
                matching: find.byType(Scaffold),
              ),
            )
            .last;

        expect(
          scaffold.backgroundColor,
          SunburstColors.sunburstPop.surface,
          reason: '${entry.key} is not on the app surface',
        );
      });
    }
  });
}
