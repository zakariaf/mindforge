import 'package:flutter/material.dart';
import 'package:mindforge/l10n/app_localizations.dart';
import 'package:mindforge/l10n/ckb_localizations.dart';
import 'package:mindforge/l10n/supported_locales.dart';
import 'package:mindforge/theme/sunburst_theme.dart';

/// The root widget.
///
/// Themed from E03 onward. **Light only** — there is no `darkTheme:` and no
/// `themeMode:`, because adding a dark mode is a new design direction rather
/// than a token flip.
///
/// There is still no `locale:`: the app follows the device until E04 adds the
/// persisted override.
class MindForgeApp extends StatelessWidget {
  /// Creates the root widget.
  const MindForgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MindForge',
      theme: buildSunburstTheme(),
      // The vendored ckb delegates come FIRST: Localizations._loadAll takes
      // the first delegate of a type that reports the locale supported.
      localizationsDelegates: localizationsDelegatesFor(
        AppLocalizations.localizationsDelegates,
      ),
      // NOT AppLocalizations.supportedLocales: gen-l10n emits that list
      // alphabetically, so its first entry is ckb and Flutter's fallback for an
      // unsupported system locale would be Kurdish Sorani.
      supportedLocales: supportedLocales,
      home: const Scaffold(),
    );
  }
}
