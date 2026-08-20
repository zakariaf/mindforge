import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mindforge/core/app_version.dart';
import 'package:mindforge/features/settings/widgets/settings_row.dart';
import 'package:mindforge/features/shell/widgets/top_bar.dart';
import 'package:mindforge/features/shell/widgets/wordmark.dart';
import 'package:mindforge/l10n/app_localizations.dart';
import 'package:mindforge/routing/routes.dart';
import 'package:mindforge/theme/sunburst_colors.dart';
import 'package:mindforge/theme/sunburst_shape.dart';
import 'package:mindforge/theme/sunburst_type.dart';
import 'package:mindforge/ui/components/pop_card.dart';
import 'package:mindforge/ui/components/pop_icon_button.dart';
import 'package:mindforge/ui/glyphs/sunburst_glyph.dart';

/// What this app is, and what it promises.
///
/// **It replaces a row that opened the platform's licence list.** Settings had
/// an About row and no About screen, so it showed a wall of package licences —
/// which says nothing about MindForge and buries the font licences it was
/// there to surface.
///
/// Every claim here is one the code can be checked against: there is no HTTP
/// client in the dependency tree, no auth, no analytics package, and the only
/// store is a SQLite file in the app's own container. `dependency_policy_test`
/// is what keeps them true.
class AboutScreen extends ConsumerWidget {
  /// Creates the screen.
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colours = SunburstColors.of(context);
    final type = SunburstType.of(context);
    final l10n = AppLocalizations.of(context);

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          TopBar(
            title: l10n.aboutTitle,
            leading: PopIconButton(
              glyph: SunburstGlyph.back,
              semanticLabel: l10n.settingsTitle,
              onPressed: () => context.go(Routes.settings),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsetsDirectional.fromSTEB(20, 4, 20, 24),
              children: <Widget>[
                PopCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Wordmark(),
                      const SizedBox(height: SunburstShape.space3),
                      // The screen's one h1. The wordmark above it is a
                      // drawing and the top bar's title is decoration.
                      Semantics(
                        header: true,
                        child: Text(
                          l10n.aboutTitle,
                          style: type.title.copyWith(
                            color: colours.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: SunburstShape.space2),
                      Text(
                        l10n.aboutTagline,
                        style: type.body.copyWith(
                          color: colours.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: SunburstShape.space4),
                _Promise(
                  glyph: SunburstGlyph.info,
                  title: l10n.aboutOffline,
                  body: l10n.aboutOfflineBody,
                ),
                const SizedBox(height: SunburstShape.space3),
                _Promise(
                  glyph: SunburstGlyph.lock,
                  title: l10n.aboutPrivate,
                  body: l10n.aboutPrivateBody,
                ),
                const SizedBox(height: SunburstShape.space3),
                _Promise(
                  glyph: SunburstGlyph.star,
                  title: l10n.aboutLicenceTitle,
                  // The SPDX identifier is passed in, not translated: it is a
                  // proper noun, and it carries ASCII digits that the fa and
                  // ckb numeral gate rightly refuses to hold.
                  body: l10n.aboutLicenceBody(kAppLicence),
                ),
                const SizedBox(height: SunburstShape.space4),
                SettingsGroup(
                  rows: <Widget>[
                    SettingsRow(
                      glyph: SunburstGlyph.language,
                      label: l10n.aboutVersion,
                      trailing: Text(
                        // ASCII, deliberately, and the one number in the app
                        // that is. A version is an identifier a player reads
                        // back to a maintainer in a bug report; rendering it
                        // in Eastern Arabic digits would make `۱.۰.۰` and
                        // `1.0.0` look like two different builds.
                        kAppVersion,
                        style: type.body.copyWith(
                          color: colours.textSecondary,
                        ),
                      ),
                    ),
                    SettingsRow(
                      glyph: SunburstGlyph.info,
                      label: l10n.aboutThirdParty,
                      onTap: () => showLicensePage(
                        context: context,
                        applicationName: l10n.appTitle,
                        applicationVersion: kAppVersion,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One promise: a heading and the sentence that makes it checkable.
class _Promise extends StatelessWidget {
  const _Promise({
    required this.glyph,
    required this.title,
    required this.body,
  });

  final SunburstGlyph glyph;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final colours = SunburstColors.of(context);
    final type = SunburstType.of(context);

    return PopCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // DECORATION. The heading beside it says the same thing in words.
          ExcludeSemantics(
            child: SunburstGlyphIcon(glyph, colour: colours.textPrimary),
          ),
          const SizedBox(width: SunburstShape.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: type.title.copyWith(color: colours.textPrimary),
                ),
                const SizedBox(height: SunburstShape.space1),
                Text(
                  body,
                  style: type.body.copyWith(color: colours.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
