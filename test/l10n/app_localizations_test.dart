import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/l10n/app_localizations.dart';

void main() {
  testWidgets('every seeded key resolves under en', (tester) async {
    late AppLocalizations l10n;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            l10n = AppLocalizations.of(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(l10n.appTitle, 'MindForge');
    expect(l10n.homeTagline, 'Train your brain. No wifi needed.');
    expect(l10n.homeYourGames, 'Your games');
    expect(l10n.actionPlay, 'Play');
    expect(l10n.labelBest, 'BEST');
    expect(l10n.settingsLanguage, 'Language');
  });
}
