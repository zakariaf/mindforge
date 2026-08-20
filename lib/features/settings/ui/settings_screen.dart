import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindforge/core/app_settings.dart';
import 'package:mindforge/core/supported_locale.dart';
import 'package:mindforge/data/data_providers.dart';
import 'package:mindforge/features/settings/ui/language_sheet.dart';
import 'package:mindforge/features/settings/widgets/colour_blind_preview.dart';
import 'package:mindforge/features/settings/widgets/settings_row.dart';
import 'package:mindforge/features/shell/widgets/ray_header.dart';
import 'package:mindforge/features/shell/widgets/shell_pane.dart';
import 'package:mindforge/features/shell/widgets/wordmark.dart';
import 'package:mindforge/l10n/app_localizations.dart';
import 'package:mindforge/theme/sunburst_colors.dart';
import 'package:mindforge/theme/sunburst_type.dart';
import 'package:mindforge/ui/components/pop_toggle.dart';
import 'package:mindforge/ui/glyphs/sunburst_glyph.dart';

/// The four switches, the Language row and the About row.
///
/// **The Language row is the first control in the app that changes the
/// direction of every other screen.** It writes through E04's one locale write
/// path — persist, then publish — so a language that fails to save is not shown
/// as chosen and then forgotten on relaunch.
///
/// Choosing a language does NOT restart the app: `routerProvider` reads no
/// locale, so the branch stack survives and the player keeps their place.
///
/// **No game appears on this screen.** Per-game options belong on game detail;
/// a settings screen that grew a Stroop Rush section would grow a Schulte one
/// next, and then the shell would know about games again.
class SettingsScreen extends ConsumerWidget {
  /// Creates the screen.
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colours = SunburstColors.of(context);
    final type = SunburstType.of(context);
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(appSettingsProvider);

    return ShellPane(
      header: RayHeader(
        fill: colours.accentAlt,
        // .3, not .5: Settings is a reading screen.
        rays: colours.headerRaySettings,
        padding: RayHeader.tabInset,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Wordmark(),
            const SizedBox(height: 4),
            Semantics(
              header: true,
              child: Text(
                l10n.settingsTitle,
                style: type.displayL.copyWith(color: colours.textInvert),
              ),
            ),
          ],
        ),
      ),
      children: <Widget>[
        SettingsGroup(
          rows: <Widget>[
            _Toggle(
              glyph: SunburstGlyph.sound,
              label: l10n.settingSound,
              value: settings.isSoundEnabled,
              onChanged: (value) => _write(
                ref,
                (current) => current.copyWith(isSoundEnabled: value),
              ),
            ),
            _Toggle(
              glyph: SunburstGlyph.haptics,
              label: l10n.settingHaptics,
              value: settings.isHapticsEnabled,
              onChanged: (value) => _write(
                ref,
                (current) => current.copyWith(isHapticsEnabled: value),
              ),
            ),
            _Toggle(
              glyph: SunburstGlyph.motion,
              label: l10n.settingReduceMotion,
              value: settings.isReduceMotionEnabled,
              onChanged: (value) => _write(
                ref,
                (current) => current.copyWith(isReduceMotionEnabled: value),
              ),
            ),
            _Toggle(
              glyph: SunburstGlyph.contrast,
              label: l10n.settingColourBlind,
              value: settings.isColourBlindPalette,
              // THE PREVIEW SHOWS WHAT THE SETTING SWAPS IN, not what is
              // on screen now. The row is an offer, and previewing the
              // current palette would tell the player nothing about it.
              below: const ColourBlindPreview(),
              onChanged: (value) => _write(
                ref,
                (current) => current.copyWith(isColourBlindPalette: value),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SettingsGroup(
          rows: <Widget>[
            SettingsRow(
              glyph: SunburstGlyph.language,
              label: l10n.settingsLanguage,
              semanticValue: _languageName(l10n, settings.localeOverride),
              trailing: _Value(
                text: _languageName(l10n, settings.localeOverride),
              ),
              onTap: () => LanguageSheet.show(context),
            ),
            SettingsRow(
              glyph: SunburstGlyph.info,
              label: l10n.aboutTitle,
              trailing: const _Chevron(),
              // NOT A DEAD ROW. There is no About screen in E08, so it
              // opens the platform's own licence page — which is where
              // the bundled font licences registered at startup are
              // actually readable, and the only legally required screen
              // in the app.
              onTap: () => showLicensePage(
                context: context,
                applicationName: Wordmark.name,
              ),
            ),
          ],
        ),
        const SizedBox(height: 26),
        const _Footer(),
      ],
    );
  }

  /// One transaction, through the repository.
  ///
  /// `mutate` reads and writes inside the same transaction, so two rows changed
  /// in quick succession cannot lose each other's field — which is exactly what
  /// a screen with four toggles on it invites.
  void _write(WidgetRef ref, AppSettings Function(AppSettings) change) {
    ref.read(writeSettingsProvider)(change).ignore();
  }
}

/// The name of [locale], **in [locale]**.
///
/// Each language is named in itself — "Deutsch", not "German". A chooser that
/// named languages in the current language is unusable by exactly the person
/// who needs it: someone who cannot read the current one.
String _languageName(AppLocalizations l10n, SupportedLocale? locale) =>
    switch (locale) {
      null => l10n.settingsLanguageSystem,
      SupportedLocale.en => l10n.languageNameEn,
      SupportedLocale.de => l10n.languageNameDe,
      SupportedLocale.fa => l10n.languageNameFa,
      SupportedLocale.ckb => l10n.languageNameCkb,
    };

/// A settings row whose control is a toggle.
class _Toggle extends StatelessWidget {
  const _Toggle({
    required this.glyph,
    required this.label,
    required this.value,
    required this.onChanged,
    this.below,
  });

  final SunburstGlyph glyph;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Widget? below;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return SettingsRow(
      glyph: glyph,
      label: label,
      below: below,
      // NO onTap. The toggle owns the interaction; a row that also tapped
      // would put two controls in a screen reader's path for one setting, and
      // a stray tap on the label would flip it.
      trailing: PopToggle(
        value: value,
        onLabel: l10n.toggleOn,
        offLabel: l10n.toggleOff,
        semanticLabel: label,
        onChanged: onChanged,
      ),
    );
  }
}

/// The current value at the end of a row.
class _Value extends StatelessWidget {
  const _Value({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colours = SunburstColors.of(context);
    final type = SunburstType.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Flexible(
          child: Text(
            text,
            textAlign: TextAlign.end,
            style: type.chip.copyWith(color: colours.textSecondary),
          ),
        ),
        const SizedBox(width: 6),
        const _Chevron(),
      ],
    );
  }
}

/// The mark that says a row opens something.
class _Chevron extends StatelessWidget {
  const _Chevron();

  @override
  Widget build(BuildContext context) => SunburstGlyphIcon(
    // It MIRRORS: "forward" is a reading-direction word, and the glyph table
    // decides that, not this file.
    SunburstGlyph.chevronForward,
    size: 20,
    colour: SunburstColors.of(context).textSecondary,
  );
}

/// The product line under the last group.
///
/// `MindForge` is a Latin run and it is pinned left to right by [Wordmark],
/// which is why the footer uses the lockup rather than splicing the name into
/// the tagline.
class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    final colours = SunburstColors.of(context);
    final type = SunburstType.of(context);

    return Column(
      children: <Widget>[
        const Wordmark(),
        const SizedBox(height: 6),
        Text(
          AppLocalizations.of(context).aboutTagline,
          textAlign: TextAlign.center,
          style: type.caption.copyWith(color: colours.textSecondary),
        ),
      ],
    );
  }
}
