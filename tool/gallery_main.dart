import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindforge/core/app_settings.dart';
import 'package:mindforge/core/hud_tone.dart';
import 'package:mindforge/core/supported_locale.dart';
import 'package:mindforge/data/data_providers.dart';
import 'package:mindforge/l10n/app_localizations.dart';
import 'package:mindforge/l10n/ckb_localizations.dart';
import 'package:mindforge/l10n/supported_locales.dart';
import 'package:mindforge/shared/feedback/haptic_gateway.dart';
import 'package:mindforge/shared/motion/motion_preference_scope.dart';
import 'package:mindforge/theme/sunburst_colors.dart';
import 'package:mindforge/theme/sunburst_shape.dart';
import 'package:mindforge/theme/sunburst_theme.dart';
import 'package:mindforge/theme/sunburst_type.dart';
import 'package:mindforge/ui/components/difficulty_segmented.dart';
import 'package:mindforge/ui/components/game_card.dart';
import 'package:mindforge/ui/components/hud_pill.dart';
import 'package:mindforge/ui/components/pop_badge.dart';
import 'package:mindforge/ui/components/pop_bottom_nav.dart';
import 'package:mindforge/ui/components/pop_button.dart';
import 'package:mindforge/ui/components/pop_card.dart';
import 'package:mindforge/ui/components/pop_chip.dart';
import 'package:mindforge/ui/components/pop_grid_tile.dart';
import 'package:mindforge/ui/components/pop_icon_button.dart';
import 'package:mindforge/ui/components/pop_progress_bar.dart';
import 'package:mindforge/ui/components/pop_toggle.dart';
import 'package:mindforge/ui/components/timer_ring.dart';
import 'package:mindforge/ui/glyphs/sunburst_glyph.dart';

/// The component gallery, for looking at the catalog on a real device.
///
/// The one thing the host-side golden lane cannot prove is how iOS itself
/// shapes Arabic script — joining, contextual forms, the way a Persian numeral
/// sits on its baseline. That is a device question, so this is a device app.
///
///   flutter run -t tool/gallery_main.dart -d `the canonical simulator`
void main() => runApp(galleryRoot());

/// The gallery's whole widget tree, including its overrides.
///
/// Named and returned rather than inlined into `runApp` so a smoke test can
/// pump the real thing. **The overrides are the point.** Two providers throw
/// until they are supplied — `hapticGatewayProvider` and
/// `initialAppSettingsProvider` — deliberately, so a missing override in an
/// entry point is loud rather than silent. Every press in the catalog reaches
/// both through `FeedbackService`, so without them this app renders perfectly
/// and throws on the first tap. It did, on device, and only a smoke test that
/// pumps this exact tree would have said so: the app has `bootstrap()` and
/// every widget test has the harness.
///
/// [settings] seeds the scope; the gallery's own switches replace it, so a
/// developer can put the catalog into Reduce motion or Haptics off on a real
/// device — the configuration the manual pass has to cover and no golden can.
Widget galleryRoot({AppSettings settings = const AppSettings.defaults()}) =>
    _GalleryRoot(initialSettings: settings);

/// Holds the settings ABOVE the scope, so flipping one rebuilds the overrides.
///
/// A `ProviderScope` reads its overrides once per build, so the state that
/// drives them cannot live inside it.
class _GalleryRoot extends StatefulWidget {
  const _GalleryRoot({required this.initialSettings});

  final AppSettings initialSettings;

  @override
  State<_GalleryRoot> createState() => _GalleryRootState();
}

class _GalleryRootState extends State<_GalleryRoot> {
  late AppSettings _settings = widget.initialSettings;

  @override
  Widget build(BuildContext context) => ProviderScope(
    overrides: [
      hapticGatewayProvider.overrideWithValue(const LiveHapticGateway()),
      initialAppSettingsProvider.overrideWithValue(_settings),
      settingsProvider.overrideWith(
        (ref) => Stream<AppSettings>.value(_settings),
      ),
    ],
    child: _GalleryApp(
      settings: _settings,
      onSettings: (settings) => setState(() => _settings = settings),
    ),
  );
}

class _GalleryApp extends StatefulWidget {
  const _GalleryApp({required this.settings, required this.onSettings});

  final AppSettings settings;
  final ValueChanged<AppSettings> onSettings;

  @override
  State<_GalleryApp> createState() => _GalleryAppState();
}

class _GalleryAppState extends State<_GalleryApp> {
  /// Starts from the DEVICE's language, so
  /// `simctl launch ... -AppleLanguages "(ckb)"` opens the gallery in Sorani
  /// without anyone tapping anything. The switcher is for comparing without
  /// relaunching.
  late SupportedLocale _locale =
      SupportedLocale.tryParse(
        WidgetsBinding.instance.platformDispatcher.locale.languageCode,
      ) ??
      SupportedLocale.en;

  @override
  Widget build(BuildContext context) => MaterialApp(
    theme: buildSunburstTheme(),
    locale: Locale(_locale.tag),
    supportedLocales: supportedLocales,
    localizationsDelegates: localizationsDelegatesFor(
      AppLocalizations.localizationsDelegates,
    ),
    // MotionPreferenceScope exactly as lib/app.dart mounts it, or the Reduce
    // motion switch below would change a setting nothing reads.
    builder: (context, child) =>
        MotionPreferenceScope(child: child ?? const SizedBox.shrink()),
    home: _Gallery(
      locale: _locale,
      onLocale: (locale) => setState(() => _locale = locale),
      settings: widget.settings,
      onSettings: widget.onSettings,
    ),
  );
}

class _Gallery extends StatelessWidget {
  const _Gallery({
    required this.locale,
    required this.onLocale,
    required this.settings,
    required this.onSettings,
  });

  final SupportedLocale locale;
  final ValueChanged<SupportedLocale> onLocale;
  final AppSettings settings;
  final ValueChanged<AppSettings> onSettings;

  @override
  Widget build(BuildContext context) {
    final colours = SunburstColors.of(context);
    final type = SunburstType.of(context);
    final strings = _specimens[locale.tag]!;

    return Scaffold(
      backgroundColor: colours.surface,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.all(SunburstShape.space3),
              child: Wrap(
                spacing: 8,
                children: [
                  for (final option in SupportedLocale.values)
                    PopChip(
                      label: option.tag,
                      fill: option == locale ? colours.accent : null,
                    ),
                ],
              ),
            ),
            // The three switches the manual pass needs on a real device. No
            // golden can render "a press with Reduce motion on"; a finger can.
            Padding(
              padding: const EdgeInsetsDirectional.symmetric(horizontal: 12),
              child: Wrap(
                spacing: 8,
                children: [
                  // PopButton, not PopChip: a chip is a label and carries no
                  // tap of its own, and a developer tool must not be the reason
                  // a catalog component grows an inlet nothing in the app uses.
                  PopButton(
                    label: settings.isReduceMotionEnabled
                        ? 'motion off'
                        : 'motion on',
                    variant: settings.isReduceMotionEnabled
                        ? PopButtonVariant.secondary
                        : PopButtonVariant.primary,
                    onPressed: () => onSettings(
                      settings.copyWith(
                        isReduceMotionEnabled: !settings.isReduceMotionEnabled,
                      ),
                    ),
                  ),
                  PopButton(
                    label: settings.isHapticsEnabled
                        ? 'haptics on'
                        : 'haptics off',
                    variant: settings.isHapticsEnabled
                        ? PopButtonVariant.primary
                        : PopButtonVariant.secondary,
                    onPressed: () => onSettings(
                      settings.copyWith(
                        isHapticsEnabled: !settings.isHapticsEnabled,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.symmetric(horizontal: 12),
              child: Row(
                children: [
                  for (final option in SupportedLocale.values)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsetsDirectional.all(2),
                        child: PopButton(
                          label: option.tag,
                          variant: option == locale
                              ? PopButtonVariant.primary
                              : PopButtonVariant.secondary,
                          onPressed: () => onLocale(option),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsetsDirectional.all(SunburstShape.space4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('${locale.tag}  ·  the catalog', style: type.title),
                    const SizedBox(height: 12),
                    PopButton(label: strings[0], onPressed: () {}),
                    const SizedBox(height: 8),
                    PopButton(
                      label: strings[0],
                      size: PopButtonSize.large,
                      leading: SunburstGlyph.go,
                      onPressed: () {},
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        PopIconButton(
                          glyph: SunburstGlyph.back,
                          semanticLabel: strings[1],
                          onPressed: () {},
                        ),
                        const SizedBox(width: 8),
                        PopChip(label: strings[1], glyph: SunburstGlyph.flame),
                        const SizedBox(width: 8),
                        PopBadge(
                          label: strings[1],
                          variant: PopBadgeVariant.best,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    PopCard(child: Text(strings[2], style: type.body)),
                    const SizedBox(height: 8),
                    GameCard(
                      title: strings[3],
                      subtitle: strings[2],
                      accent: colours.gameStroop,
                      semanticLabel: strings[3],
                      bestLabel: strings[4],
                      bestValue: strings[5],
                      onTap: () {},
                    ),
                    const SizedBox(height: 8),
                    DifficultySegmented(
                      labels: <String>[strings[6], strings[7], strings[8]],
                      selectedIndex: 1,
                      onSelected: (_) {},
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        HudPill(label: strings[4], value: strings[5]),
                        const SizedBox(width: 8),
                        HudPill(
                          label: strings[4],
                          value: strings[9],
                          tone: HudTone.alarm,
                        ),
                        const SizedBox(width: 8),
                        PopGridTile(
                          label: strings[10],
                          state: PopGridTileState.next,
                          semanticLabel: strings[10],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    PopProgressBar(value: 0.45, semanticLabel: strings[4]),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        PopToggle(
                          value: true,
                          onLabel: strings[11],
                          offLabel: strings[12],
                          semanticLabel: strings[1],
                          onChanged: (_) {},
                        ),
                        const SizedBox(width: 12),
                        TimerRing(
                          progress: 0.4,
                          label: strings[9],
                          semanticLabel: strings[4],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            PopBottomNav(
              items: <PopNavItem>[
                PopNavItem(glyph: SunburstGlyph.navPlay, label: strings[13]),
                PopNavItem(glyph: SunburstGlyph.navStats, label: strings[14]),
                PopNavItem(
                  glyph: SunburstGlyph.navSettings,
                  label: strings[15],
                ),
              ],
              selectedIndex: 0,
              onSelected: (_) {},
            ),
          ],
        ),
      ),
    );
  }
}

/// The same specimens the golden lane uses, inlined so this tool depends on
/// nothing under `test/`.
const Map<String, List<String>> _specimens = <String, List<String>>{
  'en': <String>[
    'Play',
    'Reaction',
    'Tap the colour, not the word',
    'Stroop Rush',
    'Score',
    '1,480',
    'Chill',
    'Classic',
    'Blitz',
    '18.6',
    '25',
    'ON',
    'OFF',
    'Play',
    'Stats',
    'Settings',
  ],
  'de': <String>[
    'Spielen',
    'Reaktionszeit',
    'Tippe die Farbe, nicht das geschriebene Wort',
    'Stroop-Ansturm',
    'Punktzahl',
    '1.480',
    'Gemütlich',
    'Klassisch',
    'Blitzschnell',
    '18,6',
    '25',
    'AN',
    'AUS',
    'Spielen',
    'Statistiken',
    'Einstellungen',
  ],
  'fa': <String>[
    'شروع',
    'واکنش',
    'رنگ را بزن، نه واژه را',
    'شتاب استروپ',
    'امتیاز',
    '۱٬۴۸۰',
    'آرام',
    'کلاسیک',
    'برق‌آسا',
    '۱۸٫۶',
    '۲۵',
    'روشن',
    'خاموش',
    'بازی',
    'آمار',
    'تنظیمات',
  ],
  'ckb': <String>[
    'دەستپێکردن',
    'کاردانەوە',
    'ڕەنگەکە دابگرە، نەک وشەکە',
    'خێرایی ستروپ',
    'خاڵ',
    '۱٬۴۸۰',
    'ئارام',
    'کلاسیک',
    'خێرا',
    '۱۸٫۶',
    '۲۵',
    'کارا',
    'ناکارا',
    'یاری',
    'ئامار',
    'ڕێکخستن',
  ],
};
