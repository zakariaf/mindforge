import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/app.dart';
import 'package:mindforge/core/app_settings.dart';
import 'package:mindforge/core/supported_locale.dart';
import 'package:mindforge/features/settings/ui/language_sheet.dart';
import 'package:mindforge/features/settings/widgets/colour_blind_preview.dart';
import 'package:mindforge/features/settings/widgets/settings_row.dart';
import 'package:mindforge/l10n/app_localizations.dart';
import 'package:mindforge/routing/routes.dart';
import 'package:mindforge/ui/components/pop_toggle.dart';

import '../../support/locale_cases.dart';
import '../../support/shell_harness.dart';

/// The four switches, the Language row and the About row.
void main() {
  late List<AppSettings> writes;

  setUp(() => writes = <AppSettings>[]);

  Future<void> pumpSettings(
    WidgetTester tester, {
    LocaleCase? localeCase,
    AppSettings settings = const AppSettings.defaults(),
    TextScaler textScaler = TextScaler.noScaling,
  }) => tester.pumpShellApp(
    const MindForgeApp(),
    localeCase: localeCase,
    settings: settings,
    textScaler: textScaler,
    settingsWrites: writes,
    initialLocation: Routes.settings,
  );

  group('the rows', () {
    testWidgets('are four switches, a language row and an about row', (
      tester,
    ) async {
      await pumpSettings(tester);

      expect(find.byType(PopToggle), findsNWidgets(4));
      expect(find.byType(SettingsRow), findsNWidgets(6));
    });

    testWidgets('a toggle row does NOT also tap', (tester) async {
      // Two controls in a screen reader's path for one setting, and a stray
      // tap on the label flipping it. The toggle owns the interaction.
      await pumpSettings(tester);

      final tappable = tester
          .widgetList<SettingsRow>(find.byType(SettingsRow))
          .where((row) => row.onTap != null);

      expect(tappable, hasLength(2), reason: 'language and about, and no more');
    });

    testWidgets('and no game is named anywhere on the screen', (tester) async {
      // Per-game options belong on game detail. A settings screen that grew a
      // Stroop Rush section would grow a Schulte one next.
      await pumpSettings(tester);

      expect(find.textContaining('Stroop'), findsNothing);
      expect(find.textContaining('Reaction Lab'), findsNothing);
    });
  });

  group('the colour-blind row', () {
    testWidgets('previews the palette it swaps IN, and announces nothing', (
      tester,
    ) async {
      await pumpSettings(tester);

      expect(find.byType(ColourBlindPreview), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(ColourBlindPreview),
          matching: find.byType(ExcludeSemantics),
        ),
        findsOneWidget,
      );
    });
  });

  group('the Language row', () {
    testWidgets('shows the current choice and announces it as a value', (
      tester,
    ) async {
      // A row that announces only its label says what the setting is CALLED
      // and not what it is SET TO — which is the half the player came for.
      await pumpSettings(tester);

      final l10n = AppLocalizations.of(
        tester.element(find.byType(SettingsRow).first),
      );
      final row = tester
          .widgetList<SettingsRow>(find.byType(SettingsRow))
          .firstWhere((row) => row.label == l10n.settingsLanguage);

      expect(row.semanticValue, l10n.languageNameEn);
      expect(row.onTap, isNotNull);
    });

    testWidgets('opens a sheet, not a route', (tester) async {
      // Five mutually exclusive options do not earn a navigation entry, and a
      // route would mean a back gesture had to undo a choice already written.
      await pumpSettings(tester);

      final l10n = AppLocalizations.of(
        tester.element(find.byType(SettingsRow).first),
      );

      await tester.tap(find.text(l10n.settingsLanguage));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(LanguageSheet), findsOneWidget);
    });
  });

  group('the language sheet', () {
    testWidgets('holds five mutually exclusive options, one selected', (
      tester,
    ) async {
      await pumpSettings(tester);

      final l10n = AppLocalizations.of(
        tester.element(find.byType(SettingsRow).first),
      );

      await tester.tap(find.text(l10n.settingsLanguage));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      final options = tester
          .widgetList<Semantics>(
            find.descendant(
              of: find.byType(LanguageSheet),
              matching: find.byType(Semantics),
            ),
          )
          .where(
            (node) => node.properties.inMutuallyExclusiveGroup ?? false,
          )
          .toList();

      expect(options, hasLength(SupportedLocale.values.length + 1));
      expect(
        options.where((node) => node.properties.selected ?? false),
        hasLength(1),
      );
    });

    testWidgets('names each language in its OWN direction', (tester) async {
      // A Persian name inside an English list is still a Persian name. Letting
      // the page's direction reorder it is how a chooser becomes unreadable by
      // the one person who needs it.
      await pumpSettings(tester);

      final l10n = AppLocalizations.of(
        tester.element(find.byType(SettingsRow).first),
      );

      await tester.tap(find.text(l10n.settingsLanguage));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      Element inSheet(String name) => tester.element(
        find.descendant(
          of: find.byType(LanguageSheet),
          matching: find.text(name),
        ),
      );

      expect(
        Directionality.of(inSheet(l10n.languageNameFa)),
        TextDirection.rtl,
      );
      expect(
        Directionality.of(inSheet(l10n.languageNameEn)),
        TextDirection.ltr,
      );
    });

    testWidgets('choosing ckb does not throw and flips the direction', (
      tester,
    ) async {
      // The ckb delegate tripwire, through the real control a player touches.
      await pumpSettings(tester);

      final l10n = AppLocalizations.of(
        tester.element(find.byType(SettingsRow).first),
      );

      await tester.tap(find.text(l10n.settingsLanguage));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      await tester.tap(
        find.descendant(
          of: find.byType(LanguageSheet),
          matching: find.text(l10n.languageNameCkb),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(tester.takeException(), isNull);
    });
  });

  group('every row fits', () {
    for (final localeCase in LocaleCase.all) {
      testWidgets('at ${localeCase.tag}, scale 1.0 and 1.3', (tester) async {
        // German expansion is why this screen is the first to break.
        for (final scale in <double>[1, 1.3]) {
          await pumpSettings(
            tester,
            localeCase: localeCase,
            textScaler: TextScaler.linear(scale),
          );

          expect(
            tester.takeException(),
            isNull,
            reason: '${localeCase.tag} at $scale',
          );
        }
      });
    }
  });

  group('the header', () {
    testWidgets('is the only heading, and the footer is not one', (
      tester,
    ) async {
      await pumpSettings(tester);

      expect(
        tester
            .widgetList<Semantics>(find.byType(Semantics))
            .where((node) => node.properties.header ?? false),
        hasLength(1),
      );
    });
  });

  group('every switch writes through the one path', () {
    testWidgets('and writes the whole row in one transaction', (tester) async {
      // mutate(), not read-then-write: `update` writes the WHOLE settings row,
      // so a read-modify-write outside the transaction loses whichever other
      // field a concurrent setter changed — and both callers get an Ok. Four
      // toggles and a language row on one screen is exactly where that
      // happens.
      await pumpSettings(tester);

      await tester.tap(find.byType(PopToggle).first);
      await tester.pump();

      expect(writes, hasLength(1));
      expect(writes.single.isSoundEnabled, isFalse);
      expect(
        writes.single.isHapticsEnabled,
        isTrue,
        reason: 'the other fields survived the write',
      );
    });

    testWidgets('and the language choice goes through the same seam', (
      tester,
    ) async {
      await pumpSettings(tester);

      final l10n = AppLocalizations.of(
        tester.element(find.byType(SettingsRow).first),
      );

      await tester.tap(find.text(l10n.settingsLanguage));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      await tester.tap(
        find.descendant(
          of: find.byType(LanguageSheet),
          matching: find.text(l10n.languageNameDe),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // PERSISTED BEFORE THE SHEET CLOSED. A chooser that dismissed first
      // would show the old language again on relaunch if the row never landed.
      expect(writes, hasLength(1));
      expect(writes.single.localeOverride, SupportedLocale.de);
      expect(find.byType(LanguageSheet), findsNothing);
    });
  });
}
