import 'package:flutter/material.dart';
import 'package:mindforge/l10n/app_localizations.dart';

/// The root widget.
///
/// Deliberately theme-less. E03 owns `lib/theme/`, and a placeholder `theme:`
/// here would be a raw aesthetic value shipped by the epic that promised not to
/// ship one. There is no `locale:` either: the app follows the device until E04
/// adds the persisted override.
class MindForgeApp extends StatelessWidget {
  /// Creates the root widget.
  const MindForgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'MindForge',
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(),
    );
  }
}
