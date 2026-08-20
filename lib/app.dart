import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindforge/l10n/app_localizations.dart';
import 'package:mindforge/l10n/ckb_localizations.dart';
import 'package:mindforge/l10n/locale_resolution.dart';
import 'package:mindforge/l10n/supported_locales.dart';
import 'package:mindforge/shared/motion/motion_preference_scope.dart';
import 'package:mindforge/theme/sunburst_theme.dart';

/// The delegate list `MaterialApp` is handed, built once.
///
/// The vendored `ckb` delegates come FIRST: `Localizations._loadAll` takes the
/// first delegate of a type that reports the locale supported.
///
/// Top-level rather than inline in `build()`: the input is a `static const` and
/// the result is invariant, so rebuilding it would hand `Localizations` a new
/// list identity on every root rebuild and make it walk `shouldReload` over all
/// seven for nothing.
final List<LocalizationsDelegate<dynamic>> appLocalizationsDelegates =
    localizationsDelegatesFor(AppLocalizations.localizationsDelegates);

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
///
/// It mounts `MotionPreferenceScope` and nothing else above the screens. That
/// is the one place the app's reduce-motion setting turns into
/// `MediaQuery.disableAnimations`, so no widget below decides whether to
/// animate by reading app state.
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
      localizationsDelegates: appLocalizationsDelegates,
      // NOT AppLocalizations.supportedLocales: gen-l10n emits that list
      // alphabetically, so its first entry is ckb and Flutter's fallback for an
      // unsupported system locale would be Kurdish Sorani.
      supportedLocales: supportedLocales,
      // INSIDE MaterialApp, through builder:, not wrapped around it. Above
      // MaterialApp there is no MediaQuery to copyWith from — the one the app
      // reads is inserted BY MaterialApp from the view — so a fold placed
      // outside would either construct a bare MediaQueryData, dropping the
      // size, the text scaler and every accessibility flag, or read a
      // MediaQuery that is not the one the screens below are reading.
      builder: (context, child) =>
          MotionPreferenceScope(child: child ?? const SizedBox.shrink()),
      home: const Scaffold(),
    );
  }
}
