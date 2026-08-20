import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindforge/core/supported_locale.dart';
import 'package:mindforge/data/data_providers.dart';
import 'package:mindforge/l10n/app_localizations.dart';
import 'package:mindforge/l10n/locale_resolution.dart';
import 'package:mindforge/theme/sunburst_colors.dart';
import 'package:mindforge/theme/sunburst_shape.dart';
import 'package:mindforge/theme/sunburst_type.dart';
import 'package:mindforge/ui/components/pop_sheet.dart';
import 'package:mindforge/ui/components/pop_surface.dart';

/// The language chooser: the four shipped locales plus "use the device's".
///
/// **A sheet, not a route.** Five mutually exclusive options do not earn an
/// entry in the navigation stack, and a route would mean a back gesture had to
/// undo a choice that has already been written.
///
/// Each option is rendered in **its own `Directionality` island** with its own
/// script's cascade. `i18n-rtl-l10n` sanctions exactly this for a language
/// picker: a Persian name inside an English list is still a Persian name, and
/// letting the page's direction reorder it is how a chooser becomes unreadable
/// by the one person who needs it.
class LanguageSheet extends ConsumerWidget {
  /// Creates the sheet.
  const LanguageSheet({super.key});

  /// Opens the sheet over [context].
  static Future<void> show(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    builder: (_) => const LanguageSheet(),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final chosen = ref.watch(appSettingsProvider).localeOverride;

    return PopSheet(
      title: l10n.settingsLanguage,
      actions: <Widget>[
        for (final option in <SupportedLocale?>[
          null,
          ...SupportedLocale.values,
        ])
          _Option(
            option: option,
            isSelected: option == chosen,
            onSelected: () async {
              // PERSIST, THEN CLOSE. The write goes through E04's one locale
              // path, and the sheet stays up until it returns — a chooser that
              // dismissed first would show the old language again on relaunch
              // if the row never landed.
              await ref.read(localeControllerProvider).setLocale(option);

              if (context.mounted) Navigator.of(context).pop();
            },
          ),
      ],
    );
  }
}

/// One language, named in itself.
class _Option extends StatelessWidget {
  const _Option({
    required this.option,
    required this.isSelected,
    required this.onSelected,
  });

  final SupportedLocale? option;
  final bool isSelected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final colours = SunburstColors.of(context);
    final shape = SunburstShape.of(context);
    final type = SunburstType.of(context);
    final l10n = AppLocalizations.of(context);
    final locale = option;

    final name = switch (locale) {
      null => l10n.settingsLanguageSystem,
      SupportedLocale.en => l10n.languageNameEn,
      SupportedLocale.de => l10n.languageNameDe,
      SupportedLocale.fa => l10n.languageNameFa,
      SupportedLocale.ckb => l10n.languageNameCkb,
    };

    return Semantics(
      inMutuallyExclusiveGroup: true,
      selected: isSelected,
      button: true,
      label: name,
      child: ExcludeSemantics(
        child: PopSurface(
          fill: isSelected ? colours.accent : colours.surfaceRaised,
          radius: BorderRadiusDirectional.all(shape.radiusMd),
          elevation: isSelected ? PopElevation.e2 : PopElevation.e1,
          padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 12),
          onTap: onSelected,
          child: Row(
            children: <Widget>[
              Expanded(
                child: Directionality(
                  // THE ISLAND. Each name carries its own direction, so a
                  // Persian name in an English list still reads right to left
                  // and an English one in a Persian list still reads left to
                  // right. The ban on a hardcoded root Directionality is about
                  // the page; this is one word that genuinely has its own.
                  textDirection: (locale?.isRightToLeft ?? false)
                      ? TextDirection.rtl
                      : TextDirection.ltr,
                  child: Text(
                    name,
                    style: type.button.copyWith(color: colours.textPrimary),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
