import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/app.dart';
import 'package:mindforge/core/difficulty.dart';
import 'package:mindforge/core/game_id.dart';
import 'package:mindforge/core/run_config.dart';
import 'package:mindforge/routing/routes.dart';
import 'package:mindforge/ui/components/pop_surface.dart';
import 'package:mindforge/ui/glyphs/sunburst_glyph.dart';

import '../support/locale_cases.dart';
import '../support/shell_harness.dart';

/// What a screen reader and a switch user meet, on every screen and in every
/// language.
///
/// Per screen and per locale, because the answers differ per locale: a heading
/// is a translated string, a tap target's size follows the text in it, and the
/// traversal order follows the reading direction. A single-locale a11y pass
/// proves the English build.
void main() {
  final run = RunConfig(
    gameId: GameId('fixture_alpha'),
    difficulty: Difficulty.classic,
    seed: 42,
  );

  /// Every screen, and whether it claims a heading.
  ///
  /// **The play scaffold has one and the design does not draw it.** The board
  /// IS the screen visually, so there is no title to paint — but a screen
  /// reader still needs to be told which game it just landed in.
  final routes = <String, String>{
    'home': Routes.home,
    'stats': Routes.stats,
    'settings': Routes.settings,
    'detail': Routes.gameDetail(run.gameId),
    'countdown': Routes.countdown(run),
    'play': Routes.play(run),
    'results': Routes.results(run),
  };

  for (final localeCase in LocaleCase.all) {
    for (final entry in routes.entries) {
      testWidgets('${entry.key} has exactly one heading in ${localeCase.tag}', (
        tester,
      ) async {
        // A heading list is only worth having if exactly one thing is in it.
        await tester.pumpShellApp(
          const MindForgeApp(),
          localeCase: localeCase,
          initialLocation: entry.value,
        );

        final headers = tester
            .widgetList<Semantics>(find.byType(Semantics))
            .where((node) => node.properties.header ?? false);

        expect(
          headers,
          hasLength(1),
          reason: '${entry.key} under ${localeCase.tag}',
        );
      });

      testWidgets('${entry.key} labels every glyph in ${localeCase.tag}', (
        tester,
      ) async {
        // A glyph is either named or excluded. An unlabelled one is a stop in
        // a screen reader's path that says nothing at all.
        await tester.pumpShellApp(
          const MindForgeApp(),
          localeCase: localeCase,
          initialLocation: entry.value,
        );

        // Either an ancestor names the glyph, or it sits under an
        // ExcludeSemantics. Anything else is a stop in a screen reader's path
        // that says nothing at all.
        final unnamed = find
            .byType(SunburstGlyphIcon)
            .evaluate()
            .where(
              (element) => !_isNamedOrExcluded(tester, element),
            )
            .length;

        expect(
          unnamed,
          0,
          reason:
              '${entry.key} under ${localeCase.tag} has an unlabelled glyph',
        );
      });

      testWidgets(
        '${entry.key} keeps every target at 48 in ${localeCase.tag}',
        (
          tester,
        ) async {
          // An explicit size loop, not meetsGuideline: that matcher skips nodes
          // flush with the view edge, which on a phone is most of a nav bar.
          await tester.pumpShellApp(
            const MindForgeApp(),
            localeCase: localeCase,
            initialLocation: entry.value,
          );

          // Every PopSurface carrying a tap IS every control in the app: the
          // catalog has one pressable primitive and everything else composes
          // it. Measuring those makes the same statement as walking the
          // semantics tree and needs no deprecated binding to make it.
          final tooSmall = <String>[];

          for (final surface in tester.widgetList<PopSurface>(
            find.byType(PopSurface),
          )) {
            if (surface.onTap == null) continue;
            // minTarget 0 is a surface that has DECLARED it is not a target —
            // a HUD pill, a stat box. Those carry no tap either, so this skip
            // only spares a composite that opted out on purpose.
            if (surface.minTarget == 0) continue;

            final size = tester.getSize(find.byWidget(surface));

            if (size.width < kPopMinTarget || size.height < kPopMinTarget) {
              tooSmall.add('${surface.semanticLabel} $size');
            }
          }

          expect(
            tooSmall,
            isEmpty,
            reason: '${entry.key} under ${localeCase.tag}',
          );
        },
      );
    }
  }
}

/// Whether [element]'s glyph is named by an ancestor or excluded outright.
bool _isNamedOrExcluded(WidgetTester tester, Element element) {
  var named = false;

  element.visitAncestorElements((ancestor) {
    final widget = ancestor.widget;

    if (widget is ExcludeSemantics && widget.excluding) {
      named = true;

      return false;
    }

    if (widget is Semantics) {
      final label = widget.properties.label;

      if (label != null && label.isNotEmpty) {
        named = true;

        return false;
      }
    }

    return true;
  });

  return named;
}
