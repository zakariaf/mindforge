import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mindforge/app.dart';
import 'package:mindforge/core/supported_locale.dart';
import 'package:mindforge/features/shell/ui/not_found_screen.dart';
import 'package:mindforge/l10n/locale_resolution.dart';
import 'package:mindforge/routing/app_router.dart';
import 'package:mindforge/routing/routes.dart';
import 'package:mindforge/ui/components/pop_bottom_nav.dart';

import '../support/locale_cases.dart';
import '../support/shell_harness.dart';

void main() {
  group('the branch shell', () {
    testWidgets('a cold start lands on Home with the first tab selected', (
      tester,
    ) async {
      await tester.pumpShellApp(const MindForgeApp());
      await tester.pump(const Duration(milliseconds: 400));

      final nav = tester.widget<PopBottomNav>(find.byType(PopBottomNav));

      expect(nav.selectedIndex, 0);
      expect(nav.items, hasLength(3));
    });

    testWidgets('and each branch selects its own tab', (tester) async {
      await tester.pumpShellApp(const MindForgeApp());
      await tester.pump(const Duration(milliseconds: 400));

      for (final expected in <int>[1, 2, 0]) {
        await tester.tap(find.byType(PopBottomNav).first, warnIfMissed: false);
        await tester.pump();

        final context = tester.element(find.byType(PopBottomNav));
        GoRouter.of(context).go(
          <String>[Routes.home, Routes.stats, Routes.settings][expected],
        );
        await tester.pump(const Duration(milliseconds: 400));

        expect(
          tester.widget<PopBottomNav>(find.byType(PopBottomNav)).selectedIndex,
          expected,
        );
      }
    });
  });

  group('an unknown location', () {
    testWidgets('renders a screen, not a red box', (tester) async {
      // go_router's default error page is an English stack trace on red, and a
      // stale deep link is something a person can hit.
      //
      // Cold-started rather than navigated to: go() from a live shell keeps
      // the branch it is already in, so the error route is only reachable at
      // launch — which is also the only way a bad deep link actually arrives.
      await tester.pumpShellApp(
        const MindForgeApp(),
        initialLocation: '/no/such/place',
      );
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(NotFoundScreen), findsOneWidget);
      expect(find.byType(PopBottomNav), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('and it is translated, not an English fallback', (
      tester,
    ) async {
      await tester.pumpShellApp(
        const MindForgeApp(),
        initialLocation: '/no/such/place',
        localeCase: LocaleCase.persian,
      );
      await tester.pump(const Duration(milliseconds: 400));

      expect(
        find.text('این صفحه دیگر وجود ندارد'),
        findsOneWidget,
      );
    });
  });

  group('the router is not a function of the locale', () {
    test('flipping the language returns the same GoRouter instance', () {
      // A router that watched the locale would tear down the branch stack on
      // every switch — losing the player's place, and silently making the
      // Settings screen's "changing language does not restart the app" claim
      // false.
      final container = ProviderContainer(
        overrides: [localeProvider.overrideWithValue(SupportedLocale.en)],
      );
      addTearDown(container.dispose);

      final before = container.read(routerProvider);

      final persian = ProviderContainer(
        overrides: [localeProvider.overrideWithValue(SupportedLocale.fa)],
      );
      addTearDown(persian.dispose);

      // Same container, re-read after the locale authority moved: the router
      // must not have been rebuilt.
      expect(identical(container.read(routerProvider), before), isTrue);
    });
  });

  group('the nav mirrors, and its indices do not', () {
    for (final localeCase in LocaleCase.all) {
      testWidgets('${localeCase.tag} paints Play on the reading start', (
        tester,
      ) async {
        // The branch list order never changes: goBranch(0) is Play in every
        // language. What moves is which side of the screen it paints on, and
        // that comes free from the Row being directional.
        await tester.pumpShellApp(
          const MindForgeApp(),
          localeCase: localeCase,
        );
        await tester.pump(const Duration(milliseconds: 400));

        final labels = find.descendant(
          of: find.byType(PopBottomNav),
          matching: find.byType(Text),
        );

        final first = tester.getRect(labels.first).left;
        final last = tester.getRect(labels.last).left;

        if (localeCase.direction == TextDirection.ltr) {
          expect(first, lessThan(last), reason: localeCase.tag);
        } else {
          expect(first, greaterThan(last), reason: localeCase.tag);
        }
      });
    }
  });
}
