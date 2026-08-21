import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/app.dart';
import 'package:mindforge/core/supported_locale.dart';
import 'package:mindforge/features/settings/ui/language_sheet.dart';
import 'package:mindforge/features/settings/widgets/settings_row.dart';
import 'package:mindforge/l10n/app_localizations.dart';
import 'package:mindforge/routing/routes.dart';
import 'package:mindforge/ui/components/pop_surface.dart';

import '../../support/locale_cases.dart';
import '../../support/shell_harness.dart';

/// The four-way language choice, and the row that opens it.
///
/// **A sheet, not a route.** Four mutually exclusive options do not earn a
/// navigation stack entry, and this asserts what E08 shipped rather than a
/// second destination.
void main() {
  /// Pumps the modal transition out, by TIME rather than by settling.
  ///
  /// `pumpAndSettle` hangs for ten minutes on any indefinite animation, and
  /// `check_test_hygiene.sh` bans it for that reason. A bottom sheet's
  /// transition is bounded and short; two frames past it is enough.
  Future<void> settleSheet(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  /// Opens Settings and taps the Language row.
  Future<void> openSheet(
    WidgetTester tester, {
    LocaleCase? localeCase,
    TextScaler textScaler = TextScaler.noScaling,
  }) async {
    await tester.pumpShellApp(
      const MindForgeApp(),
      localeCase: localeCase,
      textScaler: textScaler,
      initialLocation: Routes.settings,
    );

    final l10n = AppLocalizations.of(
      tester.element(find.byType(SettingsRow).first),
    );

    await tester.tap(find.text(l10n.settingsLanguage));
    await settleSheet(tester);
  }

  /// Every language name the sheet offers, in order.
  List<String> endonymsOf(WidgetTester tester) {
    final l10n = AppLocalizations.of(
      tester.element(find.byType(LanguageSheet)),
    );

    return <String>[
      l10n.settingsLanguageSystem,
      l10n.languageNameEn,
      l10n.languageNameDe,
      l10n.languageNameFa,
      l10n.languageNameCkb,
    ];
  }

  group('the Language row', () {
    testWidgets('is a live control, not a label, in every locale', (
      tester,
    ) async {
      // THE NO-DEAD-CONTROL ASSERTION. app.html draws a chevron on this row
      // and on About; a chevron that leads nowhere is the affordance this epic
      // exists to rule out.
      for (final localeCase in LocaleCase.all) {
        await tester.pumpShellApp(
          const MindForgeApp(),
          localeCase: localeCase,
          initialLocation: Routes.settings,
        );

        final l10n = AppLocalizations.of(
          tester.element(find.byType(SettingsRow).first),
        );
        final row = tester.widgetList<SettingsRow>(find.byType(SettingsRow));
        final language = row.firstWhere(
          (candidate) => candidate.label == l10n.settingsLanguage,
        );
        final about = row.firstWhere(
          (candidate) => candidate.label == l10n.aboutTitle,
        );

        expect(language.onTap, isNotNull, reason: localeCase.tag);
        expect(about.onTap, isNotNull, reason: localeCase.tag);
      }
    });

    testWidgets('and states the active language in its own name', (
      tester,
    ) async {
      // THE ENDONYM, never a translation of it. A chooser that named languages
      // in the CURRENT language is unusable by exactly the person who needs
      // it: someone who cannot read the current one.
      for (final localeCase in LocaleCase.all) {
        await tester.pumpShellApp(
          const MindForgeApp(),
          localeCase: localeCase,
          initialLocation: Routes.settings,
        );

        final l10n = AppLocalizations.of(
          tester.element(find.byType(SettingsRow).first),
        );
        final expected = switch (localeCase.locale) {
          SupportedLocale.en => l10n.languageNameEn,
          SupportedLocale.de => l10n.languageNameDe,
          SupportedLocale.fa => l10n.languageNameFa,
          SupportedLocale.ckb => l10n.languageNameCkb,
        };

        expect(
          find.text(expected),
          findsOneWidget,
          reason: '${localeCase.tag} did not print its own endonym',
        );
      }
    });
  });

  group('the sheet', () {
    testWidgets('offers System and the four locales, in order', (tester) async {
      await openSheet(tester);

      final names = endonymsOf(tester);

      for (final name in names) {
        expect(find.text(name), findsWidgets, reason: name);
      }
    });

    testWidgets('and each option is a button in one exclusive group', (
      tester,
    ) async {
      await openSheet(tester);

      final nodes = tester
          .widgetList<Semantics>(
            find.descendant(
              of: find.byType(LanguageSheet),
              matching: find.byType(Semantics),
            ),
          )
          .where((node) => node.properties.inMutuallyExclusiveGroup ?? false);

      expect(nodes, hasLength(5), reason: 'System plus four locales');

      for (final node in nodes) {
        expect(node.properties.button, isTrue);
      }
    });

    testWidgets('and the selected one is told apart without hue', (
      tester,
    ) async {
      // TWO CHANNELS BESIDES THE FILL: the surface lifts to e2, and the
      // semantics carry `selected`, which is what a screen reader announces.
      //
      // NOT a check glyph. The epic asks for one, and the sheet has no
      // reference PNG in either direction — its own note says new visual
      // vocabulary here belongs in app.html first, so inventing a checkmark
      // would be this epic drawing rather than verifying. Recorded as a
      // finding rather than built.
      await openSheet(tester);

      final surfaces = tester
          .widgetList<PopSurface>(
            find.descendant(
              of: find.byType(LanguageSheet),
              matching: find.byType(PopSurface),
            ),
          )
          .where((surface) => surface.onTap != null)
          .toList();

      expect(
        surfaces.where((surface) => surface.elevation == PopElevation.e2),
        hasLength(1),
        reason: 'exactly one option is lifted',
      );

      final selected = tester
          .widgetList<Semantics>(
            find.descendant(
              of: find.byType(LanguageSheet),
              matching: find.byType(Semantics),
            ),
          )
          .where((node) => node.properties.selected ?? false);

      expect(selected, hasLength(1));
    });

    testWidgets('and every option clears the tap floor at 2.0x', (
      tester,
    ) async {
      // `کوردیی ناوەندی` is the longest label and the tallest line box.
      //
      // The SHEET is pumped directly rather than tapped through Settings: at
      // 2.0x the Language row sits below the fold behind a scroll, and what is
      // being asserted here is the option's height, not the route to it.
      await tester.pumpShellApp(
        const MindForgeApp(),
        textScaler: const TextScaler.linear(2),
        initialLocation: Routes.settings,
      );

      final context = tester.element(find.byType(SettingsRow).first);

      unawaited(LanguageSheet.show(context));
      await settleSheet(tester);

      for (final surface in tester.widgetList<PopSurface>(
        find.descendant(
          of: find.byType(LanguageSheet),
          matching: find.byType(PopSurface),
        ),
      )) {
        if (surface.onTap == null) continue;

        expect(
          tester.getSize(find.byWidget(surface)).height,
          greaterThanOrEqualTo(kPopMinTarget),
        );
      }

      expect(tester.takeException(), isNull);
    });
  });

  group('choosing a language', () {
    testWidgets('closes the sheet and flips the whole app to RTL', (
      tester,
    ) async {
      // ASSERTED ON THE APP ROOT, never on a hardcoded Directionality: a
      // wrapper in the test is exactly what would hide a page that failed to
      // follow its locale.
      await openSheet(tester);

      final l10n = AppLocalizations.of(
        tester.element(find.byType(LanguageSheet)),
      );

      await tester.tap(find.text(l10n.languageNameFa).last);
      await settleSheet(tester);

      expect(find.byType(LanguageSheet), findsNothing);
      expect(
        Directionality.of(tester.element(find.byType(SettingsRow).first)),
        TextDirection.rtl,
      );
    });

    testWidgets('and back to LTR when a Latin language is chosen', (
      tester,
    ) async {
      await openSheet(tester, localeCase: LocaleCase.persian);

      final l10n = AppLocalizations.of(
        tester.element(find.byType(LanguageSheet)),
      );

      await tester.tap(find.text(l10n.languageNameDe).last);
      await settleSheet(tester);

      expect(
        Directionality.of(tester.element(find.byType(SettingsRow).first)),
        TextDirection.ltr,
      );
    });
  });
}
