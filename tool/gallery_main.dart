import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindforge/core/hud_tone.dart';
import 'package:mindforge/core/supported_locale.dart';
import 'package:mindforge/l10n/app_localizations.dart';
import 'package:mindforge/l10n/ckb_localizations.dart';
import 'package:mindforge/l10n/supported_locales.dart';
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
void main() => runApp(const ProviderScope(child: _GalleryApp()));

class _GalleryApp extends StatefulWidget {
  const _GalleryApp();

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
    home: _Gallery(
      locale: _locale,
      onLocale: (locale) => setState(() => _locale = locale),
    ),
  );
}

class _Gallery extends StatelessWidget {
  const _Gallery({required this.locale, required this.onLocale});

  final SupportedLocale locale;
  final ValueChanged<SupportedLocale> onLocale;

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
