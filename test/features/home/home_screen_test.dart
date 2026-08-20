import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mindforge/app.dart';
import 'package:mindforge/core/streak_status.dart';
import 'package:mindforge/features/home/application/home_notifier.dart';
import 'package:mindforge/features/shell/widgets/daily_mix_card.dart';
import 'package:mindforge/games/game_definition.dart';
import 'package:mindforge/games/placeholder/placeholder_definitions.dart';
import 'package:mindforge/l10n/app_localizations.dart';
import 'package:mindforge/routing/routes.dart';
import 'package:mindforge/ui/components/game_card.dart';
import 'package:mindforge/ui/components/pop_chip.dart';

import '../../support/locale_cases.dart';
import '../../support/shell_harness.dart';

void main() {
  group('the hub renders the registry as data', () {
    testWidgets('one card per definition, locked slot included', (
      tester,
    ) async {
      await tester.pumpShellApp(const MindForgeApp());

      expect(find.byType(GameCard), findsNWidgets(3));
    });

    testWidgets('and a FOURTH definition adds a fourth card with no edit here', (
      tester,
    ) async {
      // THE ENGINE CLAIM, asserted. If this needed a change to home_screen.dart
      // then Schulte Grid would need one too, and the seam is gone.
      await tester.pumpShellApp(
        const MindForgeApp(),
        games: <GameDefinition>[
          ...placeholderDefinitions(),
          placeholderCoralDefinition,
        ],
      );

      expect(find.byType(GameCard), findsNWidgets(4));
    });

    testWidgets('and the locked slot carries no tap', (tester) async {
      await tester.pumpShellApp(const MindForgeApp());

      final locked = tester
          .widgetList<GameCard>(find.byType(GameCard))
          .where((card) => card.locked)
          .toList();

      expect(locked, hasLength(1));
      expect(locked.single.onTap, isNull);
    });

    testWidgets('and a locked card does not print its tagline twice', (
      tester,
    ) async {
      // E05 fixed exactly this and it must not come back: the badge is its own
      // string, not the subtitle reused.
      await tester.pumpShellApp(const MindForgeApp());

      final locked = tester
          .widgetList<GameCard>(find.byType(GameCard))
          .firstWhere((card) => card.locked);

      expect(locked.lockedLabel, isNotNull);
      expect(locked.lockedLabel, isNot(locked.subtitle));
    });
  });

  group('a game nobody has played', () {
    testWidgets('shows no BEST pill rather than a zero', (tester) async {
      // A zero states a score that was never achieved — and it would state it
      // in whichever digits the locale uses, which makes it look deliberate.
      await tester.pumpShellApp(const MindForgeApp());

      for (final card in tester.widgetList<GameCard>(find.byType(GameCard))) {
        expect(card.bestValue, isNull, reason: card.title);
      }
    });
  });

  group('in every locale', () {
    for (final localeCase in LocaleCase.all) {
      testWidgets('${localeCase.tag} renders translated card titles', (
        tester,
      ) async {
        // Resolved through the ARB, never a literal in the screen. Asserted by
        // resolving the same key the screen resolves, so the test survives a
        // translation edit.
        await tester.pumpShellApp(
          const MindForgeApp(),
          localeCase: localeCase,
        );

        final l10n = AppLocalizations.of(
          tester.element(find.byType(GameCard).first),
        );

        // The pane scrolls now that the Daily Mix card and the section row
        // sit above the cards, and a SliverList does not build what is off
        // screen — so the locked slot has to be reached before it can be
        // asserted on.
        await tester.scrollUntilVisible(
          find.text(l10n.gamePlaceholderLockedName),
          120,
          scrollable: find.byType(Scrollable).last,
        );

        expect(find.text(l10n.gamePlaceholderCoralName), findsOneWidget);
        expect(find.text(l10n.gamePlaceholderLockedName), findsOneWidget);

        // The badge, asserted through the card rather than by finding text: a
        // locked GAME still has a name, and a status word that happened to
        // match one would make a text finder ambiguous rather than wrong.
        final locked = tester
            .widgetList<GameCard>(find.byType(GameCard))
            .firstWhere((card) => card.locked);

        expect(locked.lockedLabel, l10n.comingSoon);
      });
    }

    testWidgets('and exactly one thing on the screen is a header', (
      tester,
    ) async {
      // A screen reader's heading list is only useful if one thing claims it.
      await tester.pumpShellApp(const MindForgeApp());

      // Counted over the widget tree rather than the semantics tree: a
      // Semantics(header: true) is the thing being asserted, and the widget
      // finder says exactly how many there are.
      final headers = tester
          .widgetList<Semantics>(find.byType(Semantics))
          .where((node) => node.properties.header ?? false);

      expect(headers, hasLength(1));
    });
  });

  group('the streak chip', () {
    testWidgets('is an ICU plural, and it is absent at zero', (tester) async {
      // "No streak yet" is the =0 branch of the SAME message, not a second
      // string and not a chip reading "0 day streak" — which is what string
      // concatenation produces and what a plural exists to prevent.
      await tester.pumpShellApp(const MindForgeApp());

      final l10n = AppLocalizations.of(
        tester.element(find.byType(GameCard).first),
      );

      expect(
        tester.widget<PopChip>(find.byType(PopChip)).label,
        l10n.streakDays(0, '0'),
      );
    });

    testWidgets('and counts in the locale own numerals', (tester) async {
      for (final localeCase in LocaleCase.rightToLeft) {
        await tester.pumpShellApp(
          const MindForgeApp(),
          localeCase: localeCase,
          streak: const StreakStatus(
            currentDays: 4,
            longestDays: 4,
            isActiveToday: true,
          ),
        );

        expect(
          tester.widget<PopChip>(find.byType(PopChip)).label,
          contains('۴'),
          reason: '${localeCase.tag} printed Latin digits in the streak chip',
        );
      }
    });
  });

  group('the Daily Mix card', () {
    testWidgets('is the grape variant here', (tester) async {
      await tester.pumpShellApp(const MindForgeApp());

      expect(
        tester.widget<DailyMixCard>(find.byType(DailyMixCard).first).variant,
        DailyMixVariant.grape,
      );
    });

    testWidgets('and it goes somewhere — no dead chevron', (tester) async {
      await tester.pumpShellApp(const MindForgeApp());

      await tester.tap(find.byType(DailyMixCard).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // The LOCATION, not a widget: the hub's branch stays alive under the
      // pushed route, so both screens are in the tree and counting widgets
      // would be counting the wrong thing.
      expect(
        GoRouter.of(
          tester.element(find.byType(DailyMixCard).first),
        ).state.uri.path,
        startsWith('/game/'),
      );
    });

    // The pick's locale-independence is asserted where it is DECIDED, in
    // home_notifier_test — the generator consumes a civil date and emits a
    // GameId, and no locale reaches it. What is asserted here is the other
    // half: that the card routes to that id and not to something the screen
    // chose for itself. One test per locale rather than a loop, because
    // pumping the whole app four times inside one test leaves the previous
    // navigator's overlay in the tree and the direction assertion then reads
    // the wrong Directionality.
    for (final localeCase in LocaleCase.all) {
      testWidgets('routes to the notifier own pick under ${localeCase.tag}', (
        tester,
      ) async {
        await tester.pumpShellApp(
          const MindForgeApp(),
          localeCase: localeCase,
        );

        final expected = Routes.gameDetail(
          ProviderScope.containerOf(
            tester.element(find.byType(DailyMixCard).first),
          ).read(homeHubProvider).dailyPick,
        );

        await tester.tap(find.byType(DailyMixCard).first);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        expect(
          GoRouter.of(
            tester.element(find.byType(DailyMixCard).first),
          ).state.uri.path,
          expected,
        );
      });
    }
  });

  group('the section label', () {
    testWidgets('counts only the UNLOCKED games', (tester) async {
      // Three cards, two playable. A count that included the locked slot would
      // promise a game the player cannot open.
      await tester.pumpShellApp(const MindForgeApp());

      final l10n = AppLocalizations.of(
        tester.element(find.byType(GameCard).first),
      );

      expect(find.text(l10n.gamesUnlocked(2, '2')), findsOneWidget);
    });
  });
}
