import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindforge/l10n/app_localizations.dart';
import 'package:mindforge/l10n/ckb_localizations.dart';
import 'package:mindforge/l10n/locale_resolution.dart';
import 'package:mindforge/l10n/supported_locales.dart';
import 'package:mindforge/theme/sunburst_theme.dart';

/// The root widget.
///
/// Themed from E03 onward. **Light only** — there is no `darkTheme:` and no
/// `themeMode:`, because adding a dark mode is a new design direction rather
/// than a token flip.
///
/// The locale is resolved from the persisted override, falling back to the
/// system locale and then to `en`. The direction follows it: nothing here names
/// a `TextDirection`, because a hardcoded one is exactly what hides a
/// physical-side bug.
class MindForgeApp extends ConsumerWidget {
  /// Creates the root widget.
  const MindForgeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      // Resolved before the first frame: settingsProvider is SEEDED with the
      // row bootstrap() read ahead of runApp, so a Persian user's cold start
      // never paints an English LTR frame and then flips.
      locale: Locale(ref.watch(localeProvider).tag),
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
