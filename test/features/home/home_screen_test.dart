import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mindforge/app.dart';
import 'package:mindforge/core/streak_status.dart';
import 'package:mindforge/features/home/application/home_notifier.dart';
import 'package:mindforge/features/home/ui/home_screen.dart';
import 'package:mindforge/features/home/widgets/locked_game_slot.dart';
import 'package:mindforge/features/shell/widgets/daily_mix_card.dart';
import 'package:mindforge/games/game_definition.dart';
import 'package:mindforge/l10n/app_localizations.dart';
import 'package:mindforge/routing/routes.dart';
import 'package:mindforge/ui/components/game_card.dart';
import 'package:mindforge/ui/components/pop_chip.dart';

import '../../support/fixture_registry.dart';
import '../../support/locale_cases.dart';
import '../../support/shell_harness.dart';

void main() {
  group('the hub renders the registry as data', () {
    testWidgets('one card per unlocked definition, plus the locked slot', (
      tester,
    ) async {
      // A locked game is a SLOT, not a card with a flag. app.html draws them
      // as two different things: no shadow, a padlock leading, a smaller
      // title, and one status line where a card has a tagline and a badge.
      await tester.pumpShellApp(const MindForgeApp());

      expect(find.byType(GameCard), findsNWidgets(2));
      expect(find.byType(LockedGameSlot), findsOneWidget);
    });

    testWidgets('and a FOURTH definition adds a fourth card with no edit here', (
      tester,
    ) async {
      // THE ENGINE CLAIM, asserted. If this needed a change to home_screen.dart
      // then Schulte Grid would need one too, and the seam is gone.
      await tester.pumpShellApp(
        const MindForgeApp(),
        games: <GameDefinition>[
          ...fixtureRegistry(),
          fixtureAlpha,
        ],
      );

      expect(find.byType(GameCard), findsNWidgets(3));
    });

    testWidgets('and the locked slot is not a control at all', (tester) async {
      // Not "a control with a null tap": a slot is a promise that the engine
      // grows, and giving it a button role would put a dead stop in a screen
      // reader's path.
      await tester.pumpShellApp(const MindForgeApp());

      final node = tester.getSemantics(find.byType(LockedGameSlot));

      expect(node.flagsCollection.isButton, isFalse);
    });

    testWidgets('and the locked slot states its status ONCE', (tester) async {
      // The card version said the same thing twice — "Not yet unlocked" as its
      // tagline and "Coming soon" as a badge. E05 fixed that defect in one
      // shape and the locked GameCard reintroduced it in another; the slot has
      // one status line and no room for a second.
      await tester.pumpShellApp(const MindForgeApp());

      final l10n = AppLocalizations.of(
        tester.element(find.byType(LockedGameSlot)),
      );
      final slot = tester.widget<LockedGameSlot>(
        find.byType(LockedGameSlot),
      );

      expect(slot.status, l10n.comingSoon);
      expect(
        find.text(fixtureGameStrings(fixtureLocked).tagline),
        findsNothing,
        reason: 'the tagline and the status are the same fact',
      );
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
      testWidgets('${localeCase.tag} renders each card through the resolver', (
        tester,
      ) async {
        // THE SHELL RESOLVES, IT DOES NOT KNOW. What is asserted is that a
        // card prints whatever `gameStringsProvider` returned for its
        // definition — not that a particular game's name is translated, which
        // is `game_strings.dart`'s subject and the ARB parity test's.
        //
        // It used to assert a shipped game's translated title, which is why
        // deleting that game broke it in four locales at once.
        await tester.pumpShellApp(
          const MindForgeApp(),
          localeCase: localeCase,
        );

        final l10n = AppLocalizations.of(
          tester.element(find.byType(GameCard).first),
        );

        for (final game in fixtureRegistry().where((g) => !g.isLocked)) {
          expect(
            find.text(fixtureGameStrings(game).title),
            findsOneWidget,
            reason: '${game.id} under ${localeCase.tag}',
          );
        }

        // The pane scrolls now that the Daily Mix card and the section row sit
        // above the cards, and a SliverList does not build what is off screen.
        await tester.scrollUntilVisible(
          find.text(fixtureGameStrings(fixtureLocked).title),
          120,
          scrollable: find.byType(Scrollable).last,
        );

        // The STATUS is chrome and stays translated — asserted through the
        // slot rather than by finding text, because a locked game still has a
        // name and a status word that matched one would make a text finder
        // ambiguous rather than wrong.
        expect(
          tester.widget<LockedGameSlot>(find.byType(LockedGameSlot)).status,
          l10n.comingSoon,
        );
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

        final pick = ProviderScope.containerOf(
          tester.element(find.byType(DailyMixCard).first),
        ).read(homeHubProvider).dailyPick;

        // Not `!`: a null pick means the card should not have been on screen
        // at all, and asserting that here is what tells the two states apart.
        expect(pick, isNotNull);

        final expected = Routes.gameDetail(pick!);

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

  group('a registry with nothing playable', () {
    testWidgets('renders the hub with no Daily Mix card and no cards', (
      tester,
    ) async {
      // The state between E09's first commit and its last, and the state a
      // build with every game feature-flagged off ships in. The hub still
      // draws — header, greeting, section heading, nav — and the one thing it
      // does NOT draw is a call to action with nowhere to go.
      await tester.pumpShellApp(
        const MindForgeApp(),
        games: const <GameDefinition>[],
      );

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(DailyMixCard), findsNothing);
      expect(find.byType(GameCard), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('and hides it when every game is locked, too', (tester) async {
      // Pointing the hub's one call to action at a "coming soon" card would be
      // the dead chevron E11 forbids, so "nothing playable" and "nothing at
      // all" have to reach the same answer.
      await tester.pumpShellApp(
        const MindForgeApp(),
        games: <GameDefinition>[fixtureLocked],
      );

      expect(find.byType(DailyMixCard), findsNothing);
      expect(find.byType(LockedGameSlot), findsOneWidget);
    });

    testWidgets('and the count reads zero, in the locale own numerals', (
      tester,
    ) async {
      await tester.pumpShellApp(
        const MindForgeApp(),
        localeCase: LocaleCase.persian,
        games: const <GameDefinition>[],
      );

      final l10n = AppLocalizations.of(tester.element(find.byType(HomeScreen)));

      expect(find.text(l10n.gamesUnlocked(0, '۰')), findsOneWidget);
    });
  });
}
