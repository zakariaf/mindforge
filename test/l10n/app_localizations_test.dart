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
    expect(l10n.aboutTagline, 'Train your brain. No wifi needed.');
    expect(l10n.yourGamesTitle, 'Your games');
    expect(l10n.playButton, 'Play');
    expect(l10n.bestLabel, 'BEST');
    expect(l10n.settingsLanguage, 'Language');
  });
}
