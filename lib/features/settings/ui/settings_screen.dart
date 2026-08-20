import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindforge/core/app_settings.dart';
import 'package:mindforge/core/supported_locale.dart';
import 'package:mindforge/data/data_providers.dart';
import 'package:mindforge/features/shell/widgets/ray_header.dart';
import 'package:mindforge/l10n/app_localizations.dart';
import 'package:mindforge/l10n/locale_resolution.dart';
import 'package:mindforge/theme/sunburst_colors.dart';
import 'package:mindforge/theme/sunburst_type.dart';
import 'package:mindforge/ui/components/pop_card.dart';
import 'package:mindforge/ui/components/pop_toggle.dart';

/// The four toggles and the Language row.
///
/// **The Language row is the first control in the app that changes the
/// direction of every other screen.** It writes through E04's one locale write
/// path — persist, then publish — so a language that fails to save is not shown
/// as chosen and then forgotten on relaunch.
///
/// Choosing a language does NOT restart the app: `routerProvider` reads no
/// locale, so the branch stack survives and the player keeps their place.
class SettingsScreen extends ConsumerWidget {
  /// Creates the screen.
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colours = SunburstColors.of(context);
    final type = SunburstType.of(context);
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(appSettingsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        RayHeader(
          fill: colours.accentAlt,
          // .3, not .5: Settings is a reading screen.
          rays: colours.headerRaySettings,
          padding: RayHeader.tabInset,
          child: Semantics(
            header: true,
            child: Text(
              l10n.settingsTitle,
              style: type.displayL.copyWith(color: colours.textPrimary),
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsetsDirectional.fromSTEB(20, 20, 20, 20),
            children: <Widget>[
              _Toggle(
                label: l10n.settingSound,
                value: settings.isSoundEnabled,
                onChanged: (value) => _write(
                  ref,
                  (current) => current.copyWith(isSoundEnabled: value),
                ),
              ),
              _Toggle(
                label: l10n.settingHaptics,
                value: settings.isHapticsEnabled,
                onChanged: (value) => _write(
                  ref,
                  (current) => current.copyWith(isHapticsEnabled: value),
                ),
              ),
              _Toggle(
                label: l10n.settingReduceMotion,
                value: settings.isReduceMotionEnabled,
                onChanged: (value) => _write(
                  ref,
                  (current) => current.copyWith(isReduceMotionEnabled: value),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.settingsLanguage,
                style: type.sectionLabel.copyWith(
                  color: colours.textSecondary,
                ),
              ),
              const SizedBox(height: 10),
              const _LanguageRow(),
            ],
          ),
        ),
      ],
    );
  }

  /// One transaction, through the repository.
  ///
  /// `mutate` reads and writes inside the same transaction, so two rows changed
  /// in quick succession cannot lose each other's field — which is exactly what
  /// a screen with four toggles on it invites.
  void _write(WidgetRef ref, AppSettings Function(AppSettings) change) {
    ref.read(settingsRepositoryProvider).mutate(change).ignore();
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final type = SunburstType.of(context);
    final colours = SunburstColors.of(context);

    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: 10),
      child: PopCard(
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                label,
                style: type.title.copyWith(color: colours.textPrimary),
              ),
            ),
            PopToggle(
              value: value,
              onLabel: l10n.toggleOn,
              offLabel: l10n.toggleOff,
              semanticLabel: label,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}

/// The language chooser: the four shipped locales plus "system".
class _LanguageRow extends ConsumerWidget {
  const _LanguageRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final type = SunburstType.of(context);
    final colours = SunburstColors.of(context);
    final chosen = ref.watch(appSettingsProvider).localeOverride;

    return PopCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (final option in <SupportedLocale?>[
            null,
            ...SupportedLocale.values,
          ])
            InkWell(
              onTap: () =>
                  ref.read(localeControllerProvider).setLocale(option).ignore(),
              child: Padding(
                padding: const EdgeInsetsDirectional.symmetric(vertical: 10),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        // Each language is named IN ITSELF — "Deutsch", not
                        // "German". A chooser that named languages in the
                        // current language is unusable by exactly the person
                        // who needs it: someone who cannot read the current one.
                        _name(l10n, option),
                        style: type.body.copyWith(color: colours.textPrimary),
                      ),
                    ),
                    if (option == chosen)
                      Text(
                        '•',
                        style: type.title.copyWith(color: colours.accentDeep),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _name(AppLocalizations l10n, SupportedLocale? locale) =>
      switch (locale) {
        null => l10n.settingsLanguageSystem,
        SupportedLocale.en => l10n.languageNameEn,
        SupportedLocale.de => l10n.languageNameDe,
        SupportedLocale.fa => l10n.languageNameFa,
        SupportedLocale.ckb => l10n.languageNameCkb,
      };
}
