import 'package:flutter/material.dart';
import 'package:mindforge/theme/sunburst_colors.dart';
import 'package:mindforge/theme/sunburst_shape.dart';
import 'package:mindforge/theme/sunburst_type.dart';
import 'package:mindforge/ui/components/pop_surface.dart';
import 'package:mindforge/ui/glyphs/sunburst_glyph.dart';

/// Which skin the Daily Mix card wears.
///
/// One widget, two fills. Two widgets would be two places to fix on the day the
/// summary string changes.
enum DailyMixVariant {
  /// The grape card on Home, where it is the loudest thing in the pane.
  grape,

  /// The paper card on game detail, where the hero above it already is.
  paper,
}

/// The card that starts a run without choosing a game first.
///
/// **The whole card is one tap target, and it goes somewhere.** `app.html`
/// draws a chevron badge on it; a badge that leads nowhere is the dead
/// affordance E11 forbids, so the card owns the tap and the badge is
/// decoration inside it — one stop for a screen reader, not two.
class DailyMixCard extends StatelessWidget {
  /// Creates the card.
  const DailyMixCard({
    required this.title,
    required this.summary,
    required this.onTap,
    this.variant = DailyMixVariant.grape,
    super.key,
  });

  /// The already-localized title.
  final String title;

  /// The already-localized line under it.
  final String summary;

  /// Where it goes.
  final VoidCallback onTap;

  /// Which skin.
  final DailyMixVariant variant;

  /// The go badge's diameter. `app.html`: `.daily .go{width:48px}`.
  static const double badgeSize = 48;

  @override
  Widget build(BuildContext context) {
    final colours = SunburstColors.of(context);
    final shape = SunburstShape.of(context);
    final type = SunburstType.of(context);

    // Grape is a dark fill and ink on it is 2.2:1; paper is the opposite. One
    // colour for both is the defect this pair exists to prevent.
    final (Color fill, Color title_, Color summary_) = switch (variant) {
      DailyMixVariant.grape => (
        colours.accentAlt,
        colours.textInvert,
        colours.textInvert,
      ),
      DailyMixVariant.paper => (
        colours.surfaceRaised,
        colours.textPrimary,
        colours.textSecondary,
      ),
    };

    return PopSurface(
      fill: fill,
      radius: BorderRadiusDirectional.all(shape.radiusLg),
      padding: const EdgeInsetsDirectional.fromSTEB(16, 17, 16, 17),
      semanticLabel: '$title. $summary',
      onTap: onTap,
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  title,
                  style: switch (variant) {
                    DailyMixVariant.grape => type.dailyTitle,
                    // The paper card sits under a hero that already carries a
                    // 38pt title, so app.html steps this one down to 19.
                    DailyMixVariant.paper => type.dailyTitle.copyWith(
                      fontSize: type.title.fontSize,
                    ),
                  }.copyWith(color: title_),
                ),
                const SizedBox(height: 3),
                Text(
                  summary,
                  style: type.caption.copyWith(color: summary_),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          ExcludeSemantics(
            child: PopSurface(
              fill: switch (variant) {
                DailyMixVariant.grape => colours.accent,
                DailyMixVariant.paper => colours.accentAlt,
              },
              radius: BorderRadiusDirectional.all(shape.radiusPill),
              elevation: PopElevation.e1,
              minTarget: 0,
              padding: const EdgeInsetsDirectional.all(13),
              child: SunburstGlyphIcon(
                SunburstGlyph.go,
                size: 20,
                colour: switch (variant) {
                  DailyMixVariant.grape => colours.textPrimary,
                  DailyMixVariant.paper => colours.textInvert,
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
