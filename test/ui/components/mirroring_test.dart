import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/theme/sunburst_colors.dart';
import 'package:mindforge/ui/components/difficulty_segmented.dart';
import 'package:mindforge/ui/components/game_card.dart';
import 'package:mindforge/ui/components/pop_bottom_nav.dart';
import 'package:mindforge/ui/components/pop_button.dart';
import 'package:mindforge/ui/components/pop_progress_bar.dart';
import 'package:mindforge/ui/components/pop_sheet.dart';
import 'package:mindforge/ui/components/pop_surface.dart';
import 'package:mindforge/ui/components/timer_ring.dart';
import 'package:mindforge/ui/glyphs/sunburst_glyph.dart';

import '../../support/component_harness.dart';
import '../../support/load_app_fonts.dart';
import '../../support/locale_cases.dart';

/// **The mirroring table, as one test.**
///
/// Everything the catalog does when the reading direction changes, in one
/// place, so the answer to "what mirrors?" is a file rather than a discussion.
/// Both halves matter equally: a component that fails to mirror reads backwards
/// in Persian, and a component that mirrors when it should not — a shadow, a
/// clock — is a different object rather than a translated one.
void main() {
  const colours = SunburstColors.sunburstPop;
  final en = LocaleCase.all.first;
  final fa = LocaleCase.rightToLeft.first;

  setUpAll(loadAppFonts);

  /// Measures [finder]'s distance from the START edge of [within].
  ///
  /// Distance from the start, not from the left: that is what makes one number
  /// comparable across both directions.
  double startInset(WidgetTester tester, Finder finder, Finder within) {
    final outer = tester.getRect(within);
    final inner = tester.getRect(finder);

    return Directionality.of(tester.element(finder)) == TextDirection.ltr
        ? inner.left - outer.left
        : outer.right - inner.right;
  }

  group('THESE MIRROR', () {
    testWidgets('a leading glyph stays at the start edge', (tester) async {
      for (final localeCase in <LocaleCase>[en, fa]) {
        await tester.pumpPopComponent(
          PopButton(
            label: 'Play',
            leading: SunburstGlyph.go,
            onPressed: () {},
          ),
          localeCase: localeCase,
        );

        expect(
          startInset(
            tester,
            find.byType(SunburstGlyphIcon),
            find.byType(PopButton),
          ),
          lessThan(
            startInset(tester, find.text('Play'), find.byType(PopButton)),
          ),
          reason: 'under ${localeCase.tag}',
        );
      }
    });

    testWidgets('the back chevron points along the reading direction', (
      tester,
    ) async {
      for (final localeCase in <LocaleCase>[en, fa]) {
        await tester.pumpPopComponent(
          const SunburstGlyphIcon(SunburstGlyph.back),
          localeCase: localeCase,
        );

        final flipped = find
            .descendant(
              of: find.byType(SunburstGlyphIcon),
              matching: find.byType(Transform),
            )
            .evaluate()
            .isNotEmpty;

        expect(flipped, localeCase == fa, reason: localeCase.tag);
      }
    });

    testWidgets('the progress fill grows from the start edge', (tester) async {
      Future<double> fillLeft(LocaleCase localeCase) async {
        await tester.pumpPopComponent(
          const SizedBox(
            width: 200,
            child: PopProgressBar(value: 0.3, semanticLabel: 'Progress'),
          ),
          localeCase: localeCase,
        );

        return tester.getRect(find.byType(FractionallySizedBox)).left;
      }

      expect(await fillLeft(en), lessThan(await fillLeft(fa)));
    });

    testWidgets('the segmented order follows reading order', (tester) async {
      Future<double> firstLeft(LocaleCase localeCase) async {
        await tester.pumpPopComponent(
          DifficultySegmented(
            labels: const <String>['A', 'B', 'C'],
            selectedIndex: 0,
            onSelected: (_) {},
          ),
          localeCase: localeCase,
        );

        return tester.getRect(find.text('A')).left;
      }

      expect(await firstLeft(en), lessThan(await firstLeft(fa)));
    });

    testWidgets('the nav order follows reading order', (tester) async {
      Future<double> firstLeft(LocaleCase localeCase) async {
        await tester.pumpPopComponent(
          PopBottomNav(
            items: const <PopNavItem>[
              PopNavItem(glyph: SunburstGlyph.navPlay, label: 'One'),
              PopNavItem(glyph: SunburstGlyph.navStats, label: 'Two'),
            ],
            selectedIndex: 0,
            onSelected: (_) {},
          ),
          localeCase: localeCase,
        );

        return tester.getRect(find.text('One')).left;
      }

      expect(await firstLeft(en), lessThan(await firstLeft(fa)));
    });

    testWidgets("a game card's artwork stays at the end edge", (tester) async {
      Future<double> artLeft(LocaleCase localeCase) async {
        await tester.pumpPopComponent(
          GameCard(
            title: 'Game',
            subtitle: 'Tagline',
            accent: colours.gameStroop,
            semanticLabel: 'Game',
            artwork: const SizedBox(
              key: ValueKey<String>('art'),
              width: 40,
              height: 40,
            ),
            onTap: () {},
          ),
          localeCase: localeCase,
        );

        return tester.getRect(find.byKey(const ValueKey<String>('art'))).left;
      }

      expect(
        await artLeft(en),
        greaterThan(await artLeft(fa)),
        reason: 'the artwork is at the END edge, which swaps sides',
      );
    });
  });

  group('THESE MUST NOT', () {
    testWidgets('the hard offset shadow, at every elevation', (tester) async {
      // A light source fixed at the top-start of the PAGE. A mirrored shadow
      // would put the light behind the reader in half the shipped locales.
      for (final elevation in PopElevation.values.where(
        (e) => e != PopElevation.flat,
      )) {
        final offsets = <Offset>[];

        for (final localeCase in <LocaleCase>[en, fa]) {
          await tester.pumpPopComponent(
            PopSurface(
              fill: colours.accent,
              elevation: elevation,
              onTap: () {},
              child: const SizedBox(width: 60, height: 40),
            ),
            localeCase: localeCase,
          );

          final decoration =
              tester
                      .widget<DecoratedBox>(find.byType(DecoratedBox).first)
                      .decoration
                  as BoxDecoration;
          offsets.add(decoration.boxShadow!.single.offset);
        }

        expect(offsets.first, offsets.last, reason: '$elevation');
        expect(offsets.first.dx, greaterThan(0), reason: '$elevation');
      }
    });

    testWidgets('the timer sweep, because it is a clock', (tester) async {
      // Its hands would run backwards. The painter reads no direction at all,
      // which is what makes this true rather than merely intended.
      for (final localeCase in <LocaleCase>[en, fa]) {
        await tester.pumpPopComponent(
          const TimerRing(progress: 0.3, label: '0:23', semanticLabel: 'Time'),
          localeCase: localeCase,
        );

        expect(
          find
              .descendant(
                of: find.byType(TimerRing),
                matching: find.byType(Transform),
              )
              .evaluate(),
          isEmpty,
          reason: 'no flip is applied under ${localeCase.tag}',
        );
      }
    });

    testWidgets('the nav bar top rule, which has no handedness', (
      tester,
    ) async {
      for (final localeCase in <LocaleCase>[en, fa]) {
        await tester.pumpPopComponent(
          PopBottomNav(
            items: const <PopNavItem>[
              PopNavItem(glyph: SunburstGlyph.navPlay, label: 'One'),
            ],
            selectedIndex: 0,
            onSelected: (_) {},
          ),
          localeCase: localeCase,
        );

        final border =
            (tester
                        .widget<DecoratedBox>(find.byType(DecoratedBox).first)
                        .decoration
                    as BoxDecoration)
                .border!;

        expect(border.bottom, BorderSide.none, reason: localeCase.tag);
        expect(border.top.width, 3, reason: localeCase.tag);
      }
    });

    testWidgets("a sheet's vertical action order", (tester) async {
      for (final localeCase in <LocaleCase>[en, fa]) {
        await tester.pumpPopComponent(
          const PopSheet(
            title: 'Paused',
            actions: <Widget>[Text('First'), Text('Second')],
          ),
          localeCase: localeCase,
        );

        expect(
          tester.getRect(find.text('First')).top,
          lessThan(tester.getRect(find.text('Second')).top),
          reason: 'vertical order has no handedness (${localeCase.tag})',
        );
      }
    });

    testWidgets('the three nav marks, which are brand marks', (tester) async {
      for (final glyph in <SunburstGlyph>[
        SunburstGlyph.navPlay,
        SunburstGlyph.navStats,
        SunburstGlyph.navSettings,
      ]) {
        await tester.pumpPopComponent(
          SunburstGlyphIcon(glyph),
          localeCase: fa,
        );

        expect(
          find
              .descendant(
                of: find.byType(SunburstGlyphIcon),
                matching: find.byType(Transform),
              )
              .evaluate(),
          isEmpty,
          reason: '$glyph is a brand mark and must not flip',
        );
      }
    });
  });
}
