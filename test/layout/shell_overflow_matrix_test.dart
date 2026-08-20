import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/app.dart';
import 'package:mindforge/core/difficulty.dart';
import 'package:mindforge/core/game_id.dart';
import 'package:mindforge/core/run_config.dart';
import 'package:mindforge/routing/routes.dart';
import 'package:mindforge/ui/components/hud_pill.dart';

import '../support/harness.dart';
import '../support/locale_cases.dart';
import '../support/shell_harness.dart';

/// Every screen, at every width, in every locale, at three text scales.
///
/// **One `testWidgets` per tuple, never a loop inside one.** Flutter reports an
/// overflow once per `RenderObject` per test: a loop would report the first
/// combination that broke and stay silent for the next eleven, so a matrix
/// written as one test proves far less than it appears to.
///
/// What it asserts is deliberately narrow — nothing threw, and the flex rows
/// that carry translated text still share their width evenly. A screen that
/// overflows throws; a screen whose HUD pills stopped being equal has drifted
/// from the design without throwing anything.
void main() {
  final run = RunConfig(
    gameId: GameId('placeholder_coral'),
    difficulty: Difficulty.classic,
    seed: 42,
  );

  final routes = <String, String>{
    'home': Routes.home,
    'stats': Routes.stats,
    'settings': Routes.settings,
    'detail': Routes.gameDetail(run.gameId),
    'countdown': Routes.countdown(run),
    'play': Routes.play(run),
    'results': Routes.results(run),
    'notFound': '/nowhere',
  };

  /// The three scales the design is asked to survive.
  ///
  /// 1.0 is the reference, 1.3 is where German first breaks, and 2.0 is the
  /// accessibility ceiling the app promises — never clamped, so a layout that
  /// cannot take it is a layout to change.
  const scales = <double>[1, 1.3, 2];

  for (final device in Device.all) {
    for (final localeCase in LocaleCase.all) {
      for (final scale in scales) {
        for (final entry in routes.entries) {
          testWidgets(
            '${entry.key} at ${device.name} ${localeCase.tag} x$scale',
            (tester) async {
              await tester.pumpShellApp(
                const MindForgeApp(),
                device: device,
                localeCase: localeCase,
                textScaler: TextScaler.linear(scale),
                initialLocation: entry.value,
              );

              expect(
                tester.takeException(),
                isNull,
                reason:
                    '${entry.key} overflowed at ${device.name} '
                    '${localeCase.tag} x$scale',
              );

              // The HUD is the one row in the app whose three children must
              // stay equal: they are equal-flex by design, and a longer
              // German caption widening one of them is a defect that throws
              // nothing.
              final pills = tester.widgetList<HudPill>(find.byType(HudPill));

              if (pills.isNotEmpty) {
                final widths = pills
                    .map((pill) => tester.getSize(find.byWidget(pill)).width)
                    .map((width) => width.toStringAsFixed(2))
                    .toSet();

                expect(
                  widths,
                  hasLength(1),
                  reason:
                      'the HUD pills stopped sharing the row at '
                      '${device.name} ${localeCase.tag} x$scale',
                );
              }
            },
          );
        }
      }
    }
  }
}
